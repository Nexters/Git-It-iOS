import DomainAuthentication
import DomainMember

#if DEBUG

// MARK: - ResetAllUseCase

struct ResetAllUseCase: Sendable {
    let deleteMemberAccount: any DeleteMemberAccountUseCase
    let signOut: any SignOutUseCase
    let policyConsent: any PolicyConsentUseCase

    func callAsFunction() async {
        _ = try? await deleteMemberAccount()
        _ = await signOut()
        _ = try? await policyConsent.clearConsentRecords()
    }
}

#endif
