import Foundation
import InfrastructureStorage

// MARK: - SharedSessionStateMarkerCoding

public struct SharedSessionStateMarkerCoding: Sendable {

    // MARK: Lifecycle

    public init(userDefaults: UserDefaults) {
        store = UserDefaultsStore<Marker>(
            namespace: SharedSessionLayout.namespace,
            userDefaults: userDefaults,
        )
    }

    // MARK: Public

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
