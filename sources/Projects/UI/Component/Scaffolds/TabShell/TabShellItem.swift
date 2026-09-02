import DesignSystem

// MARK: - TabShellItem

public protocol TabShellItem: CaseIterable, Hashable, Identifiable, Sendable {
    var tabTitle: String { get }
    var tabSystemImage: String { get }
}

extension TabShellItem {

    /// 탭 아이콘과 라벨 색. 기본은 비활성 라벨 색이고 선택은 브랜드 강조 색이다.
    public static func tabColor(isSelected: Bool) -> SemanticColorToken {
        isSelected ? .brandAccent : .mutedText
    }

}
