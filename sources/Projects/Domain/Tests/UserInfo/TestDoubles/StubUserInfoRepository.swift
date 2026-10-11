import DomainUseCaseDependency
@testable import DomainUseCaseInterface

actor StubUserInfoRepository: UserInfoRepository {

    // MARK: Lifecycle

    init(
        profile: UserProfile,
        holdsProfile: Bool = false,
        holdsFirstUpdate: Bool = false,
    ) {
        storedProfile = profile
        self.holdsProfile = holdsProfile
        self.holdsFirstUpdate = holdsFirstUpdate
    }

    // MARK: Internal

    private(set) var profileCallCount = 0
    private(set) var events = [String]()

    func profile() async throws -> UserProfile {
        profileCallCount += 1
        if holdsProfile {
            await withCheckedContinuation { profileWaiters.append($0) }
        }
        return storedProfile
    }

    func updateCuration(_: Curation) async throws {
        await recordUpdate("curation")
    }

    func updatePosition(_: MemberPosition) async throws {
        await recordUpdate("position")
    }

    func updateCareerLevel(_: CareerLevel) async throws {
        await recordUpdate("careerLevel")
    }

    func releaseProfile() {
        holdsProfile = false
        for waiter in profileWaiters {
            waiter.resume()
        }
        profileWaiters.removeAll()
    }

    func releaseUpdate() {
        holdsFirstUpdate = false
        updateWaiter?.resume()
        updateWaiter = nil
    }

    // MARK: Private

    private let storedProfile: UserProfile
    private var holdsProfile: Bool
    private var holdsFirstUpdate: Bool
    private var profileWaiters = [CheckedContinuation<Void, Never>]()
    private var updateWaiter: CheckedContinuation<Void, Never>?

    private func recordUpdate(_ name: String) async {
        events.append("\(name):start")
        if holdsFirstUpdate {
            await withCheckedContinuation { updateWaiter = $0 }
        }
        events.append("\(name):end")
    }

}
