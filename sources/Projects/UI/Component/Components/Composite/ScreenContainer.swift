import DesignSystem
import SwiftUI

public struct ScreenContainer<Content: View>: View {

    // MARK: Lifecycle

    public init(
        background: SemanticColorToken = .screenBackground,
        @ViewBuilder content: () -> Content,
    ) {
        self.background = background
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(designSystem: background))
            .preferredColorScheme(.dark)
    }

    // MARK: Private

    private let background: SemanticColorToken
    private let content: Content

}

#Preview("Screen Container") {
    ScreenContainer {
        StyledText.subtitle1("화면 콘텐츠", alignment: .center)
    }
    .frame(width: 320, height: 240)
}
