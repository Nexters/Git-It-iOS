public actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func store(
        _ value: Value,
        forKey key: Key,
    ) {
        storage[key] = value
    }

    public func value(forKey key: Key) -> Value? {
        storage[key]
    }

    public func removeValue(forKey key: Key) {
        storage.removeValue(forKey: key)
    }

    public func removeAll() {
        storage.removeAll()
    }

    // MARK: Private

    private var storage = [Key: Value]()

}
