import Foundation
import Testing

@testable import DomainProject

@Suite("Project")
struct ProjectTests {

    // MARK: Internal

    @Test
    func `구독자 둘이 같은 목록을 받는다`() async {
        let fixture = Fixture(pages: [0: ProjectPage(summaries: [Self.summary("p1")], hasNextPage: false)])

        var first = await fixture.project.projects().makeAsyncIterator()
        var second = await fixture.project.projects().makeAsyncIterator()

        let firstList = await Self.next(&first) { $0.isLoaded }
        let secondList = await Self.next(&second) { $0.isLoaded }
        #expect(firstList == secondList)
        #expect(firstList?.summaries.map(\.id) == ["p1"])
    }

    @Test
    func `첫 로드와 새로고침이 동시에 일어나면 첫 페이지를 한 번만 요청한다`() async throws {
        let fixture = Fixture(
            pages: [0: ProjectPage(summaries: [Self.summary("p1")], hasNextPage: false)],
            holdsFirstRequest: true,
        )

        var lists = await fixture.project.projects().makeAsyncIterator()
        await Self.settle { await fixture.repository.requestedPageIndexes == [0] }
        let refresh = Task { try await fixture.project.refresh() }
        for _ in 0 ..< 50 {
            await Task.yield()
        }
        await fixture.repository.release()
        try await refresh.value

        let list = await Self.next(&lists) { $0.isLoaded }
        #expect(list?.summaries.map(\.id) == ["p1"])
        #expect(await fixture.repository.requestedPageIndexes == [0])
    }

    @Test
    func `다음 페이지를 중복 없이 이어 붙인다`() async throws {
        let fixture = Fixture(pages: [
            0: ProjectPage(summaries: [Self.summary("p1"), Self.summary("p2")], hasNextPage: true),
            1: ProjectPage(summaries: [Self.summary("p2"), Self.summary("p3")], hasNextPage: false),
        ])

        try await fixture.project.refresh()
        try await fixture.project.requestNextPage()
        try await fixture.project.requestNextPage()

        var lists = await fixture.project.projects().makeAsyncIterator()
        let list = await lists.next()
        #expect(list?.summaries.map(\.id) == ["p1", "p2", "p3"])
        #expect(list?.hasNextPage == false)
        #expect(await fixture.repository.requestedPageIndexes == [0, 1])
    }

    @Test
    func `준비 중인 프로젝트는 재요청 없이 목록에서 뺀다`() async throws {
        let fixture = Fixture(pages: [0: ProjectPage(summaries: [Self.summary("p1"), Self.summary("p2")], hasNextPage: false)])
        try await fixture.project.refresh()
        var lists = await fixture.project.projects().makeAsyncIterator()
        _ = await lists.next()

        fixture.preparingContinuation.yield(["p2"])

        let list = await Self.next(&lists) { $0.summaries.count == 1 }
        #expect(list?.summaries.map(\.id) == ["p1"])
        #expect(await fixture.repository.requestedPageIndexes == [0])
    }

    @Test
    func `준비 목록에서 빠진 프로젝트가 생기면 첫 페이지를 새로고침한다`() async throws {
        let fixture = Fixture(pages: [0: ProjectPage(summaries: [Self.summary("p1")], hasNextPage: false)])
        try await fixture.project.refresh()
        var lists = await fixture.project.projects().makeAsyncIterator()
        _ = await lists.next()
        fixture.preparingContinuation.yield(["p2"])
        _ = await Self.next(&lists) { _ in true }

        await fixture.repository.setPage(
            ProjectPage(summaries: [Self.summary("p2"), Self.summary("p1")], hasNextPage: false),
            at: 0,
        )
        fixture.preparingContinuation.yield([])

        let list = await Self.next(&lists) { $0.summaries.count == 2 }
        #expect(list?.summaries.map(\.id) == ["p2", "p1"])
        #expect(await fixture.repository.requestedPageIndexes == [0, 0])
    }

    @Test
    func `삭제에 성공하면 목록에서 제거한다`() async throws {
        let fixture = Fixture(pages: [0: ProjectPage(summaries: [Self.summary("p1"), Self.summary("p2")], hasNextPage: false)])
        try await fixture.project.refresh()

        try await fixture.project.delete("p1")

        var lists = await fixture.project.projects().makeAsyncIterator()
        let list = await lists.next()
        #expect(list?.summaries.map(\.id) == ["p2"])
        #expect(await fixture.repository.deletedProjectIDs == ["p1"])
    }

    @Test
    func `로그아웃하면 목록을 비우고 로드 전 상태로 되돌린다`() async throws {
        let fixture = Fixture(pages: [0: ProjectPage(summaries: [Self.summary("p1")], hasNextPage: true)])
        try await fixture.project.refresh()
        var lists = await fixture.project.projects().makeAsyncIterator()
        _ = await lists.next()

        fixture.signedOutContinuation.yield(())

        let list = await Self.next(&lists) { !$0.isLoaded }
        #expect(list == ProjectList(summaries: [], hasNextPage: false, isLoaded: false))
    }

    @Test
    func `새로고침이 실패하면 오류를 전달하고 마지막 목록을 유지한다`() async throws {
        let fixture = Fixture(pages: [0: ProjectPage(summaries: [Self.summary("p1")], hasNextPage: false)])
        try await fixture.project.refresh()
        await fixture.repository.setFailure(.temporarilyUnavailable)

        await #expect(throws: ProjectError.temporarilyUnavailable) {
            try await fixture.project.refresh()
        }

        var lists = await fixture.project.projects().makeAsyncIterator()
        let list = await lists.next()
        #expect(list == ProjectList(summaries: [Self.summary("p1")], hasNextPage: false, isLoaded: true))
    }

    // MARK: Private

    private struct Fixture {

        // MARK: Lifecycle

        init(
            pages: [Int: ProjectPage],
            holdsFirstRequest: Bool = false,
        ) {
            let repository = StubProjectRepository(pages: pages, holdsFirstRequest: holdsFirstRequest)
            let (preparing, preparingContinuation) = AsyncStream<Set<String>>.makeStream()
            let (signedOut, signedOutContinuation) = AsyncStream<Void>.makeStream()
            self.repository = repository
            self.preparingContinuation = preparingContinuation
            self.signedOutContinuation = signedOutContinuation
            project = Project(
                repository: repository,
                preparingProjectIDs: { preparing },
                signedOutEvents: { signedOut },
            )
        }

        // MARK: Internal

        let repository: StubProjectRepository
        let preparingContinuation: AsyncStream<Set<String>>.Continuation
        let signedOutContinuation: AsyncStream<Void>.Continuation
        let project: Project

    }

    private static func summary(_ id: String) -> ProjectSummary {
        ProjectSummary(
            id: id,
            repositoryName: "repo-\(id)",
            repositoryImageURL: nil,
            techStack: ["Swift"],
            currentSet: ProjectSetLabel(label: "L1", title: "세트"),
            next: ProjectNextQuiz(setID: "s1", quizID: nil),
            progressPercent: 0,
        )
    }

    private static func next(
        _ iterator: inout AsyncStream<ProjectList>.Iterator,
        where predicate: (ProjectList) -> Bool,
    ) async -> ProjectList? {
        while let list = await iterator.next() {
            if predicate(list) {
                return list
            }
        }
        return nil
    }

    private static func settle(until condition: @Sendable () async -> Bool) async {
        for _ in 0 ..< 200 {
            guard await !condition() else { return }
            await Task.yield()
        }
    }

}
