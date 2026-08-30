import DomainMember
import Foundation

actor DeleteMemberAccountUseCaseMock: DeleteMemberAccountUseCase {

    // MARK: Lifecycle

    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }

    // MARK: Internal

    func callAsFunction() async throws {
        callCount += 1
        if shouldThrow {
            throw MemberError.temporarilyUnavailable
        }
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private let shouldThrow: Bool
    private var callCount = 0

}
