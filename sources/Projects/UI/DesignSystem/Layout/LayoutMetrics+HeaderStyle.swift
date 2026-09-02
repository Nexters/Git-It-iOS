extension LayoutMetrics {

    /// 헤더 종류. 종류마다 고정 높이를 가지며 스크롤과 무관하게 유지된다.
    ///
    /// 높이는 Figma `Toolbar - Top`의 `Type` 변형 실측값이다 —
    /// Default 50 · Inline Title 43 · Inline User 74 · Large Title 99.
    public enum HeaderStyle: Sendable, Equatable, CaseIterable {
        case plain
        case inlineTitle
        case inlineUser
        case largeTitle

        // MARK: Public

        public var height: Double {
            switch self {
            case .plain:
                50
            case .inlineTitle:
                43
            case .inlineUser:
                74
            case .largeTitle:
                99
            }
        }
    }

}
