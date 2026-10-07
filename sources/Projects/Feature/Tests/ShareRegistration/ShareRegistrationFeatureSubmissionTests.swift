import ComposableArchitecture
import DomainLearningProject
import Foundation
import Synchronization
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureSubmissionTests

@MainActor
@Suite("ShareRegistrationFeature 등록")
struct ShareRegistrationFeatureSubmissionTests {

    // MARK: Internal

    @Test
    func `기본 난이도로도 등록할 수 있고 선택한 난이도가 요청에 쓰인다`() async {
        let createLearningProject = SpyCreateLearningProject()
        let store = Self.makeStore(createLearningProject: createLearningProject)

        #expect(store.state.quizLevel == .l1)
        await store.send(.quizLevelSelection(.view(.levelSelected(.l3)))) {
            $0.quizLevelSelection.quizLevel = .l3
        }
        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .succeeded
        }

        #expect(createLearningProject.lastQuizLevel == .l3)
        #expect(createLearningProject.callCount == 1)
    }

    @Test
    func `요청 중에는 추가 등록 실행을 받지 않는다`() async {
        let createLearningProject = SpyCreateLearningProject(suspendsUntilResumed: true)
        let store = Self.makeStore(createLearningProject: createLearningProject)

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested)))

        #expect(createLearningProject.callCount == 1)

        createLearningProject.resume()
        await store.receive(\.effect.registrationFinished) {
            $0.status = .succeeded
        }
    }

    @Test
    func `등록 응답이 인증 오류면 갱신 없이 로그인 필요 상태가 된다`() async {
        let store = Self.makeStore(
            createLearningProject: SpyCreateLearningProject(error: .unauthorized)
        )

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .signInRequired
        }
    }

    @Test
    func `알림 권한이 허용되어 있으면 리마인더 대기 목록에 남긴다`() async {
        let enqueued = Mutex([String]())
        let store = Self.makeStore(
            isNotificationAuthorized: true,
            enqueueGenerationReminder: { projectID in
                enqueued.withLock { $0.append(projectID) }
            },
        )

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .succeeded
        }
        await store.finish()

        #expect(enqueued.withLock { $0 } == ["project-1"])
    }

    @Test
    func `알림 권한이 없으면 권한을 요청하지 않고 대기 목록에도 남기지 않는다`() async {
        let enqueued = Mutex([String]())
        let store = Self.makeStore(
            isNotificationAuthorized: false,
            enqueueGenerationReminder: { projectID in
                enqueued.withLock { $0.append(projectID) }
            },
        )

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .succeeded
        }
        await store.finish()

        #expect(enqueued.withLock { $0 }.isEmpty)
    }

    @Test
    func `대기 목록 기록이 실패해도 성공 상태를 유지한다`() async {
        let store = Self.makeStore(
            isNotificationAuthorized: true,
            enqueueGenerationReminder: { _ in
            },
        )

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .succeeded
        }
        await store.finish()

        #expect(store.state.status == .succeeded)
    }

    // MARK: Private

    private static func makeStore(
        createLearningProject: SpyCreateLearningProject = SpyCreateLearningProject(),
        isNotificationAuthorized: Bool = false,
        enqueueGenerationReminder: @escaping @Sendable (String) async -> Void = { _ in },
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
                createLearningProject: createLearningProject,
                resolveSession: { .available },
                isNotificationAuthorized: { isNotificationAuthorized },
                enqueueGenerationReminder: enqueueGenerationReminder,
            )
        }
    }

}
