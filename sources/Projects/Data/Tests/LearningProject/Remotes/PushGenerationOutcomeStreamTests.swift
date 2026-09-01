import Testing

@testable import DataLearningProject

// MARK: - PushGenerationOutcomeStreamTests

@Suite("PushGenerationOutcomeStream")
struct PushGenerationOutcomeStreamTests {

    @Test
    func `ingest 한 번으로 두 구독 스트림이 같은 이벤트를 받는다`() async {
        let remote = PushGenerationOutcomeStream()
        let stream1 = await remote.outcomes()
        let stream2 = await remote.outcomes()

        await remote.ingest(rawPayload: ["projectId": "project-1", "status": "completed"])

        let expected = GenerationOutcomeDTO(projectID: "project-1", status: .completed)
        var iterator1 = stream1.makeAsyncIterator()
        var iterator2 = stream2.makeAsyncIterator()
        #expect(await iterator1.next() == expected)
        #expect(await iterator2.next() == expected)
    }

    @Test
    func `디코딩 실패 payload는 조용히 폐기된다`() async {
        let remote = PushGenerationOutcomeStream()
        let stream = await remote.outcomes()

        await remote.ingest(rawPayload: ["projectId": "project-1"])
        await remote.ingest(rawPayload: ["projectId": "project-2", "status": "completed"])

        var iterator = stream.makeAsyncIterator()
        let received = await iterator.next()

        #expect(received == GenerationOutcomeDTO(projectID: "project-2", status: .completed))
    }

    @Test
    func `한 스트림의 소비를 끝내도 다른 스트림은 계속 이벤트를 받는다`() async {
        let remote = PushGenerationOutcomeStream()
        let stream1 = await remote.outcomes()
        let stream2 = await remote.outcomes()

        let task1 = Task {
            for await _ in stream1 { }
        }
        task1.cancel()
        _ = await task1.value

        await remote.ingest(rawPayload: ["projectId": "project-1", "status": "completed"])

        var iterator2 = stream2.makeAsyncIterator()
        let received = await iterator2.next()

        #expect(received == GenerationOutcomeDTO(projectID: "project-1", status: .completed))
    }

}
