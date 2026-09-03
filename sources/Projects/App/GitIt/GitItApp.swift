import ComposableArchitecture
import CompositionAdapter
import DomainAuthentication
import DomainMember
import Foundation
import SwiftUI
import UIKit

#if DEBUG
import AppDebug
#endif

// MARK: - GitItApp

@main
struct GitItApp: App {

    // MARK: Lifecycle

    init() {
        let policyDocuments = (try? PolicyManifestLoader.loadPolicyDocuments()) ?? []
        let composition = AppComposition.live(
            AppComposition.Environment(
                apiBaseURL: AppEndpointHost.api.url,
                externalRepositoryBaseURL: AppEndpointHost.externalRepository.url,
                policyDocuments: policyDocuments,
            )
        )

        let restoreSession = composition.restoreSession
        let deletesCompletedAccountOnSignIn = false

        #if DEBUG
        let resetAll = ResetAllUseCase(
            deleteMemberAccount: composition.deleteMemberAccount,
            signOut: composition.signOut,
            policyConsent: composition.policyConsent,
        )
        let resetAllForTesting: (@Sendable () async -> Void)? = { await resetAll() }
        #else
        let resetAllForTesting: (@Sendable () async -> Void)? = nil
        #endif

        let bundleVersion = AppBundleMetadata.shortVersion.value
        rootStore = Store(initialState: AppRootFeature.State(bundleVersion: bundleVersion)) {
            AppRootFeature(
                restoreSession: restoreSession,
                signIn: composition.signIn,
                signOut: composition.signOut,
                authenticationOutcomes: composition.authenticationOutcomes,
                fetchMemberProfile: composition.fetchMemberProfile,
                completeCuration: composition.completeCuration,
                policyConsent: composition.policyConsent,
                fetchLearningProjects: composition.fetchLearningProjects,
                fetchLearningProjectDetail: composition.fetchLearningProjectDetail,
                deleteLearningProject: composition.deleteLearningProject,
                fetchBookmarkedQuestions: composition.fetchBookmarkedQuestions,
                fetchLearningSet: composition.fetchLearningSet,
                submitChoiceAnswer: composition.submitChoiceAnswer,
                submitEssayAnswer: composition.submitEssayAnswer,
                setQuestionBookmark: composition.setQuestionBookmark,
                updateMemberPosition: composition.updateMemberPosition,
                updateMemberCareerLevel: composition.updateMemberCareerLevel,
                deleteMemberAccount: composition.deleteMemberAccount,
                fetchExternalRepository: composition.fetchExternalRepository,
                createLearningProject: composition.createLearningProject,
                observeGenerationOutcomes: composition.observeGenerationOutcomes,
                requestGenerationReminder: composition.requestGenerationReminder,
                trackGenerationProgress: composition.trackGenerationProgress,
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
                resetAllForTesting: resetAllForTesting,
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
                    await composition.bootstrap(appDelegate)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    rootStore.send(.view(.applicationBecameActive))
                }
                .onOpenURL { url in
                    guard url.scheme == Constant.sharedLinkURLScheme else { return }
                    guard let link = Self.takeSharedRepositoryLink() else { return }
                    rootStore.send(.effect(.sharedRepositoryLinkReceived(link)))
                }
        }
    }

    // MARK: Private

    private enum Constant {
        static let sharedLinkURLScheme = "gitit"
        static let appGroupIdentifier = "group.com.nexters.hytime.gitit"
        static let sharedLinkStorageKey = "sharedRepositoryURL"
    }

    @Environment(\.scenePhase) private var scenePhase

    private static func takeSharedRepositoryLink() -> SharedRepositoryLink? {
        guard let defaults = UserDefaults(suiteName: Constant.appGroupIdentifier) else { return nil }
        guard let urlString = defaults.string(forKey: Constant.sharedLinkStorageKey) else { return nil }
        defaults.removeObject(forKey: Constant.sharedLinkStorageKey)
        return SharedRepositoryLink(url: urlString)
    }

}
