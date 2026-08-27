import DesignSystem
import SwiftUI

public struct TabShell<Item: TabShellItem, Content: View>: View where Item.AllCases: RandomAccessCollection {

    // MARK: Lifecycle

    public init(
        selected: Item,
        @ViewBuilder content: () -> Content,
    ) {
        self.selected = selected
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        TabView(selection: .constant(selected)) {
            ForEach(Item.allCases) { item in
                Group {
                    if selected == item {
                        content
                    } else {
                        Color(designSystem: .screenBackground)
                    }
                }
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

    private let selected: Item
    private let content: Content

}

#Preview("Tab Shell") {
    TabShell(selected: TabShellPreviewItem.home) {
        ScreenContainer {
            StyledText.subtitle1("선택한 탭 콘텐츠", alignment: .center)
        }
    }
}
