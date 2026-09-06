import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

extension SettingsScreen {
    @ViewAction(for: SettingsFeature.self)
    struct PositionSelectionView: View {

        // MARK: Internal

        @Bindable var store: StoreOf<SettingsFeature>

        var body: some View {
            OverlayContainer {
                VStack(alignment: .leading, spacing: Constant.headerTitleSpacing) {
                    HStack(alignment: .top, spacing: LayoutToken.gutter) {
                        IconGlassButton.neutral(
                            icon: ScreenControlBar.Control.back.icon,
                            label: ScreenControlBar.Control.back.label,
                            size: .medium,
                            action: { send(.backTapped) },
                        )

                        Spacer(minLength: 0)
                    }
                    .frame(height: Constant.headerControlRowHeight, alignment: .top)

                    ScreenHeaderTitle(title: Constant.title)
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(height: Constant.headerHeight, alignment: .top)
                .designSystemScreenMargin()
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
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

    }
}
