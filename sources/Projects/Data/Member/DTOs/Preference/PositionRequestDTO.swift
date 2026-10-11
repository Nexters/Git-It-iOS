public struct PositionRequestDTO: Encodable, Equatable, Sendable {
    public init(position: PositionDTO) {
        self.position = position
    }

    public let position: PositionDTO
}
