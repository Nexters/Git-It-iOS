import DataShared
import Foundation

// MARK: - SharedSessionStateMarkerCoding

public struct SharedSessionStateMarkerCoding: Sendable {

    // MARK: Lifecycle

    public init(storage: any KeyValueStorage) {
        self.storage = storage
    }

    // MARK: Public

    public static let stateMarkerKey = "stateMarker"
    public static let markerSchemaVersion = 1

    public func loadSignedInState() async -> Bool? {
        guard
            let marker = await storage.value(
                Marker.self,
                forKey: Self.stateMarkerKey,
            ),
            marker.schemaVersion == Self.markerSchemaVersion
        else { return nil }
        return marker.isSignedIn
    }

    public func save(
        isSignedIn: Bool,
        updatedAt: Date = Date(),
    ) async {
        await storage.setValue(
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

    private let storage: any KeyValueStorage

}
