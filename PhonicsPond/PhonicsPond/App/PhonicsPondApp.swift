import SwiftUI

@main
struct PhonicsPondApp: App {
    @State private var app: AppModel

    init() {
        Typeface.registerBundledFonts()
        _app = State(initialValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.light)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
        }
    }
}
