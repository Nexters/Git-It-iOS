import DesignSystem
import SwiftUI

// MARK: - HomeProjectCard

public struct HomeProjectCard: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        onSelect: @escaping () -> Void = { },
        onStart: @escaping () -> Void = { },
    ) {
        self.displayModel = displayModel
        self.onSelect = onSelect
        self.onStart = onStart
    }

    // MARK: Public

    public static let designHeight: CGFloat = 192

    public static let designWidth: CGFloat = 154

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: select) {
                cardContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            startButton
                .padding(.trailing, Constant.startTrailingPadding)
                .padding(.top, Constant.startTopPadding)
        }
        .frame(
            width: cardWidth,
            height: Constant.cardHeight,
        )
        .background(Color(designSystem: style.cardColor))
        .designSystemCornerRadius(.large)
    }

    // MARK: Internal

    static let minimumTouchArea = Constant.startTouchSize

    var displayedCurrentSetLabel: String {
        displayModel.currentSetLabel
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

    private let displayModel: DisplayModel
    private var style = Style.purple
    private var isLearningEnabled = true
    private let onSelect: () -> Void
    private let onStart: () -> Void

    private var cardContent: some View {
        VStack(
            alignment: .leading,
            spacing: 0,
        ) {
            VStack(
                alignment: .leading,
                spacing: Constant.titleSpacing,
            ) {
                StyledText(text: displayModel.title)
                    .textStyle(Constant.titleStyle)
                    .foregroundColorToken(style.titleColor)
                    .lineLimit(2)

                StyledText(text: displayModel.technologies)
                    .textStyle(.caption2)
                    .foregroundColorToken(style.technologyColor)
                    .lineLimit(2)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading,
            )
            .padding(.leading, Constant.headerLeadingPadding)
            .padding(.trailing, Constant.headerTextTrailingReserve)
            .padding(.top, Constant.headerTopPadding)
            progressBar
                .padding(.horizontal, Constant.headerLeadingPadding)
                .padding(.top, LayoutToken.gutter)

            Spacer(minLength: 0)

            VStack(
                alignment: .leading,
                spacing: Constant.footerSpacing,
            ) {
                StyledText(text: displayModel.currentSetLabel)
                    .textStyle(.caption2)
                    .padding(.horizontal, Constant.setBadgeHorizontalPadding)
                    .frame(height: Constant.setBadgeHeight)
                    .background(
                        Color(designSystem: style.progressColor),
                        in: Capsule(),
                    )

                StyledText(text: displayModel.setTitle)
                    .textStyle(.caption1)
                    .foregroundColorToken(style.setTitleColor)
                    .lineLimit(1)
            }
            .padding(.leading, LayoutToken.gutter)
            .padding(.trailing, Constant.headerTrailingPadding)
            .padding(.bottom, Constant.footerBottomPadding)
        }
        .frame(
            width: cardWidth,
            height: Constant.cardHeight,
        )
    }

    private var cardWidth: CGFloat {
        Self.designWidth
    }

    private var startButton: some View {
        Button(action: start) {
            Image(systemName: "play.fill")
                .font(.system(
                    size: Constant.startSymbolSize,
                    weight: .bold,
                ))
                .designSystemForeground(style.cardColor)
                .frame(
                    width: Constant.startSurfaceSize,
                    height: Constant.startSurfaceSize,
                )
                .background(
                    Color(designSystem: .grey100),
                    in: Circle(),
                )
                .frame(
                    width: Constant.startTouchSize,
                    height: Constant.startTouchSize,
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isLearningEnabled)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(designSystem: style.trackColor))

                Capsule()
                    .fill(Color(designSystem: style.progressColor))
                    .frame(width: proxy.size.width * Self.clampedProgress(displayModel.progress))
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

        static let startVisualTopInset: CGFloat = 20
        static let startVisualTrailingInset: CGFloat = 12

        static let startSymbolSize: CGFloat = 12

        static let startBoxSize: CGFloat = 36
        static let startSurfaceSize: CGFloat = 32
        static let startTouchSize: CGFloat = 44

        static let headerTextTrailingReserve = headerTrailingPadding + startBoxSize

        static let startTouchOverhang = (startTouchSize - startSurfaceSize) / 2
        static let startTopPadding = startVisualTopInset - startTouchOverhang
        static let startTrailingPadding = startVisualTrailingInset - startTouchOverhang

        static let titleStyle = TextStyleToken(
            name: "Home Project Card Title",
            weight: .bold,
            size: 18,
            lineHeightPercent: 120,
        )
    }
}

// MARK: HomeProjectCard.DisplayModel

extension HomeProjectCard {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String,
            technologies: String,
            progress: Double,
            currentSetLabel: String,
            setTitle: String,
        ) {
            self.title = title
            self.technologies = technologies
            self.progress = progress
            self.currentSetLabel = currentSetLabel
            self.setTitle = setTitle
        }

        public let title: String
        public let technologies: String
        public let progress: Double
        public let currentSetLabel: String
        public let setTitle: String
    }
}

// MARK: HomeProjectCard.Style

extension HomeProjectCard {
    public enum Style: Sendable, Equatable {
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

// MARK: StyleConfigurable

extension HomeProjectCard: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: HomeProjectCard 상태 선언

extension HomeProjectCard {
    public func learningEnabled(_ isLearningEnabled: Bool) -> Self {
        var copy = self
        copy.isLearningEnabled = isLearningEnabled
        return copy
    }
}

#Preview("Home Project Card") {
    HStack(spacing: LayoutToken.margin) {
        HomeProjectCard(
            displayModel: .init(
                title: "Nexters",
                technologies: "Kotlin · Compose · Coroutines",
                progress: 0.4,
                currentSetLabel: "Set 1",
                setTitle: "Compose 핵심 개념",
            )
        )
        HomeProjectCard(
            displayModel: .init(
                title: "Now in Android",
                technologies: "Kotlin · Compose · Coroutines",
                progress: 0.4,
                currentSetLabel: "Set 1",
                setTitle: "Compose 핵심 개념",
            )
        )
        .style(.lightBlue)
        HomeProjectCard(
            displayModel: .init(
                title: "Git It iOS",
                technologies: "Swift · SwiftUI · TCA",
                progress: 0.4,
                currentSetLabel: "Set 1",
                setTitle: "Presentation 구조",
            )
        )
        .style(.darkBlue)
    }
    .padding(.vertical, LayoutToken.margin)
    .designSystemScreenMargin()
    .designSystemBackground(.grey700)
}
