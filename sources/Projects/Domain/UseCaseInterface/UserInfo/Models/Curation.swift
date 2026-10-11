public struct Curation: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) {
        self.position = position
        self.careerLevel = careerLevel
    }

    // MARK: Public

    public let position: MemberPosition
    public let careerLevel: CareerLevel

}
