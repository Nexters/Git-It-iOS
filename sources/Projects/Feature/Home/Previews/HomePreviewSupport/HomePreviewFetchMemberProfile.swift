import DomainMember
import Foundation

struct HomePreviewFetchMemberProfile: FetchMemberProfileUseCase {
    enum Behavior: Sendable {
        case success(MemberProfile)
        case failure(MemberError)
    }

    let behavior: Behavior

    func callAsFunction() async throws -> MemberProfile {
        switch behavior {
        case .success(let profile): return profile
        case .failure(let error): throw error
        }
    }
}
