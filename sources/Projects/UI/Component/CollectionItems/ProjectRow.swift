import DesignSystem
import SwiftUI

// MARK: - ProjectRow

public struct ProjectRow<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        onAccessoryTap: @escaping () -> Void = { },
        @ViewBuilder thumbnail: () -> Thumbnail,
    ) {
        self.displayModel = displayModel
        self.onAccessoryTap = onAccessoryTap
        self.thumbnail = thumbnail()
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter) {
            HStack(spacing: Constant.thumbnailSpacing) {
                thumbnail
                    .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                    .designSystemCornerRadius(.small)

                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText(text: displayModel.name)
                        .textStyle(.subtitle2)
                        .lineLimit(2)
                    StyledText(text: displayModel.supportingText)
                        .textStyle(.body3)
                        .foregroundColorToken(.grey400)
                        .lineLimit(1)
                }
                .padding(.top, Constant.textColumnTopPadding)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                accessoryButton
            }

            if !isDeleting {
                ContinuousProgressBar(progress: displayModel.progress)

                HStack(spacing: LayoutToken.compactSpacing) {
                    TagBadge(text: "Set \(displayModel.currentSet)")
                        .style(.muted)
                        .size(.compact)
                        .designSystemCornerRadius(.pill)
                    StyledText(text: displayModel.setTitle)
                        .textStyle(.body2)
                        .foregroundColorToken(.grey300)
                        .lineLimit(1)
                }
            }
        }
        .padding(.top, Constant.topPadding)
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.bottom, Constant.bottomPadding)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .top)
        .designSystemBackground(.grey600)
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
            4
        }

        static var textColumnTopPadding: CGFloat {
            4
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

    private let displayModel: DisplayModel
    private var isDeleting = false
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
            IconGlassButton(
                icon: .minus,
                label: "\(displayModel.name) 삭제",
                action: onAccessoryTap,
            )
            .style(.destructive)
            .size(.medium)
            .designSystemBackground(.clear)
        } else {
            IconPlainButton(
                icon: .play,
                label: "\(displayModel.name) 학습 시작",
                action: onAccessoryTap,
            )
        }
    }

}

// MARK: ProjectRow.DisplayModel

extension ProjectRow {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            name: String,
            supportingText: String,
            progress: Double,
            currentSet: Int,
            setTitle: String,
        ) {
            self.name = name
            self.supportingText = supportingText
            self.progress = progress
            self.currentSet = currentSet
            self.setTitle = setTitle
        }

        public let name: String
        public let supportingText: String
        public let progress: Double
        public let currentSet: Int
        public let setTitle: String
    }
}

// MARK: ProjectRow 상태 선언

extension ProjectRow {
    public func deleting(_ isDeleting: Bool) -> Self {
        var copy = self
        copy.isDeleting = isDeleting
        return copy
    }
}

#Preview("Project Row") {
    VStack(spacing: LayoutToken.gutter) {
        ProjectRow(
            displayModel: .init(
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
            displayModel: .init(
                name: "삭제할 프로젝트",
                supportingText: "Kotlin · Compose",
                progress: 0,
                currentSet: 1,
                setTitle: "기본 개념",
            )
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .blue500))
        }
        .deleting(true)
    }
    .frame(width: 360)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
