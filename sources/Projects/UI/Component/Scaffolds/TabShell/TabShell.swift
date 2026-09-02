import DesignSystem
import SwiftUI

public struct TabShell<Item: TabShellItem, Content: View>: View where Item.AllCases: RandomAccessCollection {

    // MARK: Lifecycle

    public init(
        selected: Binding<Item>,
        pillWidth: CGFloat = Self.defaultPillWidth,
        @ViewBuilder content: @escaping (Item) -> Content,
    ) {
        _selected = selected
        self.pillWidth = pillWidth
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        TabView(selection: $selected) {
            ForEach(Item.allCases) { item in
                content(item)
                    .toolbar(.hidden, for: .tabBar)
                    .tag(item)
            }
        }
        .overlay(alignment: .bottom) {
            tabBar
        }
    }

    /// 규격이 직접 확정한 알약 폭. 인자로 바꿔 채움으로 쓸 수 있다.
    public static var defaultPillWidth: CGFloat {
        Constant.pillWidth
    }

    // MARK: Internal

    enum Constant {
        static var pillWidth: CGFloat {
            298
        }

        static var pillHeight: CGFloat {
            68
        }

        static var iconBottomSpacing: CGFloat {
            4
        }
    }

    // MARK: Private

    @Binding private var selected: Item

    @Environment(\.layoutMetrics) private var layoutMetrics

    private let pillWidth: CGFloat
    private let content: (Item) -> Content

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Item.allCases) { item in
                Button {
                    selected = item
                } label: {
                    tabLabel(item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .designSystemControlSize(.minimumTouch)
                .accessibilityLabel(item.tabTitle)
                .accessibilityAddTraits(item == selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .frame(width: pillWidth, height: Constant.pillHeight)
        .background {
            Capsule()
                .fill(Color(designSystem: .tabBarSurface))
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    Color(designSystem: .tabBarBorder),
                    lineWidth: CGFloat(BorderToken.tabBar.width),
                )
        }
        .padding(.bottom, CGFloat(layoutMetrics.tabBarBottomInset))
    }

    private func tabLabel(_ item: Item) -> some View {
        VStack(spacing: Constant.iconBottomSpacing) {
            Image(item.tabSystemImage, bundle: .module)
            Text.designSystemStyled(item.tabTitle, style: .tabItem)
        }
        .foregroundStyle(Color(designSystem: item == selected ? SemanticColorToken.brandAccent : .mutedText))
    }

}

#Preview("Tab Shell") {
    TabShell(selected: .constant(TabShellPreviewItem.home)) { _ in
        ScreenContainer {
            StyledText.subtitle1("선택한 탭 콘텐츠", alignment: .center)
        }
    }
}
