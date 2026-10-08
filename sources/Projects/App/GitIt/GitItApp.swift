import ComposableArchitecture
import CompositionApp
import Foundation
import SwiftUI
import UIKit

// MARK: - GitItApp

@main
struct GitItApp: App {

    // MARK: Lifecycle

    init() {
        let policyDocuments = (try? PolicyManifestLoader.loadPolicyDocuments()) ?? []
        let bundleVersion = AppBundleMetadata.shortVersion.value
        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: AppEndpointHost.api.url,
                externalRepositoryBaseURL: AppEndpointHost.externalRepository.url,
                appVersion: bundleVersion,
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                policyDocuments: policyDocuments,
            )
        )

        let deletesCompletedAccountOnSignIn = false
        rootStore = Store(initialState: AppRootFeature.State(bundleVersion: bundleVersion)) {
            AppRootFeature(
                account: composition.account,
                userInfo: composition.userInfo,
                appSetting: composition.appSetting,
                externalRepository: composition.externalRepository,
                quizDetail: composition.quizDetail,
                project: composition.project,
                projectGeneration: composition.projectGeneration,
                openNotificationSettings: {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    await UIApplication.shared.open(url)
                },
                openExternalURL: { @MainActor url in
                    await UIApplication.shared.open(url)
                },
                deviceTokenRefreshes: composition.deviceTokenRefreshes,
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
            )
        }
        self.composition = composition
    }

    // MARK: Internal

    @UIApplicationDelegateAdaptor(PushNotificationAppDelegate.self) var appDelegate

    let rootStore: StoreOf<AppRootFeature>
    let composition: AppComposition

    var body: some Scene {
        WindowGroup {
            AppRootView(store: rootStore)
                .task {
                    await AppLaunchSequence(
                        recordSharedSessionState: composition.recordSharedSessionState,
                        activatePushClient: composition.activatePushClient,
                        configureAppDelegate: { composition.configureAppDelegate(appDelegate) },
                    )()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        rootStore.send(.view(.applicationBecameActive))

                    case .background:
                        rootStore.send(.view(.applicationEnteredBackground))

                    case .inactive:
                        break

                    @unknown default:
                        break
                    }
                }
        }
    }

    // MARK: Private

    @Environment(\.scenePhase) private var scenePhase

}
