import DomainMember

/// 설정 흐름(프로필 배지·설정 값·개발 분야 선택)이 공유하는 직군 표시 값.
/// 순서는 Figma `1535:18281`(개발 분야 선택)의 카드 순서를 따른다.
enum PositionDisplay {

    // MARK: Internal

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

    /// 미설정(`nil`)이면 FR-006a의 "선택 안 함"을 돌려준다.
    static func settingValue(for position: MemberPosition?) -> String {
        position.map(title(for:)) ?? unselectedTitle
    }

}
