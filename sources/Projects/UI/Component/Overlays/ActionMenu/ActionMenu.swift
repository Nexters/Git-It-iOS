import DesignSystem
import SwiftUI

public struct ActionMenu: View {

    // MARK: Lifecycle

    public init(
        items: [Item],
        onSelect: @escaping (Item.ID) -> Void = { _ in },
    ) {
        self.items = items
        self.onSelect = onSelect
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    onSelect(item.id)
                } label: {
                    StyledText.body2(item.title, color: Constant.titleColor)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: Self.itemMinimumHeight(
                                itemCount: items.count
                            ),
                            alignment: .leading,
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.accessibilityLabel)
            }
        }
        .frame(
            minHeight: Self.contentMinimumHeight(
                itemCount: items.count
            )
        )
        .padding(.top, Constant.topPadding)
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.bottom, Constant.bottomPadding)
        .frame(width: Constant.menuWidth)
        .background(
            Color(designSystem: Constant.backgroundColor),
            in: RoundedRectangle(designSystem: .large),
        )
    }

    // MARK: Internal

    static var menuWidth: CGFloat {
        Constant.menuWidth
    }

    static var menuHeight: CGFloat {
        Constant.menuHeight
    }

    static var topPadding: CGFloat {
        Constant.topPadding
    }

    static var horizontalPadding: CGFloat {
        Constant.horizontalPadding
    }

    static var bottomPadding: CGFloat {
        Constant.bottomPadding
    }

    static var availableContentHeight: CGFloat {
        Constant.menuHeight
            - Constant.topPadding
            - Constant.bottomPadding
    }

    static func itemMinimumHeight(itemCount: Int) -> CGFloat {
        guard itemCount > 0 else { return Constant.itemMinimumHeight }

        return max(
            Constant.itemMinimumHeight,
            availableContentHeight / CGFloat(itemCount),
        )
    }

    static func contentMinimumHeight(itemCount: Int) -> CGFloat {
        max(
            availableContentHeight,
            itemMinimumHeight(itemCount: itemCount) * CGFloat(max(itemCount, 0)),
        )
    }

    static func menuMinimumHeight(itemCount: Int) -> CGFloat {
        Constant.topPadding
            + contentMinimumHeight(itemCount: itemCount)
            + Constant.bottomPadding
    }

    // MARK: Private

    private let items: [Item]
    private let onSelect: (Item.ID) -> Void

}

#Preview("Action Menu") {
    ActionMenu(
        items: [
            .init(
                id: "delete",
                title: "프로젝트 삭제",
                accessibilityLabel: "학습 프로젝트 삭제 모드 열기",
            ),
            .init(
                id: "close",
                title: "메뉴 닫기",
                accessibilityLabel: "프로젝트 메뉴 닫기",
            ),
        ]
    )
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .designSystemBackground(.grey700)
}
