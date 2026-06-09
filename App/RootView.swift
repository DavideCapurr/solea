import SwiftUI
import SwiftData
import SoleaCore

struct RootView: View {
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
        if let phototype = profiles.first?.phototype {
            MainTabView(phototype: phototype)
        } else {
            OnboardingView()
        }
    }
}
