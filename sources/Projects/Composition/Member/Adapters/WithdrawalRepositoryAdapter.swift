import DataMember
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - WithdrawalRepositoryAdapter

public struct WithdrawalRepositoryAdapter: WithdrawalRepository {

    // MARK: Lifecycle

    public init(remote: MemberRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func withdraw() async throws {
        do {
            try await remote.withdrawMember()
        } catch let error as MemberServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: MemberRemote

    private func domainError(for error: MemberServiceError) -> AccountError {
        switch error {
        case .unauthorized:
            .unauthorized

        case .invalidRequest,
             .memberUnavailable:
            .withdrawalUnavailable

        case .temporarilyUnavailable,
             .transport,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
