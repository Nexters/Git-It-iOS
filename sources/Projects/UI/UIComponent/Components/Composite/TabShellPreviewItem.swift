/// 프리뷰 전용 타입은 컴포넌트의 공개 계약이 아니므로 중첩하지 않고 독립 파일에 둡니다.
enum TabShellPreviewItem: String, TabShellItem {
    case home
    case saved
    case profile

    var id: Self { self }

    var tabTitle: String {
        switch self {
        case .home: "홈"
        case .saved: "저장"
        case .profile: "프로필"
        }
    }

    var tabSystemImage: String {
        switch self {
        case .home: "house"
        case .saved: "bookmark"
        case .profile: "person"
        }
    }
}
