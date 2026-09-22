import ComposableArchitecture
import DomainExternalRepository
import Foundation
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureStepTests

@MainActor
@Suite("ShareRegistrationFeature 등록 단계 이동")
struct ShareRegistrationFeatureStepTests {

    // MARK: Internal

    @Test
    func `화면 진입은 공유 링크로 등록 검증을 시작한다`() async {
        let store = Self.makeStore(state: ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(.registration(.input(.validate(sharedURL: ShareRegistrationTestSupport.sharedURL))))
    }

    @Test
    func `공유 링크가 아직 없으면 화면 진입만으로 검증하지 않는다`() async {
        let store = Self.makeStore(state: ShareRegistrationFeature.State())

        await store.send(.view(.task))
    }

    @Test
    func `공유 링크를 받으면 그 링크로 등록 검증을 시작한다`() async {
        let store = Self.makeStore(state: ShareRegistrationFeature.State())

        await store.send(.view(.sharedURLResolved(nil)))
        await store.receive(.registration(.input(.validate(sharedURL: nil)))) {
            $0.registration.phase = .invalidURL(reason: "공유한 항목에서 링크를 찾지 못했어요.")
        }
    }

    @Test
    func `저장소를 확인하면 저장소 확인 단계로 두고 확인할 저장소를 넘긴다`() async {
        let store = Self.makeStore(state: ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL))
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(.registration(.delegate(.repositoryResolved(ShareRegistrationTestSupport.repository))))
        await store.receive(.repositoryConfirmation(.input(.repositoryProvided(ShareRegistrationTestSupport.repository))))

        #expect(store.state.step == .repositoryConfirmation)
        #expect(store.state.registration.phase == .ready(ShareRegistrationTestSupport.repository))
        #expect(store.state.repository == ShareRegistrationTestSupport.repository)
    }

    @Test
    func `저장소 확인 뒤 난이도와 생성 확인 순서로 이동한다`() async {
        let store = Self.makeStore()

        await store.send(.repositoryConfirmation(.view(.confirmTapped)))
        await store.receive(\.repositoryConfirmation.delegate.confirmed) {
            $0.step = .quizLevelSelection
        }

        await store.send(.quizLevelSelection(.view(.nextTapped)))
        await store.receive(\.quizLevelSelection.delegate.confirmed) {
            $0.step = .quizGenerationConfirmation
        }
    }

    @Test
    func `뒤로 가기는 직전 단계로 되돌린다`() async {
        var state = Self.readyState()
        state.step = .quizGenerationConfirmation
        let store = Self.makeStore(state: state)

        await store.send(.quizGenerationConfirmation(.view(.backTapped)))
        await store.receive(\.quizGenerationConfirmation.delegate.backRequested) {
            $0.step = .quizLevelSelection
        }

        await store.send(.quizLevelSelection(.view(.backTapped)))
        await store.receive(\.quizLevelSelection.delegate.backRequested) {
            $0.step = .repositoryConfirmation
        }
    }

    @Test
    func `생성 요청은 확인한 저장소와 선택한 난이도로 등록에 submit을 보낸다`() async {
        var state = Self.readyState()
        state.step = .quizGenerationConfirmation
        state.quizLevelSelection.quizLevel = .l3
        let store = Self.makeStore(state: state)
        store.exhaustivity = .off

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested)))
        await store.receive(.registration(.input(.submit(
            repository: ShareRegistrationTestSupport.repository,
            quizLevel: .l3,
        ))))
        await store.finish()
    }

    @Test
    func `재시도 탭은 등록에 retry를 보낸다`() async {
        let store = Self.makeStore()

        await store.send(.view(.retryTapped))
        await store.receive(.registration(.input(.retry)))
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

    private static func readyState() -> ShareRegistrationFeature.State {
        var state = ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.registration.phase = .ready(ShareRegistrationTestSupport.repository)
        state.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
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
