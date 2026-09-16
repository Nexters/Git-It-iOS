import DataAuthentication
import DomainAuthentication

// MARK: - SharedSignInStateRepositoryAdapter

public struct SharedSignInStateRepositoryAdapter: SharedSignInStateRepository {

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
