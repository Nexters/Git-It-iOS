import Foundation
import UIKit

// MARK: - PushMessagingAppDelegate

public final class PushMessagingAppDelegate: NSObject, UIApplicationDelegate {

    // MARK: Public

    public func configure(_ callbacks: PushNotificationCallbacks) {
        base.configure(callbacks)
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

    private let base = FirebaseMessagingAppDelegate()

}
