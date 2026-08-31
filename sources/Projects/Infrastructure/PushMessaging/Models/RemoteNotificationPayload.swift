import Foundation

// MARK: - RemoteNotificationPayload

public struct RemoteNotificationPayload {

    // MARK: Lifecycle

    public init(userInfo: [AnyHashable: Any]) {
        value = userInfo.reduce(into: [String: String]()) { result, entry in
            guard let key = entry.key as? String else { return }
            result[key] = String(describing: entry.value)
        }
    }

    // MARK: Public

    public let value: [String: String]

}
