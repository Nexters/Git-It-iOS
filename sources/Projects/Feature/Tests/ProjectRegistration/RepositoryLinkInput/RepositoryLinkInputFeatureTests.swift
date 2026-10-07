import ComposableArchitecture
import DomainExternalRepository
import Testing

@testable import Feature

// MARK: - RepositoryLinkInputFeatureTests

@MainActor
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
        let externalRepository = ExternalRepositoryUseCaseStub(results: [.success(sampleRepository)])
        let store = makeRepositoryLinkInputStore(externalRepository: externalRepository)

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

        #expect(await externalRepository.snapshot().callCount == 1)
    }

    @Test
    func `validateTapped 실패는 validation을 failed로 전이한다`() async {
        let externalRepository = ExternalRepositoryUseCaseStub(results: [.failure(.invalidURLFormat)])
        let store = makeRepositoryLinkInputStore(externalRepository: externalRepository)

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
        let externalRepository = ExternalRepositoryUseCaseStub()
        let store = makeRepositoryLinkInputStore(externalRepository: externalRepository)

        await store.send(.view(.validateTapped))

        #expect(await externalRepository.snapshot().callCount == 0)
    }

    @Test
    func `늦게 도착한 validationRequestID 불일치 응답은 최신 상태를 덮어쓰지 않는다`() async {
        let externalRepository = ExternalRepositoryUseCaseStub(suspendsRequests: true)
        let store = makeRepositoryLinkInputStore(externalRepository: externalRepository)

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

        await externalRepository.resumeOldest()
        await externalRepository.resumeOldest()
        await store.skipReceivedActions(strict: false)
        await store.finish()
    }

    @Test
    func `dismissTapped는 dismissRequested를 위임한다`() async {
        let store = makeRepositoryLinkInputStore()

        await store.send(.view(.dismissTapped))
        await store.receive(.delegate(.dismissRequested))
    }

    @Test
    func `State가 폐기되면 진행 중이던 검증 Effect가 취소되고 이후 이벤트를 받지 않는다`() async {
        let externalRepository = ExternalRepositoryUseCaseStub(suspendsRequests: true)
        var childState = RepositoryLinkInputFeature.State()
        childState.repositoryURLInput = "https://github.com/owner/repo"
        let store = TestStore(initialState: RepositoryLinkInputHostFeature.State(child: childState)) {
            RepositoryLinkInputHostFeature(externalRepository: externalRepository)
        }

        await store.send(.child(.presented(.view(.validateTapped)))) {
            $0.child?.validation = .validating
            $0.child?.validationRequestID = 1
        }
        await store.send(.child(.dismiss)) {
            $0.child = nil
        }
        await externalRepository.resumeOldest()

        await store.finish()
    }

}

// MARK: - RepositoryLinkInputHostFeature

@Reducer
private struct RepositoryLinkInputHostFeature {

    @ObservableState
    struct State: Equatable {
        @Presents var child: RepositoryLinkInputFeature.State?
    }

    enum Action {
        case child(PresentationAction<RepositoryLinkInputFeature.Action>)
    }

    let externalRepository: ExternalRepositoryUseCaseStub

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
            .ifLet(\.$child, action: \.child) {
                RepositoryLinkInputFeature(repository: { [externalRepository] in
                    try await externalRepository.repository(at: $0)
                })
            }
    }

}
