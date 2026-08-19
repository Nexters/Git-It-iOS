import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@MainActor
@Suite("학습 프로젝트 목록 상호작용")
struct LearningProjectListInteractionTests {

    // MARK: Internal

    @Test
    func `메뉴를 열고 닫은 뒤 삭제 모드에 진입하고 종료한다`() async throws {
        let project = try makeProject(id: "project-1")
        let store = makeStore(project: project)

        await store.send(.menuButtonTapped) {
            $0.isMenuPresented = true
        }
        await store.send(.menuDismissed) {
            $0.isMenuPresented = false
        }
        await store.send(.menuButtonTapped) {
            $0.isMenuPresented = true
        }
        await store.send(.deleteModeEntered) {
            $0.isMenuPresented = false
            $0.isDeleteMode = true
        }
        await store.send(.deleteModeExited) {
            $0.isDeleteMode = false
        }
    }

    @Test
    func `삭제 대상 선택을 취소하면 삭제 모드를 유지한다`() async throws {
        let project = try makeProject(id: "project-1")
        let store = makeStore(project: project, isDeleteMode: true)

        await store.send(.deleteButtonTapped(project.id)) {
            $0.pendingDeletion = project.id
        }
        await store.send(.deletionCancelled) {
            $0.pendingDeletion = nil
        }

        #expect(store.state.isDeleteMode)
        #expect(store.state.projects[id: project.id] == project)
    }

    @Test
    func `삭제 확인 성공은 식별자를 한 번 전달하고 마지막 항목을 제거한다`() async throws {
        let project = try makeProject(id: "project-1")
        let deleteProjects = DeleteLearningProjectMock(
            behavior: .result(.success(()))
        )
        let store = makeStore(
            project: project,
            isDeleteMode: true,
            deleteLearningProject: deleteProjects,
        )

        await store.send(.deleteButtonTapped(project.id)) {
            $0.pendingDeletion = project.id
        }
        await store.send(.deletionConfirmed)
        await store.receive(\.deletionResponse) {
            $0.projects.remove(id: project.id)
            $0.pendingDeletion = nil
            $0.isDeleteMode = false
        }

        #expect(await deleteProjects.snapshot() == [project.id])
        #expect(store.state.isEmpty)
    }

    @Test
    func `삭제 실패는 확인 상태만 닫고 목록과 삭제 모드를 보존한다`() async throws {
        let project = try makeProject(id: "project-1")
        let deleteProjects = DeleteLearningProjectMock(
            behavior: .result(.failure(.temporarilyUnavailable))
        )
        let store = makeStore(
            project: project,
            isDeleteMode: true,
            deleteLearningProject: deleteProjects,
        )

        await store.send(.deleteButtonTapped(project.id)) {
            $0.pendingDeletion = project.id
        }
        await store.send(.deletionConfirmed)
        await store.receive(\.deletionResponse) {
            $0.pendingDeletion = nil
        }

        #expect(await deleteProjects.snapshot() == [project.id])
        #expect(store.state.projects[id: project.id] == project)
        #expect(store.state.isDeleteMode)
    }

    @Test
    func `학습 시작 선택은 화면 밖 이동 delegate를 출력한다`() async throws {
        let project = try makeProject(id: "project-1")
        let store = makeStore(project: project)

        await store.send(.learningStartButtonTapped(project.id))
        await store.receive(.delegate(.learningStarted(project.id)))
    }

    // MARK: Private

    private func makeStore(
        project: LearningProjectSummary,
        isDeleteMode: Bool = false,
        deleteLearningProject: any DeleteLearningProject = DeleteLearningProjectMock(
            behavior: .result(.success(()))
        ),
    ) -> TestStore<LearningProjectListFeature.State, LearningProjectListFeature.Action> {
        TestStore(
            initialState: LearningProjectListFeature.State(
                projects: .init(uniqueElements: [project]),
                loadState: .loaded,
                isDeleteMode: isDeleteMode,
            )
        ) {
            LearningProjectListFeature(
                fetchLearningProjects: FetchLearningProjectsMock(
                    behavior: .result(.success(.init(
                        projects: [project],
                        hasNextPage: false,
                    )))
                ),
                deleteLearningProject: deleteLearningProject,
            )
        }
    }

    private func makeProject(id: String) throws -> LearningProjectSummary {
        LearningProjectSummary(
            id: try #require(LearningProjectID(rawValue: id)),
            name: "Git It iOS",
            technologies: "Swift · SwiftUI · TCA",
            progress: .init(completedRatio: 0.65),
            nextSet: .init(order: 2, title: "Presentation 구조"),
        )
    }

}
