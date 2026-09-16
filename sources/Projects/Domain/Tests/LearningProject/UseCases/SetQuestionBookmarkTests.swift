import Testing

@testable import DomainLearningProject

// MARK: - SetQuestionBookmarkTests

@Suite("SetQuestionBookmark")
struct SetQuestionBookmarkTests {

    // MARK: Internal

    @Test
    func `desired bool을 정확히 전송한다`() async throws {
        let repository = SetQuestionBookmarkRepository()
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        _ = try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)

        #expect(await repository.lastRequestedValue == true)
    }

    @Test
    func `서버 최종 응답을 정본으로 반영한다`() async throws {
        let repository = SetQuestionBookmarkRepository(responds: false)
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        let state = try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)

        #expect(state.bookmarked == false)
    }

    @Test
    func `같은 question의 동시 호출은 직렬화된다`() async throws {
        let repository = SetQuestionBookmarkRepository()
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        async let first = setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)
        async let second = setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: false)
        _ = try await (first, second)

        #expect(await repository.maxConcurrentCalls == 1)
    }

    @Test
    func `같은 question의 두 호출은 시작 순서대로 처리한다`() async throws {
        let gate = Gate()
        let repository = SetQuestionBookmarkRepository(gate: gate, gatedQuestionID: "q1")
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        let first = Task { try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true) }
        await gate.waitUntilArrived(count: 1)
        let second = Task { try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: false) }
        await Self.yieldUntilQueued()
        await gate.open()

        _ = try await (first.value, second.value)

        #expect(await repository.requestLog == [
            Request(questionID: "q1", bookmarked: true),
            Request(questionID: "q1", bookmarked: false),
        ])
    }

    @Test
    func `앞 호출이 실패해도 뒤 호출은 실행하고 실패는 각 호출자에게 전달한다`() async throws {
        let gate = Gate()
        let repository = SetQuestionBookmarkRepository(gate: gate, gatedQuestionID: "q1", failsFirstCall: true)
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        let first = Task { try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true) }
        await gate.waitUntilArrived(count: 1)
        let second = Task { try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: false) }
        await Self.yieldUntilQueued()
        await gate.open()

        await #expect(throws: SampleError.rejected) { _ = try await first.value }
        let state = try await second.value

        #expect(state.bookmarked == false)
        #expect(await repository.requestLog.count == 2)
    }

    @Test
    func `다른 question의 호출은 서로 기다리지 않는다`() async throws {
        let gate = Gate()
        let repository = SetQuestionBookmarkRepository(gate: gate, gatedQuestionID: "q1")
        let setQuestionBookmark = SetQuestionBookmark(repository: repository)

        let blocked = Task { try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true) }
        await gate.waitUntilArrived(count: 1)

        let other = try await setQuestionBookmark(projectID: "project-1", questionID: "q2", bookmarked: true)
        #expect(other.bookmarked == true)

        await gate.open()
        _ = try await blocked.value
    }

    @Test
    func `대기가 끝난 question의 추적 항목은 남지 않는다`() async throws {
        let setQuestionBookmark = SetQuestionBookmark(repository: SetQuestionBookmarkRepository())

        _ = try await setQuestionBookmark(projectID: "project-1", questionID: "q1", bookmarked: true)
        _ = try await setQuestionBookmark(projectID: "project-1", questionID: "q2", bookmarked: false)

        #expect(await setQuestionBookmark.pendingKeyCount == 0)
    }

    // MARK: Private

    private static func yieldUntilQueued() async {
        for _ in 0 ..< 100 {
            await Task.yield()
        }
    }

}

// MARK: - Request

private struct Request: Equatable, Sendable {
    let questionID: String
    let bookmarked: Bool
}

// MARK: - SampleError

private enum SampleError: Equatable, Error {
    case rejected
}

// MARK: - Gate

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

// MARK: - SetQuestionBookmarkRepository

private actor SetQuestionBookmarkRepository: BookmarkRepository {

    // MARK: Lifecycle

    init(
        responds: Bool? = nil,
        gate: Gate? = nil,
        gatedQuestionID: String? = nil,
        failsFirstCall: Bool = false,
    ) {
        self.responds = responds
        self.gate = gate
        self.gatedQuestionID = gatedQuestionID
        self.failsFirstCall = failsFirstCall
    }

    // MARK: Internal

    private(set) var lastRequestedValue: Bool?
    private(set) var maxConcurrentCalls = 0
    private(set) var requestLog = [Request]()

    func setBookmark(
        projectID _: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        if let gate, questionID == gatedQuestionID {
            await gate.wait()
        }
        lastRequestedValue = bookmarked
        requestLog.append(Request(questionID: questionID, bookmarked: bookmarked))
        concurrentCalls += 1
        maxConcurrentCalls = max(maxConcurrentCalls, concurrentCalls)
        if gate == nil {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        concurrentCalls -= 1
        if failsFirstCall, requestLog.count == 1 {
            throw SampleError.rejected
        }
        return BookmarkState(bookmarked: responds ?? bookmarked)
    }

    func fetchBookmarkedQuestions(projectID _: String?) async throws -> BookmarkedQuestionCollection {
        BookmarkedQuestionCollection(totalCount: 0, availableProjects: [], bookmarks: [])
    }

    // MARK: Private

    private let responds: Bool?
    private let gate: Gate?
    private let gatedQuestionID: String?
    private let failsFirstCall: Bool
    private var concurrentCalls = 0

}
