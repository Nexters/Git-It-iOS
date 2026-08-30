import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

struct AppEntryPreviewRestoreSession: RestoreSessionUseCase {
    func callAsFunction() async -> RestoreSessionResult {
        .unauthenticated
    }
}
