import DesignSystem
import SwiftUI

// MARK: - SelectionCard

public struct SelectionCard<Thumbnail: View>: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        @ViewBuilder thumbnail: () -> Thumbnail,
    ) {
        self.displayModel = displayModel
        self.thumbnail = thumbnail()
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: Constant.thumbnailSpacing) {
            if style.showsThumbnail {
                thumbnail
                    .frame(
                        width: Constant.thumbnailSize,
                        height: Constant.thumbnailSize,
                    )
                    .designSystemCornerRadius(.small)
            }

            VStack(
                alignment: .leading,
                spacing: Constant.titleSpacing,
            ) {
                HStack(spacing: Constant.badgeSpacing) {
                    StyledText(text: displayModel.title)
                        .textStyle(.subtitle3)
                    if let badgeText = displayModel.badgeText {
                        TagBadge(text: badgeText)
                            .style(.selected)
                    }
                }
                if let supportingText = displayModel.supportingText {
                    StyledText(text: supportingText)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey300)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading,
            )
        }
        .padding(Constant.contentPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: style.minimumHeight,
            alignment: .leading,
        )
        .designSystemBackground(.grey600)
        .designSystemCornerRadius(.large)
        .overlay {
            if let borderToken {
                RoundedRectangle(designSystem: .large)
                    .stroke(
                        Color(designSystem: borderToken.colorToken),
                        lineWidth: CGFloat(borderToken.width),
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

        static var borderWidth: CGFloat {
            1
        }
    }

    private let displayModel: DisplayModel
    private var isSelected = false
    private var style = Style.detailed
    private let thumbnail: Thumbnail

    private var borderToken: BorderToken? {
        isSelected ? .highlight : nil
    }

}

// MARK: SelectionCard.DisplayModel

extension SelectionCard {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String,
            supportingText: String? = nil,
            badgeText: String? = nil,
        ) {
            self.title = title
            self.supportingText = supportingText
            self.badgeText = badgeText
        }

        public let title: String
        public let supportingText: String?
        public let badgeText: String?
    }
}

// MARK: SelectionCard.Style

extension SelectionCard {
    public enum Style: Sendable, Equatable {
        case detailed
        case compact

        // MARK: Internal

        var minimumHeight: CGFloat {
            switch self {
            case .detailed:
                80
            case .compact:
                52
            }
        }

        var showsThumbnail: Bool {
            self == .detailed
        }
    }
}

extension SelectionCard where Thumbnail == EmptyView {
    public init(
        displayModel: DisplayModel
    ) {
        self.init(displayModel: displayModel) { EmptyView() }
        style = .compact
    }
}

// MARK: StyleConfigurable

extension SelectionCard: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: SelectionCard 상태 선언

extension SelectionCard {
    public func selected(_ isSelected: Bool) -> Self {
        var copy = self
        copy.isSelected = isSelected
        return copy
    }
}

#Preview("Selection Card") {
    VStack(spacing: LayoutToken.gutter) {
        SelectionCard(
            displayModel: .init(
                title: "기술 개념은 알아요",
                supportingText: "실제 코드 흐름을 중심으로 학습",
            )
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .purple300))
        }

        SelectionCard(
            displayModel: .init(
                title: "프로젝트 경험이 있어요",
                supportingText: "심화 문제와 서술형 비중 확대",
            )
        ) {
            RoundedRectangle(designSystem: .small)
                .fill(Color(designSystem: .blue400))
        }
        .selected(true)
    }
    .frame(width: 340)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}

#Preview("Selection Card - compact · 737:10372") {
    VStack(spacing: LayoutToken.compactSpacing) {
        SelectionCard(displayModel: .init(title: "Front-end"))
        SelectionCard(displayModel: .init(title: "Back-end"))
            .selected(true)
    }
    .frame(width: 340)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
