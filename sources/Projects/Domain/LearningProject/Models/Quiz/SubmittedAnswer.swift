public struct SubmittedAnswer: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        selectedIndex: Int?,
        text: String?,
        correct: Bool?,
    ) {
        self.selectedIndex = selectedIndex
        self.text = text
        self.correct = correct
    }

    // MARK: Public

    /// 객관식에서 고른 선택지 index. 서술형에서는 비어 있습니다.
    public let selectedIndex: Int?
    /// 서술형 답안 원문. 객관식에서는 비어 있습니다.
    public let text: String?
    /// 서버가 채점한 정답 여부. 서버가 서술형을 채점하지 않으므로 서술형에서는 비어 있습니다.
    public let correct: Bool?

}
