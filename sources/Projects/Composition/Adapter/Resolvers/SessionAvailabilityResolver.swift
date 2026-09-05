import DomainAuthentication
import Foundation
import InfrastructureAuthentication

// MARK: - SessionAvailabilityResolver

/// 공유 저장소의 세션 상태 마커와 세션 기록으로 Extension이 등록을 진행할 수 있는지
/// 판정한다. 어떤 경로로도 토큰 갱신을 시도하지 않는다.
public struct SessionAvailabilityResolver: Sendable {

    // MARK: Lifecycle

    public init(
        markerCoding: SharedSessionStateMarkerCoding,
        keychainStore: KeychainStore,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.markerCoding = markerCoding
        sessionCoding = SessionRecordKeychainCoding(keychainStore: keychainStore)
        self.now = now
    }

    // MARK: Public

    public func callAsFunction() async -> SessionAvailability {
        guard let isSignedIn = await markerCoding.loadSignedInState() else {
            return .appLaunchRequired
        }
        guard isSignedIn else { return .signInRequired }
        guard
            let record = try? sessionCoding.load(),
            !record.tokens.accessToken.isEmpty
        else { return .signInRequired }
        if
            let expiresAt = record.tokens.accessTokenExpiresAt,
            expiresAt <= now()
        {
            return .signInRequired
        }
        return .available(accessToken: record.tokens.accessToken)
    }

    // MARK: Private

    private let markerCoding: SharedSessionStateMarkerCoding
    private let sessionCoding: SessionRecordKeychainCoding
    private let now: @Sendable () -> Date

}
