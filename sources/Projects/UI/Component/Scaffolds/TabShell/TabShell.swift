import DesignSystem
import SwiftUI

public struct TabShell<Item: TabShellItem, Content: View>: View where Item.AllCases: RandomAccessCollection {

    // MARK: Lifecycle

    public init(
        selected: Binding<Item>,
        @ViewBuilder content: @escaping (Item) -> Content,
    ) {
        _selected = selected
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        TabView(selection: $selected) {
            ForEach(Item.allCases) { item in
                content(item)
                    .tabItem {
                        Image(item.tabSystemImage, bundle: .module)
                            .padding(.bottom, 4)
                        Text.designSystemStyled(item.tabTitle, style: .tabItem)
                    }
                    .tag(item)
            }
        }
        .tint(Color(designSystem: .brandAccent))
    }

    // MARK: Private

    @Binding private var selected: Item

    private let content: (Item) -> Content

}

#Preview("Tab Shell") {
    TabShell(selected: .constant(TabShellPreviewItem.home)) { _ in
        ScreenContainer {
            StyledText.subtitle1("선택한 탭 콘텐츠", alignment: .center)
        }
    }
}
