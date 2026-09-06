import ComposableArchitecture
import DomainLearningProject
import Foundation
import Synchronization
import Testing

@testable import Feature

// MARK: - ShareRegistrationDiagnosticsTests

@MainActor
@Suite("ShareRegistration 진단 이벤트")
struct ShareRegistrationDiagnosticsTests {

    // MARK: Internal

    @Test
    func `링크 판정 실패를 진단 이벤트로 남긴다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(location: nil, recorder: recorder)

        await store.send(.view(.task)) {
            $0.status = .invalidURL(reason: "GitHub 저장소 주소가 아니에요.")
        }

        #expect(recorder.events == [.repositoryLinkRejected])
    }

    @Test
    func `공유 항목이 없으면 별도의 진단 이벤트를 남긴다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(sharedURL: nil, recorder: recorder)

        await store.send(.view(.task))
        await store.send(.view(.sharedURLResolved(nil))) {
            $0.status = .invalidURL(reason: "공유한 항목에서 링크를 찾지 못했어요.")
        }

        #expect(recorder.events == [.sharedItemUnavailable])
    }

    @Test
    func `세션 판정 결과를 토큰 없이 남긴다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(session: .appLaunchRequired, recorder: recorder)

        await store.send(.view(.task))
        await store.receive(\.effect.validationFinished) {
            $0.status = .appLaunchRequired
        }

        #expect(recorder.events == [.sessionResolved(.appLaunchRequired)])
    }

    @Test
    func `저장소 조회 실패와 등록 실패를 서로 다른 이벤트로 구분한다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(
            lookupResult: .failure(ExternalRepositoryError.offline),
            recorder: recorder,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.skipReceivedActions()

        #expect(recorder.events.contains(.sessionResolved(.available)))
        #expect(recorder.events.contains { event in
            if case .repositoryLookupFailed = event {
                return true
            }
            return false
        })
        #expect(recorder.events.contains { event in
            if case .registrationFailed = event {
                return true
            }
            return false
        } == false)
    }

    @Test
    func `진단 이벤트 값에 토큰이나 원본 URL 전체를 담지 않는다`() async {
        let recorder = Recorder()
        let store = Self.makeStore(recorder: recorder)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.skipReceivedActions()

        let described = recorder.events.map { String(describing: $0) }.joined()
        #expect(described.contains(ShareRegistrationTestSupport.sharedURL) == false)
        #expect(described.contains("token") == false)
    }

    // MARK: Private

    private final class Recorder: Sendable {

        // MARK: Internal

        var events: [ShareRegistrationDiagnosticEvent] {
            storage.withLock { $0 }
        }

        func record(_ event: ShareRegistrationDiagnosticEvent) {
            storage.withLock { $0.append(event) }
        }

        // MARK: Private

        private let storage = Mutex([ShareRegistrationDiagnosticEvent]())

    }

    private static func makeStore(
        sharedURL: String? = ShareRegistrationTestSupport.sharedURL,
        location: ExternalRepositoryLocation? = ShareRegistrationTestSupport.location,
        session: ShareRegistrationSessionState = .available,
        lookupResult: Result<ExternalRepository, any Error> = .success(ShareRegistrationTestSupport.repository),
        recorder: Recorder,
    ) -> TestStoreOf<ShareRegistrationFeature> {
        TestStore(initialState: ShareRegistrationFeature.State(sharedURL: sharedURL)) {
            ShareRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: location),
                fetchExternalRepository: StubFetchExternalRepository(result: lookupResult),
                createLearningProject: SpyCreateLearningProject(),
                resolveSession: { session },
                recordDiagnostic: { recorder.record($0) },
            )
        }
    }

}
