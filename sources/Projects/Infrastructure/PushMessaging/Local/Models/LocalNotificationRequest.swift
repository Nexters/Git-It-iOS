// MARK: - LocalNotificationRequest

public struct LocalNotificationRequest: Sendable, Equatable {

    // MARK: Lifecycle

    public init(
        identifier: String,
        title: String,
        body: String,
    ) {
        self.identifier = identifier
        self.title = title
        self.body = body
    }

    // MARK: Public

    public let identifier: String
    public let title: String
    public let body: String

}
