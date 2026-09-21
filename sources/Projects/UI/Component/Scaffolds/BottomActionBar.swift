import DesignSystem
import SwiftUI

// MARK: - BottomActionBar

public struct BottomActionBar<Content: View>: View {

    // MARK: Lifecycle

    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.top, Constant.topPadding)
            .padding(.bottom, Constant.minimumBottomInset)
    }

    // MARK: Private

    private enum Constant {
        static var topPadding: CGFloat {
            4
        }

        static var minimumBottomInset: CGFloat {
            24
        }
    }

    private let content: Content

}

#Preview("Bottom Action Bar") {
    VStack(spacing: 0) {
        Spacer()

        BottomActionBar {
            ActionButton(title: "계속하기")
        }
        .designSystemBackground(.grey600)
    }
    .frame(width: 390, height: 240)
    .designSystemBackground(.grey700)
}
