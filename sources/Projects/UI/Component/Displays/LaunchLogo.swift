import DesignSystem
import SwiftUI

// MARK: - LaunchLogo

/// 크기 결정 방식은 `SizingMode.fixed` — 로고는 종횡비가 의미를 갖는다.
///
/// 등장 연출은 keyframe 타임라인이 소유한다. 표시 상태를 뷰가 보관하지 않는다.
public struct LaunchLogo: View {

    // MARK: Lifecycle

    public init(onCompletion: (() -> Void)? = nil) {
        self.onCompletion = onCompletion
    }

    // MARK: Public

    public var body: some View {
        ResourceImage(asset: .logo(.app))
            .frame(width: Constant.logoSize, height: Constant.logoSize)
            .keyframeAnimator(
                initialValue: IntroValues(),
                repeating: false,
            ) { content, values in
                content
                    .opacity(values.opacity)
                    .scaleEffect(values.scale)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: Constant.fadeInSeconds)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1, duration: Constant.fadeInSeconds)
                }
            }
            .accessibilityHidden(true)
            .task { await runIntroSequence() }
    }

    // MARK: Private

    private struct IntroValues {
        var opacity: Double = 0
        var scale: Double = Constant.initialScale
    }

    private enum Constant {
        static let logoSize: CGFloat = 120
        static let initialScale = 0.85
        static let fadeInSeconds = 0.45
        static let holdSeconds = 0.3
    }

    private let onCompletion: (() -> Void)?

    private func runIntroSequence() async {
        try? await Task.sleep(for: .seconds(Constant.fadeInSeconds))
        try? await Task.sleep(for: .seconds(Constant.holdSeconds))
        onCompletion?()
    }

}

#Preview("Launch Logo") {
    ScreenContainer { _ in
        LaunchLogo()
    }
    .frame(width: 390, height: 700)
}
