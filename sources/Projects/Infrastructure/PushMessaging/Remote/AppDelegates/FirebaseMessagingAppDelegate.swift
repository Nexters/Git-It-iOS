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

    public static let pendingPayloadLimit = 8

    public func configure(_ callbacks: PushNotificationCallbacks) {
        let pending = state.withLock { state -> PendingDelivery in
            state.callbacks = callbacks
            let pending = PendingDelivery(
                apnsToken: state.pendingAPNsToken,
                payloads: state.pendingPayloads,
            )
            state.pendingAPNsToken = nil
            state.pendingPayloads = []
            return pending
        }

        if let apnsToken = pending.apnsToken {
            Self.logger.debug("대기 슬롯의 APNs token을 전달합니다.")
            callbacks.forwardAPNsToken(apnsToken)
        }
        guard !pending.payloads.isEmpty else { return }
        Self.logger.debug("대기 슬롯의 payload \(pending.payloads.count, privacy: .public)개를 도착 순서대로 전달합니다.")
        Task {
            for pendingPayload in pending.payloads {
                await callbacks.ingestGenerationOutcomePayload(
                    pendingPayload.payload,
                    pendingPayload.delivery,
                )
            }
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
        let payload = RemoteNotificationPayload(userInfo: userInfo).userInfoStrings
        let delivery = RemoteNotificationDelivery(
            route: .background,
            deliveredAt: Date(),
        )
        guard
            let callbacks = callbacksOrPending(
                payload,
                delivery: delivery,
            )
        else {
            completionHandler(.noData)
            return
        }

        Messaging.messaging().appDidReceiveMessage(userInfo)
        Self.logger.debug("didReceiveRemoteNotification 수신: \(payload, privacy: .public)")

        Task {
            await callbacks.ingestGenerationOutcomePayload(
                payload,
                delivery,
            )
            completionHandler(.newData)
        }
    }

    // MARK: Private

    private struct PendingPayload {
        let payload: [String: String]
        let delivery: RemoteNotificationDelivery
    }

    private struct PendingDelivery {
        let apnsToken: Data?
        let payloads: [PendingPayload]
    }

    private struct State {
        var callbacks: PushNotificationCallbacks?
        var pendingAPNsToken: Data?
        var pendingPayloads = [PendingPayload]()
    }

    private static let logger = Logger(
        subsystem: "com.nexters.hytime.gitit",
        category: "FirebaseMessagingAppDelegate",
    )

    private let state = Mutex(State())

    private func callbacksOrPending(
        _ payload: [String: String],
        delivery: RemoteNotificationDelivery,
    ) -> PushNotificationCallbacks? {
        let callbacks = state.withLock { state -> PushNotificationCallbacks? in
            guard let callbacks = state.callbacks else {
                state.pendingPayloads.append(PendingPayload(
                    payload: payload,
                    delivery: delivery,
                ))
                if state.pendingPayloads.count > Self.pendingPayloadLimit {
                    state.pendingPayloads.removeFirst(state.pendingPayloads.count - Self.pendingPayloadLimit)
                }
                return nil
            }
            return callbacks
        }
        let route = String(describing: delivery.route)
        if callbacks == nil {
            Self.logger
                .notice(
                    "configure(_:) 전에 도착한 원격 알림을 대기 슬롯에 보관합니다: route=\(route, privacy: .public) deliveredAt=\(delivery.deliveredAt, privacy: .public)"
                )
        } else {
            Self.logger
                .debug(
                    "원격 알림을 전달합니다: route=\(route, privacy: .public) deliveredAt=\(delivery.deliveredAt, privacy: .public)"
                )
        }
        return callbacks
    }

    private func ingest(
        _ payload: [String: String],
        delivery: RemoteNotificationDelivery,
    ) async {
        guard
            let callbacks = callbacksOrPending(
                payload,
                delivery: delivery,
            )
        else { return }
        await callbacks.ingestGenerationOutcomePayload(
            payload,
            delivery,
        )
    }

}

// MARK: UNUserNotificationCenterDelegate

extension FirebaseMessagingAppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        let payload = RemoteNotificationPayload(userInfo: notification.request.content.userInfo).userInfoStrings
        await ingest(
            payload,
            delivery: RemoteNotificationDelivery(
                route: .presentation,
                deliveredAt: notification.date,
            ),
        )
        return [.banner, .list, .sound]
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
    ) async {
        let notification = response.notification
        let payload = RemoteNotificationPayload(userInfo: notification.request.content.userInfo).userInfoStrings
        await ingest(
            payload,
            delivery: RemoteNotificationDelivery(
                route: .opened,
                deliveredAt: notification.date,
            ),
        )
    }
}
