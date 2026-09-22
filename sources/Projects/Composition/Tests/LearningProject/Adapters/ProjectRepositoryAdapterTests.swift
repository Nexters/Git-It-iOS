import Foundation
import Testing

@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DataShared
@testable import DomainProject

// MARK: - ProjectRepositoryAdapterTests

@Suite("ProjectRepositoryAdapter")
struct ProjectRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `목록 응답을 요약 모델로 변환하고 다음 퀴즈를 묶는다`() async throws {
        let adapter = Self.makeAdapter(results: [
            Self.successResponse(#"""
                {"items":[{"projectId":"project-1","repositoryName":"repo","repositoryImageUrl":null,"techStack":["Swift"],"currentSetLabel":"Set 1","currentSetTitle":"title","nextSetId":"set-1","nextQuestionId":"quiz-1","overallProgressPercent":40}],"hasNext":true}
                """#)
        ])

        let page = try await adapter.page(
            0,
            size: 10,
        )

        #expect(page.summaries.first?.id == "project-1")
        #expect(page.summaries.first?.currentSet == ProjectSetLabel(
            label: "Set 1",
            title: "title",
        ))
        #expect(page.summaries.first?.next == ProjectNextQuiz(
            setID: "set-1",
            quizID: "quiz-1",
        ))
        #expect(page.hasNextPage)
    }

    @Test
    func `다음 세트가 없으면 요약의 다음 퀴즈는 nil이다`() async throws {
        let adapter = Self.makeAdapter(results: [
            Self.successResponse(#"""
                {"items":[{"projectId":"project-1","repositoryName":"repo","repositoryImageUrl":null,"techStack":[],"currentSetLabel":"Set 1","currentSetTitle":"title","nextSetId":null,"nextQuestionId":null,"overallProgressPercent":100}],"hasNext":false}
                """#)
        ])

        #expect(try await adapter.page(
            0,
            size: 10,
        ).summaries.first?.next == nil)
    }

    @Test
    func `상세 응답의 세트 문제 수를 quizCount로 옮기고 미완료 첫 세트를 다음 대상으로 삼는다`() async throws {
        let adapter = Self.makeAdapter(results: [
            Self.successResponse(#"""
                {"projectId":"project-1","repositoryUrl":"https://github.com/owner/repo","repositoryName":"repo","repositoryImageUrl":null,"starCount":3,"techStack":["Swift"],"overallProgressPercent":40,"nextQuestionId":"quiz-1","sets":[{"setId":"set-1","label":"Set 1","title":"첫 세트","problemCount":5,"completedCount":5},{"setId":"set-2","label":"Set 2","title":"둘째 세트","problemCount":3,"completedCount":0}]}
                """#)
        ])

        let detail = try await adapter.detail(of: "project-1")

        #expect(detail.repository == ProjectRepositoryInfo(
            url: "https://github.com/owner/repo",
            name: "repo",
            imageURL: nil,
            starCount: 3,
            techStack: ["Swift"],
        ))
        #expect(detail.sets.map(\.quizCount) == [5, 3])
        #expect(detail.next == ProjectNextQuiz(
            setID: "set-2",
            quizID: "quiz-1",
        ))
    }

    @Test
    func `서버 401 응답을 unauthorized로 변환한다`() async {
        let adapter = Self.makeAdapter(results: [Self.errorResponse(
            statusCode: 401,
            code: "AUTH-001",
        )])

        await #expect(throws: ProjectError.unauthorized) {
            _ = try await adapter.page(
                0,
                size: 10,
            )
        }
    }

    // MARK: Private

    private static func makeAdapter(results: [TransportResponse]) -> ProjectRepositoryAdapter {
        ProjectRepositoryAdapter(remote: ProjectRemote(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            transport: RecordingRequestTransport(results: results),
            responseTimeout: RequestClientFactory.defaultResponseTimeout,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        ))
    }

    private static func successResponse(_ payload: String) -> TransportResponse {
        TransportResponse(
            statusCode: 200,
            body: Data(#"{"success":true,"data":\#(payload),"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private static func errorResponse(
        statusCode: Int,
        code: String,
    ) -> TransportResponse {
        TransportResponse(
            statusCode: statusCode,
            body: Data(#"{"success":false,"data":null,"code":"\#(code)","message":"error","errors":null}"#.utf8),
        )
    }

}
