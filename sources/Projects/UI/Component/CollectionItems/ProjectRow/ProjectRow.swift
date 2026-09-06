import DesignSystem
import SwiftUI

// MARK: - ProjectRow

public struct ProjectRow<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        name: String,
        supportingText: String,
        progress: Double,
        currentSet: Int,
        setTitle: String,
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

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            HStack(spacing: Constant.thumbnailSpacing) {
                thumbnail
                    .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                    .designSystemCornerRadius(.small)

                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText.subtitle2(name)
                        .lineLimit(2)
                    StyledText.body3(supportingText, color: .grey400)
                        .lineLimit(1)
                }
                .padding(.top, Constant.textColumnTopPadding)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                accessoryButton
            }

            if !isDeleting {
                ContinuousProgressBar(progress: progress)

                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    TagBadge.muted("Set \(currentSet)").designSystemCornerRadius(.pill)
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
                size: .medium,
                action: onAccessoryTap,
            ).designSystemBackground(.clear)
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
