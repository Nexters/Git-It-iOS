import DesignSystem
import SwiftUI

// MARK: - SplashView

/// 크기 결정 방식은 `SizingMode.fill` — 내부 도형만 비율로 유도한다.
///
/// 타이핑 연출은 keyframe 타임라인이 소유한다. 표시 상태를 뷰가 보관하지 않는다.
public struct SplashView: View {

    // MARK: Lifecycle

    public init(onCompletion: (() -> Void)? = nil) {
        self.onCompletion = onCompletion
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .center, spacing: Constant.lineSpacing) {
            EmptyView()
        }
        .hidden()
        .overlay {
            typedLines
        }
        .accessibilityHidden(true)
        .task { await runIntroSequence() }
    }

    // MARK: Private

    private struct IntroValues {
        var helloCharacters: Double = 0
        var letsCharacters: Double = 0
        var gitCharacters: Double = 0
        var cursor1Opacity: Double = 0
        var cursor2Opacity: Double = 0
    }

    private enum Constant {
        static let lineSpacing: CGFloat = 4
        static let hello = "Hello World"
        static let lets = "Let’s "
        static let git = "Git-it!"

        static let initialDelay = 0.2
        static let typingInterval1 = 0.072
        static let typingInterval2 = 0.062
        static let cursorHandoffBlinkDuration = 0.5
        static let blinkHalfInterval = 0.7
        static let fadeInterval = 0.7

        static let titleText = TextStyleToken.splashTitle
        static let subtitleText = TextStyleToken.splashSubtitle

        static var helloDuration: Double {
            Double(hello.count) * typingInterval1
        }

        static var letsDuration: Double {
            Double(lets.count) * typingInterval2
        }

        static var gitDuration: Double {
            Double(git.count) * typingInterval2
        }

        /// `onCompletion`을 호출하는 시점. 타임라인과 같은 순서를 따른다.
        static var completionDelay: Double {
            initialDelay
                + helloDuration
                + cursorHandoffBlinkDuration
                + letsDuration
                + gitDuration
                + fadeInterval
        }
    }

    private let onCompletion: (() -> Void)?

    private var typedLines: some View {
        Color.clear
            .keyframeAnimator(
                initialValue: IntroValues(),
                repeating: false,
            ) { _, values in
                lines(values: values)
            } keyframes: { _ in
                KeyframeTrack(\.cursor1Opacity) {
                    LinearKeyframe(1, duration: 0)
                    LinearKeyframe(1, duration: Constant.initialDelay + Constant.helloDuration)
                    LinearKeyframe(0, duration: Constant.cursorHandoffBlinkDuration)
                }
                KeyframeTrack(\.helloCharacters) {
                    LinearKeyframe(0, duration: Constant.initialDelay)
                    LinearKeyframe(
                        Double(Constant.hello.count),
                        duration: Constant.helloDuration,
                    )
                }
                KeyframeTrack(\.cursor2Opacity) {
                    LinearKeyframe(
                        0,
                        duration: Constant.initialDelay
                            + Constant.helloDuration
                            + Constant.cursorHandoffBlinkDuration,
                    )
                    LinearKeyframe(1, duration: 0)
                    LinearKeyframe(
                        1,
                        duration: Constant.letsDuration + Constant.gitDuration + Constant.fadeInterval,
                    )
                    LinearKeyframe(0, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(1, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(0, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(1, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(0, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(1, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(0, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(1, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(0, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(1, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(0, duration: Constant.blinkHalfInterval)
                    LinearKeyframe(1, duration: Constant.blinkHalfInterval)
                }
                KeyframeTrack(\.letsCharacters) {
                    LinearKeyframe(
                        0,
                        duration: Constant.initialDelay
                            + Constant.helloDuration
                            + Constant.cursorHandoffBlinkDuration,
                    )
                    LinearKeyframe(
                        Double(Constant.lets.count),
                        duration: Constant.letsDuration,
                    )
                }
                KeyframeTrack(\.gitCharacters) {
                    LinearKeyframe(
                        0,
                        duration: Constant.initialDelay
                            + Constant.helloDuration
                            + Constant.cursorHandoffBlinkDuration
                            + Constant.letsDuration,
                    )
                    LinearKeyframe(
                        Double(Constant.git.count),
                        duration: Constant.gitDuration,
                    )
                }
            }
    }

    private static func revealed(
        _ text: String,
        characters: Double,
    ) -> String {
        String(text.prefix(max(0, Int(characters))))
    }

    private func lines(values: IntroValues) -> some View {
        VStack(alignment: .center, spacing: Constant.lineSpacing) {
            HStack(spacing: 0) {
                Text.designSystemStyled(
                    Self.revealed(Constant.hello, characters: values.helloCharacters),
                    style: Constant.subtitleText,
                )
                .foregroundStyle(Color(designSystem: .grey400))

                cursorBar(
                    style: Constant.subtitleText,
                    color: .grey400,
                    opacity: values.cursor1Opacity,
                )
            }
            .frame(alignment: .leading)

            HStack(spacing: 0) {
                Text.designSystemStyled(
                    Self.revealed(Constant.lets, characters: values.letsCharacters),
                    style: Constant.titleText,
                )
                .foregroundStyle(Color(designSystem: .grey100))

                Text.designSystemStyled(
                    Self.revealed(Constant.git, characters: values.gitCharacters),
                    style: Constant.titleText,
                )
                .foregroundStyle(Color(designSystem: .blue100))

                cursorBar(
                    style: Constant.titleText,
                    color: .blue100,
                    opacity: values.cursor2Opacity,
                )
            }
            .frame(alignment: .leading)
        }
    }

    private func cursorBar(
        style: TextStyleToken,
        color: ColorToken,
        opacity: Double,
    ) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(designSystem: color))
            .frame(width: style.size * 0.075, height: style.size * 0.92)
            .opacity(opacity)
    }

    private func runIntroSequence() async {
        try? await Task.sleep(for: .seconds(Constant.completionDelay))
        onCompletion?()
    }

}

#Preview("Splash") {
    ScreenContainer {
        SplashView()
            .designSystemScreenMargin()
    }
}
