import ComposableArchitecture
import DomainExternalRepository
import DomainProjectGeneration
import Foundation
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureFailureTests

@MainActor
@Suite("ShareRegistrationFeature 실패와 중단")
struct ShareRegistrationFeatureFailureTests {

    // MARK: Internal

    @Test
    func `등록이 실패하면 재시도와 닫기를 모두 허용한다`() {
        var state = Self.readyState()
        state.registration.phase = .failed(
            reason: "지금은 연결할 수 없어요. 잠시 후 다시 시도해 주세요.",
            retry: .registration,
        )
        let store = Self.makeStore(state: state)

        #expect(store.state.canRetry)
        #expect(store.state.canDismiss)
    }

    @Test
    func `요청 중에는 닫기 동작을 받지 않는다`() async {
        var state = Self.readyState()
        state.registration.phase = .submitting
        let store = Self.makeStore(state: state)

        #expect(store.state.isBusy)
        #expect(!store.state.canDismiss)
        await store.send(.view(.dismissTapped))
    }

    @Test
    func `등록 가능 상태에서 닫으면 진행 중 작업을 취소하고 종료를 요청한다`() async {
        let store = Self.makeStore()

        await store.send(.view(.dismissTapped))
        await store.receive(.registration(.input(.cancel)))
        await store.receive(\.delegate.dismissRequested)
        await store.finish()
    }

    // MARK: Private

    private static func readyState() -> ShareRegistrationFeature.State {
        var state = ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.registration.phase = .ready(ShareRegistrationTestSupport.repository)
        state.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
        state.step = .quizGenerationConfirmation
        return state
    }

    private static func makeStore(
        state: ShareRegistrationFeature.State? = nil
    ) -> TestStoreOf<ShareRegistrationFeature> {
        TestStore(initialState: state ?? readyState()) {
            ShareRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: ShareRegistrationTestSupport.location),
                externalRepository: ExternalRepositoryUseCaseFixedResultStub(
                    result: .success(ShareRegistrationTestSupport.repository)
                ),
                projectGeneration: ProjectGenerationUseCaseSpy(),
                signInAvailability: { .signedIn },
            )
        }
    }

}
