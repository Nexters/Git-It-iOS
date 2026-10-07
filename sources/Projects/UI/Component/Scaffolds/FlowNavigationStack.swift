import SwiftUI

public struct FlowNavigationStack<Screen: Hashable, Root: View, Destination: View>: View {

    // MARK: Lifecycle

    public init(
        path: [Screen],
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (Screen) -> Destination,
    ) {
        self.path = path
        self.root = root
        self.destination = destination
    }

    // MARK: Public

    public var body: some View {
        NavigationStack(path: .constant(path)) {
            flowScreen(root())
                .navigationDestination(for: Screen.self) { screen in
                    flowScreen(destination(screen))
                }
        }
    }

    // MARK: Private

    private let path: [Screen]
    private let root: () -> Root
    private let destination: (Screen) -> Destination

    private func flowScreen(_ content: some View) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
    }

}

#Preview("Flow Navigation Stack") {
    FlowNavigationStack(path: ["두 번째"]) {
        StyledText.subtitle1("첫 번째", alignment: .center)
    } destination: { screen in
        StyledText.subtitle1(screen, alignment: .center)
    }
}
