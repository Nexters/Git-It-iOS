import DesignSystem
import SwiftUI

// MARK: - ProjectRow

public struct ProjectRow<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        name: String,
        supportingText: String,
        progress: Double,
        currentSet: Int = 1,
        setTitle: String = "",
        isDeleting: Bool = false,
        onAccessoryTap: @escaping () -> Void = { },
        @ViewBuilder thumbnail: () -> Thumbnail,
    ) {
        self.name = name
        self.supportingText = supportingText
        self.progress = progress
        self.currentSet = currentSet
        self.setTitle = setTitle
        self.isDeleting = isDeleting
        self.onAccessoryTap = onAccessoryTap
        self.thumbnail = thumbnail()
    }

    public init(
        name: String,
        supportingText: String,
        progress: Double,
        currentSet: Int = 1,
        setTitle: String = "",
        isDeleting: Bool = false,
        onAccessoryTap: @escaping () -> Void = { },
    ) where Thumbnail == EmptyView {
        self.init(
            name: name,
            supportingText: supportingText,
            progress: progress,
            currentSet: currentSet,
            setTitle: setTitle,
            isDeleting: isDeleting,
            onAccessoryTap: onAccessoryTap,
            thumbnail: EmptyView.init,
        )
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            HStack(spacing: Constant.thumbnailSpacing) {
                thumbnail
                    .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                    .designSystemCornerRadius(.small)

                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText.subtitle3(name)
                        .lineLimit(2)
                    StyledText.caption1(supportingText, color: .grey400)
                        .lineLimit(1)
                }

                Spacer(minLength: Constant.minimumTrailingSpacing)

                accessoryButton
            }

            if !isDeleting {
                ContinuousProgressBar(progress: progress)

                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    TagBadge.neutral("Set \(currentSet)")
                    StyledText.body2(setTitle, color: .grey300)
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

    private let name: String
    private let supportingText: String
    private let progress: Double
    private let currentSet: Int
    private let setTitle: String
    private let isDeleting: Bool
    private let onAccessoryTap: () -> Void
    private let thumbnail: Thumbnail

    private var minimumHeight: CGFloat {
        isDeleting
            ? Constant.deletingMinimumHeight
            : Constant.defaultMinimumHeight
    }

    @ViewBuilder
    private var accessoryButton: some View {
        if isDeleting {
            IconGlassButton.destructive(
                symbol: "minus",
                label: "\(name) 삭제",
                size: .small,
                action: onAccessoryTap,
            )
        } else {
            IconPlainButton(
                symbol: "ic-play-1",
                label: "\(name) 학습 시작",
                action: onAccessoryTap,
            )
        }
    }

}

#Preview("Project Row") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        ProjectRow(
            name: "Git It iOS",
            supportingText: "Swift · SwiftUI · TCA",
            progress: 0.65,
            currentSet: 2,
            setTitle: "Presentation 구조",
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .purple300))
        }

        ProjectRow(
            name: "삭제할 프로젝트",
            supportingText: "Kotlin · Compose",
            progress: 0,
            currentSet: 1,
            setTitle: "기본 개념",
            isDeleting: true,
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
