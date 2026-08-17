import DesignSystem
import SwiftUI

public struct TabShell<Item: TabShellItem, Content: View>: View where Item.AllCases: RandomAccessCollection {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        @ViewBuilder content: () -> Content,
    ) {
        self.viewModel = viewModel
        self.content = content()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(selected: Item) {
            self.selected = selected
        }

        public let selected: Item
    }

    public var body: some View {
        TabView(selection: .constant(viewModel.selected)) {
            ForEach(Item.allCases) { item in
                Group {
                    if viewModel.selected == item {
                        content
                    } else {
                        Color(designSystem: .screenBackground)
                    }
                }
                .tabItem {
                    Label(item.tabTitle, systemImage: item.tabSystemImage)
                }
                .tag(item)
            }
        }
        .tint(Color(designSystem: .brandAccent))
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let content: Content

}

#Preview("Tab Shell") {
    TabShell(viewModel: .init(selected: TabShellPreviewItem.home)) {
        ScreenContainer {
            StyledText.subtitle1("선택한 탭 콘텐츠", alignment: .center)
        }
    }
}
