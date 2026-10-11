import Foundation

// MARK: - DeliveredRemoteNotification

public struct DeliveredRemoteNotification: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        payload: [String: String],
        deliveredAt: Date,
    ) {
        self.payload = payload
        self.deliveredAt = deliveredAt
    }

    // MARK: Public

    public let payload: [String: String]
    public let deliveredAt: Date

}
