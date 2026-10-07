import ComposableArchitecture
import SwiftUI
import UIComponent

extension SettingsScreen {
    /// 개발 분야 선택 단계(Figma `1535:18281`). 선택 즉시 `positionSelected`로 저장한다.
    @ViewAction(for: SettingsFeature.self)
    struct PositionSelectionView: View {

        // MARK: Internal

        @Bindable var store: StoreOf<SettingsFeature>

        var body: some View {
            OverlayContainer {
                ScreenOverlayHeader(
                    title: Constant.title,
                    style: .largeTitle,
                    leading: .back,
                    onLeadingTap: { send(.backTapped) },
                )
            } content: {
                VStack(spacing: Constant.messageSpacing) {
                    if case .failed = store.positionMutation {
                        StyledText.caption1(Constant.failureMessage, color: .error, alignment: .center)
                    }

                    SelectionCardList(
                        items: PositionDisplay.orderedPositions.map { position in
                            .init(
                                id: PositionDisplay.identifier(for: position),
                                title: PositionDisplay.title(for: position),
                                isSelected: store.profile?.position == position,
                            )
                        },
                        style: .compact,
                        onSelect: { identifier in
                            if let position = PositionDisplay.position(forIdentifier: identifier) {
                                send(.positionSelected(position))
                            }
                        },
                    )
                }
                .designSystemScreenMargin()
                .padding(.top, Constant.contentTopPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let title = "개발 분야"
            static let failureMessage = "변경에 실패했어요. 다시 시도해 주세요."
            static let messageSpacing: CGFloat = 12
            static let contentTopPadding: CGFloat = 8
        }

    }
}
