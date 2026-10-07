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
        static let fadeInSeconds = 0.3
        static let holdSeconds = 0.5
    }

    @State private var isVisible = false

    private let onCompletion: (() -> Void)?

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
