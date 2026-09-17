import ComposableArchitecture
import DomainAccount
import DomainExternalRepository
import DomainProjectGeneration
import Foundation
import Testing

@testable import Feature

// MARK: - ShareRegistrationFeatureSubmissionTests

@MainActor
@Suite("ShareRegistrationFeature 등록")
struct ShareRegistrationFeatureSubmissionTests {

    // MARK: Internal

    @Test
    func `기본 난이도로도 등록할 수 있고 선택한 난이도가 요청에 쓰인다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(projectGeneration: projectGeneration)

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

        #expect(projectGeneration.lastQuizLevel == .l3)
        #expect(projectGeneration.callCount == 1)
    }

    @Test
    func `요청 중에는 추가 등록 실행을 받지 않는다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy(suspendsUntilResumed: true)
        let store = Self.makeStore(projectGeneration: projectGeneration)

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested)))

        #expect(projectGeneration.callCount == 1)

        projectGeneration.resume()
        await store.receive(\.effect.registrationFinished) {
            $0.status = .succeeded
        }
    }

    @Test
    func `등록 응답이 인증 오류면 갱신 없이 로그인 필요 상태가 된다`() async {
        let store = Self.makeStore(projectGeneration: ProjectGenerationUseCaseSpy(error: .unauthorized))

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .signInRequired
        }
    }

    @Test
    func `이미 등록 중인 저장소면 재시도 가능한 실패로 남긴다`() async {
        let store = Self.makeStore(projectGeneration: ProjectGenerationUseCaseSpy(error: .duplicateRequest))

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.registrationFinished) {
            $0.status = .failed(reason: "이미 등록 중인 저장소예요.", retry: .registration)
        }
    }

    @Test
    func `제출 시점에 로그인이 필요하면 등록을 요청하지 않는다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            availability: .signInRequired,
        )

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.validationFinished) {
            $0.status = .signInRequired
        }

        #expect(projectGeneration.callCount == 0)
    }

    @Test
    func `제출 시점에 앱 실행이 필요하면 앱 실행 필요 상태가 된다`() async {
        let projectGeneration = ProjectGenerationUseCaseSpy()
        let store = Self.makeStore(
            projectGeneration: projectGeneration,
            availability: .appLaunchRequired,
        )

        await store.send(.quizGenerationConfirmation(.delegate(.submitRequested))) {
            $0.status = .submitting
        }
        await store.receive(\.effect.validationFinished) {
            $0.status = .appLaunchRequired
        }

        #expect(projectGeneration.callCount == 0)
    }

    // MARK: Private

    private static func makeStore(
        projectGeneration: ProjectGenerationUseCaseSpy = ProjectGenerationUseCaseSpy(),
        availability: SignInAvailability = .signedIn,
    ) -> TestStoreOf<ShareRegistrationFeature> {
        var state = ShareRegistrationFeature.State(sharedURL: ShareRegistrationTestSupport.sharedURL)
        state.repositoryConfirmation.repository = ShareRegistrationTestSupport.repository
        state.status = .quizGenerationConfirmation
        return TestStore(initialState: state) {
            ShareRegistrationFeature(
                parseRepositoryLink: StubRepositoryURLParser(location: ShareRegistrationTestSupport.location),
                externalRepository: ExternalRepositoryUseCaseFixedResultStub(
                    result: .success(ShareRegistrationTestSupport.repository)
                ),
                projectGeneration: projectGeneration,
                signInAvailability: { availability },
            )
        }
    }

}
