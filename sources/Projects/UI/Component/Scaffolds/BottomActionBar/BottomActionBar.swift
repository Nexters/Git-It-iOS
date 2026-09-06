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
            .background {
                Color.clear
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.safeAreaInsets.bottom
                    } action: { safeAreaBottomInset = $0 }
            }
            .padding(.bottom, max(safeAreaBottomInset, Constant.minimumBottomInset))
    }

    // MARK: Private

    private enum Constant {
        static var topPadding: CGFloat {
            4
        }

        static var bottomPadding: CGFloat {
            24
        }

        static var minimumBottomInset: CGFloat {
            24
        }
    }

    @State private var safeAreaBottomInset: CGFloat = 0

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
