enum TabShellPreviewItem: String, TabShellItem {
    case home
    case project
    case saved
    case profile

    // MARK: Internal

    var id: Self {
        self
    }

    var tabTitle: String {
        switch self {
        case .home: "홈"
        case .project: "프로젝트"
        case .saved: "저장"
        case .profile: "마이"
        }
    }

    var tabSystemImage: String {
        switch self {
        case .home: "ic-home"
        case .project: "ic-file-text"
        case .saved: "ic-bookmark"
        case .profile: "ic-user"
        }
    }
}
