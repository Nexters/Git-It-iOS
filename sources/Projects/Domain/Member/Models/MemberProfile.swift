public struct MemberProfile: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        name: String,
        email: String,
        position: MemberPosition?,
        careerLevel: CareerLevel?,
        statistics: LearningStatistics,
    ) {
        self.name = name
        self.email = email
        self.position = position
        self.careerLevel = careerLevel
        self.statistics = statistics
    }

    // MARK: Public

    public let name: String
    public let email: String
    /// 서버 null을 그대로 보존한다. 지원하지 않는 non-null raw value는 nil이 아니라
    /// decoding 오류로 처리해야 하며 이 필드로 치환하지 않는다.
    public let position: MemberPosition?
    /// 서버 null을 그대로 보존한다. 지원하지 않는 non-null raw value는 nil이 아니라
    /// decoding 오류로 처리해야 하며 이 필드로 치환하지 않는다.
    public let careerLevel: CareerLevel?
    public let statistics: LearningStatistics

}
