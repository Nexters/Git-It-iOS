public struct CurationRequestDTO: Encodable, Equatable, Sendable {
    public init(
        position: PositionDTO,
        careerLevel: CareerLevelDTO,
    ) {
        self.position = position
        self.careerLevel = careerLevel
    }

    public let position: PositionDTO
    public let careerLevel: CareerLevelDTO
}
