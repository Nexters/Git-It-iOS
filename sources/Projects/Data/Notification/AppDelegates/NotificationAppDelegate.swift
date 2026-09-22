import Foundation
import InfrastructurePushMessaging
import UIKit

// MARK: - NotificationAppDelegate

@MainActor
public final class NotificationAppDelegate: NSObject, UIApplicationDelegate {

    // MARK: Public

    public func configure(_ callbacks: NotificationAppCallbacks) {
        base.configure(
            PushNotificationCallbacks(
                forwardAPNsToken: callbacks.forwardDeviceToken,
                ingestGenerationOutcomePayload: callbacks.ingestRemoteMessagePayload,
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

}
