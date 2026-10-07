import Foundation
import InfrastructureStorage

// MARK: - SharedSessionStateMarkerCoding

public struct SharedSessionStateMarkerCoding: Sendable {

    // MARK: Lifecycle

    public init(userDefaults: UserDefaults) {
        store = UserDefaultsStore<Marker>(
            namespace: AppGroupUserDefaults.sharedSessionNamespace,
            userDefaults: userDefaults,
        )
    }

    // MARK: Public

    public static let stateMarkerKey = "stateMarker"
    public static let markerSchemaVersion = 1

    public func loadSignedInState() async -> Bool? {
        guard
            let marker = await store.value(forKey: Self.stateMarkerKey),
            marker.schemaVersion == Self.markerSchemaVersion
        else { return nil }
        return marker.isSignedIn
    }

    public func save(
        isSignedIn: Bool,
        updatedAt: Date = Date(),
    ) async {
        await store.store(
            Marker(
                schemaVersion: Self.markerSchemaVersion,
                isSignedIn: isSignedIn,
                updatedAt: updatedAt,
            ),
            forKey: Self.stateMarkerKey,
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
