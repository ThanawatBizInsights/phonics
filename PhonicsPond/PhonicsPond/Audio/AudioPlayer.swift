import AVFoundation
import Foundation
import Observation

/// One speech channel for every teaching clip.
///
/// - Starting a clip stops the one already playing.
/// - Effects never play while speech is playing.
/// - On an interruption or when the app leaves the foreground, audio stops and
///   `needsReplayCue` turns on, so the screen can pulse its replay button.
///   Nothing restarts by itself.
/// - A missing recording never blocks the lesson: the completion runs after a
///   short pause, and the ID is listed in `missingIDs` (shown in debug builds).
@MainActor
@Observable
final class AudioPlayer: NSObject {
    private(set) var currentID: String?
    private(set) var missingIDs: Set<String> = []
    /// The most recent missing clip, for the debug banner.
    var lastMissing: String?
    var needsReplayCue = false
    var effectsEnabled = true

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var effectPlayer: AVAudioPlayer?
    @ObservationIgnored private var completion: (() -> Void)?
    @ObservationIgnored private var token = 0
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private let bundle: Bundle

    static let fileExtensions = ["wav", "m4a", "caf", "mp3"]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        super.init()
        configureSession()
        observeInterruptions()
    }

    var isPlaying: Bool { currentID != nil }

    func url(for id: String) -> URL? {
        for ext in Self.fileExtensions {
            if let url = bundle.url(forResource: id, withExtension: ext) { return url }
        }
        return nil
    }

    func isAvailable(_ id: String) -> Bool { url(for: id) != nil }

    /// Play one clip, stopping anything already playing.
    func play(_ id: String, then completion: (() -> Void)? = nil) {
        stopSpeech()
        token += 1
        let myToken = token
        currentID = id
        self.completion = completion

        guard let url = url(for: id) else {
            missingIDs.insert(id)
            lastMissing = id
            #if DEBUG
            print("[audio] missing recording: \(id)")
            #endif
            // Keep the flow moving at a natural pace without the clip.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                self.finish(token: myToken)
            }
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            self.player = player
            effectPlayer?.stop()
            player.play()
        } catch {
            missingIDs.insert(id)
            lastMissing = id
            Task { @MainActor in self.finish(token: myToken) }
        }
    }

    func play(_ prompt: Prompt, then completion: (() -> Void)? = nil) {
        play(prompt.rawValue, then: completion)
    }

    /// Play clips one after another with a gap between them. Any new `play` cancels the rest.
    func playSequence(_ ids: [String], gap: TimeInterval = 0.25, then completion: (() -> Void)? = nil) {
        guard let first = ids.first else { completion?(); return }
        play(first) { [weak self] in
            guard let self else { return }
            let rest = Array(ids.dropFirst())
            if rest.isEmpty { completion?(); return }
            let expected = self.token
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(gap * 1_000_000_000))
                guard self.token == expected else { return }
                self.playSequence(rest, gap: gap, then: completion)
            }
        }
    }

    /// Stop everything and drop pending completions. Used when leaving a screen.
    func stop() {
        stopSpeech()
        effectPlayer?.stop()
        token += 1
    }

    /// Soft chime after a sticker. Skipped if speech is playing or effects are off.
    func playEffect(_ effect: Effect) {
        guard let url = url(for: effect.rawValue) else {
            missingIDs.insert(effect.rawValue)
            lastMissing = effect.rawValue
            return
        }
        guard effectsEnabled, !isPlaying else { return }
        effectPlayer = try? AVAudioPlayer(contentsOf: url)
        effectPlayer?.volume = 0.6
        effectPlayer?.play()
    }

    /// App left the foreground or another app took audio.
    /// The replay button pulses afterwards; nothing auto-plays on return.
    func interrupt() {
        stop()
        needsReplayCue = true
    }

    // MARK: Private

    private func stopSpeech() {
        player?.stop()
        player = nil
        completion = nil
        currentID = nil
    }

    fileprivate func finish(token finishedToken: Int) {
        guard finishedToken == token else { return }
        currentID = nil
        player = nil
        let done = completion
        completion = nil
        done?()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // Playback: lesson speech is heard even with the silent switch on.
        try? session.setCategory(.playback, mode: .spokenAudio, options: [])
        try? session.setActive(true)
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard raw == AVAudioSession.InterruptionType.began.rawValue else { return }
            MainActor.assumeIsolated { self?.interruptForSession() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            // Headphones unplugged: stop rather than blast from the speaker.
            let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            guard raw == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
            MainActor.assumeIsolated { self?.interruptForSession() }
        })
    }

    private func interruptForSession() {
        interrupt()
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in
            guard let current = self.player, ObjectIdentifier(current) == id else { return }
            self.finish(token: self.token)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in
            guard let current = self.player, ObjectIdentifier(current) == id else { return }
            self.finish(token: self.token)
        }
    }
}
