import AuthenticationServices
import Foundation

public struct AppleCredentialStateProvider: Sendable {

    // MARK: Lifecycle

    public init() {
        stateLookup = { userID in
            try await Self.liveState(for: userID)
        }
    }

    init(stateLookup: @escaping @Sendable (String) async throws -> AppleCredentialState) {
        self.stateLookup = stateLookup
    }

    // MARK: Public

    public enum PlatformState: Sendable {
        case authorized
        case revoked
        case notFound
        case transferred
    }

    public static func map(_ state: PlatformState) -> AppleCredentialState {
        switch state {
        case .authorized: .authorized
        case .revoked: .revoked
        case .notFound: .notFound
        case .transferred: .transferred
        }
    }

    public func state(for userID: String) async -> AppleCredentialState {
        (try? await stateLookup(userID)) ?? .temporarilyUnavailable
    }

    // MARK: Private

    private let stateLookup: @Sendable (String) async throws -> AppleCredentialState

    private static func liveState(for userID: String) async throws -> AppleCredentialState {
        try await withCheckedThrowingContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let mapped: PlatformState =
                    switch state {
                    case .authorized: .authorized
                    case .revoked: .revoked
                    case .notFound: .notFound
                    case .transferred: .transferred
                    @unknown default: .notFound
                    }
                continuation.resume(returning: map(mapped))
            }
        }
    }

}
