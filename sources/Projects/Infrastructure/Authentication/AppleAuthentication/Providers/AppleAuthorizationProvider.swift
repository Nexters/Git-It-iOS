import AuthenticationServices
import Synchronization

// MARK: - AppleAuthorizationProvider

public final class AppleAuthorizationProvider: NSObject, Sendable {

    // MARK: Lifecycle

    public init(
        randomValue: @escaping @Sendable (Int) throws -> String = { try SecureRandomGenerator().value(length: $0) },
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.randomValue = randomValue
        self.now = now
    }

    // MARK: Public

    public func beginAuthorization(expiresIn: TimeInterval = 300) throws -> AppleAuthorizationAttempt {
        let attempt = AppleAuthorizationAttempt(
            id: try randomValue(24),
            nonce: try randomValue(32),
            state: try randomValue(24),
            expiresAt: now().addingTimeInterval(expiresIn),
        )
        state.withLock { $0.currentAttempt = attempt }
        return attempt
    }

    public func startAuthorization(expiresIn: TimeInterval = 300) throws -> AppleAuthorizationAttempt {
        let attempt = try beginAuthorization(expiresIn: expiresIn)
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = attempt.nonce
        request.state = attempt.state
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        state.withLock { $0.authorizationController = controller }
        controller.performRequests()
        return attempt
    }

    public func complete(
        credential: AppleCredential,
        state: String,
        attemptID: String,
        now completionDate: Date? = nil,
    ) throws -> AppleCredential {
        try self.state.withLock { protectedState in
            guard
                let attempt = protectedState.currentAttempt,
                attempt.id == attemptID,
                attempt.state == state
            else {
                throw AppleAuthorizationError.invalidCallback
            }
            protectedState.currentAttempt = nil
            guard (completionDate ?? now()) <= attempt.expiresAt else { throw AppleAuthorizationError.expiredAttempt }
            guard credential.identityToken != nil, credential.authorizationCode != nil else {
                throw AppleAuthorizationError.missingCredential
            }
        }
        return credential
    }

    public func cancel(attemptID: String) throws {
        try state.withLock { protectedState in
            guard protectedState.currentAttempt?.id == attemptID else { throw AppleAuthorizationError.invalidCallback }
            protectedState.currentAttempt = nil
        }
        throw AppleAuthorizationError.cancelled
    }

    public func authorize(expiresIn: TimeInterval = 300) async throws -> AppleCredential {
        let attempt = try startAuthorization(expiresIn: expiresIn)
        return try await withCheckedThrowingContinuation { continuation in
            state.withLock { $0.pendingContinuation = (attempt.id, continuation) }
        }
    }

    // MARK: Private

    private struct State {
        var authorizationController: ASAuthorizationController?
        var currentAttempt: AppleAuthorizationAttempt?
        var pendingContinuation: (attemptID: String, continuation: CheckedContinuation<AppleCredential, Error>)?
    }

    private let randomValue: @Sendable (Int) throws -> String
    private let now: @Sendable () -> Date
    private let state = Mutex(State())

    private func resumePendingContinuation(
        attemptID: String,
        with result: Result<AppleCredential, Error>,
    ) {
        let continuation = state.withLock { protectedState -> CheckedContinuation<AppleCredential, Error>? in
            guard protectedState.pendingContinuation?.attemptID == attemptID else { return nil }
            defer { protectedState.pendingContinuation = nil }
            return protectedState.pendingContinuation?.continuation
        }
        continuation?.resume(with: result)
    }

}

// MARK: ASAuthorizationControllerDelegate

extension AppleAuthorizationProvider: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization,
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let coreCredential = AppleCredential(
            userID: credential.user,
            identityToken: credential.identityToken,
            authorizationCode: credential.authorizationCode,
            email: credential.email,
            fullName: credential.fullName?.formatted(),
        )
        guard let attempt = state.withLock({ $0.currentAttempt }) else { return }
        do {
            let result = try complete(
                credential: coreCredential,
                state: attempt.state,
                attemptID: attempt.id,
            )
            resumePendingContinuation(attemptID: attempt.id, with: .success(result))
        } catch {
            resumePendingContinuation(attemptID: attempt.id, with: .failure(error))
        }
    }

    public func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error,
    ) {
        guard let attempt = state.withLock({ $0.currentAttempt }) else { return }
        if (error as? ASAuthorizationError)?.code == .canceled {
            try? cancel(attemptID: attempt.id)
            resumePendingContinuation(attemptID: attempt.id, with: .failure(AppleAuthorizationError.cancelled))
        } else {
            state.withLock { protectedState in
                if protectedState.currentAttempt?.id == attempt.id {
                    protectedState.currentAttempt = nil
                }
            }
            resumePendingContinuation(attemptID: attempt.id, with: .failure(AppleAuthorizationError.unavailable))
        }
    }
}
