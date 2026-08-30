public protocol PolicyConsentStore: Sendable {
    func records() async -> [PolicyConsentRecordDTO]

    func saveRecord(_ record: PolicyConsentRecordDTO) async

    func removeAll() async
}
