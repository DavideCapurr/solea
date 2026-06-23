import SwiftUI
import SwiftData
import SoleaCore

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SoleaPlusStore.self) private var plusStore
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @State private var connectivity = PhoneConnectivityService()

    var body: some View {
        Group {
            if let phototype = profiles.first?.phototype {
                MainTabView(phototype: phototype, connectivity: connectivity)
            } else {
                OnboardingView()
            }
        }
        .task {
            #if DEBUG
            ScreenshotDemoSeeder.seedIfNeeded(in: modelContext)
            #endif
            await plusStore.start()
            connectivity.activate()
            if let phototype = profiles.first?.phototype {
                connectivity.sync(phototype: phototype, hasSoleaPlus: plusStore.hasPlus)
            }
        }
        .onChange(of: profiles.first?.phototype) { _, newPhototype in
            if let newPhototype {
                connectivity.sync(phototype: newPhototype, hasSoleaPlus: plusStore.hasPlus)
            }
        }
        .onChange(of: plusStore.hasPlus) { _, hasPlus in
            if let phototype = profiles.first?.phototype {
                connectivity.sync(phototype: phototype, hasSoleaPlus: hasPlus)
            }
        }
    }
}
