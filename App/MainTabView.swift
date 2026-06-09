import SwiftUI
import SoleaCore

struct MainTabView: View {
    let phototype: Fitzpatrick

    @State private var sessionManager = SessionManager()

    var body: some View {
        TabView {
            TodayView(phototype: phototype, sessionManager: sessionManager)
                .tabItem { Label("Oggi", systemImage: "sun.max.fill") }

            DiaryView()
                .tabItem { Label("Diario", systemImage: "book.closed") }

            ProfileView(phototype: phototype)
                .tabItem { Label("Profilo", systemImage: "person.crop.circle") }
        }
    }
}
