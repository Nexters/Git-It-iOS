import Foundation

// MARK: - SecureValueStorage

public protocol SecureValueStorage: Sendable {
    func data(forKey key: String) throws(SecureValueStorageError) -> Data?
    func setData(
        _ data: Data,
        forKey key: String,
    ) throws(SecureValueStorageError)
    func removeData(forKey key: String) throws(SecureValueStorageError)
}
