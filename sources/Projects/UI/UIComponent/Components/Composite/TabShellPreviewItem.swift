/// 프리뷰 전용 타입은 컴포넌트의 공개 계약이 아니므로 중첩하지 않고 독립 파일에 둡니다.
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
