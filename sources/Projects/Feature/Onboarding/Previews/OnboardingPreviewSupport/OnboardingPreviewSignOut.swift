import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

struct OnboardingPreviewSignOut: SignOutUseCase {
    func callAsFunction() async -> SignOutResult {
        .success
    }
}
