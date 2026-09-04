import DomainMember
import UIComponent

/// 설정 흐름(프로필 배지·설정 값·개발 수준 선택)이 공유하는 연차 표시 값.
/// 문구·순서·일러스트는 온보딩 `CareerSelectionScreen.Display`와 Figma `1535:18378`을 따른다.
enum CareerLevelDisplay {

    // MARK: Internal

    static let orderedLevels: [CareerLevel] = [.entry, .junior, .middle, .senior]

    static let unselectedTitle = "선택 안 함"

    static func identifier(for level: CareerLevel) -> String {
        switch level {
        case .entry: "entry"
        case .junior: "junior"
        case .middle: "midLevel"
        case .senior: "senior"
        @unknown default: "unknown"
        }
    }

    static func level(forIdentifier identifier: String) -> CareerLevel? {
        orderedLevels.first { self.identifier(for: $0) == identifier }
    }

    static func title(for level: CareerLevel) -> String {
        switch level {
        case .entry: "입문"
        case .junior: "주니어"
        case .middle: "미들"
        case .senior: "시니어"
        @unknown default: ""
        }
    }

    static func description(for level: CareerLevel) -> String {
        switch level {
        case .entry: "프로젝트 코드를 처음 살펴봐요."
        case .junior: "작은 기능 단위로 코드를 이해할 수 있어요."
        case .middle: "프로젝트 구조와 흐름을 함께 살펴봐요."
        case .senior: "설계 의도와 변경 영향을 분석할 수 있어요."
        @unknown default: ""
        }
    }

    static func illust(for level: CareerLevel) -> ResourceImage.Asset.Illust {
        switch level {
        case .entry: .levelEntry
        case .junior: .levelJunior
        case .middle: .levelMiddle
        case .senior: .levelSenior
        @unknown default: .levelEntry
        }
    }

    /// 미설정(`nil`)이면 FR-006a의 "선택 안 함"을 돌려준다.
    static func settingValue(for level: CareerLevel?) -> String {
        level.map(title(for:)) ?? unselectedTitle
    }

}
