// MARK: - PositionDTO

public struct PositionDTO: Codable, Equatable, Sendable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public let rawValue: String

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - CareerLevelDTO

public struct CareerLevelDTO: Codable, Equatable, Sendable {
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public let rawValue: String

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - CurationRequestDTO

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

// MARK: - PositionRequestDTO

public struct PositionRequestDTO: Encodable, Equatable, Sendable {
    public init(position: PositionDTO) {
        self.position = position
    }

    public let position: PositionDTO
}

// MARK: - CareerLevelRequestDTO

public struct CareerLevelRequestDTO: Encodable, Equatable, Sendable {
    public init(careerLevel: CareerLevelDTO) {
        self.careerLevel = careerLevel
    }

    public let careerLevel: CareerLevelDTO
}
