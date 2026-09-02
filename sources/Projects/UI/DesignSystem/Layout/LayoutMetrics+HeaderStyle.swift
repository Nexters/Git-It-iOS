extension LayoutMetrics {

    /// 헤더 종류. 종류마다 고정 높이를 가지며 스크롤과 무관하게 유지된다.
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
                64
            case .inlineUser:
                98
            case .largeTitle:
                120
            }
        }
    }
}
