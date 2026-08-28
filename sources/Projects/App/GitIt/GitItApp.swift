import ComposableArchitecture
import CompositionAdapter
import DomainAuthentication
import DomainMember
import Foundation
import SwiftUI

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
                observeAuthenticationOutcomes: composition.observeAuthenticationOutcomes,
                fetchMemberProfile: composition.fetchMemberProfile,
                completeCuration: composition.completeCuration,
                policyConsent: composition.policyConsent,
                fetchLearningProjects: composition.fetchLearningProjects,
                deleteLearningProject: composition.deleteLearningProject,
                fetchBookmarkedQuestions: composition.fetchBookmarkedQuestions,
                updateMemberPosition: composition.updateMemberPosition,
                updateMemberCareerLevel: composition.updateMemberCareerLevel,
                deleteMemberAccount: composition.deleteMemberAccount,
                deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
                resetAllForTesting: resetAllForTesting,
            )
        }
    }

    // MARK: Internal

    let rootStore: StoreOf<AppRootFeature>

    var body: some Scene {
        WindowGroup {
            AppRootView(store: rootStore)
        }
    }

}
