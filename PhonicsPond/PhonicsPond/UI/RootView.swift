import SwiftUI

/// Scales the 1194 × 834 canvas to the screen and routes between screens.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// System Reduce Motion, or `-reduceMotion` for UI tests.
    private var reduced: Bool {
        systemReduceMotion || ProcessInfo.processInfo.arguments.contains("-reduceMotion")
    }

    var body: some View {
        GeometryReader { geo in
            let k = min(geo.size.width / CanvasSize.width, geo.size.height / CanvasSize.height)
            ZStack {
                PondBackground()
                screen
                    .frame(width: CanvasSize.width * k, height: CanvasSize.height * k)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack {
                    Spacer()
                    HStack {
                        PendingAudioBanner()
                        Spacer()
                    }
                }
                .padding(12)
            }
            .environment(\.u, Unit(k: k))
            .environment(\.reducedStoryMotion, reduced)
        }
        .fullScreenCover(isPresented: Binding(get: { app.showParentArea }, set: { app.showParentArea = $0 })) {
            ParentAreaView()
                .environment(app)
                .environment(\.reducedStoryMotion, reduced)
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving the foreground (or the app switcher) stops audio. Nothing auto-plays on return.
            if phase != .active { app.audio.interrupt() }
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch app.route {
        case .home:
            HomeView()
        case .lesson(let page, let resume):
            LessonView(page: page, resume: resume)
                .id("lesson-\(app.lessonSession)")
        case .stickerBook:
            StickerBookView()
        }
    }
}
