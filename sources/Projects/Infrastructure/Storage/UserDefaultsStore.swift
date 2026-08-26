import Foundation

/// Codable 값을 `UserDefaults` 위에 영속 보관하는 범용 기술 API다.
public actor UserDefaultsStore<Value: Codable & Sendable> {

    // MARK: Lifecycle

    /// namespace로 격리된 저장소를 만든다. 같은 namespace를 쓰는 인스턴스끼리만 값을 공유한다.
    public init(
        namespace: String,
        userDefaults: UserDefaults = .standard,
    ) {
        self.namespace = namespace
        self.userDefaults = userDefaults
    }

    // MARK: Public

    /// 키에 값을 저장한다. 같은 키에 값이 이미 있으면 새 값으로 교체한다.
    public func store(
        _ value: Value,
        forKey key: String,
    ) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        userDefaults.set(data, forKey: storageKey(for: key))
    }

    /// 키에 저장된 값을 반환한다. 값이 없거나 디코딩할 수 없으면 오류 없이 `nil`을 반환한다.
    public func value(forKey key: String) -> Value? {
        guard let data = userDefaults.data(forKey: storageKey(for: key)) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    /// 키에 저장된 값을 제거한다. 값이 없어도 오류 없이 완료된다.
    public func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: storageKey(for: key))
    }

    /// 같은 namespace에 저장된 모든 값을 제거한다. 다른 namespace의 값에는 영향을 주지 않는다.
    public func removeAll() {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }

    // MARK: Private

    private let namespace: String
    private let userDefaults: UserDefaults

    private var keyPrefix: String {
        "\(namespace)."
    }

    private func storageKey(for key: String) -> String {
        "\(keyPrefix)\(key)"
    }

}
