import Foundation
import Testing

@testable import CompositionAdapter

@Suite("AppComposition 공개 표면")
struct AppCompositionPublicSurfaceTests {

    @Test
    func `공개 프로퍼티 이름이 UseCase 전체 목록과 정확히 일치한다`() throws {
        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
            )
        )

        let labels = Set(Mirror(reflecting: composition).children.compactMap(\.label))

        let expected: Set = [
            "signIn",
            "signOut",
            "restoreSession",
            "authenticationOutcomes",
            "refreshSession",
            "verifyAccessToken",
            "policyConsent",
            "completeCuration",
            "fetchLearningProjects",
            "fetchLearningProjectDetail",
            "createLearningProject",
            "deleteLearningProject",
            "fetchLearningSet",
            "submitChoiceAnswer",
            "submitEssayAnswer",
            "setQuestionBookmark",
            "fetchBookmarkedQuestions",
            "fetchMemberProfile",
            "updateMemberPosition",
            "updateMemberCareerLevel",
            "registerMemberDevice",
            "deleteMemberAccount",
            "fetchExternalRepository",
            "learningProjectOutcomes",
            "requestGenerationReminder",
        ]

        #expect(labels == expected)
    }

}
