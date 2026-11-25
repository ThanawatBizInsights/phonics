import SwiftUI

// MARK: - Shelf (two screens of six covers)

struct StorybookShelfView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    @State private var shelf = 0

    private var books: [StoryBook] { app.library.books.sorted { $0.level < $1.level } }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KitRoundButton(icon: "icon_home", fallback: "house.fill", label: "Home") { app.goHome() }
                .position(x: u(70), y: u(64))
            Text("Storybook")
                .font(Typeface.child(u(40)))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, u(30)).padding(.vertical, u(10))
                .background(Capsule().fill(Palette.cream))
                .position(x: u(597), y: u(64))
                .accessibilityAddTraits(.isHeader)
            TabView(selection: $shelf) {
                ForEach(0..<2, id: \.self) { index in
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(u(300)), spacing: u(40)), count: 3), spacing: u(26)) {
                        ForEach(books.filter { (index == 0) == ($0.level <= 6) }) { book in
                            cover(book)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: u(1060), height: u(650))
            .position(x: u(597), y: u(440))

            HStack(spacing: u(24)) {
                KitRoundButton(icon: "icon_back", fallback: "chevron.left", label: "Previous shelf", size: 64, enabled: shelf > 0) {
                    withAnimation { shelf = 0 }
                }
                ForEach(0..<2, id: \.self) { i in
                    Circle().fill(i == shelf ? Palette.ink : Palette.lavenderDeep).frame(width: u(16), height: u(16))
                }
                .accessibilityHidden(true)
                KitRoundButton(icon: "icon_next", fallback: "chevron.right", label: "Next shelf", size: 64, enabled: shelf < 1) {
                    withAnimation { shelf = 1 }
                }
            }
            .position(x: u(597), y: u(790))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Shelf \(shelf + 1) of 2")
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }

    private func cover(_ book: StoryBook) -> some View {
        let unlocked = app.store.data.isUnlocked(book, in: app.library)
        let progress = app.store.data.book(book.id)
        // Every book opens at Page 1: "Open book" if unfinished, "Read again" if finished.
        let action = progress.levelTrophy ? "Read again" : "Open book"
        let status: String = progress.levelTrophy ? "finished" :
            unlocked ? "open" : (book.status == .draft ? "coming soon" : "finish Level \(book.level - 1) first")
        return Button {
            app.openStory(book.id)
        } label: {
            VStack(spacing: u(6)) {
                ZStack(alignment: .topTrailing) {
                    KitIcon(name: book.cover, fallback: "book.closed.fill", size: u(172))
                        .saturation(unlocked ? 1 : 0.35)
                        .opacity(unlocked ? 1 : 0.75)
                    if progress.levelTrophy {
                        KitIcon(name: "trophy_level", fallback: "trophy.fill", size: u(70)).offset(x: u(14), y: -u(8))
                    } else if !unlocked {
                        KitIcon(name: "icon_lock", fallback: "lock.fill", size: u(56))
                            .padding(u(6)).background(Circle().fill(Palette.cream)).offset(x: u(8), y: -u(6))
                    }
                }
                Text("Level \(book.level)")
                    .font(Typeface.child(u(28)))
                    .foregroundStyle(Palette.ink)
                Text(unlocked || progress.levelTrophy ? book.title : status.capitalized(with: nil))
                    .font(Typeface.child(u(20)))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if unlocked {
                    PillLabel(title: action, symbol: progress.levelTrophy ? "arrow.counterclockwise" : "book.fill",
                              height: 44, style: progress.levelTrophy ? .lavender : .blue)
                        .fixedSize()
                        .accessibilityHidden(true)
                }
            }
            .frame(width: u(300), height: u(300))
            .creamPanel(radius: 34)
        }
        .buttonStyle(PressableStyle())
        .disabled(!unlocked)
        .accessibilityLabel("Level \(book.level), \(book.title), \(status)\(unlocked ? ". \(action)" : "")")
        .accessibilityIdentifier("cover.l\(book.level)")
    }
}

// MARK: - Story page (any page count)

struct StoryPageView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u
    let bookID: String
    let startPage: Int

    @State private var index = 0
    @State private var overlay: Overlay?
    @State private var gate = TapGate()
    @State private var loaded = false

    enum Overlay: Equatable {
        case pageTrophy(isLast: Bool, levelEarned: Int?, unlocked: Int?)
        case levelTrophy(level: Int, unlocked: Int?, isNew: Bool)
    }

    private var book: StoryBook? { app.library.book(id: bookID) }
    private var page: StoryPage? { book.flatMap { $0.pages.indices.contains(index) ? $0.pages[index] : nil } }
    private var isLast: Bool { (book?.pages.count ?? 1) - 1 == index }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let book, let page {
                LayeredScene(layers: page.layers, sunset: page.sunset)
                    .environment(\.pageCast, book.cast)
                    .frame(width: u(1150), height: u(470))
                    .position(x: u(597), y: u(345))
                    .id(page.id)

                // Top bar: Back to books · Level 1 · Page 1 of 5 · Read to me, all one height on one centre line.
                KitRoundButton(icon: "icon_back", fallback: "chevron.left", label: "Back to books", size: ControlMetrics.row) { leave() }
                    .position(x: u(70), y: u(64))
                    .accessibilityIdentifier("story.back")
                Text("Level \(book.level) · Page \(index + 1) of \(book.pages.count)")
                    .font(Typeface.child(u(30)))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, u(28))
                    .frame(height: u(ControlMetrics.row))
                    .background(Capsule().fill(Palette.cream))
                    .position(x: u(597), y: u(64))
                    .accessibilityIdentifier("story.pageChip")
                AudioButton(audioID: page.narration, title: "Read to me", icon: "icon_read_aloud",
                            fallback: "book.fill", highlightKey: "story.line")
                    .fixedSize()
                    .position(x: u(1040), y: u(64))

                VStack {
                    Spacer(minLength: 0)
                    bottomPanel(book: book, page: page)
                }
                .padding(.bottom, u(10))
                .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))

                if let overlay { overlayView(overlay, book: book) }
            }
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .onAppear {
            guard !loaded else { return }
            loaded = true
            index = min(max(startPage, 0), (book?.pages.count ?? 1) - 1)
        }
        .onDisappear { app.audio.leaveScreen() }
    }

    /// Two rows: the line, then one row of controls on a shared centre line.
    /// Previous page is always at the left edge and Next page / Finish story at the right edge.
    private func bottomPanel(book: StoryBook, page: StoryPage) -> some View {
        VStack(spacing: u(14)) {
            VStack(spacing: u(8)) {
                Text(page.mode == .tryReading ? "Try reading" : "Read together")
                    .font(.system(size: u(17), weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.horizontal, u(12)).padding(.vertical, u(3))
                    .background(Capsule().fill(Palette.lavender))
                Text(page.line ?? page.beat)
                    .font(Typeface.child(u(48)))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.6)
                    .underline(app.audio.isHighlighted("story.line"), color: Palette.blue)
                    .accessibilityIdentifier("story.line")
            }

            ViewThatFits(in: .horizontal) {
                // Wide: [Previous page] · chips · Hear sounds · [Next page]
                HStack(alignment: .center, spacing: u(18)) {
                    previousButton
                    Spacer(minLength: u(8))
                    targets(page)
                    Spacer(minLength: u(8))
                    nextButton(page, in: book)
                }
                .alignedRow()
                // Narrow or larger text: targets on their own row, navigation below at the same edges.
                VStack(spacing: u(14)) {
                    ScrollView(.horizontal, showsIndicators: false) { targets(page).alignedRow().padding(.vertical, u(6)) }
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .center) {
                        previousButton
                        Spacer(minLength: u(8))
                        nextButton(page, in: book)
                    }
                    .alignedRow()
                }
            }
        }
        .padding(.horizontal, u(26))
        .padding(.vertical, u(18))
        .frame(width: u(1150))
        .creamPanel(radius: 40)
    }

    private static let navWidth: CGFloat = 270

    private var previousButton: some View {
        PillButton(title: "Previous page", symbol: "arrow.left", width: Self.navWidth, style: .cream, enabled: index > 0) {
            turn(to: index - 1)
        }
        .accessibilityIdentifier("story.previous")
    }

    private func nextButton(_ page: StoryPage, in book: StoryBook) -> some View {
        PillButton(title: isLast ? "Finish story" : "Next page", trailingSymbol: isLast ? "flag.checkered" : "arrow.right",
                   width: Self.navWidth) {
            finishPage(page, in: book)
        }
        .accessibilityIdentifier(isLast ? "story.finish" : "story.next")
    }

    private func targets(_ page: StoryPage) -> some View {
        HStack(alignment: .center, spacing: u(14)) {
            ForEach(page.chips, id: \.self) { WordChip(word: $0) }
            if let word = page.hearSounds {
                AudioButton(audioID: AudioID.blend(word), title: "Hear sounds", icon: "icon_speaker",
                            fallback: "waveform", style: .lavender)
            }
        }
    }

    // MARK: Actions

    private func turn(to newIndex: Int) {
        guard let book, book.pages.indices.contains(newIndex) else { return }
        app.audio.stop()                          // turning a page stops the previous audio
        index = newIndex
    }

    private func finishPage(_ page: StoryPage, in book: StoryBook) {
        guard gate.allow(), overlay == nil else { return }   // repeated taps never double-award
        app.audio.stop()
        var awards = PageAwards()
        app.store.update { awards = $0.finishPage(page, in: book, library: app.library) }
        if awards.pageTrophy != nil {
            overlay = .pageTrophy(isLast: isLast, levelEarned: awards.levelTrophy, unlocked: awards.unlockedLevel)
        } else if isLast {
            // Reread of the last page: show the big trophy again, nothing new is saved.
            overlay = .levelTrophy(level: book.level, unlocked: nil, isNew: false)
        } else {
            turn(to: index + 1)
        }
    }

    private func leave() {
        app.openShelf()
    }

    @ViewBuilder
    private func overlayView(_ overlay: Overlay, book: StoryBook) -> some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea().accessibilityHidden(true)
            switch overlay {
            case .pageTrophy(let isLast, let levelEarned, let unlocked):
                VStack(spacing: u(18)) {
                    KitIcon(name: "trophy_page", fallback: "trophy.fill", size: u(200))
                    Text("Page complete!").font(Typeface.child(u(48))).foregroundStyle(Palette.ink)
                    Text("You earned a small trophy.").font(Typeface.child(u(26))).foregroundStyle(Palette.inkSoft)
                    if isLast {
                        PillButton(title: "See big trophy", symbol: "trophy.fill", height: ControlMetrics.large) {
                            self.overlay = .levelTrophy(level: book.level, unlocked: unlocked, isNew: levelEarned != nil)
                        }
                        .accessibilityIdentifier("trophy.seeBig")
                    } else {
                        PillButton(title: "Next page", trailingSymbol: "arrow.right", height: ControlMetrics.large) {
                            self.overlay = nil
                            turn(to: index + 1)
                        }
                        .accessibilityIdentifier("trophy.nextPage")
                    }
                }
                .padding(u(44)).frame(width: u(620)).creamPanel(radius: 44)
                .accessibilityElement(children: .contain)
            case .levelTrophy(let level, let unlocked, let isNew):
                VStack(spacing: u(18)) {
                    ZStack(alignment: .bottom) {
                        KitIcon(name: "trophy_level", fallback: "trophy.fill", size: u(270))
                        Text("\(level)")
                            .font(Typeface.child(u(56)))
                            .foregroundStyle(Palette.ink)
                            .frame(width: u(80), height: u(80))
                            .background(Circle().fill(Palette.cream))
                            .offset(y: u(20))
                            .accessibilityLabel("Level \(level)")
                    }
                    Text(isNew ? "Level \(level) complete!" : "Level \(level) trophy")
                        .font(Typeface.child(u(48))).foregroundStyle(Palette.ink)
                    HStack(alignment: .center, spacing: u(24)) {
                        if level == 12 {
                            PillButton(title: "My trophies", symbol: "star.fill", height: ControlMetrics.large, width: 330) { app.openTrophies() }
                        } else if let next = app.library.book(level: level + 1),
                                  app.store.data.isUnlocked(next, in: app.library) {
                            PillButton(title: "Next level", trailingSymbol: "arrow.right", height: ControlMetrics.large, width: 330) { app.openStory(next.id) }
                                .accessibilityIdentifier("trophy.nextLevel")
                        } else {
                            PillButton(title: "Next level", symbol: "lock.fill", height: ControlMetrics.large, width: 330, enabled: false,
                                       accessibilityText: "Next level, coming soon") {}
                        }
                        PillButton(title: "Bookshelf", symbol: "books.vertical.fill", height: ControlMetrics.large, width: 330, style: .cream) { app.openShelf() }
                            .accessibilityIdentifier("trophy.bookshelf")
                    }
                    .alignedRow()
                    if let unlocked { Text("Level \(unlocked) is open!").font(Typeface.child(u(24))).foregroundStyle(Palette.inkSoft) }
                }
                .padding(u(44)).frame(width: u(820)).creamPanel(radius: 44)
                .accessibilityElement(children: .contain)
            }
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }
}

// MARK: - My trophies

struct TrophyShelfView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u

    var body: some View {
        ZStack(alignment: .topLeading) {
            KitRoundButton(icon: "icon_back", fallback: "chevron.left", label: "Back to stickers") { app.openStickers() }
                .position(x: u(70), y: u(64))
            Text("My trophies")
                .font(Typeface.child(u(40))).foregroundStyle(Palette.ink)
                .padding(.horizontal, u(30)).padding(.vertical, u(10))
                .background(Capsule().fill(Palette.cream))
                .position(x: u(597), y: u(64))
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: u(14)) {
                    ForEach(app.library.books.sorted { $0.level < $1.level }) { book in row(book) }
                }
                .padding(u(24))
            }
            .frame(width: u(1080), height: u(680))
            .creamPanel(radius: 40)
            .position(x: u(597), y: u(470))
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
    }

    private func row(_ book: StoryBook) -> some View {
        let p = app.store.data.book(book.id)
        return HStack(spacing: u(18)) {
            KitIcon(name: book.cover, fallback: "book.closed.fill", size: u(80))
            VStack(alignment: .leading, spacing: u(2)) {
                Text("Level \(book.level)").font(Typeface.child(u(26))).foregroundStyle(Palette.ink)
                Text(book.title).font(Typeface.child(u(18))).foregroundStyle(Palette.inkSoft)
            }
            .frame(width: u(220), alignment: .leading)
            HStack(spacing: u(6)) {
                ForEach(book.pages) { page in
                    KitIcon(name: "trophy_page", fallback: "trophy", size: u(52))
                        .opacity(p.pageTrophies.contains(page.id) ? 1 : 0.18)
                        .saturation(p.pageTrophies.contains(page.id) ? 1 : 0)
                }
            }
            Spacer()
            KitIcon(name: "trophy_level", fallback: "trophy.fill", size: u(76))
                .opacity(p.levelTrophy ? 1 : 0.15)
                .saturation(p.levelTrophy ? 1 : 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(book.level): \(p.pageTrophies.count) of \(book.pages.count) page trophies\(p.levelTrophy ? ", big trophy earned" : "")")
        .accessibilityIdentifier("trophies.l\(book.level)")
    }
}
