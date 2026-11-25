import SwiftUI
import UIKit

// MARK: - Phonics: "Listen and repeat"

/// One screen per level: IPA sound tabs, "Listen and repeat" with one Hear sound control,
/// and "Try these words" (picture, word, speaker). No mouth pictures or mouth instructions
/// (pronunciation video is a later update; the mouth_* art stays in the asset catalog).
struct PhonicsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    @Environment(\.dynamicTypeSize) private var dynamicType
    let level: Int
    let tileID: String?

    @State private var selectedID: String?

    private var tiles: [SoundTile] { app.phonicsCatalog.tiles(level: level) }
    private var tile: SoundTile? {
        let id = selectedID ?? tileID
        return tiles.first { $0.id == id } ?? tiles.first
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KitRoundButton(icon: "icon_home", fallback: "house.fill", label: "Home", size: ControlMetrics.row) { app.goHome() }
                .position(x: u(70), y: u(64))
            Text("Phonics")
                .font(Typeface.child(u(60))).foregroundStyle(Palette.ink)
                .position(x: u(597), y: u(64))
                .accessibilityAddTraits(.isHeader)
            levelMenu
                .position(x: u(1060), y: u(64))

            tabs
                .frame(width: u(1060))
                .position(x: u(597), y: u(178))

            if let tile {
                HStack(alignment: .top, spacing: u(28)) {
                    listenPanel(tile)
                    wordsPanel(tile)
                }
                .frame(height: u(560), alignment: .top)
                .position(x: u(597), y: u(530))
            }
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .onDisappear { app.audio.leaveScreen() }
    }

    // MARK: Header

    private var levelMenu: some View {
        Menu {
            ForEach(app.unlockedLevels, id: \.self) { l in
                Button("Level \(l)") { app.openPhonics(level: l) }
            }
        } label: {
            PillLabel(title: "Level \(level)", trailingSymbol: "chevron.down", height: 64, style: .cream)
                .fixedSize()
        }
        .accessibilityLabel("Level \(level). Choose a level")
        .accessibilityIdentifier("phonics.level")
    }

    // MARK: Sound tabs (IPA)

    /// "/æ/". Where two spellings share a sound at this level (c and k), or there is no single
    /// phoneme (blends), the spelling is shown too.
    private func ipa(_ t: SoundTile) -> String { t.phoneme.isEmpty ? t.grapheme : "/\(t.phoneme)/" }
    private func needsSpelling(_ t: SoundTile) -> Bool {
        t.phoneme.isEmpty || tiles.filter { $0.phoneme == t.phoneme }.count > 1
    }

    private var tabs: some View {
        let scrolls = tiles.count > 6
        let width = scrolls ? 160 : (1060 - CGFloat(max(tiles.count - 1, 0)) * 16) / CGFloat(max(tiles.count, 1))
        let row = HStack(spacing: u(16)) {
            ForEach(tiles) { t in tab(t, width: width) }
        }
        return Group {
            if scrolls {
                ScrollView(.horizontal, showsIndicators: false) { row.padding(.vertical, u(8)) }
            } else {
                row
            }
        }
    }

    private func tab(_ t: SoundTile, width: CGFloat) -> some View {
        let selected = t.id == tile?.id
        return Button {
            app.audio.stop()
            selectedID = t.id
        } label: {
            VStack(spacing: 0) {
                Text(ipa(t))
                    .font(.custom("Andika-Bold", fixedSize: u(54)))
                    .lineLimit(1).minimumScaleFactor(0.5)
                if needsSpelling(t) {
                    Text(t.grapheme).font(Typeface.child(u(20))).opacity(0.8)
                }
            }
            .foregroundStyle(selected ? Color.white : Palette.ink)
            .frame(width: u(width), height: u(92))
            .background(RoundedRectangle(cornerRadius: u(30), style: .continuous)
                .fill(selected ? Palette.blue : Palette.lavender)
                .shadow(color: selected ? Palette.blueDeep : Palette.lavenderDeep, radius: 0, y: u(5)))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("sound \(ipa(t))\(t.label.isEmpty ? "" : ", \(t.label)")")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("tile.\(t.grapheme)")
    }

    // MARK: Listen and repeat

    private func listenPanel(_ t: SoundTile) -> some View {
        VStack(spacing: u(12)) {
            Text("Listen and repeat")
                .font(Typeface.child(u(36))).foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                Text(ipa(t))
                    .font(.custom("Andika-Bold", fixedSize: u(120)))
                    .lineLimit(1).minimumScaleFactor(0.4)
                if needsSpelling(t) {
                    Text("spelled \(t.grapheme)").font(Typeface.child(u(24))).foregroundStyle(Palette.inkSoft)
                }
            }
            .foregroundStyle(Palette.ink)
            .frame(width: u(360), height: u(150))
            .background(RoundedRectangle(cornerRadius: u(34), style: .continuous).fill(Palette.lavender))
            .playingHighlight(app.audio.isHighlighted("sound.\(t.id)"), radius: u(34))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("sound \(ipa(t))")
            .accessibilityIdentifier("phonics.sound")

            HStack(alignment: .bottom, spacing: u(24)) {
                KitIcon(name: ArtworkNames.patWavingCutout, fallback: "person.fill", size: u(130))
                    .accessibilityHidden(true)
                if UIImage(named: t.actionAsset) != nil {
                    Image(t.actionAsset).resizable().scaledToFit()
                        .frame(width: u(160), height: u(130))
                        .accessibilityLabel("picture for \(t.grapheme)")
                }
            }
            .frame(height: u(130))

            AudioButton(audioID: t.audio, title: "Hear sound", height: ControlMetrics.large, width: 440,
                        highlightKey: "sound.\(t.id)")
            Text("Your turn!")
                .font(Typeface.control(u(26), dynamicType)).foregroundStyle(Palette.ink)
        }
        .padding(u(24))
        .frame(width: u(520), height: u(560), alignment: .top)
        .creamPanel(radius: 40)
    }

    // MARK: Try these words

    private func wordsPanel(_ t: SoundTile) -> some View {
        VStack(spacing: u(16)) {
            Text("Try these words")
                .font(Typeface.child(u(36))).foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            // Three fixed columns: picture · word · speaker, the same in every row.
            VStack(spacing: u(14)) {
                ForEach(t.examples, id: \.self) { word in
                    HStack(alignment: .center, spacing: u(20)) {
                        picture(word)
                        Text(word)
                            .font(.custom("Andika-Bold", fixedSize: u(72) * min(ControlMetrics.textScale(dynamicType), 1.15)))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .frame(width: u(220), alignment: .leading)
                            .accessibilityLabel("word \(word)")
                        SpeakerButton(audioID: app.wordID(word), label: "Hear \(word)", highlightKey: "ex.\(word)")
                    }
                    .padding(.horizontal, u(16))
                    .frame(width: u(512), height: u(140), alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: u(30), style: .continuous).fill(Palette.butter.opacity(0.25)))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("phonics.example.\(word)")
                }
            }
        }
        .padding(u(24))
        .frame(width: u(560), height: u(560), alignment: .top)
        .creamPanel(radius: 40)
    }

    @ViewBuilder
    private func picture(_ word: String) -> some View {
        let name = app.curriculum.word(word, through: level)?.picture
        ZStack {
            Circle().fill(Palette.cream)
            if let name, UIImage(named: name) != nil {
                Image(name).resizable().scaledToFit().padding(u(8))
            }
        }
        .frame(width: u(116), height: u(116))
        .clipShape(Circle())
        .accessibilityHidden(true)
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
            KitRoundButton(icon: "icon_home", fallback: "house.fill", label: "Home", size: ControlMetrics.row) { app.goHome() }
                .position(x: u(70), y: u(64))
            Text("Stickers")
                .font(Typeface.child(u(40))).foregroundStyle(Palette.ink)
                .padding(.horizontal, u(30))
                .frame(height: u(ControlMetrics.row))
                .background(Capsule().fill(Palette.cream))
                .position(x: u(597), y: u(64))
                .accessibilityAddTraits(.isHeader)
            PillButton(title: "My trophies", symbol: "trophy.fill", style: .cream) { app.openTrophies() }
                .fixedSize()
                .position(x: u(1030), y: u(64))
                .accessibilityIdentifier("stickers.trophies")

            if completed.isEmpty {
                VStack(spacing: u(22)) {
                    KitIcon(name: "sticker_album", fallback: "book.closed", size: u(220))
                    Text("Finish Level 1 to start sticker practice.")
                        .font(Typeface.child(u(38))).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                        .accessibilityIdentifier("stickers.empty")
                    PillButton(title: "Open Storybook", symbol: "book.fill", height: ControlMetrics.large) { app.openShelf() }
                        .fixedSize()
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
        HStack(alignment: .center, spacing: u(22)) {
            PillButton(title: "Random word", symbol: "shuffle", width: 280) { draw(.word) }
                .accessibilityIdentifier("stickers.randomWord")
            PillButton(title: "Random sound", symbol: "shuffle", width: 280, style: .lavender) { draw(.sound) }
                .accessibilityIdentifier("stickers.randomSound")
            Menu {
                Button("All finished levels") { filter = nil; card = nil }
                ForEach(completed.sorted(), id: \.self) { l in
                    Button("Level \(l)") { filter = l; card = nil }
                }
            } label: {
                PillLabel(title: filter.map { "Level \($0)" } ?? "All levels", trailingSymbol: "chevron.down",
                          width: 230, style: .cream)
            }
            .accessibilityLabel("Practise from: \(filter.map { "Level \($0)" } ?? "all finished levels")")
            .accessibilityIdentifier("stickers.filter")
        }
        .alignedRow()
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
                    HStack(alignment: .center, spacing: u(20)) {
                        AudioButton(audioID: app.wordID(card.value), title: "Hear word", width: 250, highlightKey: "sticker.word")
                        if let picture = app.word(card.value)?.picture, UIImage(named: picture) != nil {
                            if showPicture {
                                Image(picture).resizable().scaledToFit().frame(width: u(150), height: u(120))
                                    .accessibilityLabel("picture for \(card.value)")
                            } else {
                                PillButton(title: "Show picture", symbol: "photo", width: 250, style: .cream) { showPicture = true }
                            }
                        }
                    }
                    .alignedRow()
                } else {
                    AudioButton(audioID: soundAudio(card), title: "Hear sound", width: 250, highlightKey: "sticker.sound")
                        .fixedSize()
                }
                PillButton(title: "Another", symbol: "arrow.clockwise", width: 250) { draw(card.kind, avoid: card) }
                    .fixedSize()
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
