import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - SettingsScreen

@ViewAction(for: SettingsFeature.self)
public struct SettingsScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<SettingsFeature>

    public var body: some View {
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

                ScreenHeaderTitle(displayModel: .init(title: LocalizedText.Settings.title))
                    .frame(
                        height: Constant.headerControlRowHeight,
                        alignment: .top,
                    )
            }
            .padding(.bottom, Constant.headerBottomPadding)
            .designSystemScreenMargin()
        } content: {
            VStack(
                alignment: .leading,
                spacing: 10,
            ) {
                Self.SectionView(title: LocalizedText.Settings.LearningSection.title) {
                    SettingRow(
                        value: PositionDisplay.settingValue(for: store.profile?.curation?.position),
                        content: {
                            Self.SettingRowContent(
                                icon: .settingDevelop,
                                title: LocalizedText.Settings.Position.title,
                            )
                        },
                        onTap: {
                            send(.positionRowTapped)
                        },
                    )
                    SettingRow(
                        value: CareerLevelDisplay.settingValue(for: store.profile?.curation?.careerLevel),
                        content: {
                            Self.SettingRowContent(
                                icon: .settingLevel,
                                title: LocalizedText.Settings.CareerLevel.title,
                            )
                        },
                        onTap: { send(.careerLevelRowTapped) },
                    )
                }

                Self.SectionView(title: LocalizedText.Settings.NotificationSection.title) {
                    SettingRow(
                        value: notificationValue,
                        content: {
                            Self.SettingRowContent(
                                icon: .settingAlert,
                                title: LocalizedText.Settings.Notification.title,
                            )
                        },
                        onTap: {
                            send(.notificationRowTapped)
                        },
                    )
                }

                Self.SectionView(title: LocalizedText.Settings.GeneralSection.title) {
                    SettingRow(
                        content: {
                            Self.SettingRowContent(
                                icon: .settingPolicy,
                                title: LocalizedText.Settings.Terms.title,
                            )
                        },
                        onTap: { send(.termsTapped) },
                    )
                    SettingRow(
                        content: {
                            HStack(spacing: 10) {
                                ResourceImage(asset: .icon(.settingLogout))
                                    .frame(
                                        width: 16,
                                        height: 16,
                                    )
                                StyledText(text: LocalizedText.Settings.SignOut.buttonTitle)
                                    .textStyle(.body2)
                                    .foregroundColorToken(.error)
                            }
                        },
                        onTap: {
                            send(.signOutTapped)
                        },
                    )
                    SettingRow(
                        content: {
                            StyledText(text: LocalizedText.Settings.DeleteAccount.buttonTitle)
                                .textStyle(.body2)
                                .foregroundColorToken(.grey400)
                        },
                        onTap: {
                            send(.deleteAccountTapped)
                        },
                    )
                }

                if let failureMessage {
                    StyledText(text: failureMessage)
                        .textStyle(.caption1)
                        .foregroundColorToken(.error)
                        .padding(.top, Constant.failureTopPadding)
                }
            }
            .designSystemScreenMargin()
            .padding(.vertical, Constant.contentBottomPadding)
        }
        .task { await send(.task).finish() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            send(.applicationBecameActive)
        }
        .toolbar(
            .hidden,
            for: .tabBar,
        )
    }

    // MARK: Private

    @Environment(\.scenePhase) private var scenePhase

    private var rowDivider: some View {
        Rectangle()
            .fill(Color(designSystem: .grey500))
            .frame(height: 0)
    }

    private var failureMessage: String? {
        switch store.accountAction.accountAction {
        case .failed:
            LocalizedText.Settings.AccountActionFailure.message

        case .idle,
             .signingOut,
             .confirmingDeletion,
             .deletingAccount:
            profileFailureMessage
        }
    }

    private var profileFailureMessage: String? {
        guard case .failed = store.userProfile.load else { return nil }
        return LocalizedText.Settings.ProfileFailure.message
    }

    private var notificationValue: String? {
        switch store.notificationPermission.notificationStatus {
        case .idle:
            nil

        case .allowed:
            LocalizedText.Settings.Notification.On.value

        case .denied:
            LocalizedText.Settings.Notification.Off.value
        }
    }

}

// MARK: SettingsScreen.Constant

extension SettingsScreen {
    fileprivate enum Constant {
        static let dividerHeight: CGFloat = 1
        static let failureTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 32
        static let headerControlRowHeight: CGFloat = 40
        static let headerTitleSpacing: CGFloat = 16
        static let headerBottomPadding: CGFloat = 10
        static let headerHeight: CGFloat = 99
    }
}
