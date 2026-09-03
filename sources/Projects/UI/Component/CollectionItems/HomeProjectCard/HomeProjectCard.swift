import DesignSystem
import SwiftUI

// MARK: - HomeProjectCard

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

    /// 카드가 그려지는 고정 높이. 카드를 담는 화면이 회전·여백을 포함한 영역 높이를
    /// 계산할 때 사용합니다.
    public static let designHeight: CGFloat = 192

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: select) {
                cardContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(currentSetLabel), 프로젝트 상세 보기")

            startButton
                .padding(.trailing, Constant.startTrailingPadding)
                .padding(.top, Constant.startTopPadding)
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
                StyledText(
                    text: title,
                    style: Constant.titleStyle,
                    color: variant.titleColor,
                )
                .lineLimit(2)

                StyledText.caption2(
                    technologies,
                    color: variant.technologyColor,
                )
                .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Constant.headerLeadingPadding)
            .padding(.trailing, Constant.headerTextTrailingReserve)
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

    private var cardWidth: CGFloat {
        154
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
        .buttonStyle(.plain)
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

// MARK: HomeProjectCard.Constant

extension HomeProjectCard {
    fileprivate enum Constant {
        static let cardHeight = HomeProjectCard.designHeight
        static let titleSpacing: CGFloat = 6
        static let headerLeadingPadding: CGFloat = 14
        static let headerTrailingPadding: CGFloat = 10
        static let headerTopPadding: CGFloat = 18
        static let progressBarHeight: CGFloat = 5
        static let footerSpacing: CGFloat = 3
        static let footerBottomPadding: CGFloat = 18
        static let setBadgeHorizontalPadding: CGFloat = 5
        static let setBadgeHeight: CGFloat = 19

        /// 원본 기준 보이는 원의 카드 상단·우측 여백.
        static let startVisualTopInset: CGFloat = 20
        static let startVisualTrailingInset: CGFloat = 12

        static let startSymbolSize: CGFloat = 12

        /// 원본 `Play1` 인스턴스 크기. 보이는 원(`startSurfaceSize`)을 감싼 레이아웃 박스다.
        static let startBoxSize: CGFloat = 36
        static let startSurfaceSize: CGFloat = 32
        static let startTouchSize: CGFloat = 44

        /// 원본 `Play1` 인스턴스(36×36) 기준으로 제목이 비워야 하는 우측 폭.
        static let headerTextTrailingReserve = headerTrailingPadding + startBoxSize

        /// 44pt 터치 영역이 보이는 원보다 각 변에서 더 차지하는 폭.
        static let startTouchOverhang = (startTouchSize - startSurfaceSize) / 2
        static let startTopPadding = startVisualTopInset - startTouchOverhang
        static let startTrailingPadding = startVisualTrailingInset - startTouchOverhang

        /// 카드 제목. 원본에서 공유 텍스트 스타일 없이 18pt Bold 120%로 지정되어 있어
        /// `TextStyleToken.subtitle2`(148%)를 쓸 수 없다. 타입 램프에 18pt 120%가
        /// 추가되면 그 토큰으로 옮긴다.
        static let titleStyle = TextStyleToken(
            name: "Home Project Card Title",
            weight: .bold,
            size: 18,
            lineHeightPercent: 120,
        )
    }
}

// MARK: HomeProjectCard.Variant

extension HomeProjectCard {
    public enum Variant: Sendable, Equatable {
        case purple
        case lightBlue
        case darkBlue

        // MARK: Lifecycle

        public init(index: Int) {
            self =
                switch index % 3 {
                case 1: .lightBlue
                case 2: .darkBlue
                default: .purple
                }
        }

        // MARK: Internal

        var cardColor: ColorToken {
            switch self {
            case .purple: .purple300
            case .lightBlue: .blue100
            case .darkBlue: .blue500
            }
        }

        var titleColor: ColorToken {
            .grey100
        }

        var technologyColor: ColorToken {
            switch self {
            case .purple: .grey200
            case .lightBlue: .grey500
            case .darkBlue: .grey400
            }
        }

        var trackColor: ColorToken {
            switch self {
            case .purple: .purple200
            case .lightBlue: .grey200
            case .darkBlue: .purple300
            }
        }

        var progressColor: ColorToken {
            switch self {
            case .purple: .purple400
            case .lightBlue: .blue200
            case .darkBlue: .blue400
            }
        }

        var setTitleColor: ColorToken {
            switch self {
            case .lightBlue: .grey500
            case .purple,
                 .darkBlue: .grey100
            }
        }
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
