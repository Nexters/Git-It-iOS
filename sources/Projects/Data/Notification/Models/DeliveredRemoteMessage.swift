import Foundation

// MARK: - DeliveredRemoteMessage

public struct DeliveredRemoteMessage: Equatable, Sendable {

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
