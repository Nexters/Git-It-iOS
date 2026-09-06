import Foundation
import Testing
@testable import CompositionAdapter

// MARK: - PendingGenerationReminderCodingTests

@Suite("PendingGenerationReminderCoding")
struct PendingGenerationReminderCodingTests {

    // MARK: Internal

    @Test
    func `기록한 프로젝트를 흡수하면 목록이 비워진다`() async throws {
        let userDefaults = try Self.makeUserDefaults()
        let coding = PendingGenerationReminderCoding(userDefaults: userDefaults)

        await coding.append(projectID: "project-1")
        await coding.append(projectID: "project-2")

        #expect(await coding.drainProjectIDs() == ["project-1", "project-2"])
        #expect(await coding.drainProjectIDs().isEmpty)
    }

    @Test
    func `같은 프로젝트를 다시 기록하지 않는다`() async throws {
        let userDefaults = try Self.makeUserDefaults()
        let coding = PendingGenerationReminderCoding(userDefaults: userDefaults)

        await coding.append(projectID: "project-1")
        await coding.append(projectID: "project-1")

        #expect(await coding.drainProjectIDs() == ["project-1"])
    }

    @Test
    func `상한을 넘으면 오래된 항목부터 버린다`() async throws {
        let userDefaults = try Self.makeUserDefaults()
        let coding = PendingGenerationReminderCoding(userDefaults: userDefaults)
        let overflow = SharedSessionLayout.pendingReminderLimit + 2

        for index in 0 ..< overflow {
            await coding.append(projectID: "project-\(index)")
        }

        let drained = await coding.drainProjectIDs()
        #expect(drained.count == SharedSessionLayout.pendingReminderLimit)
        #expect(drained.first == "project-2")
        #expect(drained.last == "project-\(overflow - 1)")
    }

    @Test
    func `저장 값이 손상되면 빈 목록으로 취급하고 기록을 이어간다`() async throws {
        let userDefaults = try Self.makeUserDefaults()
        userDefaults.set(
            Data([0xFF, 0xFE]),
            forKey: "\(SharedSessionLayout.namespace).\(SharedSessionLayout.pendingGenerationRemindersKey)",
        )
        let coding = PendingGenerationReminderCoding(userDefaults: userDefaults)

        #expect(await coding.drainProjectIDs().isEmpty)

        await coding.append(projectID: "project-1")
        #expect(await coding.drainProjectIDs() == ["project-1"])
    }

    // MARK: Private

    private static func makeUserDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "PendingGenerationReminderCodingTests.\(UUID().uuidString)"))
    }

}
