import ComposableArchitecture
import DomainExternalRepository
import Testing

@testable import Feature

@MainActor
@Suite("RepositoryConfirmationFeature")
struct RepositoryConfirmationFeatureTests {

    // MARK: Internal

    @Test
    func `repositoryProvided 입력은 확인할 저장소를 저장한다`() async {
        let store = makeStore()

        await store.send(.input(.repositoryProvided(sampleRepository))) {
            $0.repository = sampleRepository
        }
    }

    @Test
    func `cleared 입력은 확인할 저장소를 비운다`() async {
        let store = makeStore(state: RepositoryConfirmationFeature.State(repository: sampleRepository))

        await store.send(.input(.cleared)) {
            $0.repository = nil
        }
    }

    @Test
    func `확인 탭은 confirmed를 위임한다`() async {
        let store = makeStore(state: RepositoryConfirmationFeature.State(repository: sampleRepository))

        await store.send(.view(.confirmTapped))
        await store.receive(.delegate(.confirmed))
    }

    @Test(arguments: [
        RepositoryConfirmationFeature.Action.View.rejectTapped,
        .backTapped,
    ])
    func `거부와 뒤로 가기는 rejected를 위임한다`(view: RepositoryConfirmationFeature.Action.View) async {
        let store = makeStore(state: RepositoryConfirmationFeature.State(repository: sampleRepository))

        await store.send(.view(view))
        await store.receive(.delegate(.rejected))
    }

    // MARK: Private

    private func makeStore(
        state: RepositoryConfirmationFeature.State = RepositoryConfirmationFeature.State()
    ) -> TestStoreOf<RepositoryConfirmationFeature> {
        TestStore(initialState: state) {
            RepositoryConfirmationFeature()
        }
    }

}
