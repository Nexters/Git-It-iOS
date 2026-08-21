import DesignSystem
import SwiftUI

public struct TabShell<Item: TabShellItem, Content: View>: View where Item.AllCases: RandomAccessCollection {

    // MARK: Lifecycle

    public init(
        selected: Item,
        onSelect: @escaping (Item) -> Void,
        @ViewBuilder content: () -> Content,
    ) {
        self.selected = selected
        self.onSelect = onSelect
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        TabView(selection: Binding(get: { selected }, set: onSelect)) {
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
    private let onSelect: (Item) -> Void
    private let content: Content

}
