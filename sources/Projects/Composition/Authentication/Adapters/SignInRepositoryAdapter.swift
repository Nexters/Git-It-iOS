import DataAuthentication
import DataShared
import DomainUseCaseDependency
import DomainUseCaseInterface
import Foundation

// MARK: - SignInRepositoryAdapter

public struct SignInRepositoryAdapter: SignInRepository {

    // MARK: Lifecycle

    public init(
        remote: AuthenticationRemote,
        sessionStorage: any SecureValueStorage,
        appleIdentityStorage: any SecureValueStorage,
        requestCredentialProvider: RequestCredentialProvider,
        sharedSessionStateMarkerCoding: SharedSessionStateMarkerCoding?,
    ) {
        self.remote = remote
        self.requestCredentialProvider = requestCredentialProvider
        self.sharedSessionStateMarkerCoding = sharedSessionStateMarkerCoding
        coding = SessionRecordStorageCoding(storage: sessionStorage)
        appleIdentityStore = AppleIdentityStore(storage: appleIdentityStorage)
    }

    // MARK: Public

    public func start(with grant: AuthenticationGrant) async throws -> SignInRecord {
        do {
            let response = try await remote.appleLogin(idToken: grant.id)
            try coding.save(StoredSessionRecord(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                accessTokenExpiresAt: nil,
                refreshTokenExpiresAt: nil,
                needsCuration: response.needsCuration,
                acceptedLegalVersions: [],
                acceptedAt: nil,
            ))
            await sharedSessionStateMarkerCoding?.save(isSignedIn: true)
            guard let accountID = try appleIdentityStore.load() else {
                throw AccountError.temporarilyUnavailable
            }
            return SignInRecord(
                account: SignedInAccount(
                    id: accountID,
                    displayName: nil,
                    needsCuration: response.needsCuration,
                ),
                isAccountAvailable: true,
            )
        } catch let error as AuthenticationServiceError {
            throw domainError(for: error)
        } catch is SecureValueStorageError {
            throw AccountError.temporarilyUnavailable
        }
    }

    public func restore() async throws -> SignInRecord? {
        do {
            guard
                let record = try coding.load(),
                let accountID = try appleIdentityStore.load()
            else { return nil }
            return SignInRecord(
                account: SignedInAccount(
                    id: accountID,
                    displayName: nil,
                    needsCuration: record.needsCuration,
                ),
                isAccountAvailable: true,
            )
        } catch is SecureValueStorageError {
            throw AccountError.temporarilyUnavailable
        }
    }

    public func signOut() async throws {
        do {
            try coding.delete()
            await sharedSessionStateMarkerCoding?.save(isSignedIn: false)
        } catch is SecureValueStorageError {
            throw AccountError.temporarilyUnavailable
        }
    }

    public func sharedSignInState() async -> Bool? {
        await sharedSessionStateMarkerCoding?.loadSignedInState()
    }

    public func hasUsableCredential() async -> Bool {
        await requestCredentialProvider.credential() != .signedOut
    }

    // MARK: Private

    private let remote: AuthenticationRemote
    private let coding: SessionRecordStorageCoding
    private let appleIdentityStore: AppleIdentityStore
    private let requestCredentialProvider: RequestCredentialProvider
    private let sharedSessionStateMarkerCoding: SharedSessionStateMarkerCoding?

    private func domainError(for error: AuthenticationServiceError) -> AccountError {
        switch error {
        case .unauthorized,
             .invalidRequest:
            .unauthorized

        case .temporarilyUnavailable,
             .transport,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
