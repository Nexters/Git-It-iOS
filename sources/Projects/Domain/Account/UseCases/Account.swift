import Foundation

public actor Account: AccountUseCase {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        signInRepository: any SignInRepository,
        withdrawalRepository: any WithdrawalRepository,
        policyConsentRepository: any PolicyConsentRepository,
        policyDocuments: [PolicyDocument],
        signInInvalidations: @escaping @Sendable () async -> AsyncStream<Void>,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.authenticationRepository = authenticationRepository
        self.signInRepository = signInRepository
        self.withdrawalRepository = withdrawalRepository
        self.policyConsentRepository = policyConsentRepository
        self.policyDocuments = policyDocuments
        self.signInInvalidations = signInInvalidations
        self.now = now
    }

    // MARK: Public

    public func signIn(with method: SignInMethod) async -> SignInResult {
        startObservingInvalidations()
        let grant: AuthenticationGrant

        do {
            grant = try await authenticationRepository.authenticate(using: method)
        } catch AccountError.signInCancelled {
            return .cancelled
        } catch {
            return .retryableFailure
        }

        do {
            let record = try await signInRepository.start(with: grant)
            update(.signedIn(record.account.id))
            return .signedIn(record.account)
        } catch {
            await clearAuthentication()
            return .retryableFailure
        }
    }

    public func signOut() async -> SignOutResult {
        startObservingInvalidations()

        do {
            try await signInRepository.signOut()
            try await authenticationRepository.clearAuthentication()
        } catch {
            return .retryableFailure
        }

        update(.signedOut)
        return .signedOut
    }

    public func signInStates() async -> AsyncStream<SignInState> {
        startObservingInvalidations()
        let (stream, continuation) = AsyncStream<SignInState>.makeStream()
        let subscriberID = UUID()
        subscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        continuation.yield(state)
        return stream
    }

    public func restoreSignIn() async -> SignInRestoration {
        startObservingInvalidations()
        let record: SignInRecord

        do {
            guard let restored = try await signInRepository.restore() else {
                await clearAuthentication()
                update(.signedOut)
                return .signedOut
            }
            record = restored
        } catch AccountError.unauthorized {
            await clearInvalidSignIn()
            return .signedOut
        } catch {
            return .temporarilyUnavailable
        }

        guard record.isAccountAvailable else {
            await clearInvalidSignIn()
            return .signedOut
        }

        do {
            switch try await authenticationRepository.authorizationStatus() {
            case .valid:
                update(.signedIn(record.account.id))
                return .signedIn(record.account)

            case .reauthenticationRequired:
                await clearInvalidSignIn()
                return .signedOut

            case .temporarilyUnavailable:
                return .temporarilyUnavailable
            }
        } catch {
            return .temporarilyUnavailable
        }
    }

    public func verifySignIn() async -> SignInVerification {
        startObservingInvalidations()
        guard let verification = try? await authenticationRepository.authorizationStatus() else {
            return .temporarilyUnavailable
        }
        if verification == .reauthenticationRequired {
            await clearInvalidSignIn()
        }
        return verification
    }

    public func signInAvailability() async -> SignInAvailability {
        startObservingInvalidations()
        guard let isSignedIn = await signInRepository.sharedSignInState() else {
            return .appLaunchRequired
        }
        guard isSignedIn, await signInRepository.hasUsableCredential() else {
            return .signInRequired
        }
        return .signedIn
    }

    public func policyConsentStatus() async throws -> PolicyConsentStatus {
        startObservingInvalidations()
        let consents = try await policyConsentRepository.consents()
        let isSatisfied = policyDocuments
            .filter(\.isRequired)
            .allSatisfy { document in
                consents.contains { $0.documentID == document.id && $0.version == document.version }
            }
        return PolicyConsentStatus(
            documents: policyDocuments,
            consents: consents,
            isSatisfied: isSatisfied,
        )
    }

    public func consent(to documentIDs: [PolicyDocumentID]) async throws {
        startObservingInvalidations()
        let consentedAt = now()
        let consents = policyDocuments
            .filter { documentIDs.contains($0.id) }
            .map { PolicyConsent(
                documentID: $0.id,
                version: $0.version,
                consentedAt: consentedAt,
            ) }
        try await policyConsentRepository.record(consents)
    }

    public func withdraw() async throws {
        startObservingInvalidations()
        try await withdrawalRepository.withdraw()
        try? await policyConsentRepository.removeAll()
        await clearInvalidSignIn()
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let signInRepository: any SignInRepository
    private let withdrawalRepository: any WithdrawalRepository
    private let policyConsentRepository: any PolicyConsentRepository
    private let policyDocuments: [PolicyDocument]
    private let signInInvalidations: @Sendable () async -> AsyncStream<Void>
    private let now: @Sendable () -> Date

    private var state = SignInState.unknown
    private var subscribers = [UUID: AsyncStream<SignInState>.Continuation]()
    private var invalidationTask: Task<Void, Never>?

    private func startObservingInvalidations() {
        guard invalidationTask == nil else { return }
        let signInInvalidations = signInInvalidations
        invalidationTask = Task { [weak self] in
            for await _ in await signInInvalidations() {
                await self?.clearInvalidSignIn()
            }
        }
    }

    private func clearInvalidSignIn() async {
        try? await signInRepository.signOut()
        await clearAuthentication()
        update(.signedOut)
    }

    private func clearAuthentication() async {
        try? await authenticationRepository.clearAuthentication()
    }

    private func update(_ next: SignInState) {
        state = next
        for continuation in subscribers.values {
            continuation.yield(next)
        }
    }

    private func removeSubscriber(_ subscriberID: UUID) {
        subscribers.removeValue(forKey: subscriberID)
    }

}
