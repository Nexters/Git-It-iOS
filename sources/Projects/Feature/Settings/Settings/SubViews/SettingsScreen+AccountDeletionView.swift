import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

extension SettingsScreen {
    @ViewAction(for: SettingsFeature.self)
    struct AccountDeletionView: View {

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
                            action: { send(.deleteAccountCancelled) },
                        )
                        .size(.medium)

                        Spacer(minLength: 0)
                    }
                    .frame(
                        height: Constant.headerControlRowHeight,
                        alignment: .top,
                    )

                    ScreenHeaderTitle(displayModel: .init(title: LocalizedText.Settings.AccountDeletion.title))
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(
                    height: Constant.headerHeight,
                    alignment: .top,
                )
                .designSystemScreenMargin()
            } content: {
                VStack(
                    alignment: .leading,
                    spacing: Constant.paragraphSpacing,
                ) {
                    ForEach(
                        paragraphs,
                        id: \.self,
                    ) { paragraph in
                        StyledText(text: paragraph)
                    }

                    if case .failed = store.accountAction.accountAction {
                        StyledText(text: LocalizedText.Settings.AccountDeletion.Failure.message)
                            .textStyle(.caption1)
                            .foregroundColorToken(.error)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading,
                )
                .designSystemScreenMargin()
                .padding(.top, Constant.contentTopPadding)
            } footer: {
                BottomActionBar {
                    FeedbackActionButton(
                        styledText: StyledText(text: LocalizedText.Settings.AccountDeletion.Confirm.buttonTitle)
                            .foregroundColorToken(.error),
                        action: { send(.deleteAccountConfirmed) },
                    )
                    .enabled(store.accountAction.accountAction != .deletingAccount)
                    .style(.text)
                    .multilineTextAlignment(.center)
                    .designSystemScreenMargin()
                }
            }
            .toolbar(
                .hidden,
                for: .tabBar,
            )
        }

        // MARK: Private

        private enum Constant {
            static let paragraphSpacing: CGFloat = 24
            static let contentTopPadding: CGFloat = 8
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

        private var paragraphs: [String] {
            [
                LocalizedText.Settings.AccountDeletion.First.paragraph,
                LocalizedText.Settings.AccountDeletion.Second.paragraph,
                LocalizedText.Settings.AccountDeletion.Third.paragraph,
            ]
        }

    }
}
