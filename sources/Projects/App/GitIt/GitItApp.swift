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
                deleteLearningProject: composition.deleteLearningProject,
                fetchBookmarkedQuestions: composition.fetchBookmarkedQuestions,
                updateMemberPosition: composition.updateMemberPosition,
                updateMemberCareerLevel: composition.updateMemberCareerLevel,
                deleteMemberAccount: composition.deleteMemberAccount,
                fetchExternalRepository: composition.fetchExternalRepository,
                createLearningProject: composition.createLearningProject,
                learningProjectOutcomes: composition.learningProjectOutcomes,
                openNotificationSettings: {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    await UIApplication.shared.open(url)
                },
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
                resetAllForTesting: resetAllForTesting,
            )
        }
    }

    // MARK: Internal

    @UIApplicationDelegateAdaptor(PushNotificationAppDelegate.self) var appDelegate

    let rootStore: StoreOf<AppRootFeature>

    var body: some Scene {
        WindowGroup {
            AppRootView(store: rootStore)
        }
    }

}
