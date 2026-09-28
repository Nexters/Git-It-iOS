import DataNotification
import Foundation
import Testing
@testable import CompositionLearningProject
@testable import DataLearningProject
@testable import DomainProjectGeneration

// MARK: - GenerationOutcomeRepositoryAdapterTests

@Suite("GenerationOutcomeRepositoryAdapter")
struct GenerationOutcomeRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `Data DTO를 Domain 모델로 변환해 순서대로 전달한다`() async {
        let adapter = GenerationOutcomeRepositoryAdapter(
            source: StubOutcomeSource(dtos: [
                QuizGenerationOutcomeDTO(
                    projectID: "project-1",
                    status: .completed,
                    deliveredAt: Date(timeIntervalSince1970: 1_000),
                ),
                QuizGenerationOutcomeDTO(
                    projectID: "project-2",
                    status: .failed,
                    deliveredAt: Date(timeIntervalSince1970: 1_000),
                ),
            ]),
            deliveredMessages: StubDeliveredMessageReader(messages: []),
        )

        var received = [GenerationOutcome]()
        for await outcome in await adapter.outcomes() {
            received.append(outcome)
        }

        #expect(received == [
            GenerationOutcome(
                projectID: "project-1",
                status: .completed,
                arrivedAt: Date(timeIntervalSince1970: 1_000),
            ),
            GenerationOutcome(
                projectID: "project-2",
                status: .failed,
                arrivedAt: Date(timeIntervalSince1970: 1_000),
            ),
        ])
    }

    @Test
    func `DTO의 전달 시각을 결과의 도착 시각으로 옮긴다`() async {
        let deliveredAt = Date(timeIntervalSince1970: 2_500)
        let adapter = GenerationOutcomeRepositoryAdapter(
            source: StubOutcomeSource(dtos: [
                QuizGenerationOutcomeDTO(
                    projectID: "project-1",
                    status: .completed,
                    deliveredAt: deliveredAt,
                )
            ]),
            deliveredMessages: StubDeliveredMessageReader(messages: []),
        )

        var iterator = await adapter.outcomes().makeAsyncIterator()
        let outcome = await iterator.next()

        #expect(outcome?.arrivedAt == deliveredAt)
    }

    @Test
    func `알림 센터 메시지 중 파싱에 성공한 생성 결과만 전달 시각으로 반환한다`() async {
        let deliveredAt = Date(timeIntervalSince1970: 3_000)
        let adapter = GenerationOutcomeRepositoryAdapter(
            source: StubOutcomeSource(dtos: []),
            deliveredMessages: StubDeliveredMessageReader(messages: [
                DeliveredRemoteMessage(
                    payload: ["projectId": "project-1", "status": "completed"],
                    deliveredAt: deliveredAt,
                ),
                DeliveredRemoteMessage(
                    payload: ["projectId": "project-2", "status": "pending"],
                    deliveredAt: deliveredAt,
                ),
                DeliveredRemoteMessage(
                    payload: ["title": "공지"],
                    deliveredAt: deliveredAt,
                ),
            ]),
        )

        let outcomes = await adapter.deliveredOutcomes()

        #expect(outcomes == [
            GenerationOutcome(
                projectID: "project-1",
                status: .completed,
                arrivedAt: deliveredAt,
            )
        ])
    }

    // MARK: Private

    private struct StubDeliveredMessageReader: DeliveredRemoteMessageReader {

        let messages: [DeliveredRemoteMessage]

        func deliveredMessages() async -> [DeliveredRemoteMessage] {
            messages
        }

    }

    private struct StubOutcomeSource: QuizGenerationOutcomeSource {

        let dtos: [QuizGenerationOutcomeDTO]

        func outcomes() -> AsyncStream<QuizGenerationOutcomeDTO> {
            AsyncStream { continuation in
                for dto in dtos {
                    continuation.yield(dto)
                }
                continuation.finish()
            }
        }

    }

}
