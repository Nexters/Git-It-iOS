import InfrastructureCache

/// Infrastructure `UserDefaultsStore` 위에서 문서별 정책 동의 기록을 설치 단위로 보존한다.
/// 로그아웃과 무관하게 유지되고 앱 데이터 삭제로 저장된 `UserDefaults` 항목이 사라지면 함께
/// 사라진다.
public struct LocalPolicyConsentStore: PolicyConsentStore {

    // MARK: Lifecycle

    public init(store: UserDefaultsStore<[PolicyConsentRecordDTO]>) {
        self.store = store
    }

    // MARK: Public

    public func records() async -> [PolicyConsentRecordDTO] {
        await store.value(forKey: Self.recordsKey) ?? []
    }

    public func saveRecord(_ record: PolicyConsentRecordDTO) async {
        var current = await records()
        current.removeAll { $0.documentIdentifier == record.documentIdentifier }
        current.append(record)
        await store.store(current, forKey: Self.recordsKey)
    }

    public func removeAll() async {
        await store.removeAll()
    }

    // MARK: Private

    private static let recordsKey = "records"

    private let store: UserDefaultsStore<[PolicyConsentRecordDTO]>

}
