public struct CareerLevelRequestDTO: Encodable, Equatable, Sendable {
    public init(careerLevel: CareerLevelDTO) {
        self.careerLevel = careerLevel
    }

    public let careerLevel: CareerLevelDTO
}
