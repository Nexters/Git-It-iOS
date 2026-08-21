/// 서술형 제출 결과. 클라이언트는 `correct`를 생성하지 않는다 — 서버가 correct 필드를
/// 내려주지 않으면 이 모델도 correct를 갖지 않는다.
public struct EssayAnswerResult: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        explanation: String,
        rubric: Rubric,
    ) {
        self.explanation = explanation
        self.rubric = rubric
    }

    // MARK: Public

    public let explanation: String
    public let rubric: Rubric

}
