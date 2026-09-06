import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("RepositoryLinkInputFeature")
struct RepositoryLinkInputFeatureTests {

    @Test
    func `repositoryURLChanged는 validation을 idle로 되돌린다`() async {
        var state = RepositoryLinkInputFeature.State()
        state.validation = .validated(sampleRepository)
        let store = makeRepositoryLinkInputStore(state: state)

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
            $0.validation = .idle
        }
    }

    @Test
    func `validateTapped 성공은 validation을 validated로 전이하고 repositoryValidated를 위임한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.success(sampleRepository)])
        let store = makeRepositoryLinkInputStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
        }
        await store.send(.view(.validateTapped)) {
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .success(sampleRepository)))) {
            $0.validation = .validated(sampleRepository)
        }
        await store.receive(.delegate(.repositoryValidated(sampleRepository)))

        #expect(await fetchExternalRepository.snapshot().callCount == 1)
    }

    @Test
    func `validateTapped 실패는 validation을 failed로 전이한다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(results: [.failure(.invalidURLFormat)])
        let store = makeRepositoryLinkInputStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
        }
        await store.send(.view(.validateTapped)) {
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.receive(.effect(.validationFinished(requestID: 1, result: .failure(.invalidURLFormat)))) {
            $0.validation = .failed
        }
        #expect(store.state.isValidationFailed)
    }

    @Test
    func `빈 URL에서 validateTapped는 아무 효과도 내지 않는다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase()
        let store = makeRepositoryLinkInputStore(fetchExternalRepository: fetchExternalRepository)

        await store.send(.view(.validateTapped))

        #expect(await fetchExternalRepository.snapshot().callCount == 0)
    }

    @Test
    func `늦게 도착한 validationRequestID 불일치 응답은 최신 상태를 덮어쓰지 않는다`() async {
        let store = makeRepositoryLinkInputStore()

        await store.send(.view(.repositoryURLChanged("https://github.com/owner/repo"))) {
            $0.repositoryURLInput = "https://github.com/owner/repo"
        }
        await store.send(.view(.validateTapped)) {
            $0.validation = .validating
            $0.validationRequestID = 1
        }
        await store.send(.view(.validateTapped)) {
            $0.validationRequestID = 2
        }
        await store.send(.effect(.validationFinished(requestID: 1, result: .success(sampleRepository))))

        #expect(store.state.validation == .validating)
    }

    @Test
    func `dismissTapped는 dismissRequested를 위임한다`() async {
        let store = makeRepositoryLinkInputStore()

        await store.send(.view(.dismissTapped))
        await store.receive(.delegate(.dismissRequested))
    }

    @Test
    func `State가 폐기되면 진행 중이던 검증 Effect가 취소되고 이후 이벤트를 받지 않는다`() async {
        let fetchExternalRepository = StubFetchExternalRepositoryUseCase(suspendsRequests: true)
        var childState = RepositoryLinkInputFeature.State()
        childState.repositoryURLInput = "https://github.com/owner/repo"
        let store = TestStore(initialState: RepositoryLinkInputHostFeature.State(child: childState)) {
            RepositoryLinkInputHostFeature(fetchExternalRepository: fetchExternalRepository)
        }

        await store.send(.child(.presented(.view(.validateTapped)))) {
            $0.child?.validation = .validating
            $0.child?.validationRequestID = 1
        }
        await store.send(.child(.dismiss)) {
            $0.child = nil
        }
        await fetchExternalRepository.resumeOldest()

        await store.finish()
    }

}

@Reducer
private struct RepositoryLinkInputHostFeature {

    @ObservableState
    struct State: Equatable {
        @Presents var child: RepositoryLinkInputFeature.State?
    }

    enum Action {
        case child(PresentationAction<RepositoryLinkInputFeature.Action>)
    }

    let fetchExternalRepository: any FetchExternalRepositoryUseCase

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
            .ifLet(\.$child, action: \.child) {
                RepositoryLinkInputFeature(fetchExternalRepository: fetchExternalRepository)
            }
    }

}
