import Foundation

// MARK: - PushNotificationCallbacks

public struct PushNotificationCallbacks: Sendable {

    // MARK: Lifecycle

    public init(
        forwardAPNsToken: @escaping @Sendable (Data) -> Void,
        ingestGenerationOutcomePayload: @escaping @Sendable ([String: String]) async -> Void,
    ) {
        self.forwardAPNsToken = forwardAPNsToken
        self.ingestGenerationOutcomePayload = ingestGenerationOutcomePayload
    }

    // MARK: Public

    public let forwardAPNsToken: @Sendable (Data) -> Void
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

}
