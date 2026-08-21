import DomainAuthentication
import DomainMember

// MARK: - CurationRepositoryAdapter

/// `MemberRepositoryAdapter`를 감싸 UC15(초기 curation 완료)의 server mutation과 local
/// onboarding state(`needsCuration`) 갱신을 원자적 순서로 조정한다: server 성공 전에는
/// local state를 절대 앞서 변경하지 않는다.
struct CurationRepositoryAdapter: MemberRepository {

    // MARK: Lifecycle

    init(
        remote: MemberRepository,
        loginSessionRepository: any LoginSessionRepository,
    ) {
        self.remote = remote
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Internal

    func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        try await remote.completeCuration(position: position, careerLevel: careerLevel)
        guard let session = await loginSessionRepository.currentSession() else { return }
        try? await loginSessionRepository.updateOnboarding(LocalOnboardingState(
            needsCuration: false,
            acceptedLegalVersions: session.onboarding.acceptedLegalVersions,
            acceptedAt: session.onboarding.acceptedAt,
        ))
    }

    func fetchProfile() async throws -> MemberProfile {
        try await remote.fetchProfile()
    }

    func updatePosition(_ position: MemberPosition) async throws {
        try await remote.updatePosition(position)
    }

    func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        try await remote.updateCareerLevel(careerLevel)
    }

    func registerDevice(_ device: MemberDeviceInfo) async throws {
        try await remote.registerDevice(device)
    }

    func deleteAccount() async throws {
        try await remote.deleteAccount()
    }

    // MARK: Private

    private let remote: MemberRepository
    private let loginSessionRepository: any LoginSessionRepository

}
