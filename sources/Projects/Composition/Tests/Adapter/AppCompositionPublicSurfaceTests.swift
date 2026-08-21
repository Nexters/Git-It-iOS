import Foundation
import Testing

@testable import CompositionAdapter

/// `AppComposition`의 공개 저장 프로퍼티 집합이 UC01~UC20 UseCase 전체와 정확히 일치하고
/// `client`·`keychainStore`·`transport` 같은 구현 세부사항을 추가로 노출하지 않는지
/// 검증한다. Swift에는 existential protocol을 식별하는 공통 marker protocol이 없어, 전체
/// 프로퍼티 이름 집합의 정확한 일치로 확인한다(추가되거나 누락된 프로퍼티가 있으면 실패).
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

        let expected: Set<String> = [
            "signIn", "signOut", "restoreSession", "observeAuthenticationOutcomes",
            "refreshSession", "verifyAccessToken", "completeCuration",
            "fetchLearningProjects", "fetchLearningProjectDetail", "createLearningProject",
            "deleteLearningProject", "fetchLearningSet", "submitChoiceAnswer",
            "submitEssayAnswer", "setQuestionBookmark", "fetchBookmarkedQuestions",
            "fetchMemberProfile", "updateMemberPosition", "updateMemberCareerLevel",
            "registerMemberDevice", "deleteMemberAccount",
            "fetchExternalRepository",
        ]

        #expect(labels == expected)
    }

}
