import DataShared
import Foundation
import Synchronization

// MARK: - InMemorySecureValueStorage

final class InMemorySecureValueStorage: SecureValueStorage {

    // MARK: Lifecycle

    init(failure: SecureValueStorageError? = nil) {
        self.failure = Mutex(failure)
    }

    // MARK: Internal

    func data(forKey key: String) throws(SecureValueStorageError) -> Data? {
        try throwIfFailing()
        return values.withLock { $0[key] }
    }

    func setData(_ data: Data, forKey key: String) throws(SecureValueStorageError) {
        try throwIfFailing()
        values.withLock { $0[key] = data }
    }

    func removeData(forKey key: String) throws(SecureValueStorageError) {
        try throwIfFailing()
        values.withLock { $0[key] = nil }
    }

    func fail(with error: SecureValueStorageError?) {
        failure.withLock { $0 = error }
    }

    func storedData(forKey key: String) -> Data? {
        values.withLock { $0[key] }
    }

    // MARK: Private

    private let values = Mutex<[String: Data]>([:])
    private let failure: Mutex<SecureValueStorageError?>

    private func throwIfFailing() throws(SecureValueStorageError) {
        if let error = failure.withLock({ $0 }) {
            throw error
        }
    }

}
