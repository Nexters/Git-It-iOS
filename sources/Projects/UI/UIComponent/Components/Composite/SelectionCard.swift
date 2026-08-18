import DesignSystem
import SwiftUI

// MARK: - SelectionCard

public struct SelectionCard<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        @ViewBuilder thumbnail: () -> Thumbnail,
    ) {
        self.viewModel = viewModel
        self.thumbnail = thumbnail()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            title: String,
            supportingText: String? = nil,
            badgeText: String? = nil,
            isSelected: Bool = false,
        ) {
            self.title = title
            self.supportingText = supportingText
            self.badgeText = badgeText
            self.isSelected = isSelected
        }

        public let title: String
        public let supportingText: String?
        public let badgeText: String?
        public var isSelected: Bool
    }

    public var body: some View {
        HStack(spacing: Constant.thumbnailSpacing) {
            thumbnail
                .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                .designSystemCornerRadius(.small)

            VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                HStack(spacing: Constant.badgeSpacing) {
                    StyledText.subtitle3(viewModel.title)
                    if let badgeText = viewModel.badgeText {
                        TagBadge.selected(badgeText)
                    }
                }
                if let supportingText = viewModel.supportingText {
                    StyledText.caption1(supportingText, color: .grey300)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Constant.contentPadding)
        .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
        .designSystemBackground(.cardBackground)
        .designSystemCornerRadius(.large)
        .overlay {
            RoundedRectangle(designSystem: .large)
                .stroke(
                    viewModel.isSelected ? Color(designSystem: .blue200) : .clear,
                    lineWidth: Constant.borderWidth,
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(viewModel.isSelected ? .isSelected : [])
    }

    // MARK: Private

    private enum Constant {
        static var thumbnailSize: CGFloat {
            52
        }

        static var thumbnailSpacing: CGFloat {
            16
        }

        static var titleSpacing: CGFloat {
            3
        }

        static var badgeSpacing: CGFloat {
            6
        }

        static var contentPadding: CGFloat {
            14
        }

        static var minimumHeight: CGFloat {
            80
        }

        static var borderWidth: CGFloat {
            1
        }
    }

    private let viewModel: ViewModel
    private let thumbnail: Thumbnail

}

#Preview("Selection Card") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        SelectionCard(
            viewModel: .init(
                title: "기술 개념은 알아요",
                supportingText: "실제 코드 흐름을 중심으로 학습",
            )
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .purple300))
        }

        SelectionCard(
            viewModel: .init(
                title: "프로젝트 경험이 있어요",
                supportingText: "심화 문제와 서술형 비중 확대",
                isSelected: true,
            )
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
