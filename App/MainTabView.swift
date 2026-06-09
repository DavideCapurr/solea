import SwiftUI
import SoleaCore

struct MainTabView: View {
    let phototype: Fitzpatrick

    var body: some View {
        TabView {
            TodayView(phototype: phototype)
                .tabItem { Label("Oggi", systemImage: "sun.max.fill") }

            ContentUnavailableView(
                "Diario",
                systemImage: "book.closed",
                description: Text("Il diario delle sessioni arriva con la prossima milestone.")
            )
            .tabItem { Label("Diario", systemImage: "book.closed") }

            ProfileView(phototype: phototype)
                .tabItem { Label("Profilo", systemImage: "person.crop.circle") }
        }
    }
}
