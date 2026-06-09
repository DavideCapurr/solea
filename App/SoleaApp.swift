import SwiftUI
import SwiftData

@main
struct SoleaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, TanSession.self])
    }
}
