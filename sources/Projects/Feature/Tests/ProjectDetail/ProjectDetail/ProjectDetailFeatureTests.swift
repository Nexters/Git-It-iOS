import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

@Suite("ProjectDetailFeature 상세 표시와 메뉴")
struct ProjectDetailFeatureTests {

    // MARK: Internal

    @Test
    func `진입하면 상세를 조회하고 세트 진행 표시를 서버 값 그대로 파생한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.detailLoadFinished)

        let displays = ProjectDetailSetDisplay.list(sets: store.state.detail?.sets ?? [])
        #expect(displays.map(\.label) == ["CHAPTER 1", "CHAPTER 2", "CHAPTER 3"])
        #expect(displays.map(\.completedCount) == [5, 2, 0])
        #expect(displays.map(\.questionCount) == [5, 4, 3])
    }

    @Test
    func `세트 시작은 라벨만 담은 진입 의도를 만든다`() async {
        let store = await loadedStore()

        await store.send(.view(.setStartTapped(setID: "set-1")))
        await store.receive(.delegate(.setStartRequested(
            projectID: ProjectDetailTestFixture.projectID,
            setID: "set-1",
            label: "CHAPTER 2",
        )))
    }

    @Test
    func `저장소 시작 컨트롤은 첫 미완료 세트로 같은 의도를 만든다`() async {
        let store = await loadedStore()

        #expect(store.state.isResumeEnabled)

        await store.send(.view(.resumeTapped))
        await store.receive(.delegate(.setStartRequested(
            projectID: ProjectDetailTestFixture.projectID,
            setID: "set-1",
            label: "CHAPTER 2",
        )))
    }

    @Test
    func `미완료 세트가 없으면 시작 컨트롤이 비활성이고 입력이 아무 일도 하지 않는다`() async {
        let store = await loadedStore(detail: ProjectDetailTestFixture.completedDetail)

        #expect(!store.state.isResumeEnabled)

        await store.send(.view(.resumeTapped))
    }

    @Test
    func `메뉴를 펼치고 저장한 문제를 고르면 메뉴를 닫고 진입 의도를 만든다`() async {
        let store = await loadedStore()

        await store.send(.view(.menuTapped)) { $0.isMenuPresented = true }
        await store.send(.view(.savedQuestionsTapped)) { $0.isMenuPresented = false }
        await store.receive(
            .delegate(.savedQuestionsRequested(projectID: ProjectDetailTestFixture.projectID))
        )
    }

    @Test
    func `저장소 링크는 상세의 URL을 그대로 외부 URL 요청으로 올린다`() async throws {
        let store = await loadedStore()
        let url = try #require(URL(string: ProjectDetailTestFixture.repositoryURL))

        await store.send(.view(.menuTapped)) { $0.isMenuPresented = true }
        await store.send(.view(.repositoryLinkTapped)) { $0.isMenuPresented = false }
        await store.receive(.delegate(.externalURLRequested(url)))
    }

    @Test
    func `삭제는 확인 단계를 거치고 취소하면 아무 것도 삭제하지 않는다`() async {
        let deleteLearningProject = StubDeleteLearningProjectUseCase()
        let store = await loadedStore(deleteLearningProject: deleteLearningProject)

        await store.send(.view(.deleteTapped)) { $0.deletion = .confirming }
        await store.send(.view(.deletionCancelled)) { $0.deletion = .idle }

        #expect(await deleteLearningProject.callCount == 0)
    }

    @Test
    func `삭제 중에는 재입력을 무시하고 성공하면 삭제 완료를 알린다`() async {
        let deleteLearningProject = StubDeleteLearningProjectUseCase(results: [.success(())])
        let store = await loadedStore(deleteLearningProject: deleteLearningProject)
        store.exhaustivity = .off

        await store.send(.view(.deleteTapped))
        await store.send(.view(.deletionConfirmed))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.effect.deletionFinished)
        await store.receive(.delegate(.projectDeleted(projectID: ProjectDetailTestFixture.projectID)))

        #expect(await deleteLearningProject.callCount == 1)
    }

    @Test
    func `갱신 요청은 상세를 다시 조회해 서버 값을 그대로 반영한다`() async {
        let fetchLearningProjectDetail = StubFetchLearningProjectDetailUseCase(results: [
            .success(ProjectDetailTestFixture.mixedProgressDetail),
            .success(ProjectDetailTestFixture.completedDetail),
        ])
        let store = makeStore(fetchLearningProjectDetail: fetchLearningProjectDetail)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.detailLoadFinished)

        await store.send(.input(.refreshRequested))
        await store.receive(\.effect.detailLoadFinished)

        #expect(store.state.detail == ProjectDetailTestFixture.completedDetail)
        #expect(await fetchLearningProjectDetail.callCount == 2)
    }

    // MARK: Private

    private func loadedStore(
        detail: LearningProjectDetail = ProjectDetailTestFixture.mixedProgressDetail,
        deleteLearningProject: StubDeleteLearningProjectUseCase = StubDeleteLearningProjectUseCase(),
    ) async -> TestStoreOf<ProjectDetailFeature> {
        var state = ProjectDetailFeature.State(projectID: ProjectDetailTestFixture.projectID)
        state.detail = detail
        state.loadStatus = .loaded
        return makeStore(deleteLearningProject: deleteLearningProject, state: state)
    }

    private func makeStore(
        fetchLearningProjectDetail: StubFetchLearningProjectDetailUseCase = StubFetchLearningProjectDetailUseCase(
            results: [.success(ProjectDetailTestFixture.mixedProgressDetail)]
        ),
        deleteLearningProject: StubDeleteLearningProjectUseCase = StubDeleteLearningProjectUseCase(),
        state: ProjectDetailFeature.State = ProjectDetailFeature.State(
            projectID: ProjectDetailTestFixture.projectID
        ),
    ) -> TestStoreOf<ProjectDetailFeature> {
        TestStore(initialState: state) {
            ProjectDetailFeature(
                fetchLearningProjectDetail: fetchLearningProjectDetail,
                deleteLearningProject: deleteLearningProject,
            )
        }
    }

}
