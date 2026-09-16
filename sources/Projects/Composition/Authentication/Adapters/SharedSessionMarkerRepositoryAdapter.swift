import DataAuthentication
import DomainAuthentication

// MARK: - SharedSessionMarkerRepositoryAdapter

public struct SharedSessionMarkerRepositoryAdapter: SharedSessionMarkerRepository {

    // MARK: Lifecycle

    public init(markerCoding: SharedSessionStateMarkerCoding) {
        self.markerCoding = markerCoding
    }

    // MARK: Public

    public func signedInState() async -> Bool? {
        await markerCoding.loadSignedInState()
    }

    // MARK: Private

    private let markerCoding: SharedSessionStateMarkerCoding

}
