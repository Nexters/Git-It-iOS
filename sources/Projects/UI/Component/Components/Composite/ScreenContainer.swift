import DesignSystem
import SwiftUI

public struct ScreenContainer<Content: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel = .init(),
        @ViewBuilder content: () -> Content,
    ) {
        self.viewModel = viewModel
        self.content = content()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(background: SemanticColorToken = .screenBackground) {
            self.background = background
        }

        public let background: SemanticColorToken
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(designSystem: viewModel.background))
            .preferredColorScheme(.dark)
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let content: Content

}

#Preview("Screen Container") {
    ScreenContainer {
        StyledText.subtitle1("화면 콘텐츠", alignment: .center)
    }
    .frame(width: 320, height: 240)
}
