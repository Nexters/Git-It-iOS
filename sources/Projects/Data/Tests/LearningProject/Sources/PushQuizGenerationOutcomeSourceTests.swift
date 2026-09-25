import Foundation
import Testing

@testable import DataLearningProject

// MARK: - PushQuizGenerationOutcomeSourceTests

@Suite("PushQuizGenerationOutcomeSource")
struct PushQuizGenerationOutcomeSourceTests {

    // MARK: Internal

    @Test
    func `ingest 한 번으로 두 구독 스트림이 같은 이벤트를 받는다`() async {
        let source = PushQuizGenerationOutcomeSource()
        let stream1 = source.outcomes()
        let stream2 = source.outcomes()

        await source.ingest(
            rawPayload: Self.payload(projectID: "project-1"),
            deliveredAt: Self.deliveredAt,
        )

        let expected = Self.outcome(projectID: "project-1")
        var iterator1 = stream1.makeAsyncIterator()
        var iterator2 = stream2.makeAsyncIterator()
        #expect(await iterator1.next() == expected)
        #expect(await iterator2.next() == expected)
    }

    @Test
    func `디코딩 실패 payload는 조용히 폐기된다`() async {
        let source = PushQuizGenerationOutcomeSource()
        let stream = source.outcomes()

        await source.ingest(
            rawPayload: ["projectId": "project-1"],
            deliveredAt: Self.deliveredAt,
        )
        await source.ingest(
            rawPayload: Self.payload(projectID: "project-2"),
            deliveredAt: Self.deliveredAt,
        )

        var iterator = stream.makeAsyncIterator()
        let received = await iterator.next()

        #expect(received == Self.outcome(projectID: "project-2"))
    }

    @Test
    func `한 스트림의 소비를 끝내도 다른 스트림은 계속 이벤트를 받는다`() async {
        let source = PushQuizGenerationOutcomeSource()
        let stream1 = source.outcomes()
        let stream2 = source.outcomes()

        let task1 = Task {
            for await _ in stream1 { }
        }
        task1.cancel()
        _ = await task1.value

        await source.ingest(
            rawPayload: Self.payload(projectID: "project-1"),
            deliveredAt: Self.deliveredAt,
        )

        var iterator2 = stream2.makeAsyncIterator()
        let received = await iterator2.next()

        #expect(received == Self.outcome(projectID: "project-1"))
    }

    @Test
    func `구독자가 없을 때 도착한 결과를 첫 구독자에게 도착 순서대로 전달한다`() async {
        let source = PushQuizGenerationOutcomeSource()

        await source.ingest(
            rawPayload: Self.payload(projectID: "project-1"),
            deliveredAt: Self.deliveredAt,
        )
        await source.ingest(
            rawPayload: Self.payload(projectID: "project-2"),
            deliveredAt: Self.deliveredAt,
        )
        var iterator = source.outcomes().makeAsyncIterator()

        #expect(await iterator.next() == Self.outcome(projectID: "project-1"))
        #expect(await iterator.next() == Self.outcome(projectID: "project-2"))
    }

    @Test
    func `구독 전 보존 결과가 32개를 넘으면 가장 오래된 결과부터 버린다`() async {
        let source = PushQuizGenerationOutcomeSource()

        for index in 0 ... 32 {
            await source.ingest(
                rawPayload: Self.payload(projectID: "project-\(index)"),
                deliveredAt: Self.deliveredAt,
            )
        }
        var iterator = source.outcomes().makeAsyncIterator()

        #expect(await iterator.next() == Self.outcome(projectID: "project-1"))
    }

    @Test
    func `보존 결과를 전달한 뒤에는 다음 구독자에게 다시 전달하지 않는다`() async {
        let source = PushQuizGenerationOutcomeSource()
        await source.ingest(
            rawPayload: Self.payload(projectID: "project-1"),
            deliveredAt: Self.deliveredAt,
        )
        var firstIterator = source.outcomes().makeAsyncIterator()
        _ = await firstIterator.next()

        let secondStream = source.outcomes()
        await source.ingest(
            rawPayload: Self.payload(projectID: "project-2"),
            deliveredAt: Self.deliveredAt,
        )
        var secondIterator = secondStream.makeAsyncIterator()

        #expect(await secondIterator.next() == Self.outcome(projectID: "project-2"))
    }

    // MARK: Private

    private static let deliveredAt = Date(timeIntervalSince1970: 1_000)

    private static func payload(projectID: String) -> [String: String] {
        ["projectId": projectID, "status": "completed"]
    }

    private static func outcome(projectID: String) -> QuizGenerationOutcomeDTO {
        QuizGenerationOutcomeDTO(
            projectID: projectID,
            status: .completed,
            deliveredAt: deliveredAt,
        )
    }

}
