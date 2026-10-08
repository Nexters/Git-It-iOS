import DesignSystem
import SwiftUI
import UIKit

// MARK: - TabShell

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
                    Image(
                        item.tabSystemImage,
                        bundle: .module,
                    )
                    .padding(.bottom, LayoutToken.tightSpacing)
                    Text.designSystemStyled(
                        item.tabTitle,
                        style: .tabItem,
                    )
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

// MARK: - TabShellItem

public protocol TabShellItem: CaseIterable, Hashable, Identifiable, Sendable {
    var tabTitle: String { get }
    var tabSystemImage: String { get }
}

extension TabShellItem {

    public static func tabColor(isSelected: Bool) -> ColorToken {
        isSelected ? .blue100 : .grey400
    }

}

// MARK: - TabShellPreviewItem

enum TabShellPreviewItem: String, TabShellItem {
    case home
    case project
    case saved
    case profile

    // MARK: Internal

    var id: Self {
        self
    }

    var tabTitle: String {
        switch self {
        case .home: "홈"
        case .project: "프로젝트"
        case .saved: "저장"
        case .profile: "마이"
        }
    }

    var tabSystemImage: String {
        switch self {
        case .home: "ic-home"
        case .project: "ic-file-text"
        case .saved: "ic-bookmark"
        case .profile: "ic-user"
        }
    }
}

#Preview("Tab Shell") {
    TabShell(selected: .constant(TabShellPreviewItem.home)) { _ in
        ScreenContainer {
            StyledText(text: "선택한 탭 콘텐츠")
                .textStyle(.subtitle1)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Tab Shell - disabled item") {
    TabShell(
        selected: .constant(TabShellPreviewItem.home),
        isEnabled: { $0 != .saved },
    ) { _ in
        ScreenContainer {
            StyledText(text: "선택한 탭 콘텐츠")
                .textStyle(.subtitle1)
                .multilineTextAlignment(.center)
        }
    }
}
