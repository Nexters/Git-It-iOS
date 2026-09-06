import DesignSystem
import SwiftUI

// MARK: - SplashView

public struct SplashView: View {

    // MARK: Lifecycle

    public init(onCompletion: (() -> Void)? = nil) {
        self.onCompletion = onCompletion
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .center, spacing: Constant.lineSpacing) {
            HStack(spacing: 0) {
                Text.designSystemStyled(hello, style: Constant.subtitleText)
                    .foregroundStyle(Color(designSystem: .grey400))
                cursorBar(style: Constant.subtitleText, color: .grey400, state: cursor1)
            }
            .frame(alignment: .leading)

            HStack(spacing: 0) {
                Text.designSystemStyled(lets, style: Constant.titleText)
                    .foregroundStyle(Color(designSystem: .grey100))
                Text.designSystemStyled(git, style: Constant.titleText)
                    .foregroundStyle(Color(designSystem: .blue100))
                cursorBar(style: Constant.titleText, color: .blue100, state: cursor2)
            }
            .frame(alignment: .leading)
        }
        .accessibilityHidden(true)
        .task { await runIntroSequence() }
    }

    // MARK: Private

    private enum Cursor: Equatable {
        case hidden
        case solid
        case blinking(isVisible: Bool)

        var opacity: Double {
            switch self {
            case .hidden: 0
            case .solid: 1
            case .blinking(let isVisible): isVisible ? 1 : 0
            }
        }
    }

    private enum Constant {
        static let lineSpacing: CGFloat = 3
        static let typingInterval1 = Duration.milliseconds(72)
        static let typingInterval2 = Duration.milliseconds(62)
        static let initialDelay = Duration.milliseconds(200)
        static let cursorHandoffBlinkDuration = Duration.milliseconds(500)
        static let blinkHalfInterval = Duration.milliseconds(700)
        static let fadeInterval = Duration.milliseconds(700)

        static let titleText = TextStyleToken.splashTitle
        static let subtitleText = TextStyleToken.splashSubtitle
    }

    @State private var hello = ""
    @State private var lets = ""
    @State private var git = ""
    @State private var cursor1 = Cursor.hidden
    @State private var cursor2 = Cursor.hidden

    private let onCompletion: (() -> Void)?

    private func cursorBar(
        style: TextStyleToken,
        color: ColorToken,
        state: Cursor,
    ) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(designSystem: color))
            .frame(width: style.size * 0.075, height: style.size * 0.92)
            .opacity(state.opacity)
    }

    private func runIntroSequence() async {
        cursor1 = .solid
        try? await Task.sleep(for: Constant.initialDelay)

        await type("Hello World", interval: Constant.typingInterval1) { hello = $0 }
        await blink(for: Constant.cursorHandoffBlinkDuration) { cursor1 = $0 }
        cursor1 = .hidden
        cursor2 = .solid

        await type("Let’s ", interval: Constant.typingInterval2) { lets = $0 }
        await type("Git-it!", interval: Constant.typingInterval2) { git = $0 }

        try? await Task.sleep(for: Constant.fadeInterval)

        onCompletion?()

        while !Task.isCancelled {
            cursor2 = .blinking(isVisible: true)
            try? await Task.sleep(for: Constant.blinkHalfInterval)
            cursor2 = .blinking(isVisible: false)
            try? await Task.sleep(for: Constant.blinkHalfInterval)
        }
    }

    private func type(
        _ text: String,
        interval: Duration,
        into apply: (String) -> Void,
    ) async {
        var revealed = ""
        for character in text {
            revealed.append(character)
            apply(revealed)
            try? await Task.sleep(for: interval)
        }
    }

    private func blink(
        for duration: Duration,
        into apply: (Cursor) -> Void,
    ) async {
        let deadline = ContinuousClock.now.advanced(by: duration)
        while ContinuousClock.now < deadline {
            apply(.blinking(isVisible: true))
            try? await Task.sleep(for: Constant.blinkHalfInterval)
            apply(.blinking(isVisible: false))
            try? await Task.sleep(for: Constant.blinkHalfInterval)
        }
    }

}

#Preview("Splash") {
    ScreenContainer {
        SplashView()
            .designSystemScreenMargin()
    }
}
