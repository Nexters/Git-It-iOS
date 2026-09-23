import UIComponent

public enum MainShellTab: String, CaseIterable, Hashable, Identifiable, Sendable, TabShellItem {
    case home
    case projects
    case saved
    case settings

    // MARK: Public

    public var id: String {
        rawValue
    }

    public var tabTitle: String {
        switch self {
        case .home: LocalizedText.MainShell.tabHomeTitle
        case .projects: LocalizedText.MainShell.tabProjectsTitle
        case .saved: LocalizedText.MainShell.tabSavedTitle
        case .settings: LocalizedText.MainShell.tabSettingsTitle
        }
    }

    public var tabSystemImage: String {
        switch self {
        case .home: "ic-home"
        case .projects: "ic-file-text"
        case .saved: "ic-bookmark"
        case .settings: "ic-user"
        }
    }
}
