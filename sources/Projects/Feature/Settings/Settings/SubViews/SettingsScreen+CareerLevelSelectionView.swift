import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

extension SettingsScreen {
    @ViewAction(for: SettingsFeature.self)
    struct CareerLevelSelectionView: View {

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

                    ScreenHeaderTitle(displayModel: .init(title: LocalizedText.Settings.CareerLevelSelection.title))
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(
                    height: Constant.headerHeight,
                    alignment: .top,
                )
                .designSystemScreenMargin()
            } content: {
                VStack(spacing: Constant.messageSpacing) {
                    if case .failed = store.curationUpdate.careerLevelMutation {
                        StyledText(text: LocalizedText.Settings.CareerLevelSelection.Failure.message)
                            .textStyle(.caption1)
                            .foregroundColorToken(.error)
                            .multilineTextAlignment(.center)
                    }

                    SelectionCardList(
                        items: CareerLevelDisplay.orderedLevels.map { level in
                            .init(
                                id: CareerLevelDisplay.identifier(for: level),
                                displayModel: .init(
                                    title: CareerLevelDisplay.title(for: level),
                                    supportingText: CareerLevelDisplay.description(for: level),
                                    illust: CareerLevelDisplay.illust(for: level),
                                ),
                            )
                        },
                        selection: Binding(
                            get: { (store.profile?.curation?.careerLevel).map(CareerLevelDisplay.identifier(for:)) },
                            set: { identifier in
                                if let identifier, let level = CareerLevelDisplay.level(forIdentifier: identifier) {
                                    send(.careerLevelSelected(level))
                                }
                            },
                        ),
                    )
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
