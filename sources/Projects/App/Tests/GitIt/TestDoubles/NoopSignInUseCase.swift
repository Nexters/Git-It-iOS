import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

struct NoopSignInUseCase: SignInUseCase {
    func callAsFunction(_: AuthenticationMethod) async -> SignInResult {
        .retryableFailure
    }
}
