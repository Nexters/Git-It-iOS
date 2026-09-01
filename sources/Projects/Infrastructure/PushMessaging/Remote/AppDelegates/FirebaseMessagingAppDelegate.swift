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

    /// 콜백을 이 인스턴스가 소유한다. 주입 전에 도착한 APNs token과 remote notification payload는
    /// 각각 대기 슬롯에 1건 보관했다가 주입 직후 정확히 1회 전달한다.
    public func configure(_ callbacks: PushNotificationCallbacks) {
        let pending = state.withLock { state -> PendingDelivery in
            state.callbacks = callbacks
            let pending = PendingDelivery(
                apnsToken: state.pendingAPNsToken,
                payload: state.pendingPayload,
            )
            state.pendingAPNsToken = nil
            state.pendingPayload = nil
            return pending
        }

        if let apnsToken = pending.apnsToken {
            Self.logger.debug("대기 슬롯의 APNs token을 전달합니다.")
            callbacks.forwardAPNsToken(apnsToken)
        }
        if let payload = pending.payload {
            Self.logger.debug("대기 슬롯의 payload를 전달합니다.")
            Task { await callbacks.ingestGenerationOutcomePayload(payload) }
        }
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
        let callbacks = state.withLock { state -> PushNotificationCallbacks? in
            guard let callbacks = state.callbacks else {
                state.pendingAPNsToken = deviceToken
                return nil
            }
            return callbacks
        }

        guard let callbacks else {
            Self.logger.notice("configure(_:) 전에 도착한 APNs token을 대기 슬롯에 보관합니다.")
            return
        }
        callbacks.forwardAPNsToken(deviceToken)
    }

    public func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void,
    ) {
        let payload = RemoteNotificationPayload(userInfo: userInfo)
        let callbacks = state.withLock { state -> PushNotificationCallbacks? in
            guard let callbacks = state.callbacks else {
                state.pendingPayload = payload.userInfoStrings
                return nil
            }
            return callbacks
        }

        guard let callbacks else {
            Self.logger.notice("configure(_:) 전에 도착한 didReceiveRemoteNotification을 대기 슬롯에 보관합니다.")
            completionHandler(.noData)
            return
        }

        Messaging.messaging().appDidReceiveMessage(userInfo)
        Self.logger.debug("didReceiveRemoteNotification 수신: \(payload.userInfoStrings, privacy: .public)")

        Task {
            await callbacks.ingestGenerationOutcomePayload(payload.userInfoStrings)
            completionHandler(.newData)
        }
    }

    // MARK: Private

    private struct PendingDelivery {
        let apnsToken: Data?
        let payload: [String: String]?
    }

    private struct State {
        var callbacks: PushNotificationCallbacks?
        var pendingAPNsToken: Data?
        var pendingPayload: [String: String]?
    }

    private static let logger = Logger(subsystem: "com.nexters.hytime.gitit", category: "FirebaseMessagingAppDelegate")

    private let state = Mutex(State())

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
