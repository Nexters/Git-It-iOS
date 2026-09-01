import FirebaseCore
import FirebaseMessaging
import Foundation
import os
import Synchronization
import UIKit
import UserNotifications

// MARK: - FirebaseMessagingAppDelegate

public final class FirebaseMessagingAppDelegate: NSObject, UIApplicationDelegate {

    // MARK: Public

    public static func configure(_ handlers: PushNotificationCallbacks) {
        Self.state.withLock { $0 = handlers }
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?,
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        UNUserNotificationCenter.current().delegate = self
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

        Messaging.messaging().appDidReceiveMessage(userInfo)

        let payload = RemoteNotificationPayload(userInfo: userInfo)
        Self.logger.debug("didReceiveRemoteNotification 수신: \(payload.userInfoStrings, privacy: .public)")

        Task {
            await handlers.ingestPushPayload(payload.userInfoStrings)
            completionHandler(.newData)
        }
    }

    // MARK: Private

    private static let state = Mutex<PushNotificationCallbacks?>(nil)
    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "FirebaseMessagingAppDelegate")

}

// MARK: UNUserNotificationCenterDelegate

extension FirebaseMessagingAppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
