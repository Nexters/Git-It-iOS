import DataShared

public struct LocalPolicyConsentStore: Sendable {

    // MARK: Lifecycle

    public init(storage: any KeyValueStorage) {
        self.storage = storage
    }

    // MARK: Public

    public func records() async -> [PolicyConsentRecordDTO] {
        await storage.value([PolicyConsentRecordDTO].self, forKey: Self.recordsKey) ?? []
    }

    public func saveRecord(_ record: PolicyConsentRecordDTO) async {
        var current = await records()
        current.removeAll { $0.documentIdentifier == record.documentIdentifier }
        current.append(record)
        await storage.setValue(current, forKey: Self.recordsKey)
    }

    public func removeAll() async {
        await storage.removeAllValues()
    }

    // MARK: Private

    private static let recordsKey = "records"

    private let storage: any KeyValueStorage

}
