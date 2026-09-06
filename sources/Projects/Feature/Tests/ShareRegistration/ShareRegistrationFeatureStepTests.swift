import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureStepTests

@MainActor
@Suite("ShareRegistrationFeature 등록 단계 이동")
struct ShareRegistrationFeatureStepTests {

    // MARK: Internal

    @Test
    func `저장소 확인 뒤 난이도와 생성 확인 순서로 이동한다`() async {
        let store = Self.makeStore()

        await store.send(.repositoryConfirmation(.view(.confirmTapped)))
        await store.receive(\.repositoryConfirmation.delegate.confirmed) {
            $0.status = .quizLevelSelection
        }

        await store.send(.quizLevelSelection(.view(.nextTapped)))
        await store.receive(\.quizLevelSelection.delegate.confirmed) {
            $0.status = .quizGenerationConfirmation
        }
    }

    @Test
    func `뒤로 가기는 직전 단계로 되돌린다`() async {
        var state = ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
        state.status = .quizGenerationConfirmation
        let store = Self.makeStore(state: state)

        await store.send(.quizGenerationConfirmation(.view(.backTapped)))
        await store.receive(\.quizGenerationConfirmation.delegate.backRequested) {
            $0.status = .quizLevelSelection
        }

        await store.send(.quizLevelSelection(.view(.backTapped)))
        await store.receive(\.quizLevelSelection.delegate.backRequested) {
            $0.status = .repositoryConfirmation
        }
    }

    @Test
    func `이 레포지토리가 아니라고 답하면 입력 화면 대신 종료를 요청한다`() async {
        let store = Self.makeStore()
        store.exhaustivity = .off

        await store.send(.repositoryConfirmation(.view(.rejectTapped)))
        await store.receive(\.repositoryConfirmation.delegate.rejected)
        await store.receive(\.delegate.dismissRequested)

        await store.finish()
    }

    // MARK: Private

    private static func makeStore(
        state: ShareRegistrationFeature.State? = nil
    ) -> TestStoreOf<ShareRegistrationFeature> {
        var initialState = state ?? {
            var value = ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
            value.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
            value.status = .repositoryConfirmation
            return value
        }()
        initialState.sharedURL = ShareRegistrationTestSupport.sharedURL
        return TestStore(initialState: initialState) {
            ShareRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: ShareRegistrationTestSupport.location),
                fetchExternalRepository: StubFetchExternalRepository(
                    result: .success(ShareRegistrationTestSupport.repository)
                ),
                createLearningProject: SpyCreateLearningProject(),
                resolveSession: { .available },
            )
        }
    }

}
