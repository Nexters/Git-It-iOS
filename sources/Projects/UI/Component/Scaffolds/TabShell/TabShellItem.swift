import DesignSystem

// MARK: - TabShellItem

public protocol TabShellItem: CaseIterable, Hashable, Identifiable, Sendable {
    var tabTitle: String { get }
    var tabSystemImage: String { get }
}

extension TabShellItem {

    public static func tabColor(isSelected: Bool) -> SemanticColorToken {
        isSelected ? .brandAccent : .mutedText
    }

}
