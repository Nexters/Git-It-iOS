import DesignSystem
import SwiftUI

// MARK: - BookmarkButton

public struct BookmarkButton: View {

    // MARK: Lifecycle

    public init(isSaved: Binding<Bool>) {
        _isSaved = isSaved
    }

    // MARK: Public

    public var body: some View {
        Button(action: { toggle() }) {
            Image(systemName: symbol)
                .font(.system(size: Constant.glyphSize))
                .designSystemForeground(isSaved ? .blue100 : .grey400)
                .frame(
                    width: Constant.surfaceWidth,
                    height: Constant.surfaceHeight,
                )
                .designSystemBackground(.grey500)
                .designSystemCornerRadius(.large)
                .frame(
                    minWidth: ControlSizeToken.minimumTouch.cgFloatValue,
                    minHeight: ControlSizeToken.minimumTouch.cgFloatValue,
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Internal

    static func symbol(isSaved: Bool) -> String {
        isSaved ? "bookmark.fill" : "bookmark"
    }

    func toggle() {
        isSaved.toggle()
    }

    // MARK: Private

    private enum Constant {
        static let surfaceWidth: CGFloat = 40
        static let surfaceHeight: CGFloat = ControlSizeToken.action.cgFloatValue
        static let glyphSize: CGFloat = 16
    }

    @Binding private var isSaved: Bool

    private var symbol: String {
        Self.symbol(isSaved: isSaved)
    }

}

#Preview("Bookmark Button") {
    HStack(spacing: LayoutToken.gutter) {
        BookmarkButton(isSaved: .constant(false))
        BookmarkButton(isSaved: .constant(true))
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
