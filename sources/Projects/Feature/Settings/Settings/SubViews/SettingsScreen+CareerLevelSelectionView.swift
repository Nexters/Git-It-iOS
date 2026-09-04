import ComposableArchitecture
import SwiftUI
import UIComponent

extension SettingsScreen {
    /// 개발 수준 선택 단계(Figma `1535:18378`). 선택 즉시 `careerLevelSelected`로 저장한다.
    @ViewAction(for: SettingsFeature.self)
    struct CareerLevelSelectionView: View {

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
        }

        // MARK: Private

        private enum Constant {
            static let title = "개발 수준"
            static let failureMessage = "변경에 실패했어요. 다시 시도해 주세요."
            static let messageSpacing: CGFloat = 12
            static let contentTopPadding: CGFloat = 8
        }

    }
}
