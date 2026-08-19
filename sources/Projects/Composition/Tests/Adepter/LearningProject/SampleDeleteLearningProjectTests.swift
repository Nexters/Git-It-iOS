import DomainLearningProject
import Testing

@testable import CompositionAdepter

// MARK: - SampleDeleteLearningProjectTests

@Suite("표본 학습 프로젝트 삭제")
struct SampleDeleteLearningProjectTests {
    @Test
    func `기존 식별자를 삭제하면 같은 저장소에서 다시 삭제할 때 projectUnavailable을 던진다`() async throws {
        let project = try makeDeleteProject(id: "project-1")
        let store = SampleLearningProjectStore(
            initialPage: .init(
                projects: [project],
                hasNextPage: false,
            )
        )
        let deleteProject = SampleDeleteLearningProject(store: store)

        try await deleteProject(project.id)

        await #expect(throws: LearningProjectError.projectUnavailable) {
            try await deleteProject(project.id)
        }
    }

    @Test
    func `없는 식별자 삭제는 projectUnavailable을 던지고 저장소 상태를 보존한다`() async throws {
        let project = try makeDeleteProject(id: "project-1")
        let missingID = try #require(LearningProjectID(rawValue: "missing-project"))
        let initialPage = LearningProjectPage(
            projects: [project],
            hasNextPage: true,
        )
        let store = SampleLearningProjectStore(initialPage: initialPage)
        let deleteProject = SampleDeleteLearningProject(store: store)
        let fetchProjects = SampleFetchLearningProjects(store: store)

        await #expect(throws: LearningProjectError.projectUnavailable) {
            try await deleteProject(missingID)
        }
        let page = try await fetchProjects(page: 0, size: 1)

        #expect(page == initialPage)
    }

    @Test
    func `별도 저장소 인스턴스의 프로세스 수명 상태는 서로 격리된다`() async throws {
        let project = try makeDeleteProject(id: "project-1")
        let initialPage = LearningProjectPage(
            projects: [project],
            hasNextPage: false,
        )
        let firstStore = SampleLearningProjectStore(initialPage: initialPage)
        let secondStore = SampleLearningProjectStore(initialPage: initialPage)
        let firstDeleteProject = SampleDeleteLearningProject(store: firstStore)
        let firstFetchProjects = SampleFetchLearningProjects(store: firstStore)
        let secondFetchProjects = SampleFetchLearningProjects(store: secondStore)

        try await firstDeleteProject(project.id)
        let firstPage = try await firstFetchProjects(page: 0, size: 1)
        let secondPage = try await secondFetchProjects(page: 0, size: 1)

        #expect(firstPage.projects.isEmpty)
        #expect(secondPage == initialPage)
    }

    @Test
    func `같은 식별자를 동시에 삭제하면 한 요청만 성공한다`() async throws {
        let project = try makeDeleteProject(id: "project-1")
        let store = SampleLearningProjectStore(
            initialPage: .init(
                projects: [project],
                hasNextPage: false,
            )
        )
        let deleteProject = SampleDeleteLearningProject(store: store)

        let outcomes = await withTaskGroup(
            of: DeletionOutcome.self,
            returning: [DeletionOutcome].self,
        ) { group in
            for _ in 0 ..< 2 {
                group.addTask {
                    await deletionOutcome(
                        deleteProject: deleteProject,
                        id: project.id,
                    )
                }
            }

            var outcomes = [DeletionOutcome]()
            for await outcome in group {
                outcomes.append(outcome)
            }
            return outcomes
        }

        #expect(outcomes.count(where: { $0 == .success }) == 1)
        #expect(outcomes.count(where: { $0 == .projectUnavailable }) == 1)
    }
}

// MARK: - DeletionOutcome

private enum DeletionOutcome: Sendable, Equatable {
    case success
    case projectUnavailable
    case unexpectedFailure
}

private func deletionOutcome(
    deleteProject: SampleDeleteLearningProject,
    id: LearningProjectID,
) async -> DeletionOutcome {
    do {
        try await deleteProject(id)
        return .success
    } catch LearningProjectError.projectUnavailable {
        return .projectUnavailable
    } catch {
        return .unexpectedFailure
    }
}

private func makeDeleteProject(id: String) throws -> LearningProjectSummary {
    LearningProjectSummary(
        id: try #require(LearningProjectID(rawValue: id)),
        name: "Swift 동시성",
        technologies: "Swift, TCA",
        progress: .init(completedRatio: 0.5),
        nextSet: .init(order: 2, title: "Actor 이해하기"),
    )
}
