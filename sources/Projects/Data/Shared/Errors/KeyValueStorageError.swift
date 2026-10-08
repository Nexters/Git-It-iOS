// MARK: - KeyValueStorageError

public enum KeyValueStorageError: Error, Equatable, Sendable {
    case unavailable
    case unreadable
}
