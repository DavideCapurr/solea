import SwiftUI
import SwiftData

@main
struct SoleaApp: App {
    @State private var plusStore = SoleaPlusStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(plusStore)
        }
        .modelContainer(for: [UserProfile.self, TanSession.self, VacationPlan.self, TanPhoto.self])
    }
}
