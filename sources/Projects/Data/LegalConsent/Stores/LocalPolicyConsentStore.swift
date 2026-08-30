import InfrastructureStorage

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
