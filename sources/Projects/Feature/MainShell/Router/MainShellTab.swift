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
        case .home: LocalizedText.MainShell.Tab.Home.title
        case .projects: LocalizedText.MainShell.Tab.Projects.title
        case .saved: LocalizedText.MainShell.Tab.Saved.title
        case .settings: LocalizedText.MainShell.Tab.Settings.title
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
