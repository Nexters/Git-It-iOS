import Testing

@testable import DomainMember

// MARK: - CompleteCurationTests

@Suite("CompleteCuration")
struct CompleteCurationTests {
    @Test
    func `정확한 position과 careerLevel로 요청한다`() async throws {
        let repository = CompleteCurationRepository()
        let completeCuration = CompleteCuration(repository: repository)

        try await completeCuration(position: .ios, careerLevel: .junior)

        #expect(await repository.requestedPosition == .ios)
        #expect(await repository.requestedCareerLevel == .junior)
    }

    @Test
    func `서버 실패 시 오류를 그대로 전파한다`() async throws {
        let repository = CompleteCurationRepository(behavior: .fail)
        let completeCuration = CompleteCuration(repository: repository)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await completeCuration(position: .ios, careerLevel: .junior)
        }
    }

    @Test
    func `CareerLevel은 entry junior midLevel senior 4개뿐이다`() {
        #expect(CareerLevel.allCases.count == 4)
        #expect(Set(CareerLevel.allCases) == [.entry, .junior, .middle, .senior])
    }

    @Test
    func `지원하는 모든 position과 career 조합을 단일 제출로 전달한다`() async throws {
        for position in MemberPosition.allCases {
            for careerLevel in CareerLevel.allCases {
                let repository = CompleteCurationRepository()
                let completeCuration = CompleteCuration(repository: repository)

                try await completeCuration(position: position, careerLevel: careerLevel)

                #expect(await repository.requestedPosition == position)
                #expect(await repository.requestedCareerLevel == careerLevel)
                #expect(await repository.completeCurationCallCount == 1)
            }
        }
    }
}

// MARK: - CompleteCurationRepository

private actor CompleteCurationRepository: MemberRepository {

    // MARK: Lifecycle

    init(behavior: Behavior = .succeed) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed
        case fail
    }

    private(set) var requestedPosition: MemberPosition?
    private(set) var requestedCareerLevel: CareerLevel?
    private(set) var completeCurationCallCount = 0

    func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        requestedPosition = position
        requestedCareerLevel = careerLevel
        completeCurationCallCount += 1
        if case .fail = behavior {
            throw MemberError.temporarilyUnavailable
        }
    }

    func fetchProfile() async throws -> MemberProfile {
        throw MemberError.memberUnavailable
    }

    func updatePosition(_: MemberPosition) async throws { }
    func updateCareerLevel(_: CareerLevel) async throws { }
    func registerDevice(_: MemberDeviceInfo) async throws { }
    func deleteAccount() async throws { }

    // MARK: Private

    private let behavior: Behavior

}
