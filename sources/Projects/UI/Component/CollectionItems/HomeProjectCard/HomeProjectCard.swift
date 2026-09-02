import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.fill` — 2열 배치의 한 열 폭(`gridColumn2`)을 따르고 정본 고정값을 쓰지 않는다.
public struct HomeProjectCard: View {

    // MARK: Lifecycle

    public init(
        title: String,
        technologies: String,
        progress: Double,
        currentSetLabel: String,
        setTitle: String,
        variant: Variant,
        isLearningEnabled: Bool = true,
        onSelect: @escaping () -> Void = { },
        onStart: @escaping () -> Void = { },
    ) {
        self.title = title
        self.technologies = technologies
        self.progress = progress
        self.currentSetLabel = currentSetLabel
        self.setTitle = setTitle
        self.variant = variant
        self.isLearningEnabled = isLearningEnabled
        self.onSelect = onSelect
        self.onStart = onStart
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: select) {
                cardContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressOverlay)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(currentSetLabel), 프로젝트 상세 보기")

            startButton
                .padding(.trailing, Constant.headerTrailingPadding)
                .padding(.top, Constant.headerTopPadding)
        }
        .frame(width: cardWidth, height: Constant.cardHeight)
        .background(Color(designSystem: variant.cardColor))
        .designSystemCornerRadius(.large)
        .accessibilityElement(children: .contain)
    }

    // MARK: Internal

    static let minimumTouchArea = Constant.startTouchSize

    var displayedCurrentSetLabel: String {
        currentSetLabel
    }

    static func clampedProgress(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }

    func select() {
        onSelect()
    }

    func start() {
        guard isLearningEnabled else { return }
        onStart()
    }

    // MARK: Private

    @Environment(\.layoutMetrics) private var layoutMetrics

    private let title: String
    private let technologies: String
    private let progress: Double
    private let currentSetLabel: String
    private let setTitle: String
    private let variant: Variant
    private let isLearningEnabled: Bool
    private let onSelect: () -> Void
    private let onStart: () -> Void

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Constant.headerLeadingPadding)
            .padding(.trailing, Constant.headerTrailingPadding + Constant.startTouchSize)
            .padding(.top, Constant.headerTopPadding)

            progressBar
                .padding(.horizontal, Constant.headerLeadingPadding)
                .padding(.top, LayoutToken.gutter.cgFloatValue)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: Constant.footerSpacing) {
                StyledText.caption2(
                    currentSetLabel,
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
        .frame(width: cardWidth, height: Constant.cardHeight)
    }

    /// 2열 배치의 한 열 폭. 정본 캔버스의 154를 쓰지 않는다.
    private var cardWidth: CGFloat {
        CGFloat(layoutMetrics.gridColumn2)
    }

    private var startButton: some View {
        Button(action: start) {
            Image(systemName: "play.fill")
                .font(.system(size: Constant.startSymbolSize, weight: .bold))
                .designSystemForeground(variant.cardColor)
                .frame(width: Constant.startSurfaceSize, height: Constant.startSurfaceSize)
                .background(Color(designSystem: .grey100), in: Circle())
                .frame(width: Constant.startTouchSize, height: Constant.startTouchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressOverlay)
        .disabled(!isLearningEnabled)
        .accessibilityLabel("\(title) 학습 시작")
        .accessibilityHint(isLearningEnabled ? "다음 학습을 시작합니다" : "다음 학습 위치가 없습니다")
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(designSystem: variant.trackColor))

                Capsule()
                    .fill(Color(designSystem: variant.progressColor))
                    .frame(width: proxy.size.width * Self.clampedProgress(progress))
            }
        }
        .frame(height: Constant.progressBarHeight)
    }

}

#Preview("Home Project Card") {
    HStack(spacing: LayoutToken.margin.cgFloatValue) {
        HomeProjectCard(
            title: "Nexters",
            technologies: "Kotlin · Compose · Coroutines",
            progress: 0.4,
            currentSetLabel: "Set 1",
            setTitle: "Compose 핵심 개념",
            variant: .purple,
        )
        HomeProjectCard(
            title: "Now in Android",
            technologies: "Kotlin · Compose · Coroutines",
            progress: 0.4,
            currentSetLabel: "Set 1",
            setTitle: "Compose 핵심 개념",
            variant: .lightBlue,
        )
        HomeProjectCard(
            title: "Git It iOS",
            technologies: "Swift · SwiftUI · TCA",
            progress: 0.4,
            currentSetLabel: "Set 1",
            setTitle: "Presentation 구조",
            variant: .darkBlue,
        )
    }
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemScreenMargin()
    .designSystemBackground(.grey700)
}
