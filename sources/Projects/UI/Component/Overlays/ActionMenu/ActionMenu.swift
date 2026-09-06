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
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                Button {
                    onSelect(item.id)
                } label: {
                    StyledText.body2(item.title, color: item.role.titleColor)
                        .padding(.horizontal, Constant.rowHorizontalPadding)
                        .padding(.top, Constant.rowTopPadding)
                        .padding(.bottom, Constant.rowBottomPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .designSystemCornerRadius(.large)
                .accessibilityLabel(item.accessibilityLabel)
            }
        }
        .padding(Constant.containerPadding)
        .frame(width: Constant.menuWidth, alignment: .leading)
        .glassEffect(
            .regular.tint(Color(designSystem: .white5)),
            in: RoundedRectangle(designSystem: .large),
        )
    }

    // MARK: Internal

    static var menuWidth: CGFloat {
        Constant.menuWidth
    }

    static var containerPadding: CGFloat {
        Constant.containerPadding
    }

    static var rowHorizontalPadding: CGFloat {
        Constant.rowHorizontalPadding
    }

    static var rowTopPadding: CGFloat {
        Constant.rowTopPadding
    }

    static var rowBottomPadding: CGFloat {
        Constant.rowBottomPadding
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
                accessibilityLabel: "프로젝트 삭제 화면 열기",
            )
        ]
    )
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .designSystemBackground(.grey700)
}

#Preview("Action Menu · 파괴적 행 포함") {
    ActionMenu(
        items: [
            .init(
                id: "savedQuestions",
                title: "저장한 문제",
                accessibilityLabel: "저장한 문제 보기",
            ),
            .init(
                id: "repositoryLink",
                title: "GitHub에서 보기",
                accessibilityLabel: "GitHub에서 보기",
            ),
            .init(
                id: "delete",
                title: "삭제하기",
                role: .destructive,
                accessibilityLabel: "프로젝트 삭제",
            ),
        ]
    )
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .designSystemBackground(.grey700)
}
