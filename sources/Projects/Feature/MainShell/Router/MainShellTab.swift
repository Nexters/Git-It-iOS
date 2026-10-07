import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
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
        case .home: "Home"
        case .projects: "프로젝트"
        case .saved: "저장"
        case .settings: "마이"
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
