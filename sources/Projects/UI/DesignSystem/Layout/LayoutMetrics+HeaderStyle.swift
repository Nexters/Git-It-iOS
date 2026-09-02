extension LayoutMetrics {

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
