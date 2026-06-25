import SwiftUI
import SoleaCore

struct MainTabView: View {
    let phototype: Fitzpatrick
    var connectivity: PhoneConnectivityService

    @Environment(SoleaPlusStore.self) private var plusStore
    @State private var sessionManager = SessionManager()

    var body: some View {
        TabView {
            TodayView(phototype: phototype, sessionManager: sessionManager)
                .tabItem { Label("Oggi", systemImage: "sun.max.fill") }

            DiaryView(hasSoleaPlus: plusStore.hasPlus)
                .tabItem { Label("Diario", systemImage: "book.closed") }

            PlannerView(phototype: phototype, hasSoleaPlus: plusStore.hasPlus)
                .tabItem { Label("Planner", systemImage: "airplane") }

            CoachView(phototype: phototype, currentUVIndex: nil, hasSoleaPlus: plusStore.hasPlus)
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right.fill") }

            ProfileView(phototype: phototype, connectivity: connectivity)
                .tabItem { Label("Profilo", systemImage: "person.crop.circle") }
        }
        .tint(SoleaTheme.sunset)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(SoleaTheme.sunshine.opacity(0.14), for: .tabBar)
    }
}
