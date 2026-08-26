import DesignSystem
import SwiftUI

public struct SelectionCardList: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onSelect: @escaping (String) -> Void = { _ in },
    ) {
        self.viewModel = viewModel
        self.onSelect = onSelect
    }

    // MARK: Public

    /// Domain 타입을 노출하지 않는 generic 단일 선택 값입니다. 여러 `Item`이 동시에
    /// `isSelected == true`여도 이 컴포넌트는 강제하지 않으며, 단일 선택 규칙은 호출자가
    /// `onSelect`로 전달받은 `id`로 `items`를 다시 구성해 유지합니다.
    public struct Item: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
            supportingText: String,
            isSelected: Bool = false,
        ) {
            self.id = id
            self.title = title
            self.supportingText = supportingText
            self.isSelected = isSelected
        }

        public let id: String
        public let title: String
        public let supportingText: String
        public let isSelected: Bool
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
                Button {
                    onSelect(item.id)
                } label: {
                    SelectionCard(
                        viewModel: .init(
                            title: item.title,
                            supportingText: item.supportingText,
                            isSelected: item.isSelected,
                        )
                    ) {
                        thumbnail
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let itemSpacing: CGFloat = 8
        static let thumbnailOverlayOpacity = 0.2
    }

    private let viewModel: ViewModel
    private let onSelect: (String) -> Void

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
            isSelected: true,
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
