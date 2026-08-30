import DomainAuthentication
import DomainMember

// MARK: - ResetAllUseCase

public struct ResetAllUseCase: Sendable {

    // MARK: Lifecycle

    public init(
        deleteMemberAccount: any DeleteMemberAccountUseCase,
        signOut: any SignOutUseCase,
        policyConsent: any PolicyConsentUseCase,
    ) {
        self.deleteMemberAccount = deleteMemberAccount
        self.signOut = signOut
        self.policyConsent = policyConsent
    }

    // MARK: Public

    public func callAsFunction() async {
        _ = try? await deleteMemberAccount()
        _ = await signOut()
        _ = try? await policyConsent.clearConsentRecords()
    }

    // MARK: Private

    private let deleteMemberAccount: any DeleteMemberAccountUseCase
    private let signOut: any SignOutUseCase
    private let policyConsent: any PolicyConsentUseCase

}
