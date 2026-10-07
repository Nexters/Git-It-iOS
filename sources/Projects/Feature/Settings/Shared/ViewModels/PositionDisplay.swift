import DomainMember

enum PositionDisplay {

    static let orderedPositions: [MemberPosition] = [.frontend, .backend, .ios, .android]

    static let unselectedTitle = "선택 안 함"

    static func identifier(for position: MemberPosition) -> String {
        switch position {
        case .ios: "ios"
        case .android: "android"
        case .backend: "backend"
        case .frontend: "frontend"
        @unknown default: "unknown"
        }
    }

    static func position(forIdentifier identifier: String) -> MemberPosition? {
        orderedPositions.first { self.identifier(for: $0) == identifier }
    }

    static func title(for position: MemberPosition) -> String {
        switch position {
        case .ios: "iOS"
        case .android: "Android"
        case .backend: "Back-end"
        case .frontend: "Front-end"
        @unknown default: ""
        }
    }

    static func settingValue(for position: MemberPosition?) -> String {
        position.map(title(for:)) ?? unselectedTitle
    }

}
