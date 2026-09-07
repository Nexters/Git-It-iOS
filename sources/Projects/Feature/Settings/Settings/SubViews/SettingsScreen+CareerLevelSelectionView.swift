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
                    if case .failed = store.careerLevelMutation {
                        StyledText.caption1(Constant.failureMessage, color: .error, alignment: .center)
                    }

                    SelectionCardList(
                        items: CareerLevelDisplay.orderedLevels.map { level in
                            .init(
                                id: CareerLevelDisplay.identifier(for: level),
                                title: CareerLevelDisplay.title(for: level),
                                supportingText: CareerLevelDisplay.description(for: level),
                                illust: CareerLevelDisplay.illust(for: level),
                                isSelected: store.profile?.careerLevel == level,
                            )
                        },
                        onSelect: { identifier in
                            if let level = CareerLevelDisplay.level(forIdentifier: identifier) {
                                send(.careerLevelSelected(level))
                            }
                        },
                    )
                }
                .designSystemScreenMargin()
                .padding(.top, Constant.contentTopPadding)
            }
            .toolbar(.hidden, for: .tabBar)

        }

        // MARK: Private

        private enum Constant {
            static let title = "개발 수준"
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
