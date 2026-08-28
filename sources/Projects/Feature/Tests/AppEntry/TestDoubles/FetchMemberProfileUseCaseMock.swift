import DomainAuthentication
import DomainMember
import Foundation

actor FetchMemberProfileUseCaseMock: FetchMemberProfileUseCase {

    // MARK: Lifecycle

    init(results: [Result<MemberProfile, MemberError>] = [.failure(.temporarilyUnavailable)]) {
        self.results = results
    }

    // MARK: Internal

    func callAsFunction() async throws -> MemberProfile {
        callCount += 1
        return try nextResult().get()
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private var results: [Result<MemberProfile, MemberError>]
    private var callCount = 0

    private func nextResult() -> Result<MemberProfile, MemberError> {
        guard !results.isEmpty else { return .failure(.temporarilyUnavailable) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
