import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@MainActor
@Suite("학습 프로젝트 목록 상호작용")
struct LearningProjectListInteractionTests {

    // MARK: Internal

    @Test
    func `메뉴를 열고 닫은 뒤 삭제 모드에 진입하고 종료한다`() async {
        let project = makeProject(id: "project-1")
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
    func `삭제 대상 선택을 취소하면 삭제 모드를 유지한다`() async {
        let project = makeProject(id: "project-1")
        let store = makeStore(project: project, isDeleteMode: true)

        await store.send(.deleteButtonTapped(project.projectId)) {
            $0.pendingDeletion = project.projectId
        }
        await store.send(.deletionCancelled) {
            $0.pendingDeletion = nil
        }

        #expect(store.state.isDeleteMode)
        #expect(store.state.projects.first(where: { $0.projectId == project.projectId }) == project)
    }

    @Test
    func `삭제 확인 성공은 식별자를 한 번 전달하고 마지막 항목을 제거한다`() async {
        let project = makeProject(id: "project-1")
        let deleteProjects = DeleteLearningProjectMock(
            behavior: .result(.success(()))
        )
        let store = makeStore(
            project: project,
            isDeleteMode: true,
            deleteLearningProject: deleteProjects,
        )

        await store.send(.deleteButtonTapped(project.projectId)) {
            $0.pendingDeletion = project.projectId
        }
        await store.send(.deletionConfirmed)
        await store.receive(\.deletionResponse) {
            $0.projects.removeAll { $0.projectId == project.projectId }
            $0.pendingDeletion = nil
            $0.isDeleteMode = false
        }

        #expect(await deleteProjects.snapshot() == [project.projectId])
        #expect(store.state.isEmpty)
    }

    @Test
    func `삭제 실패는 확인 상태만 닫고 목록과 삭제 모드를 보존한다`() async {
        let project = makeProject(id: "project-1")
        let deleteProjects = DeleteLearningProjectMock(
            behavior: .result(.failure(.unexpected))
        )
        let store = makeStore(
            project: project,
            isDeleteMode: true,
            deleteLearningProject: deleteProjects,
        )

        await store.send(.deleteButtonTapped(project.projectId)) {
            $0.pendingDeletion = project.projectId
        }
        await store.send(.deletionConfirmed)
        await store.receive(\.deletionResponse) {
            $0.pendingDeletion = nil
        }

        #expect(await deleteProjects.snapshot() == [project.projectId])
        #expect(store.state.projects.first(where: { $0.projectId == project.projectId }) == project)
        #expect(store.state.isDeleteMode)
    }

    @Test
    func `학습 시작 선택은 화면 밖 이동 delegate를 출력한다`() async {
        let project = makeProject(id: "project-1")
        let store = makeStore(project: project)

        await store.send(.learningStartButtonTapped(project.projectId))
        await store.receive(.delegate(.learningStarted(project.projectId)))
    }

    // MARK: Private

    private func makeStore(
        project: LearningProjectSummary,
        isDeleteMode: Bool = false,
        deleteLearningProject: any DeleteLearningProjectUseCase = DeleteLearningProjectMock(
            behavior: .result(.success(()))
        ),
    ) -> TestStore<LearningProjectListFeature.State, LearningProjectListFeature.Action> {
        TestStore(
            initialState: LearningProjectListFeature.State(
                projects: [project],
                loadState: .loaded,
                isDeleteMode: isDeleteMode,
            )
        ) {
            LearningProjectListFeature(
                fetchLearningProjects: FetchLearningProjectsMock(
                    behavior: .result(.success(.init(
                        items: [project],
                        hasNext: false,
                    )))
                ),
                deleteLearningProject: deleteLearningProject,
            )
        }
    }

    private func makeProject(id: String) -> LearningProjectSummary {
        LearningProjectSummary(
            projectId: id,
            repositoryName: "Git It iOS",
            repositoryImageURL: nil,
            techStack: ["Swift", "SwiftUI", "TCA"],
            currentSetLabel: "Set 2",
            currentSetTitle: "Presentation 구조",
            nextSetId: "set-2",
            nextQuestionId: "question-1",
            overallProgressPercent: 65,
        )
    }

}
