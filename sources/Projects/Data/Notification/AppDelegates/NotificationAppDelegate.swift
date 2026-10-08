import Foundation
import InfrastructurePushMessaging
import UIKit

// MARK: - NotificationAppDelegate

@MainActor
public final class NotificationAppDelegate: NSObject, UIApplicationDelegate {

    // MARK: Public

    public func configure(_ callbacks: NotificationAppCallbacks) {
        let ingestRemoteMessagePayload = callbacks.ingestRemoteMessagePayload
        base.configure(
            PushNotificationCallbacks(
                forwardAPNsToken: callbacks.forwardDeviceToken,
                ingestGenerationOutcomePayload: { payload, delivery in
                    await ingestRemoteMessagePayload(
                        payload,
                        Self.messageDelivery(from: delivery),
                    )
                },
            )
        )
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
    ) -> Bool {
        base.application(
            application,
            didFinishLaunchingWithOptions: launchOptions,
        )
    }

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
    ) {
        base.application(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken,
        )
    }

    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void,
    ) {
        base.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler,
        )
    }

    // MARK: Private

    private let base = PushMessagingAppDelegate()

    nonisolated private static func messageDelivery(from delivery: RemoteNotificationDelivery) -> RemoteMessageDelivery {
        let route: RemoteMessageDelivery.Route =
            switch delivery.route {
            case .background: .background
            case .presentation: .presentation
            case .opened: .opened
            }
        return RemoteMessageDelivery(
            route: route,
            deliveredAt: delivery.deliveredAt,
        )
    }

}
