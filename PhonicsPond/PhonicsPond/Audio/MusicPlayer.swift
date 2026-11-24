import AVFoundation
import Foundation
import Observation

/// One background-music player for the whole app.
///
/// - A single looping track (`music_pond_loop`) keeps playing across screen changes.
/// - Each screen asks for a level (`.home`, `.reading`); the player fades between them.
/// - While teaching speech plays, the music ducks lower (`duck(true)`), then comes back.
/// - It pauses when the app leaves the foreground and resumes only if Music is on.
@MainActor
@Observable
final class MusicPlayer {
    enum Level {
        /// Home, shelf, stickers, trophies.
        case home
        /// Story pages and phonics: low under reading.
        case reading

        var volume: Float {
            switch self {
            case .home: return 0.28
            case .reading: return 0.16
            }
        }
    }

    static let trackID = "music_pond_loop"
    static let duckedVolume: Float = 0.05

    private(set) var isEnabled: Bool
    private(set) var isPlaying = false
    private(set) var level: Level = .home
    private(set) var ducked = false

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private let bundle: Bundle

    init(enabled: Bool, bundle: Bundle = .main) {
        self.isEnabled = enabled
        self.bundle = bundle
    }

    var isAvailable: Bool { url != nil }

    private var url: URL? {
        for ext in ["m4a", "wav", "caf", "mp3"] {
            if let url = bundle.url(forResource: Self.trackID, withExtension: ext) { return url }
        }
        return nil
    }

    /// Target volume for the current screen and speech state.
    var targetVolume: Float { ducked ? min(Self.duckedVolume, level.volume) : level.volume }

    /// Music On/Off from Grown-ups. Persisting the choice is the caller's job (ProgressStore).
    func setEnabled(_ on: Bool) {
        isEnabled = on
        on ? start() : pause()
    }

    /// Call when the app becomes active (and on launch).
    func start() {
        guard isEnabled else { return }
        if player == nil, let url {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0
            player?.prepareToPlay()
        }
        guard let player else { return }
        if !player.isPlaying { player.play() }
        isPlaying = player.isPlaying
        player.setVolume(targetVolume, fadeDuration: 1.0)
    }

    /// Call when the app leaves the foreground, or when Music is switched off.
    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Each screen sets its level; the track itself keeps playing (no restart between screens).
    func setLevel(_ newLevel: Level) {
        guard newLevel != level else { return }
        level = newLevel
        player?.setVolume(targetVolume, fadeDuration: 0.6)
    }

    /// Lower the music while teaching audio (sounds, words, narration) plays.
    func duck(_ on: Bool) {
        guard on != ducked else { return }
        ducked = on
        player?.setVolume(targetVolume, fadeDuration: on ? 0.15 : 0.5)
    }
}
