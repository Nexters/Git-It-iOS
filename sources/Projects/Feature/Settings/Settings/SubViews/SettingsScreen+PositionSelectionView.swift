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
                VStack(
                    alignment: .leading,
                    spacing: Constant.headerTitleSpacing,
                ) {
                    HStack(
                        alignment: .top,
                        spacing: LayoutToken.gutter,
                    ) {
                        IconGlassButton(
                            icon: ScreenControlBar.Control.back.icon,
                            action: { send(.backTapped) },
                        )
                        .size(.medium)

                        Spacer(minLength: 0)
                    }
                    .frame(
                        height: Constant.headerControlRowHeight,
                        alignment: .top,
                    )

                    ScreenHeaderTitle(displayModel: .init(title: LocalizedText.Settings.PositionSelection.title))
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(
                    height: Constant.headerHeight,
                    alignment: .top,
                )
                .designSystemScreenMargin()
            } content: {
                VStack(spacing: Constant.messageSpacing) {
                    if case .failed = store.curationUpdate.positionMutation {
                        StyledText(text: LocalizedText.Settings.PositionSelection.Failure.message)
                            .textStyle(.caption1)
                            .foregroundColorToken(.error)
                            .multilineTextAlignment(.center)
                    }

                    SelectionCardList(
                        items: PositionDisplay.orderedPositions.map { position in
                            .init(
                                id: PositionDisplay.identifier(for: position),
                                displayModel: .init(title: PositionDisplay.title(for: position)),
                            )
                        },
                        selection: Binding(
                            get: { (store.profile?.curation?.position).map(PositionDisplay.identifier(for:)) },
                            set: { identifier in
                                if let identifier, let position = PositionDisplay.position(forIdentifier: identifier) {
                                    send(.positionSelected(position))
                                }
                            },
                        ),
                    )
                    .style(.compact)
                }
                .designSystemScreenMargin()
                .padding(.top, Constant.contentTopPadding)
            }
            .toolbar(
                .hidden,
                for: .tabBar,
            )
        }

        // MARK: Private

        private enum Constant {
            static let messageSpacing: CGFloat = 12
            static let contentTopPadding: CGFloat = 8
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

    }
}
