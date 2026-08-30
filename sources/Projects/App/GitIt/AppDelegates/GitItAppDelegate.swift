import FirebaseCore
import Foundation
import os
import Synchronization
import UIKit
import UserNotifications

// MARK: - GitItAppDelegate

public final class GitItAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: Public

    public static func configure(
        forwardAPNsToken: @escaping @Sendable (Data) -> Void,
        ingestPushPayload: @escaping @Sendable ([String: String]) async -> Void,
    ) {
        Self.state.withLock { $0 = Configuration(forwardAPNsToken: forwardAPNsToken, ingestPushPayload: ingestPushPayload) }
    }

    public func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?,
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    public func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
    ) {
        guard let forwardAPNsToken = Self.state.withLock({ $0?.forwardAPNsToken }) else {
            Self.logger.notice("configure(...) 전에 도착한 didRegisterForRemoteNotificationsWithDeviceToken을 무시합니다.")
            return
        }
        forwardAPNsToken(deviceToken)
    }

    public func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void,
    ) {
        guard let ingestPushPayload = Self.state.withLock({ $0?.ingestPushPayload }) else {
            Self.logger.notice("configure(...) 전에 도착한 didReceiveRemoteNotification을 무시합니다.")
            completionHandler(.noData)
            return
        }

        let payload = userInfo.reduce(into: [String: String]()) { result, entry in
            guard let key = entry.key as? String else { return }
            result[key] = String(describing: entry.value)
        }

        Task {
            await ingestPushPayload(payload)
            completionHandler(.newData)
        }
    }

    // MARK: Private

    private struct Configuration {
        let forwardAPNsToken: @Sendable (Data) -> Void
        let ingestPushPayload: @Sendable ([String: String]) async -> Void
    }

    private static let state = Mutex<Configuration?>(nil)
    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "GitItAppDelegate")

}
