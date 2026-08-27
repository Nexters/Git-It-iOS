import DesignSystem
import SwiftUI

public struct HomeProjectCard: View {

    // MARK: Lifecycle

    public init(
        title: String,
        technologies: String,
        progress: Double,
        currentSet: Int,
        setTitle: String,
        variant: Variant,
        onStart: @escaping () -> Void = { },
    ) {
        self.title = title
        self.technologies = technologies
        self.progress = progress
        self.currentSet = currentSet
        self.setTitle = setTitle
        self.variant = variant
        self.onStart = onStart
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText.subtitle2(
                        title,
                        color: variant.titleColor,
                    )
                    .lineLimit(2)

                    StyledText.caption2(
                        technologies,
                        color: variant.technologyColor,
                    )
                    .lineLimit(3)
                }
                .frame(width: Constant.titleWidth, alignment: .leading)

                Spacer(minLength: 0)

                startButton
            }
            .padding(.leading, Constant.headerLeadingPadding)
            .padding(.trailing, Constant.headerTrailingPadding)
            .padding(.top, Constant.headerTopPadding)

            progressBar
                .padding(.horizontal, Constant.headerLeadingPadding)
                .padding(.top, LayoutToken.gutter.cgFloatValue)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: Constant.footerSpacing) {
                StyledText.caption2(
                    "Set \(currentSet)",
                    color: .grey100,
                )
                .padding(.horizontal, Constant.setBadgeHorizontalPadding)
                .frame(height: Constant.setBadgeHeight)
                .background(
                    Color(designSystem: variant.progressColor),
                    in: Capsule(),
                )

                StyledText.caption1(
                    setTitle,
                    color: variant.setTitleColor,
                )
                .lineLimit(1)
            }
            .padding(.leading, LayoutToken.gutter.cgFloatValue)
            .padding(.trailing, Constant.headerTrailingPadding)
            .padding(.bottom, Constant.footerBottomPadding)
        }
        .frame(width: Constant.cardWidth, height: Constant.cardHeight)
        .background(Color(designSystem: variant.cardColor))
        .designSystemCornerRadius(.large)
        .rotationEffect(.degrees(variant.rotationDegrees))
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let title: String
    private let technologies: String
    private let progress: Double
    private let currentSet: Int
    private let setTitle: String
    private let variant: Variant
    private let onStart: () -> Void

    private var startButton: some View {
        Button(action: onStart) {
            Image(systemName: "play.fill")
                .font(.system(size: Constant.startSymbolSize, weight: .bold))
                .designSystemForeground(variant.cardColor)
                .frame(width: Constant.startSurfaceSize, height: Constant.startSurfaceSize)
                .background(Color(designSystem: .grey100), in: Circle())
                .frame(width: Constant.startTouchSize, height: Constant.startTouchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 학습 시작")
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(designSystem: variant.trackColor))

                Capsule()
                    .fill(Color(designSystem: variant.progressColor))
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .frame(height: Constant.progressBarHeight)
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

}

#Preview("Home Project Card") {
    HStack(spacing: LayoutToken.margin.cgFloatValue) {
        HomeProjectCard(
            title: "Nexters",
            technologies: "Kotlin · Compose · Coroutines",
            progress: 0.4,
            currentSet: 1,
            setTitle: "Compose 핵심 개념",
            variant: .purple,
        )
        HomeProjectCard(
            title: "Now in Android",
            technologies: "Kotlin · Compose · Coroutines",
            progress: 0.4,
            currentSet: 1,
            setTitle: "Compose 핵심 개념",
            variant: .lightBlue,
        )
        HomeProjectCard(
            title: "Git It iOS",
            technologies: "Swift · SwiftUI · TCA",
            progress: 0.4,
            currentSet: 1,
            setTitle: "Presentation 구조",
            variant: .darkBlue,
        )
    }
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemScreenMargin()
    .designSystemBackground(.grey700)
}
