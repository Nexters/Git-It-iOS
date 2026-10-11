// MARK: - DeliveredRemoteMessageReader

public protocol DeliveredRemoteMessageReader: Sendable {

    func deliveredMessages() async -> [DeliveredRemoteMessage]

}
