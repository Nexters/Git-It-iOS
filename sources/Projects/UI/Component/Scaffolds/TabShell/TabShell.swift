import DesignSystem
import SwiftUI
import UIKit

public struct TabShell<Item: TabShellItem, Content: View>: View where Item.AllCases: RandomAccessCollection {

    // MARK: Lifecycle

    public init(
        selected: Binding<Item>,
        isEnabled: @escaping (Item) -> Bool = { _ in true },
        @ViewBuilder content: @escaping (Item) -> Content,
    ) {
        _selected = selected
        self.isEnabled = isEnabled
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        TabView(selection: $selected) {
            ForEach(Item.allCases) { item in
                Tab(value: item) {
                    content(item)
                } label: {
                    Image(item.tabSystemImage, bundle: .module)
                        .padding(.bottom, LayoutToken.tightSpacing)
                    Text.designSystemStyled(item.tabTitle, style: .tabItem)
                }
                .disabled(!isEnabled(item))
            }
        }
        .tint(Color(designSystem: .blue100))
        .onAppear {
            UITabBar.appearance().unselectedItemTintColor = UIColor(Color(designSystem: .blue100))
        }
    }

    // MARK: Internal

    let isEnabled: (Item) -> Bool

    // MARK: Private

    @Binding private var selected: Item

    private let content: (Item) -> Content

}

#Preview("Tab Shell") {
    TabShell(selected: .constant(TabShellPreviewItem.home)) { _ in
        ScreenContainer {
            StyledText(text: "선택한 탭 콘텐츠", style: .subtitle1, alignment: .center)
        }
    }
}

#Preview("Tab Shell - disabled item") {
    TabShell(
        selected: .constant(TabShellPreviewItem.home),
        isEnabled: { $0 != .saved },
    ) { _ in
        ScreenContainer {
            StyledText(text: "선택한 탭 콘텐츠", style: .subtitle1, alignment: .center)
        }
    }
}
