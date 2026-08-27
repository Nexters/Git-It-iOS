import DesignSystem
import SwiftUI

// MARK: - BottomActionBar

public struct BottomActionBar<Content: View>: View {

    // MARK: Lifecycle

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.top, Constant.topPadding)
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomPadding)
    }

    // MARK: Private

    private let content: Content

}

#Preview("Bottom Action Bar") {
    VStack(spacing: 0) {
        Spacer()

        BottomActionBar {
            ActionButton.primary("계속하기")
        }
        .designSystemBackground(.cardBackground)
    }
    .frame(width: 390, height: 240)
    .designSystemBackground(.grey700)
}
