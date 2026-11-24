import SwiftUI

/// One Home destination. Future activities are added as one more entry in `HomeView.cards`.
struct HomeCard: Identifiable {
    let id: String
    let title: String
    let art: String
    let fallback: String
    let subtitle: String?
    let action: () -> Void
}

/// Home (wireframe v2): Storybook, Phonics and Stickers, with Pat by the pond.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.u) private var u

    private var cards: [HomeCard] {
        [
            HomeCard(id: "storybook", title: "Storybook", art: "home_storybook", fallback: "book.fill",
                     subtitle: app.storyProgressLine, action: { app.openShelf() }),
            HomeCard(id: "phonics", title: "Phonics", art: "home_phonics", fallback: "textformat.abc",
                     subtitle: nil, action: { app.openPhonics() }),
            HomeCard(id: "stickers", title: "Stickers", art: "home_stickers", fallback: "star.fill",
                     subtitle: nil, action: { app.openStickers() }),
        ]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("Phonics Pond")
                .font(Typeface.child(u(46)))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, u(30))
                .padding(.vertical, u(12))
                .background(Capsule().fill(Palette.cream))
                .overlay(Capsule().stroke(Palette.creamEdge, lineWidth: u(3)))
                .position(x: u(230), y: u(64))
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: u(4)) {
                HoldToOpenButton(size: 76, label: "Grown-ups") { app.openParentArea() }
                Text("Grown-ups")
                    .font(.system(size: u(16), weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .accessibilityHidden(true)
            }
            .position(x: u(1110), y: u(74))

            Mascot()
                .frame(width: u(300), height: u(300))
                .position(x: u(597), y: u(240))

            HStack(spacing: u(36)) {
                ForEach(cards) { card in cardView(card) }
            }
            .position(x: u(597), y: u(560))

            // Reserved for future activities: new cards go here as they become available.
            Color.clear
                .frame(width: u(1080), height: u(70))
                .position(x: u(597), y: u(780))
                .accessibilityHidden(true)
        }
        .frame(width: u(CanvasSize.width), height: u(CanvasSize.height))
        .onAppear { app.store.update { $0.hasLaunchedBefore = true } }
        .onDisappear { app.audio.leaveScreen() }
    }

    private func cardView(_ card: HomeCard) -> some View {
        Button(action: card.action) {
            VStack(spacing: u(10)) {
                KitIcon(name: card.art, fallback: card.fallback, size: u(190))
                Text(card.title)
                    .font(Typeface.child(u(44)))
                    .foregroundStyle(Palette.ink)
                Text(card.subtitle ?? " ")
                    .font(Typeface.child(u(22)))
                    .foregroundStyle(Palette.inkSoft)
                    .opacity(card.subtitle == nil ? 0 : 1)
            }
            .frame(width: u(320), height: u(330))
            .creamPanel(radius: 44)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel([card.title, card.subtitle].compactMap { $0 }.joined(separator: ", "))
        .accessibilityIdentifier("home.\(card.id)")
    }
}
