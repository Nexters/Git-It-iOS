import DesignSystem
import SwiftUI

// MARK: - BookmarkButton

public struct BookmarkButton: View {

    // MARK: Lifecycle

    public init(
        isSaved: Bool,
        accessibilityLabel: String,
        onTap: @escaping () -> Void,
    ) {
        self.isSaved = isSaved
        self.accessibilityLabel = accessibilityLabel
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            Image(systemName: symbol)
                .font(.system(size: Constant.glyphSize))
                .designSystemForeground(isSaved ? .blue100 : .grey400)
                .frame(width: Constant.surfaceWidth, height: Constant.surfaceHeight)
                .designSystemBackground(.raisedBackground)
                .designSystemCornerRadius(.large)
                .frame(
                    minWidth: ControlSizeToken.minimumTouch.cgFloatValue,
                    minHeight: ControlSizeToken.minimumTouch.cgFloatValue,
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSaved ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Internal

    static func symbol(isSaved: Bool) -> String {
        isSaved ? "bookmark.fill" : "bookmark"
    }

    // MARK: Private

    private enum Constant {
        static let surfaceWidth: CGFloat = 40
        static let surfaceHeight: CGFloat = ControlSizeToken.action.cgFloatValue
        static let glyphSize: CGFloat = 16
    }

    private let isSaved: Bool
    private let accessibilityLabel: String
    private let onTap: () -> Void

    private var symbol: String {
        Self.symbol(isSaved: isSaved)
    }

}

#Preview("Bookmark Button") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        BookmarkButton(isSaved: false, accessibilityLabel: "저장하기") { }
        BookmarkButton(isSaved: true, accessibilityLabel: "저장 해제하기") { }
    }
    .padding(LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
