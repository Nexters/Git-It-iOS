import DesignSystem
import SwiftUI

// MARK: - ScreenContainer

public struct ScreenContainer<Content: View>: View {

    // MARK: Lifecycle

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        content()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
            )
            .background(Color(designSystem: backgroundColor))
            .preferredColorScheme(.dark)
    }

    // MARK: Private

    private var backgroundColor = ColorToken.grey700
    private let content: () -> Content

}

// MARK: BackgroundColorConfigurable

extension ScreenContainer: BackgroundColorConfigurable {
    public func backgroundColorToken(_ color: ColorToken) -> Self {
        var copy = self
        copy.backgroundColor = color
        return copy
    }
}

#Preview("Screen Container") {
    ScreenContainer {
        StyledText(text: "화면 콘텐츠")
            .textStyle(.subtitle1)
            .multilineTextAlignment(.center)
    }
    .frame(
        width: 320,
        height: 240,
    )
}
