import Foundation
import Testing

@testable import CompositionAdapter
@testable import CompositionApp

@Suite("AppComposition 공개 표면")
struct AppCompositionPublicSurfaceTests {

    @Test
    func `공개 프로퍼티 이름이 UseCase 전체 목록과 정확히 일치한다`() throws {
        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: try #require(URL(string: "https://api.git-it.example.com")),
                externalRepositoryBaseURL: try #require(URL(string: "https://api.github.com")),
                appVersion: "1.0.0",
                osVersion: "Version 26.0",
                generationReminderTitle: "세트 생성 완료",
                generationReminderBody: "학습 세트 생성이 완료됐어요. 지금 확인해보세요.",
            )
        )

        let labels = Set(Mirror(reflecting: composition).children.compactMap(\.label))

        let expected: Set = [
            "signIn",
            "signOut",
            "restoreSession",
            "verifyAuthorization",
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
            "requestGenerationReminder",
            "trackGeneration",
            "bootstrap",
            "registerCurrentDevice",
            "deviceTokenRefreshes",
            "ingestGenerationOutcomePayload",
        ]

        #expect(labels == expected)
    }

}
