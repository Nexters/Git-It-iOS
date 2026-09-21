import ComposableArchitecture
import DomainProject
import Testing

@testable import Feature

@MainActor
@Suite("ProjectDeletionFeature 프로젝트 삭제")
struct ProjectDeletionFeatureTests {

    // MARK: Internal

    @Test(arguments: [
        ProjectDeletionFeature.State.Deletion.idle,
        .failed(projectID: "project-0", error: .temporarilyUnavailable),
    ])
    func `대기나 실패 상태의 request는 삭제 확인 상태가 된다`(deletion: ProjectDeletionFeature.State.Deletion) async {
        let store = makeStore(state: ProjectDeletionFeature.State(deletion: deletion))

        await store.send(.input(.request("project-1"))) {
            $0.deletion = .confirming(projectID: "project-1")
        }
    }

    @Test(arguments: [
        ProjectDeletionFeature.State.Deletion.confirming(projectID: "project-0"),
        .committing(projectID: "project-0"),
    ])
    func `확인 중이거나 삭제 중이면 request를 무시한다`(deletion: ProjectDeletionFeature.State.Deletion) async {
        let store = makeStore(state: ProjectDeletionFeature.State(deletion: deletion))

        await store.send(.input(.request("project-1")))
    }

    @Test(arguments: [
        ProjectDeletionFeature.State.Deletion.confirming(projectID: "project-0"),
        .failed(projectID: "project-0", error: .temporarilyUnavailable),
    ])
    func `확인 중이거나 실패 상태의 cancel은 대기 상태로 돌린다`(deletion: ProjectDeletionFeature.State.Deletion) async {
        let store = makeStore(state: ProjectDeletionFeature.State(deletion: deletion))

        await store.send(.input(.cancel)) {
            $0.deletion = .idle
        }
    }

    @Test
    func `삭제 중의 cancel은 무시한다`() async {
        let store = makeStore(state: ProjectDeletionFeature.State(deletion: .committing(projectID: "project-0")))

        await store.send(.input(.cancel))
    }

    @Test
    func `확인 전에는 confirm이 삭제를 요청하지 않는다`() async {
        let deleteProject = ProjectUseCaseDeletionStub()
        let store = makeStore(deleteProject: deleteProject)

        await store.send(.input(.confirm))

        #expect(await deleteProject.callCount == 0)
    }

    @Test
    func `삭제 성공은 대기 상태로 돌리고 deleted를 보낸다`() async {
        let deleteProject = ProjectUseCaseDeletionStub()
        let store = makeStore(
            deleteProject: deleteProject,
            state: ProjectDeletionFeature.State(deletion: .confirming(projectID: "project-0")),
        )

        await store.send(.input(.confirm)) {
            $0.deletion = .committing(projectID: "project-0")
        }
        await store.receive(.effect(.deletionFinished(projectID: "project-0", error: nil))) {
            $0.deletion = .idle
        }
        await store.receive(.delegate(.deleted(projectID: "project-0")))

        #expect(await deleteProject.callCount == 1)
    }

    @Test
    func `이미 사라진 프로젝트의 삭제는 성공으로 보고 deleted를 보낸다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.notFound)]),
            state: ProjectDeletionFeature.State(deletion: .confirming(projectID: "project-0")),
        )

        await store.send(.input(.confirm)) {
            $0.deletion = .committing(projectID: "project-0")
        }
        await store.receive(.effect(.deletionFinished(projectID: "project-0", error: .notFound))) {
            $0.deletion = .idle
        }
        await store.receive(.delegate(.deleted(projectID: "project-0")))
    }

    @Test
    func `그 밖의 삭제 오류는 실패 상태로 남긴다`() async {
        let store = makeStore(
            deleteProject: ProjectUseCaseDeletionStub(results: [.failure(.temporarilyUnavailable)]),
            state: ProjectDeletionFeature.State(deletion: .confirming(projectID: "project-0")),
        )

        await store.send(.input(.confirm)) {
            $0.deletion = .committing(projectID: "project-0")
        }
        await store.receive(.effect(.deletionFinished(projectID: "project-0", error: .temporarilyUnavailable))) {
            $0.deletion = .failed(projectID: "project-0", error: .temporarilyUnavailable)
        }
    }

    @Test
    func `삭제 중에는 confirm을 다시 받지 않는다`() async {
        let deleteProject = ProjectUseCaseDeletionStub()
        let store = makeStore(
            deleteProject: deleteProject,
            state: ProjectDeletionFeature.State(deletion: .committing(projectID: "project-0")),
        )

        await store.send(.input(.confirm))

        #expect(await deleteProject.callCount == 0)
    }

    // MARK: Private

    private func makeStore(
        deleteProject: ProjectUseCaseDeletionStub = ProjectUseCaseDeletionStub(),
        state: ProjectDeletionFeature.State = ProjectDeletionFeature.State(),
    ) -> TestStoreOf<ProjectDeletionFeature> {
        TestStore(initialState: state) {
            ProjectDeletionFeature(deleteProject: deleteProject.deleteProject)
        }
    }

}
