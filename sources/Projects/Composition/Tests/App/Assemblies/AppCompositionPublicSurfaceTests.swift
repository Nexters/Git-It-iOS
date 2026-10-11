import Foundation
import Testing

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
            )
        )

        let labels = Set(Mirror(reflecting: composition).children.compactMap(\.label))

        let expected: Set = [
            "account",
            "userInfo",
            "appSetting",
            "externalRepository",
            "quizDetail",
            "project",
            "projectGeneration",
            "recordSharedSessionState",
            "activatePushClient",
            "configureAppDelegate",
            "deviceTokenRefreshes",
            "ingestGenerationOutcomePayload",
        ]

        #expect(labels == expected)
    }

}
