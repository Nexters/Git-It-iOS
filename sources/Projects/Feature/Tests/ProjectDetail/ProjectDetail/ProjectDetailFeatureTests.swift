import ComposableArchitecture
import DomainProject
import Foundation
import Testing

@testable import Feature

@MainActor
@Suite("ProjectDetailFeature 상세 표시와 메뉴")
struct ProjectDetailFeatureTests {

    // MARK: Internal

    @Test
    func `진입하면 상세를 조회하고 세트 진행 표시를 서버 값 그대로 파생한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.detailLoad.effect.detailLoadFinished)

        let displays = ProjectDetailSetDisplay.list(sets: store.state.detailLoad.detail?.sets ?? [])
        #expect(displays.map(\.label) == ["CHAPTER 1", "CHAPTER 2", "CHAPTER 3"])
        #expect(displays.map(\.completedCount) == [5, 2, 0])
        #expect(displays.map(\.questionCount) == [5, 4, 3])
    }

    @Test(arguments: [
        ProjectDetailFeature.Action.view(.task),
        .view(.retryTapped),
        .input(.refreshRequested),
    ])
    func `진입·재시도·갱신 요청은 상세 조회에 load를 보낸다`(action: ProjectDetailFeature.Action) async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(action)
        await store.receive(.detailLoad(.input(.load)))
        await store.receive(\.detailLoad.effect.detailLoadFinished)
    }

    @Test
    func `세트 시작은 라벨만 담은 진입 의도를 만든다`() async {
        let store = loadedStore()

        await store.send(.view(.setStartTapped(setID: "set-1")))
        await store.receive(.delegate(.setStartRequested(
            projectID: ProjectDetailTestFixture.projectID,
            setID: "set-1",
            label: "CHAPTER 2",
        )))
    }

    @Test
    func `저장소 시작 컨트롤은 첫 미완료 세트로 같은 의도를 만든다`() async {
        let store = loadedStore()

        #expect(store.state.detailLoad.isResumeEnabled)

        await store.send(.view(.resumeTapped))
        await store.receive(.delegate(.setStartRequested(
            projectID: ProjectDetailTestFixture.projectID,
            setID: "set-1",
            label: "CHAPTER 2",
        )))
    }

    @Test
    func `미완료 세트가 없으면 시작 컨트롤이 비활성이고 입력이 아무 일도 하지 않는다`() async {
        let store = loadedStore(detail: ProjectDetailTestFixture.completedDetail)

        #expect(!store.state.detailLoad.isResumeEnabled)

        await store.send(.view(.resumeTapped))
    }

    @Test
    func `메뉴를 펼치고 저장한 문제를 고르면 메뉴를 닫고 진입 의도를 만든다`() async {
        let store = loadedStore()

        await store.send(.view(.menuTapped)) { $0.isMenuPresented = true }
        await store.send(.view(.savedQuestionsTapped)) { $0.isMenuPresented = false }
        await store.receive(
            .delegate(.savedQuestionsRequested(projectID: ProjectDetailTestFixture.projectID))
        )
    }

    @Test
    func `저장소 링크는 상세의 URL을 그대로 외부 URL 요청으로 올린다`() async throws {
        let store = loadedStore()
        let url = try #require(URL(string: ProjectDetailTestFixture.repositoryURL))

        await store.send(.view(.menuTapped)) { $0.isMenuPresented = true }
        await store.send(.view(.repositoryLinkTapped)) { $0.isMenuPresented = false }
        await store.receive(.delegate(.externalURLRequested(url)))
    }

    @Test
    func `삭제는 메뉴를 닫고 삭제에 request를 보내며 취소하면 아무 것도 삭제하지 않는다`() async {
        let deleteProject = ProjectUseCaseDeletionStub()
        let store = loadedStore(deleteProject: deleteProject)

        await store.send(.view(.menuTapped)) { $0.isMenuPresented = true }
        await store.send(.view(.deleteTapped)) { $0.isMenuPresented = false }
        await store.receive(.deletion(.input(.request(ProjectDetailTestFixture.projectID)))) {
            $0.deletion.deletion = .confirming(projectID: ProjectDetailTestFixture.projectID)
        }
        await store.send(.view(.deletionCancelled))
        await store.receive(.deletion(.input(.cancel))) { $0.deletion.deletion = .idle }

        #expect(await deleteProject.callCount == 0)
    }

    @Test
    func `삭제 중에는 재입력을 무시하고 성공하면 삭제 완료를 알린다`() async {
        let deleteProject = ProjectUseCaseDeletionStub(results: [.success(())], suspendsRequests: true)
        let store = loadedStore(deleteProject: deleteProject)
        store.exhaustivity = .off

        await store.send(.view(.deleteTapped))
        await store.send(.view(.deletionConfirmed))
        await store.send(.view(.deletionConfirmed))
        await deleteProject.resumeOldest()
        await store.receive(\.deletion.effect.deletionFinished)
        await store.receive(.delegate(.projectDeleted(projectID: ProjectDetailTestFixture.projectID)))

        #expect(await deleteProject.callCount == 1)
    }

    @Test
    func `삭제에 실패하면 오류를 남기고 삭제 완료를 알리지 않는다`() async {
        let store = loadedStore(
            deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.temporarilyUnavailable)])
        )
        store.exhaustivity = .off

        await store.send(.view(.deleteTapped))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.deletion.effect.deletionFinished)

        #expect(
            store.state.deletion.deletion
                == .failed(projectID: ProjectDetailTestFixture.projectID, error: .temporarilyUnavailable)
        )
    }

    @Test
    func `이미 사라진 프로젝트를 삭제하면 삭제 완료를 알린다`() async {
        let store = loadedStore(deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.notFound)]))
        store.exhaustivity = .off

        await store.send(.view(.deleteTapped))
        await store.send(.view(.deletionConfirmed))
        await store.receive(\.deletion.effect.deletionFinished)
        await store.receive(.delegate(.projectDeleted(projectID: ProjectDetailTestFixture.projectID)))

        #expect(store.state.deletion.deletion == .idle)
    }

    @Test
    func `갱신 요청은 상세를 다시 조회해 서버 값을 그대로 반영한다`() async {
        let projectDetail = ProjectUseCaseDetailStub(results: [
            .success(ProjectDetailTestFixture.mixedProgressDetail),
            .success(ProjectDetailTestFixture.completedDetail),
        ])
        let store = makeStore(projectDetail: projectDetail)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.detailLoad.effect.detailLoadFinished)

        await store.send(.input(.refreshRequested))
        await store.receive(\.detailLoad.effect.detailLoadFinished)

        #expect(store.state.detailLoad.detail == ProjectDetailTestFixture.completedDetail)
        #expect(await projectDetail.callCount == 2)
    }

    @Test
    func `조회에 실패하면 오류 의미를 보존한다`() async {
        let store = makeStore(
            projectDetail: ProjectUseCaseDetailStub(results: [.failure(.temporarilyUnavailable)])
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.detailLoad.effect.detailLoadFinished)

        #expect(store.state.detailLoad.loadStatus == .failed(.temporarilyUnavailable))
    }

    // MARK: Private

    private func loadedStore(
        detail: ProjectDetail = ProjectDetailTestFixture.mixedProgressDetail,
        deleteProject: ProjectUseCaseDeletionStub = ProjectUseCaseDeletionStub(),
    ) -> TestStoreOf<ProjectDetailFeature> {
        var state = ProjectDetailFeature.State(projectID: ProjectDetailTestFixture.projectID)
        state.detailLoad.detail = detail
        state.detailLoad.loadStatus = .loaded
        return makeStore(deleteProject: deleteProject, state: state)
    }

    private func makeStore(
        projectDetail: ProjectUseCaseDetailStub = ProjectUseCaseDetailStub(
            results: [.success(ProjectDetailTestFixture.mixedProgressDetail)]
        ),
        deleteProject: ProjectUseCaseDeletionStub = ProjectUseCaseDeletionStub(),
        state: ProjectDetailFeature.State = ProjectDetailFeature.State(
            projectID: ProjectDetailTestFixture.projectID
        ),
    ) -> TestStoreOf<ProjectDetailFeature> {
        TestStore(initialState: state) {
            ProjectDetailFeature(
                projectDetail: projectDetail.projectDetail,
                deleteProject: deleteProject.deleteProject,
            )
        }
    }

}
