import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.fill`.
public struct SelectionCardList: View {

    // MARK: Lifecycle

    public init(
        items: [Item],
        style: SelectionCardStyle = .detailed,
        onSelect: @escaping (String) -> Void = { _ in },
    ) {
        self.items = items
        self.style = style
        self.onSelect = onSelect
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: Constant.itemSpacing) {
            ForEach(items) { item in
                Button {
                    onSelect(item.id)
                } label: {
                    card(for: item)
                }
                .buttonStyle(.pressOverlay)
            }
        }
    }

    // MARK: Private

    private let items: [Item]
    private let style: SelectionCardStyle
    private let onSelect: (String) -> Void

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
                title: item.title,
                supportingText: item.supportingText,
                isSelected: item.isSelected,
                style: style,
            ) {
                if let illust = item.illust {
                    thumbnail(for: illust)
                }
            }
        } else {
            SelectionCard(
                title: item.title,
                supportingText: item.supportingText,
                isSelected: item.isSelected,
            )
        }
    }

}

#Preview("Selection Card List") {
    SelectionCardList(items: [
        .init(
            id: "concept",
            title: "기술 개념은 알아요",
            supportingText: "실제 코드 작동 방식을 흐름 중심으로 학습",
            illust: .knowledgeBasic,
        ),
        .init(
            id: "code",
            title: "일부 코드를 봤어요",
            supportingText: "구현 의도와 연결 영향까지 포함",
            illust: .knowledgeIntermediate,
            isSelected: true,
        ),
        .init(
            id: "project",
            title: "유사 프로젝트 경험이 있어요",
            supportingText: "심화 문제와 서술형 비중 확대",
            illust: .knowledgeAdvanced,
        ),
    ])
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
