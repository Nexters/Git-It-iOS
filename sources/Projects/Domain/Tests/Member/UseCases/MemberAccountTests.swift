import Testing

@testable import DomainMember

// MARK: - MemberAccountTests

@Suite("MemberAccount")
struct MemberAccountTests {

    // MARK: Internal

    @Test
    func `전체 프로필과 통계를 손실 없이 전달한다`() async throws {
        let statistics = LearningStatistics(
            thisWeekSolvedCount: 10,
            thisMonthSolvedCount: 7,
            streakDays: 2,
            weeklyCounts: [WeeklyLearningCount(dayLabel: "월", count: 3)],
        )
        let profile = MemberProfile(
            name: "홍길동",
            email: "gildong@example.com",
            position: .ios,
            careerLevel: .senior,
            statistics: statistics,
        )
        let account = MemberAccount(repository: RecordingMemberRepository(profile: profile))

        let result = try await account.profile()

        #expect(result == profile)
        #expect(result.statistics.weeklyCounts.count == 1)
    }

    @Test
    func `member unavailable 오류를 그대로 전파한다`() async throws {
        let account = MemberAccount(repository: RecordingMemberRepository(profile: nil))

        await #expect(throws: MemberError.memberUnavailable) {
            try await account.profile()
        }
    }

    @Test
    func `position만 요청하고 career는 건드리지 않는다`() async throws {
        let repository = RecordingMemberRepository()
        let account = MemberAccount(repository: repository)

        try await account.updatePosition(.backend)

        #expect(await repository.requestedPosition == .backend)
        #expect(await repository.careerUpdateCallCount == 0)
    }

    @Test
    func `position 변경이 실패하면 오류를 그대로 전파한다`() async throws {
        let repository = RecordingMemberRepository(positionBehavior: .fail)
        let account = MemberAccount(repository: repository)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await account.updatePosition(.backend)
        }
    }

    @Test
    func `career만 요청하고 position은 건드리지 않는다`() async throws {
        let repository = RecordingMemberRepository()
        let account = MemberAccount(repository: repository)

        try await account.updateCareerLevel(.senior)

        #expect(await repository.requestedCareerLevel == .senior)
        #expect(await repository.positionUpdateCallCount == 0)
    }

    @Test
    func `큐레이션은 정확한 position과 careerLevel로 요청한다`() async throws {
        let repository = RecordingMemberRepository()
        let account = MemberAccount(repository: repository)

        try await account.completeCuration(position: .ios, careerLevel: .junior)

        #expect(await repository.curatedPosition == .ios)
        #expect(await repository.curatedCareerLevel == .junior)
    }

    @Test
    func `큐레이션 서버 실패 시 오류를 그대로 전파한다`() async throws {
        let repository = RecordingMemberRepository(curationBehavior: .fail)
        let account = MemberAccount(repository: repository)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await account.completeCuration(position: .ios, careerLevel: .junior)
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
                let repository = RecordingMemberRepository()
                let account = MemberAccount(repository: repository)

                try await account.completeCuration(position: position, careerLevel: careerLevel)

                #expect(await repository.curatedPosition == position)
                #expect(await repository.curatedCareerLevel == careerLevel)
                #expect(await repository.curationCallCount == 1)
            }
        }
    }

    @Test
    func `같은 키의 두 변경은 시작 순서대로 처리한다`() async throws {
        let gate = Gate()
        let repository = RecordingMemberRepository(positionGate: gate)
        let account = MemberAccount(repository: repository)

        async let first: Void = account.updatePosition(.ios)
        await gate.waitUntilArrived(count: 1)
        async let second: Void = account.updatePosition(.backend)
        await Self.yieldUntilQueued()
        await gate.open()

        _ = try await (first, second)

        #expect(await repository.positionLog == [.ios, .backend])
    }

    @Test
    func `앞 호출이 실패해도 뒤 호출은 실행하고 실패는 각 호출자에게 전달한다`() async throws {
        let gate = Gate()
        let repository = RecordingMemberRepository(positionBehavior: .failFirst, positionGate: gate)
        let account = MemberAccount(repository: repository)

        let first = Task { try await account.updatePosition(.ios) }
        await gate.waitUntilArrived(count: 1)
        let second = Task { try await account.updatePosition(.backend) }
        await Self.yieldUntilQueued()
        await gate.open()

        await #expect(throws: MemberError.temporarilyUnavailable) { try await first.value }
        try await second.value

        #expect(await repository.positionLog == [.ios, .backend])
    }

    @Test
    func `다른 키의 호출은 서로 기다리지 않는다`() async throws {
        let gate = Gate()
        let repository = RecordingMemberRepository(positionGate: gate)
        let account = MemberAccount(repository: repository)

        async let blocked: Void = account.updatePosition(.ios)
        await gate.waitUntilArrived(count: 1)

        try await account.updateCareerLevel(.senior)
        #expect(await repository.requestedCareerLevel == .senior)

        await gate.open()
        try await blocked
    }

    @Test
    func `대기가 끝난 키의 추적 항목은 남지 않는다`() async throws {
        let account = MemberAccount(repository: RecordingMemberRepository())

        try await account.updatePosition(.ios)
        try await account.updateCareerLevel(.senior)
        try await account.completeCuration(position: .ios, careerLevel: .junior)

        #expect(await account.pendingKeyCount == 0)
    }

    // MARK: Private

    private actor Gate {

        // MARK: Internal

        func open() {
            isOpen = true
            for waiter in waiters { waiter.resume() }
            waiters = []
        }

        func wait() async {
            arrived += 1
            for waiter in arrivalWaiters where waiter.count <= arrived { waiter.continuation.resume() }
            arrivalWaiters.removeAll { $0.count <= arrived }
            guard !isOpen else { return }
            await withCheckedContinuation { waiters.append($0) }
        }

        func waitUntilArrived(count: Int) async {
            guard arrived < count else { return }
            await withCheckedContinuation { arrivalWaiters.append(ArrivalWaiter(count: count, continuation: $0)) }
        }

        // MARK: Private

        private struct ArrivalWaiter {
            let count: Int
            let continuation: CheckedContinuation<Void, Never>
        }

        private var isOpen = false
        private var arrived = 0
        private var waiters = [CheckedContinuation<Void, Never>]()
        private var arrivalWaiters = [ArrivalWaiter]()

    }

    private actor RecordingMemberRepository: MemberRepository {

        // MARK: Lifecycle

        init(
            profile: MemberProfile? = nil,
            positionBehavior: Behavior = .succeed,
            curationBehavior: Behavior = .succeed,
            positionGate: Gate? = nil,
        ) {
            self.profile = profile
            self.positionBehavior = positionBehavior
            self.curationBehavior = curationBehavior
            self.positionGate = positionGate
        }

        // MARK: Internal

        enum Behavior: Sendable {
            case succeed
            case fail
            case failFirst
        }

        private(set) var requestedPosition: MemberPosition?
        private(set) var requestedCareerLevel: CareerLevel?
        private(set) var curatedPosition: MemberPosition?
        private(set) var curatedCareerLevel: CareerLevel?
        private(set) var positionUpdateCallCount = 0
        private(set) var careerUpdateCallCount = 0
        private(set) var curationCallCount = 0
        private(set) var positionLog = [MemberPosition]()

        func completeCuration(
            position: MemberPosition,
            careerLevel: CareerLevel,
        ) async throws {
            curatedPosition = position
            curatedCareerLevel = careerLevel
            curationCallCount += 1
            if case .fail = curationBehavior {
                throw MemberError.temporarilyUnavailable
            }
        }

        func fetchProfile() async throws -> MemberProfile {
            guard let profile else { throw MemberError.memberUnavailable }
            return profile
        }

        func updatePosition(_ position: MemberPosition) async throws {
            if let positionGate {
                await positionGate.wait()
            }
            requestedPosition = position
            positionUpdateCallCount += 1
            positionLog.append(position)
            switch positionBehavior {
            case .succeed:
                return
            case .fail:
                throw MemberError.temporarilyUnavailable
            case .failFirst:
                if positionUpdateCallCount == 1 {
                    throw MemberError.temporarilyUnavailable
                }
            }
        }

        func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
            requestedCareerLevel = careerLevel
            careerUpdateCallCount += 1
        }

        func registerDevice(_: MemberDeviceInfo) async throws { }

        func deleteAccount() async throws { }

        // MARK: Private

        private let profile: MemberProfile?
        private let positionBehavior: Behavior
        private let curationBehavior: Behavior
        private let positionGate: Gate?

    }

    private static func yieldUntilQueued() async {
        for _ in 0 ..< 100 {
            await Task.yield()
        }
    }

}
