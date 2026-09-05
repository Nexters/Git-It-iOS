import Foundation
import InfrastructureStorage

// MARK: - SharedSessionStateMarkerCoding

/// 본 앱이 기록하고 Share Extension이 읽는 세션 상태 마커를 다룬다. 마커에는 토큰이나
/// 개인정보를 담지 않고 "본 앱이 실행된 적이 있는지"와 "로그인 상태인지"만 남긴다.
public struct SharedSessionStateMarkerCoding: Sendable {

    // MARK: Lifecycle

    public init(userDefaults: UserDefaults) {
        store = UserDefaultsStore<Marker>(
            namespace: SharedSessionLayout.namespace,
            userDefaults: userDefaults,
        )
    }

    // MARK: Public

    /// 마커가 없거나 알 수 없는 형식이면 `nil`을 돌려준다. 호출자는 이를 "본 앱이 아직
    /// 실행되지 않음"으로 해석한다.
    public func loadSignedInState() async -> Bool? {
        guard
            let marker = await store.value(forKey: SharedSessionLayout.stateMarkerKey),
            marker.schemaVersion == SharedSessionLayout.markerSchemaVersion
        else { return nil }
        return marker.isSignedIn
    }

    public func save(
        isSignedIn: Bool,
        updatedAt: Date = Date(),
    ) async {
        await store.store(
            Marker(
                schemaVersion: SharedSessionLayout.markerSchemaVersion,
                isSignedIn: isSignedIn,
                updatedAt: updatedAt,
            ),
            forKey: SharedSessionLayout.stateMarkerKey,
        )
    }

    // MARK: Private

    private struct Marker: Codable, Sendable {
        let schemaVersion: Int
        let isSignedIn: Bool
        let updatedAt: Date
    }

    private let store: UserDefaultsStore<Marker>

}
