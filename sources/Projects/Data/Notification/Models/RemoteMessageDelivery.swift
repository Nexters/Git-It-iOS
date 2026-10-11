import Foundation

// MARK: - RemoteMessageDelivery

public struct RemoteMessageDelivery: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        route: Route,
        deliveredAt: Date,
    ) {
        self.route = route
        self.deliveredAt = deliveredAt
    }

    // MARK: Public

    public enum Route: Equatable, Sendable {
        case background
        case presentation
        case opened
    }

    public let route: Route
    public let deliveredAt: Date

}
