import DomainAuthentication
import InfrastructureAuthentication

// MARK: - CurrentSessionRepositoryAdapter

public struct CurrentSessionRepositoryAdapter: CurrentSessionRepository {

    // MARK: Lifecycle

    public init(keychainStore: KeychainStore) {
        coding = SessionRecordCoding(keychainStore: keychainStore)
    }

    // MARK: Public

    public func currentSession() async -> SessionRecord? {
        try? coding.load()
    }

    // MARK: Private

    private let coding: SessionRecordCoding

}
