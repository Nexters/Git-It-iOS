import ComposableArchitecture
import DomainMember
import Foundation

struct OnboardingPreviewDeleteMemberAccount: DeleteMemberAccountUseCase {
    func callAsFunction() async throws {
        throw CancellationError()
    }
}
