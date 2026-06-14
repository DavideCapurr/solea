import SwiftUI
import SwiftData
import SoleaCore

struct RootView: View {
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
            connectivity.activate()
            if let phototype = profiles.first?.phototype {
                connectivity.sync(phototype: phototype)
            }
        }
        .onChange(of: profiles.first?.phototype) { _, newPhototype in
            if let newPhototype {
                connectivity.sync(phototype: newPhototype)
            }
        }
    }
}
