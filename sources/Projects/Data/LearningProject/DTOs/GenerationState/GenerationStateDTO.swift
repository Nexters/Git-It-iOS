public struct GenerationStateDTO: Codable, Equatable, Sendable {

    // MARK: Lifecycle

    public init(records: [GenerationRecordDTO]) {
        self.records = records
    }

    // MARK: Public

    public let records: [GenerationRecordDTO]

}
