import DataShared
import DomainAuthentication

// MARK: - CurrentSessionRepositoryAdapter

public struct CurrentSessionRepositoryAdapter: CurrentSessionRepository {

    // MARK: Lifecycle

    public init(secureStorage: any SecureValueStorage) {
        coding = SessionRecordCoding(secureStorage: secureStorage)
    }

    // MARK: Public

    public func currentSession() async -> SessionRecord? {
        try? coding.load()
    }

    // MARK: Private

    private let coding: SessionRecordCoding

}
