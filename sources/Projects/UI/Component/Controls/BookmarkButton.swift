import DesignSystem
import SwiftUI

// MARK: - BookmarkButton

/// 저장 여부를 값으로 받는 북마크 버튼.
///
/// 접근성 라벨은 생략할 수 없다. 아이콘 이름이 아니라 동작 이름을 받는다.
/// 크기 결정 방식은 `SizingMode.hug`이며 히트 영역만 44 이상으로 넓힌다.
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
                .designSystemForeground(isSaved ? .blue100 : .grey400)
                .frame(
                    width: ControlSizeToken.minimumTouch.cgFloatValue,
                    height: ControlSizeToken.minimumTouch.cgFloatValue,
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressOverlay)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSaved ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Internal

    static func symbol(isSaved: Bool) -> String {
        isSaved ? "bookmark.fill" : "bookmark"
    }

    // MARK: Private

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
