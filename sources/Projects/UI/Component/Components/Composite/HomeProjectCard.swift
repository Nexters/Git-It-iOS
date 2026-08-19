import DesignSystem
import SwiftUI

public struct HomeProjectCard: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onStart: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.onStart = onStart
    }

    // MARK: Public

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

        var rotationDegrees: Double {
            switch self {
            case .purple: 0
            case .lightBlue: 16
            case .darkBlue: -12
            }
        }

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

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            title: String,
            technologies: String,
            progress: Double,
            currentSet: Int,
            setTitle: String,
            variant: Variant,
        ) {
            self.title = title
            self.technologies = technologies
            self.progress = progress
            self.currentSet = currentSet
            self.setTitle = setTitle
            self.variant = variant
        }

        // MARK: Public

        public let title: String
        public let technologies: String
        public let progress: Double
        public let currentSet: Int
        public let setTitle: String
        public let variant: Variant

    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText.subtitle2(
                        viewModel.title,
                        color: viewModel.variant.titleColor,
                    )
                    .lineLimit(2)

                    StyledText.caption2(
                        viewModel.technologies,
                        color: viewModel.variant.technologyColor,
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
                    "Set \(viewModel.currentSet)",
                    color: .grey100,
                )
                .padding(.horizontal, Constant.setBadgeHorizontalPadding)
                .frame(height: Constant.setBadgeHeight)
                .background(
                    Color(designSystem: viewModel.variant.progressColor),
                    in: Capsule(),
                )

                StyledText.caption1(
                    viewModel.setTitle,
                    color: viewModel.variant.setTitleColor,
                )
                .lineLimit(1)
            }
            .padding(.leading, LayoutToken.gutter.cgFloatValue)
            .padding(.trailing, Constant.headerTrailingPadding)
            .padding(.bottom, Constant.footerBottomPadding)
        }
        .frame(width: Constant.cardWidth, height: Constant.cardHeight)
        .background(Color(designSystem: viewModel.variant.cardColor))
        .designSystemCornerRadius(.large)
        .rotationEffect(.degrees(viewModel.variant.rotationDegrees))
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static let cardWidth: CGFloat = 154
        static let cardHeight: CGFloat = 192
        static let titleWidth: CGFloat = 94
        static let titleSpacing: CGFloat = 6
        static let headerLeadingPadding: CGFloat = 14
        static let headerTrailingPadding: CGFloat = 10
        static let headerTopPadding: CGFloat = 18
        static let progressBarHeight: CGFloat = 5
        static let footerSpacing: CGFloat = 3
        static let footerBottomPadding: CGFloat = 18
        static let setBadgeHorizontalPadding: CGFloat = 5
        static let setBadgeHeight: CGFloat = 19

        static let startSymbolSize: CGFloat = 12
        static let startSurfaceSize: CGFloat = 32
        static let startTouchSize: CGFloat = 44
    }

    private let viewModel: ViewModel
    private let onStart: () -> Void

    /// 시각 표면은 32pt지만 44pt 프레임으로 감싸 최소 터치 대상을 확보합니다.
    private var startButton: some View {
        Button(action: onStart) {
            Image(systemName: "play.fill")
                .font(.system(size: Constant.startSymbolSize, weight: .bold))
                .designSystemForeground(viewModel.variant.cardColor)
                .frame(width: Constant.startSurfaceSize, height: Constant.startSurfaceSize)
                .background(Color(designSystem: .grey100), in: Circle())
                .frame(width: Constant.startTouchSize, height: Constant.startTouchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(viewModel.title) 학습 시작")
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(designSystem: viewModel.variant.trackColor))

                Capsule()
                    .fill(Color(designSystem: viewModel.variant.progressColor))
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .frame(height: Constant.progressBarHeight)
    }

    private var clampedProgress: Double {
        min(max(viewModel.progress, 0), 1)
    }

}

#Preview("Home Project Card") {
    HStack(spacing: LayoutToken.margin.cgFloatValue) {
        HomeProjectCard(
            viewModel: .init(
                title: "Nexters",
                technologies: "Kotlin · Compose · Coroutines",
                progress: 0.4,
                currentSet: 1,
                setTitle: "Compose 핵심 개념",
                variant: .purple,
            )
        )
        HomeProjectCard(
            viewModel: .init(
                title: "Now in Android",
                technologies: "Kotlin · Compose · Coroutines",
                progress: 0.4,
                currentSet: 1,
                setTitle: "Compose 핵심 개념",
                variant: .lightBlue,
            )
        )
        HomeProjectCard(
            viewModel: .init(
                title: "Git It iOS",
                technologies: "Swift · SwiftUI · TCA",
                progress: 0.4,
                currentSet: 1,
                setTitle: "Presentation 구조",
                variant: .darkBlue,
            )
        )
    }
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemScreenMargin()
    .designSystemBackground(.grey700)
}
