import AuthenticationServices
import DesignSystem
import SwiftUI

// MARK: - AppleSignInButton

/// 크기 결정 방식은 `SizingMode.fill`.
public struct AppleSignInButton: View {

    // MARK: Lifecycle

    public init(
        action: @escaping () -> Void = { }
    ) {
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: LayoutToken.iconSpacing.cgFloatValue) {
                Image(systemName: "applelogo")
                    .font(.system(size: 16))
                    .designSystemForeground(.black)
                StyledText.body1("Apple로 시작하기", color: .black)
            }
        }
        .buttonStyle(.pressOverlay)
        .frame(height: Constant.surfaceHeight)
        .frame(maxWidth: .infinity)
        .designSystemBackground(.white)
        .designSystemCornerRadius(.large)
    }

    // MARK: Private

    private enum Constant {
        static let surfaceHeight: CGFloat = 54
    }

    private let action: () -> Void

}

#Preview("Apple Sign In Button") {
    ZStack {
        Rectangle().designSystemBackground(.black)
        AppleSignInButton().padding(20)
    }
}
