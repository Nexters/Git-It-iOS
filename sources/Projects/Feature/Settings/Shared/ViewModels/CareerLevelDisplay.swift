import DomainUserInfo
import UIComponent

enum CareerLevelDisplay {

    static let orderedLevels: [CareerLevel] = [.entry, .junior, .middle, .senior]

    static var unselectedTitle: String {
        LocalizedText.Settings.CareerLevel.Unselected.title
    }

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
        case .entry: LocalizedText.Settings.CareerLevel.Entry.title
        case .junior: LocalizedText.Settings.CareerLevel.Junior.title
        case .middle: LocalizedText.Settings.CareerLevel.Middle.title
        case .senior: LocalizedText.Settings.CareerLevel.Senior.title
        @unknown default: ""
        }
    }

    static func description(for level: CareerLevel) -> String {
        switch level {
        case .entry: LocalizedText.Settings.CareerLevel.Entry.description
        case .junior: LocalizedText.Settings.CareerLevel.Junior.description
        case .middle: LocalizedText.Settings.CareerLevel.Middle.description
        case .senior: LocalizedText.Settings.CareerLevel.Senior.description
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

    static func settingValue(for level: CareerLevel?) -> String {
        level.map(title(for:)) ?? unselectedTitle
    }

}
