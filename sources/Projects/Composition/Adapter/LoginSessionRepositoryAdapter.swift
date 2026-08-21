import DataAuthentication
import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - LoginSessionRepositoryAdapter

struct LoginSessionRepositoryAdapter: LoginSessionRepository {

    // MARK: Lifecycle

    init(
        remote: AuthenticationRemote,
        keychainStore: KeychainStore,
    ) {
        self.remote = remote
        self.keychainStore = keychainStore
    }

    // MARK: Internal

    func start(with grant: AuthenticationGrant) async throws -> AuthenticatedUser {
        do {
            let response = try await remote.appleLogin(idToken: grant.id.rawValue)
            try persist(response: response, userID: grant.id.rawValue)
            // 서버가 반환하는 사용자 식별자·표시 이름 필드가 없어 grant의 idToken을 임시
            // 식별자로 사용한다. 실제 사용자 프로필 조회가 추가되면 갱신해야 한다.
            return AuthenticatedUser(
                id: grant.id.rawValue,
                availability: .available,
                displayName: nil,
            )
        } catch let error as DataAuthenticationError {
            throw domainError(for: error)
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func restore() async throws -> AuthenticatedUser? {
        do {
            guard let accessToken = try loadString(.accessToken), !accessToken.isEmpty else { return nil }
            let userID = (try? loadString(.userID)) ?? accessToken
            return AuthenticatedUser(id: userID, availability: .available, displayName: nil)
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    func signOut() async throws {
        do {
            try keychainStore.delete(for: Key.accessToken.rawValue, in: namespace)
            try keychainStore.delete(for: Key.refreshToken.rawValue, in: namespace)
            try keychainStore.delete(for: Key.userID.rawValue, in: namespace)
        } catch is KeychainStoreError {
            throw LoginSessionError.temporarilyUnavailable
        }
    }

    // MARK: Private

    private typealias Key = SessionKeychainLayout.Key

    private let remote: AuthenticationRemote
    private let keychainStore: KeychainStore
    private let namespace = SessionKeychainLayout.namespace

    private func persist(
        response: LoginResponseDTO,
        userID: String,
    ) throws {
        try keychainStore.save(Data(response.accessToken.utf8), for: Key.accessToken.rawValue, in: namespace)
        try keychainStore.save(Data(response.refreshToken.utf8), for: Key.refreshToken.rawValue, in: namespace)
        try keychainStore.save(Data(userID.utf8), for: Key.userID.rawValue, in: namespace)
    }

    private func loadString(_ key: Key) throws -> String? {
        guard let data = try keychainStore.load(for: key.rawValue, in: namespace) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func domainError(for error: DataAuthenticationError) -> LoginSessionError {
        switch error {
        case .unauthorized:
            .refreshRejectedOrExpired

        case .invalidRequest:
            .accountUnavailable

        case .temporarilyUnavailable,
             .transport,
             .decoding,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
