import DesignSystem
import SwiftUI

// MARK: - LaunchLogo

public struct LaunchLogo: View {

    // MARK: Lifecycle

    public init(onCompletion: (() -> Void)? = nil) {
        self.onCompletion = onCompletion
    }

    // MARK: Public

    public var body: some View {
        ResourceImage(asset: .logo(.app))
            .frame(width: Constant.logoSize, height: Constant.logoSize)
            .background { glow }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : Constant.initialScale)
            .accessibilityHidden(true)
            .task { await runIntroSequence() }
    }

    // MARK: Private

    private enum Constant {
        static let logoSize: CGFloat = 120
        static let initialScale: CGFloat = 0.85

        static let glowSize: CGFloat = 220
        static let glowOpacity = 0.18
        static let glowBlur: CGFloat = 24
        static let fadeInSeconds = 0.45
        static let holdSeconds = 0.3
    }

    @State private var isVisible = false

    private let onCompletion: (() -> Void)?

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(designSystem: ColorToken.blue300).opacity(Constant.glowOpacity),
                        Color(designSystem: ColorToken.blue300).opacity(0),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: Constant.glowSize / 2,
                )
            )
            .frame(width: Constant.glowSize, height: Constant.glowSize)
            .blur(radius: Constant.glowBlur)
    }

    private func runIntroSequence() async {
        withAnimation(.easeOut(duration: Constant.fadeInSeconds)) {
            isVisible = true
        }
        try? await Task.sleep(for: .seconds(Constant.fadeInSeconds))
        try? await Task.sleep(for: .seconds(Constant.holdSeconds))
        onCompletion?()
    }

}

#Preview("Launch Logo") {
    ScreenContainer {
        LaunchLogo()
    }
    .frame(width: 390, height: 700)
}
