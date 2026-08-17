import DesignSystem
import SwiftUI

public struct SelectionCardList: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct Item: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
            supportingText: String,
        ) {
            self.id = id
            self.title = title
            self.supportingText = supportingText
        }

        public let id: String
        public let title: String
        public let supportingText: String
    }

    public struct ViewModel: Sendable, Equatable {
        public init(items: [Item]) {
            self.items = items
        }

        public let items: [Item]
    }

    public var body: some View {
        VStack(spacing: Constant.itemSpacing) {
            ForEach(viewModel.items) { item in
                SelectionCard(
                    viewModel: .init(
                        title: item.title,
                        supportingText: item.supportingText,
                    )
                ) {
                    thumbnail
                }
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let itemSpacing: CGFloat = 8
        static let thumbnailOverlayOpacity = 0.2
    }

    private let viewModel: ViewModel

    private var thumbnail: some View {
        ResourceImage.Asset.selectionCardThumbnail.image
            .resizable()
            .scaledToFill()
            .overlay {
                LinearGradient(designSystem: .gradient3)
                    .opacity(Constant.thumbnailOverlayOpacity)
            }
    }

}

#Preview("Selection Card List") {
    SelectionCardList(viewModel: .init(items: [
        .init(
            id: "concept",
            title: "기술 개념은 알아요",
            supportingText: "실제 코드 작동 방식을 흐름 중심으로 학습",
        ),
        .init(
            id: "code",
            title: "일부 코드를 봤어요",
            supportingText: "구현 의도와 연결 영향까지 포함",
        ),
        .init(
            id: "project",
            title: "유사 프로젝트 경험이 있어요",
            supportingText: "심화 문제와 서술형 비중 확대",
        ),
    ]))
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
