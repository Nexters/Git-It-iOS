public struct ProjectListResponseDTO: Decodable, Equatable, Sendable {
    public init(
        items: [ProjectListItemDTO],
        hasNext: Bool,
    ) {
        self.items = items
        self.hasNext = hasNext
    }

    public let items: [ProjectListItemDTO]
    public let hasNext: Bool
}
