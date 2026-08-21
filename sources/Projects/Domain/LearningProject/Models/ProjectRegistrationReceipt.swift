/// UC02 프로젝트 생성 요청의 raw 접수 결과다. 서버 `requestStatus` 값을 그대로 보존하며
/// generation 진행 상태 머신으로 사용하지 않는다(GAP-014-003, GAP-014-004).
public struct ProjectRegistrationReceipt: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        projectID: String,
        requestStatus: String,
        quizLevel: QuizLevel,
    ) {
        self.projectID = projectID
        self.requestStatus = requestStatus
        self.quizLevel = quizLevel
    }

    // MARK: Public

    public let projectID: String
    public let requestStatus: String
    public let quizLevel: QuizLevel

}
