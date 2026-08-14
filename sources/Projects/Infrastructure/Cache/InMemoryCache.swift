/// 키-값 쌍을 프로세스 메모리 범위에서만 보관하는 범용 기술 API다.
public actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {

    // MARK: Lifecycle

    /// 빈 캐시를 새로 만든다. 다른 인스턴스와 상태를 공유하지 않는다.
    public init() { }

    // MARK: Public

    /// 키에 값을 저장한다. 같은 키에 값이 이미 있으면 새 값으로 교체한다.
    public func store(
        _ value: Value,
        forKey key: Key,
    ) {
        storage[key] = value
    }

    /// 키에 저장된 값을 반환한다. 값이 없으면 오류 없이 `nil`을 반환한다.
    public func value(forKey key: Key) -> Value? {
        storage[key]
    }

    /// 키에 저장된 값을 제거한다. 값이 없어도 오류 없이 완료된다.
    public func removeValue(forKey key: Key) {
        storage.removeValue(forKey: key)
    }

    /// 저장된 모든 값을 제거한다.
    public func removeAll() {
        storage.removeAll()
    }

    // MARK: Private

    private var storage = [Key: Value]()

}
