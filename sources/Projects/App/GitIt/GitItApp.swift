import ComposableArchitecture
import CompositionApp
import DomainAuthentication
import DomainMember
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
                generationReminderTitle: GenerationReminderContent.title,
                generationReminderBody: GenerationReminderContent.body,
                policyDocuments: policyDocuments,
            )
        )

        let restoreSession = composition.restoreSession
        let deletesCompletedAccountOnSignIn = false
        rootStore = Store(initialState: AppRootFeature.State(bundleVersion: bundleVersion)) {
            AppRootFeature(
                restoreSession: restoreSession,
                signIn: composition.signIn,
                signOut: composition.signOut,
                verifyAuthorization: composition.verifyAuthorization,
                memberAccount: composition.memberAccount,
                policyConsent: composition.policyConsent,
                fetchLearningProjects: composition.fetchLearningProjects,
                learningLibrary: composition.learningLibrary,
                submitChoiceAnswer: composition.submitChoiceAnswer,
                submitEssayAnswer: composition.submitEssayAnswer,
                setQuestionBookmark: composition.setQuestionBookmark,
                deleteMemberAccount: composition.deleteMemberAccount,
                fetchExternalRepository: composition.fetchExternalRepository,
                createLearningProject: composition.createLearningProject,
                requestGenerationReminder: composition.requestGenerationReminder,
                trackGeneration: composition.trackGeneration,
                openNotificationSettings: {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    await UIApplication.shared.open(url)
                },
                openExternalURL: { @MainActor url in
                    await UIApplication.shared.open(url)
                },
                registerCurrentDevice: composition.registerCurrentDevice,
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
                        startObservingGenerationState: composition.startObservingGenerationState,
                    )()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    rootStore.send(.view(.applicationBecameActive))
                }
        }
    }

    // MARK: Private

    @Environment(\.scenePhase) private var scenePhase

}
