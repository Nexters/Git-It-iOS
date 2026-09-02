import DesignSystem
import SwiftUI

// MARK: - SelectionCard

public struct SelectionCard<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        title: String,
        supportingText: String? = nil,
        badgeText: String? = nil,
        isSelected: Bool = false,
        style: SelectionCardStyle = .detailed,
        @ViewBuilder thumbnail: () -> Thumbnail,
    ) {
        self.title = title
        self.supportingText = supportingText
        self.badgeText = badgeText
        self.isSelected = isSelected
        self.style = style
        self.thumbnail = thumbnail()
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: Constant.thumbnailSpacing) {
            if style.showsThumbnail {
                thumbnail
                    .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                    .designSystemCornerRadius(.small)
            }

            VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                HStack(spacing: Constant.badgeSpacing) {
                    StyledText.subtitle3(title)
                    if let badgeText {
                        TagBadge.selected(badgeText)
                    }
                }
                if let supportingText {
                    StyledText.caption1(supportingText, color: .grey300)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Constant.contentPadding)
        .frame(maxWidth: .infinity, minHeight: style.minimumHeight, alignment: .leading)
        .designSystemBackground(.screenBackground)
        .designSystemCornerRadius(.large)
        .overlay {
            if isSelected {
                RoundedRectangle(designSystem: .large)
                    .fill(Color(designSystem: SemanticColorToken.selectedSurface))
            }
        }
        .overlay {
            RoundedRectangle(designSystem: .large)
                .stroke(
                    Color(designSystem: borderToken.colorToken),
                    lineWidth: CGFloat(borderToken.width),
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Private

    private let title: String
    private let supportingText: String?
    private let badgeText: String?
    private let isSelected: Bool
    private let style: SelectionCardStyle
    private let thumbnail: Thumbnail

    private var borderToken: BorderToken {
        isSelected ? .focus : .default
    }

}

extension SelectionCard where Thumbnail == EmptyView {
    public init(
        title: String,
        supportingText: String? = nil,
        badgeText: String? = nil,
        isSelected: Bool = false,
    ) {
        self.init(
            title: title,
            supportingText: supportingText,
            badgeText: badgeText,
            isSelected: isSelected,
            style: .compact,
        ) { EmptyView() }
    }
}

#Preview("Selection Card") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        SelectionCard(
            title: "기술 개념은 알아요",
            supportingText: "실제 코드 흐름을 중심으로 학습",
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .purple300))
        }

        SelectionCard(
            title: "프로젝트 경험이 있어요",
            supportingText: "심화 문제와 서술형 비중 확대",
            isSelected: true,
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .blue400))
        }
    }
    .frame(width: 340)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}

#Preview("Selection Card - compact · 737:10372") {
    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
        SelectionCard(title: "Front-end")
        SelectionCard(title: "Back-end", isSelected: true)
    }
    .frame(width: 340)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
