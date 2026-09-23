import DomainUserInfo
import UIComponent

enum CareerLevelDisplay {

    static let orderedLevels: [CareerLevel] = [.entry, .junior, .middle, .senior]

    static var unselectedTitle: String {
        LocalizedText.Settings.careerLevelUnselectedTitle
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
        case .entry: LocalizedText.Settings.careerLevelEntryTitle
        case .junior: LocalizedText.Settings.careerLevelJuniorTitle
        case .middle: LocalizedText.Settings.careerLevelMiddleTitle
        case .senior: LocalizedText.Settings.careerLevelSeniorTitle
        @unknown default: ""
        }
    }

    static func description(for level: CareerLevel) -> String {
        switch level {
        case .entry: LocalizedText.Settings.careerLevelEntryDescription
        case .junior: LocalizedText.Settings.careerLevelJuniorDescription
        case .middle: LocalizedText.Settings.careerLevelMiddleDescription
        case .senior: LocalizedText.Settings.careerLevelSeniorDescription
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
