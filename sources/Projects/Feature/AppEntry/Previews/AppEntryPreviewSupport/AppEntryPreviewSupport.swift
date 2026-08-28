import ComposableArchitecture
import DomainAuthentication
import Foundation

// MARK: - AppEntryPreviewSupport

enum AppEntryPreviewSupport {
    struct NoopSignOut: SignOutUseCase {
        func callAsFunction() async -> SignOutResult {
            .success
        }
    }
}

extension AppEntryFeature {
    static func previewStore(_ state: State) -> StoreOf<AppEntryFeature> {
        Store(initialState: state) {
            AppEntryFeature(
                restoreSession: AppEntryPreviewRestoreSession(),
                fetchMemberProfile: AppEntryPreviewFetchMemberProfile(),
                signOut: AppEntryPreviewSupport.NoopSignOut(),
            )
        }
    }
}
