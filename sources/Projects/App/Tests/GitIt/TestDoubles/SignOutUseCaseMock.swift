import DomainUserInfo
import Foundation

actor UserInfoUseCaseMock: UserInfoUseCase {

    // MARK: Lifecycle

    init(curations: [Result<Curation?, UserInfoError>] = [.success(AppRootTestFixture.curation)]) {
        self.curations = curations
    }

    // MARK: Internal

    private(set) var curationCallCount = 0

    func detail() async throws -> UserDetail {
        AppRootTestFixture.userDetail
    }

    func curation() async throws -> Curation? {
        curationCallCount += 1
        guard !curations.isEmpty else { return nil }
        let next = curations.count > 1 ? curations.removeFirst() : curations[0]
        return try next.get()
    }

    func updateCuration(_: Curation) async throws { }

    func updatePosition(_: MemberPosition) async throws { }

    func updateCareerLevel(_: CareerLevel) async throws { }

    // MARK: Private

    private var curations: [Result<Curation?, UserInfoError>]

}
