import SwiftUI
import SoleaCore

struct MainTabView: View {
    let phototype: Fitzpatrick
    var connectivity: PhoneConnectivityService

    @State private var sessionManager = SessionManager()

    var body: some View {
        TabView {
            TodayView(phototype: phototype, sessionManager: sessionManager)
                .tabItem { Label("Oggi", systemImage: "sun.max.fill") }

            DiaryView()
                .tabItem { Label("Diario", systemImage: "book.closed") }

            PlannerView(phototype: phototype)
                .tabItem { Label("Planner", systemImage: "airplane") }

            CoachView(phototype: phototype, currentUVIndex: nil)
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right.fill") }

            ProfileView(phototype: phototype, connectivity: connectivity)
                .tabItem { Label("Profilo", systemImage: "person.crop.circle") }
        }
    }
}
