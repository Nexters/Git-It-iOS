import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureValidationTests

@MainActor
@Suite("ShareRegistrationFeature 검증")
struct ShareRegistrationFeatureValidationTests {

    // MARK: Internal

    @Test
    func `공유 항목에 URL이 없으면 네트워크 호출 없이 오류 상태가 된다`() async {
        let store = Self.makeStore(sharedURL: nil)

        await store.send(.view(.task))
        await store.send(.view(.sharedURLResolved(nil))) {
            $0.status = .invalidURL(reason: "공유한 항목에서 링크를 찾지 못했어요.")
        }
    }

    @Test
    func `GitHub 저장소 경로가 아니면 조회하지 않고 오류 상태가 된다`() async {
        let store = Self.makeStore(location: nil)

        await store.send(.view(.task)) {
            $0.status = .invalidURL(reason: "GitHub 저장소 주소가 아니에요.")
        }
    }

    @Test
    func `세션 마커가 없으면 앱 실행 필요 상태가 된다`() async {
        let store = Self.makeStore(session: .appLaunchRequired)

        await store.send(.view(.task))
        await store.receive(\.effect.validationFinished) {
            $0.status = .appLaunchRequired
        }
    }

    @Test
    func `세션이 없으면 갱신 없이 로그인 필요 상태가 된다`() async {
        let store = Self.makeStore(session: .signInRequired)

        await store.send(.view(.task))
        await store.receive(\.effect.validationFinished) {
            $0.status = .signInRequired
        }
    }

    @Test
    func `조회가 인증 오류로 실패하면 로그인 필요 상태가 된다`() async {
        let store = Self.makeStore(lookupResult: .failure(LearningProjectError.unauthorized))

        await store.send(.view(.task))
        await store.receive(\.effect.validationFinished) {
            $0.status = .signInRequired
        }
    }

    @Test
    func `조회가 네트워크 오류로 실패하면 재시도 가능한 실패 상태가 된다`() async {
        let store = Self.makeStore(lookupResult: .failure(ExternalRepositoryError.offline))

        await store.send(.view(.task))
        await store.receive(\.effect.validationFinished) {
            $0.status = .failed(reason: "네트워크에 연결할 수 없어요.", retry: .lookup)
        }
    }

    @Test
    func `조회에 성공하면 저장소 정보와 함께 등록 가능 상태가 된다`() async {
        let store = Self.makeStore()

        await store.send(.view(.task))
        await store.receive(\.effect.repositoryResolved) {
            $0.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
            $0.status = .repositoryConfirmation
        }
    }

    // MARK: Private

    private static func makeStore(
        sharedURL: String? = ShareRegistrationTestSupport.sharedURL,
        location: ExternalRepositoryLocation? = ShareRegistrationTestSupport.location,
        session: ShareRegistrationSessionState = .available,
        lookupResult: Result<ExternalRepository, any Error> = .success(ShareRegistrationTestSupport.repository),
    ) -> TestStoreOf<ShareRegistrationFeature> {
        TestStore(initialState: ShareRegistrationFeature.State(sharedURL: sharedURL)) {
            ShareRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: location),
                fetchExternalRepository: StubFetchExternalRepository(result: lookupResult),
                createLearningProject: SpyCreateLearningProject(),
                resolveSession: { session },
            )
        }
    }

}
