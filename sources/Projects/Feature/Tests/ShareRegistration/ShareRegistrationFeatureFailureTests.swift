import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureFailureTests

@MainActor
@Suite("ShareRegistrationFeature 실패와 중단")
struct ShareRegistrationFeatureFailureTests {

    // MARK: Internal

    @Test
    func `등록 실패 사유를 표시하고 등록 단계 재시도를 제공한다`() async {
        let store = Self.makeStore(error: .temporarilyUnavailable)

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .failed(
                reason: "지금은 연결할 수 없어요. 잠시 후 다시 시도해 주세요.",
                retry: .registration,
            )
        }

        #expect(store.state.canRetry)
        #expect(store.state.canDismiss)
    }

    @Test
    func `재시도는 등록 단계부터 다시 수행한다`() async {
        let createLearningProject = SpyCreateLearningProject(error: .temporarilyUnavailable)
        let store = Self.makeStore(createLearningProject: createLearningProject)
        store.exhaustivity = .off

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested)))
        await store.skipReceivedActions()
        await store.send(.view(.retryTapped))
        await store.skipReceivedActions()

        #expect(createLearningProject.callCount == 2)
    }

    @Test
    func `요청 중에는 닫기 동작을 받지 않는다`() async {
        let store = Self.makeStore()
        store.exhaustivity = .off

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.send(.view(.dismissTapped))
        await store.skipReceivedActions()

        #expect(store.state.isBusy == false || store.state.status == .succeeded)
    }

    @Test
    func `등록 가능 상태에서 닫으면 진행 중 작업을 취소하고 종료를 요청한다`() async {
        let store = Self.makeStore()

        await store.send(.view(.dismissTapped))
        await store.receive(\.delegate.dismissRequested)
        await store.finish()
    }

    // MARK: Private

    private static func makeStore(
        error: LearningProjectError? = nil,
        createLearningProject: SpyCreateLearningProject? = nil,
    ) -> TestStoreOf<ShareRegistrationFeature> {
        var state = ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
        state.status = .quizGenerationConfirmation
        return TestStore(initialState: state) {
            ShareRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: ShareRegistrationTestSupport.location),
                fetchExternalRepository: StubFetchExternalRepository(
                    result: .success(ShareRegistrationTestSupport.repository)
                ),
                createLearningProject: createLearningProject ?? SpyCreateLearningProject(error: error),
                resolveSession: { .available },
            )
        }
    }

}
