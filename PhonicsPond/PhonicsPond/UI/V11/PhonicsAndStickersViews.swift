import SwiftUI
import UIKit

// MARK: - Phonics: sounds by level

struct PhonicsHomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let level: Int

    private var tiles: [SoundTile] { app.phonicsCatalog.tiles(level: level) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KitRoundButton(icon: "icon_home", fallback: "house.fill", label: "Home") { app.goHome() }
                .position(x: u(70), y: u(64))
            Text("Phonics")
                .font(Typeface.child(u(40))).foregroundStyle(Palette.ink)
                .padding(.horizontal, u(30)).padding(.vertical, u(10))
                .background(Capsule().fill(Palette.cream))
                .position(x: u(597), y: u(64))
                .accessibilityAddTraits(.isHeader)

            // Level selector: unlocked levels only.
            HStack(spacing: u(12)) {
                ForEach(app.unlockedLevels, id: \.self) { l in
                    Button { app.openPhonics(level: l) } label: {
                        Text("Level \(l)")
                            .font(Typeface.child(u(26)))
                            .foregroundStyle(l == level ? Color.white : Palette.ink)
                            .padding(.horizontal, u(22)).frame(height: u(58))
                            .background(Capsule().fill(l == level ? Palette.blue : Palette.lavender))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(l == level ? .isSelected : [])
                }
            }
            .position(x: u(597), y: u(150))

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(u(200)), spacing: u(28)), count: min(5, max(tiles.count, 1))), spacing: u(28)) {
                ForEach(tiles) { tile in
                    Button { app.openSound(level: level, tileID: tile.id) } label: {
                        VStack(spacing: u(4)) {
                            Text(tile.grapheme)
                                .font(Typeface.letter(u(110)))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1).minimumScaleFactor(0.5)
                            if !tile.label.isEmpty && tile.label != "review" && tile.label != "blend" {
                                Text(tile.label).font(Typeface.child(u(16))).foregroundStyle(Palette.inkSoft).lineLimit(1)
                            }
                        }
                        .frame(width: u(200), height: u(200))
                        .background(RoundedRectangle(cornerRadius: u(36), style: .continuous).fill(Palette.cream)
                            .shadow(color: Palette.creamEdge, radius: 0, y: u(6)))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("sound \(tile.grapheme)\(tile.label.isEmpty ? "" : ", \(tile.label)")")
                    .accessibilityIdentifier("tile.\(tile.grapheme)")
                }
            }
            .frame(width: u(1120))
            .position(x: u(597), y: u(480))
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }
}

// MARK: - Phonics: one sound

struct SoundDetailView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let level: Int
    let tileID: String

    private var tile: SoundTile? { app.phonicsCatalog.tiles(level: level).first { $0.id == tileID } }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KitRoundButton(icon: "icon_back", fallback: "chevron.left", label: "Back to sounds") { app.openPhonics(level: level) }
                .position(x: u(70), y: u(64))
            Text("Level \(level)")
                .font(Typeface.child(u(32))).foregroundStyle(Palette.ink)
                .padding(.horizontal, u(26)).padding(.vertical, u(8))
                .background(Capsule().fill(Palette.cream))
                .position(x: u(597), y: u(64))
            if let tile {
                HStack(alignment: .top, spacing: u(30)) {
                    // Sound: big letter, Hear sound, mouth and gesture pictures.
                    VStack(spacing: u(18)) {
                        Text(tile.grapheme)
                            .font(Typeface.letter(u(220)))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1).minimumScaleFactor(0.4)
                            .frame(width: u(360), height: u(260))
                            .background(RoundedRectangle(cornerRadius: u(40), style: .continuous).fill(Palette.cream))
                            .playingHighlight(app.audio.isHighlighted("sound.\(tile.id)"), radius: u(40))
                            .accessibilityLabel("sound \(tile.grapheme)")
                        AudioButton(audioID: tile.audio, title: "Hear sound", height: 76, highlightKey: "sound.\(tile.id)")
                        HStack(spacing: u(14)) {
                            if UIImage(named: tile.mouthAsset) != nil {
                                Image(tile.mouthAsset).resizable().scaledToFit()
                                    .frame(width: u(170), height: u(130))
                                    .clipShape(RoundedRectangle(cornerRadius: u(20), style: .continuous))
                                    .accessibilityLabel("mouth position for \(tile.grapheme)")
                            }
                            if UIImage(named: tile.actionAsset) != nil {
                                Image(tile.actionAsset).resizable().scaledToFit()
                                    .frame(width: u(170), height: u(130))
                                    .accessibilityLabel("gesture for \(tile.grapheme)")
                            }
                        }
                    }
                    .frame(width: u(420))

                    // Example words (curriculum-checked for this level).
                    VStack(alignment: .leading, spacing: u(16)) {
                        Text("Words with \(tile.grapheme)")
                            .font(Typeface.child(u(32))).foregroundStyle(Palette.ink)
                        ForEach(tile.examples, id: \.self) { word in example(word) }
                    }
                    .padding(u(26))
                    .frame(width: u(620), alignment: .leading)
                    .creamPanel(radius: 36)
                }
                .position(x: u(597), y: u(450))
            }
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .onDisappear { app.audio.leaveScreen() }
    }

    private func example(_ word: String) -> some View {
        HStack(spacing: u(16)) {
            Text(word).font(Typeface.letter(u(56))).foregroundStyle(Palette.ink).frame(width: u(150), alignment: .leading)
            AudioButton(audioID: app.wordID(word), title: "Hear word", height: 58, highlightKey: "ex.\(word)")
            AudioButton(audioID: AudioID.blend(word), title: "Hear sounds", icon: "icon_speaker", fallback: "waveform",
                        height: 58, style: .lavender)
            if let picture = app.word(word)?.picture, UIImage(named: picture) != nil {
                Image(picture).resizable().scaledToFit().frame(width: u(80), height: u(70))
                    .accessibilityLabel("picture for \(word)")
            }
        }
    }
}

// MARK: - Stickers: random practice from completed levels

struct StickersView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    @State private var filter: Int?
    @State private var card: StickerItem?
    @State private var lastKind: StickerItemKind = .word
    @State private var showPicture = false

    private var completed: Set<Int> { app.store.data.completedLevels }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KitRoundButton(icon: "icon_home", fallback: "house.fill", label: "Home") { app.goHome() }
                .position(x: u(70), y: u(64))
            Text("Stickers")
                .font(Typeface.child(u(40))).foregroundStyle(Palette.ink)
                .padding(.horizontal, u(30)).padding(.vertical, u(10))
                .background(Capsule().fill(Palette.cream))
                .position(x: u(597), y: u(64))
                .accessibilityAddTraits(.isHeader)
            BlueButton(title: "My trophies", systemImage: "trophy.fill", height: 70, style: .cream) { app.openTrophies() }
                .position(x: u(1030), y: u(64))
                .accessibilityIdentifier("stickers.trophies")

            if completed.isEmpty {
                VStack(spacing: u(22)) {
                    KitIcon(name: "sticker_album", fallback: "book.closed", size: u(220))
                    Text("Finish Level 1 to start sticker practice.")
                        .font(Typeface.child(u(38))).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                        .accessibilityIdentifier("stickers.empty")
                    BlueButton(title: "Open Storybook", systemImage: "book.fill", height: 84) { app.openShelf() }
                }
                .padding(u(40)).creamPanel(radius: 44)
                .position(x: u(597), y: u(450))
            } else {
                controls.position(x: u(597), y: u(170))
                cardArea.position(x: u(597), y: u(520))
            }
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .onDisappear { app.audio.leaveScreen() }
    }

    private var controls: some View {
        HStack(spacing: u(22)) {
            BlueButton(title: "Random word", systemImage: "shuffle", height: 80) { draw(.word) }
                .accessibilityIdentifier("stickers.randomWord")
            BlueButton(title: "Random sound", systemImage: "shuffle", height: 80, style: .lavender) { draw(.sound) }
                .accessibilityIdentifier("stickers.randomSound")
            Menu {
                Button("All finished levels") { filter = nil; card = nil }
                ForEach(completed.sorted(), id: \.self) { l in
                    Button("Level \(l)") { filter = l; card = nil }
                }
            } label: {
                HStack(spacing: u(8)) {
                    Text(filter.map { "Level \($0)" } ?? "All levels").font(Typeface.child(u(28)))
                    KitIcon(name: "icon_chevron_down", fallback: "chevron.down", size: u(30))
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, u(24)).frame(height: u(80))
                .background(Capsule().fill(Palette.cream).shadow(color: Palette.creamEdge, radius: 0, y: u(5)))
            }
            .accessibilityLabel("Practise from: \(filter.map { "Level \($0)" } ?? "all finished levels")")
            .accessibilityIdentifier("stickers.filter")
        }
    }

    @ViewBuilder
    private var cardArea: some View {
        if let card {
            VStack(spacing: u(20)) {
                ZStack {
                    KitIcon(name: "sticker_blank_star", fallback: "star", size: u(300)).opacity(0.35)
                    Text(card.value)
                        .font(Typeface.letter(u(card.kind == .word ? 130 : 170)))
                        .foregroundStyle(Palette.ink)
                        .accessibilityIdentifier("stickers.card")
                }
                if card.kind == .word {
                    Text("Try it! Then check.").font(Typeface.child(u(26))).foregroundStyle(Palette.inkSoft)
                    HStack(spacing: u(20)) {
                        AudioButton(audioID: app.wordID(card.value), title: "Hear word", height: 70, highlightKey: "sticker.word")
                        if let picture = app.word(card.value)?.picture, UIImage(named: picture) != nil {
                            if showPicture {
                                Image(picture).resizable().scaledToFit().frame(width: u(150), height: u(120))
                                    .accessibilityLabel("picture for \(card.value)")
                            } else {
                                BlueButton(title: "Show picture", systemImage: "photo", height: 70, style: .cream) { showPicture = true }
                            }
                        }
                    }
                } else {
                    AudioButton(audioID: soundAudio(card), title: "Hear sound", height: 70, highlightKey: "sticker.sound")
                }
                BlueButton(title: "Another", systemImage: "arrow.clockwise", height: 76) { draw(card.kind, avoid: card) }
                    .accessibilityIdentifier("stickers.another")
            }
            .padding(u(36)).frame(width: u(700)).creamPanel(radius: 44)
        } else {
            VStack(spacing: u(16)) {
                KitIcon(name: "sticker_album", fallback: "book.closed", size: u(200))
                Text("Pick Random word or Random sound.").font(Typeface.child(u(30))).foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func soundAudio(_ item: StickerItem) -> String {
        app.phonicsCatalog.tiles(level: item.level).first { $0.grapheme == item.value }?.audio ?? "phoneme_\(item.value)"
    }

    private func draw(_ kind: StickerItemKind, avoid: StickerItem? = nil) {
        app.audio.stop()
        let pool = StickerPool.eligible(kind: kind, completed: completed, filter: filter,
                                        library: app.library, phonics: app.phonicsCatalog)
        let key = StickerPool.poolKey(kind: kind, filter: filter)
        var drawn: StickerItem?
        app.store.update { drawn = $0.drawSticker(from: pool, key: key, avoid: avoid) }
        lastKind = kind
        showPicture = false
        card = drawn
    }
}
