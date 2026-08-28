import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

struct OnboardingPreviewSignIn: SignInUseCase {
    func callAsFunction(_: AuthenticationMethod) async -> SignInResult {
        .retryableFailure
    }
}
