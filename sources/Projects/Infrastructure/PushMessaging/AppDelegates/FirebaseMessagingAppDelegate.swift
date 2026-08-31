import FirebaseCore
import Foundation
import os
import Synchronization
import UIKit

// MARK: - FirebaseMessagingAppDelegate

public final class FirebaseMessagingAppDelegate: NSObject, UIApplicationDelegate {

    // MARK: Public

    public static func configure(_ handlers: PushNotificationHandlers) {
        Self.state.withLock { $0 = handlers }
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?,
    ) -> Bool {
        FirebaseApp.configure()
        application.registerForRemoteNotifications()
        return true
    }

    public func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
    ) {
        guard let handlers = Self.state.withLock({ $0 }) else {
            Self.logger.notice("configure(...) 전에 도착한 didRegisterForRemoteNotificationsWithDeviceToken을 무시합니다.")
            return
        }
        handlers.forwardAPNsToken(deviceToken)
    }

    public func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void,
    ) {
        guard let handlers = Self.state.withLock({ $0 }) else {
            Self.logger.notice("configure(...) 전에 도착한 didReceiveRemoteNotification을 무시합니다.")
            completionHandler(.noData)
            return
        }

        let payload = RemoteNotificationPayload(userInfo: userInfo)

        Task {
            await handlers.ingestPushPayload(payload.value)
            completionHandler(.newData)
        }
    }

    // MARK: Private

    private static let state = Mutex<PushNotificationHandlers?>(nil)
    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "FirebaseMessagingAppDelegate")

}
