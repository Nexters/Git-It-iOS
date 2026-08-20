import DesignSystem
import SwiftUI

// MARK: - ProjectRow

public struct ProjectRow<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onAccessoryTap: @escaping () -> Void = { },
        @ViewBuilder thumbnail: () -> Thumbnail,
    ) {
        self.viewModel = viewModel
        self.onAccessoryTap = onAccessoryTap
        self.thumbnail = thumbnail()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            name: String,
            supportingText: String,
            progress: Double,
            currentSet: Int,
            setTitle: String,
            isDeleting: Bool = false,
        ) {
            self.name = name
            self.supportingText = supportingText
            self.progress = progress
            self.currentSet = currentSet
            self.setTitle = setTitle
            self.isDeleting = isDeleting
        }

        // MARK: Public

        public let name: String
        public let supportingText: String
        public let progress: Double
        public let currentSet: Int
        public let setTitle: String
        public let isDeleting: Bool

    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            HStack(spacing: Constant.thumbnailSpacing) {
                thumbnail
                    .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                    .designSystemCornerRadius(.small)

                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText.subtitle3(viewModel.name)
                        .lineLimit(2)
                    StyledText.caption1(viewModel.supportingText, color: .grey400)
                        .lineLimit(1)
                }

                Spacer(minLength: Constant.minimumTrailingSpacing)

                accessoryButton
            }

            if !viewModel.isDeleting {
                ContinuousProgressBar(viewModel: .init(progress: viewModel.progress))

                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    TagBadge.neutral("Set \(viewModel.currentSet)")
                    StyledText.body2(viewModel.setTitle, color: .grey300)
                        .lineLimit(1)
                }
            }
        }
        .padding(.top, Constant.topPadding)
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.bottom, Constant.bottomPadding)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .top)
        .designSystemBackground(.cardBackground)
        .designSystemCornerRadius(.large)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private enum Constant {
        static var thumbnailSize: CGFloat {
            60
        }

        static var thumbnailSpacing: CGFloat {
            14
        }

        static var titleSpacing: CGFloat {
            2
        }

        static var minimumTrailingSpacing: CGFloat {
            4
        }

        static var topPadding: CGFloat {
            16
        }

        static var horizontalPadding: CGFloat {
            18
        }

        static var bottomPadding: CGFloat {
            18
        }

        static var defaultMinimumHeight: CGFloat {
            150
        }

        static var deletingMinimumHeight: CGFloat {
            94
        }
    }

    private let viewModel: ViewModel
    private let onAccessoryTap: () -> Void
    private let thumbnail: Thumbnail

    private var minimumHeight: CGFloat {
        viewModel.isDeleting
            ? Constant.deletingMinimumHeight
            : Constant.defaultMinimumHeight
    }

    @ViewBuilder
    private var accessoryButton: some View {
        if viewModel.isDeleting {
            IconGlassButton.destructive(
                symbol: "minus",
                label: "\(viewModel.name) 삭제",
                size: .small,
                action: onAccessoryTap,
            )
        } else {
            IconPlainButton(
                viewModel: .init(symbol: "ic-play-1", label: "\(viewModel.name) 학습 시작"),
                action: onAccessoryTap,
            )
        }
    }

}

#Preview("Project Row") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ProjectRow(
            viewModel: .init(
                name: "Git It iOS",
                supportingText: "Swift · SwiftUI · TCA",
                progress: 0.65,
                currentSet: 2,
                setTitle: "Presentation 구조",
            )
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .purple300))
        }

        ProjectRow(
            viewModel: .init(
                name: "삭제할 프로젝트",
                supportingText: "Kotlin · Compose",
                progress: 0,
                currentSet: 1,
                setTitle: "기본 개념",
                isDeleting: true,
            )
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .blue500))
        }
    }
    .frame(width: 360)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
