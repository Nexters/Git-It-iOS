import DesignSystem
import SwiftUI

// MARK: - SelectionCardList

public struct SelectionCardList: View {

    // MARK: Lifecycle

    public init(
        items: [Item],
        selection: Binding<String?>,
    ) {
        self.items = items
        _selection = selection
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: Constant.itemSpacing) {
            ForEach(items) { item in
                Button {
                    select(item)
                } label: {
                    card(for: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Internal

    func isSelected(_ item: Item) -> Bool {
        selection == item.id
    }

    func select(_ item: Item) {
        selection = item.id
    }

    // MARK: Private

    @Binding private var selection: String?

    private let items: [Item]
    private var style = Style.detailed

    private func thumbnail(for illust: ResourceImage.Asset.Illust) -> some View {
        Image.resizable(.illust(illust))
            .scaledToFill()
            .overlay {
                LinearGradient(designSystem: .gradient3)
                    .opacity(Constant.thumbnailOverlayOpacity)
            }
    }

    @ViewBuilder
    private func card(for item: Item) -> some View {
        if style.showsThumbnail {
            SelectionCard(
                displayModel: .init(title: item.displayModel.title, supportingText: item.displayModel.supportingText),
                isSelected: isSelected(item),
            ) {
                if let illust = item.displayModel.illust {
                    thumbnail(for: illust)
                }
            }
        } else {
            SelectionCard(
                displayModel: .init(title: item.displayModel.title, supportingText: item.displayModel.supportingText),
                isSelected: isSelected(item),
            )
        }
    }

}

// MARK: StyleConfigurable

extension SelectionCardList: StyleConfigurable {
    public func style(_ style: Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: SelectionCardList.Style

extension SelectionCardList {
    public enum Style: Sendable, Equatable {
        case detailed
        case compact

        // MARK: Internal

        var showsThumbnail: Bool {
            self == .detailed
        }
    }
}

// MARK: SelectionCardList.Constant

extension SelectionCardList {
    fileprivate enum Constant {
        static let itemSpacing: CGFloat = 8
        static let thumbnailOverlayOpacity = 0.2
    }
}

// MARK: SelectionCardList.Item

extension SelectionCardList {
    public struct Item: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            displayModel: DisplayModel,
        ) {
            self.id = id
            self.displayModel = displayModel
        }

        public let id: String
        public let displayModel: DisplayModel
    }
}

// MARK: - SelectionCardList.Item.DisplayModel

extension SelectionCardList.Item {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String,
            supportingText: String? = nil,
            illust: ResourceImage.Asset.Illust? = nil,
        ) {
            self.title = title
            self.supportingText = supportingText
            self.illust = illust
        }

        public let title: String
        public let supportingText: String?
        public let illust: ResourceImage.Asset.Illust?
    }
}

#Preview("Selection Card List") {
    SelectionCardList(
        items: [
            .init(
                id: "concept",
                displayModel: .init(
                    title: "기술 개념은 알아요",
                    supportingText: "실제 코드 작동 방식을 흐름 중심으로 학습",
                    illust: .knowledgeBasic,
                ),
            ),
            .init(
                id: "code",
                displayModel: .init(
                    title: "일부 코드를 봤어요",
                    supportingText: "구현 의도와 연결 영향까지 포함",
                    illust: .knowledgeIntermediate,
                ),
            ),
            .init(
                id: "project",
                displayModel: .init(
                    title: "유사 프로젝트 경험이 있어요",
                    supportingText: "심화 문제와 서술형 비중 확대",
                    illust: .knowledgeAdvanced,
                ),
            ),
        ],
        selection: .constant("code"),
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
