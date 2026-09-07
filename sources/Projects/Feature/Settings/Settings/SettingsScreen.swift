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
                    .frame(height: Constant.headerControlRowHeight, alignment: .top)
            }
            .padding(.bottom, Constant.headerBottomPadding)
            .designSystemScreenMargin()
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                Self.SectionView(title: Constant.learningSectionTitle) {
                    SettingRow(
                        value: PositionDisplay.settingValue(for: store.profile?.position),
                        content: {
                            Self.SettingRowContent(icon: .settingDevelop, title: Constant.positionTitle)
                        },
                        onTap: {
                            send(.positionRowTapped)
                        },
                    )
                    SettingRow(
                        value: CareerLevelDisplay.settingValue(for: store.profile?.careerLevel),
                        content: {
                            Self.SettingRowContent(icon: .settingLevel, title: Constant.careerLevelTitle)
                        },
                        onTap: { send(.careerLevelRowTapped) },
                    )
                }

                Self.SectionView(title: Constant.notificationSectionTitle) {
                    SettingRow(
                        value: notificationValue,
                        content: {
                            Self.SettingRowContent(icon: .settingAlert, title: Constant.notificationTitle)
                        },
                        onTap: {
                            send(.notificationRowTapped)
                        },
                    )
                }

                Self.SectionView(title: Constant.generalSectionTitle) {
                    SettingRow(
                        content: {
                            Self.SettingRowContent(icon: .settingPolicy, title: Constant.termsTitle)
                        },
                        onTap: { send(.termsTapped) },
                    )
                    SettingRow(
                        content: {
                            HStack(spacing: 10) {
                                ResourceImage(asset: .icon(.settingLogout))
                                    .frame(width: 16, height: 16)
                                StyledText.body2(Constant.signOutTitle, color: .error)
                            }
                        },
                        onTap: {
                            send(.signOutTapped)
                        },
                    )
                    SettingRow(
                        content: {
                            StyledText.body2(Constant.deleteAccountTitle, color: .grey400)
                        },
                        onTap: {
                            send(.deleteAccountTapped)
                        },
                    )
                }

                if let failureMessage {
                    StyledText.caption1(failureMessage, color: .error)
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
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: Private

    @Environment(\.scenePhase) private var scenePhase

    private var rowDivider: some View {
        Rectangle()
            .fill(Color(designSystem: .grey500))
            .frame(height: 0)
    }

    private var failureMessage: String? {
        switch store.accountAction {
        case .failed:
            Constant.accountActionFailureMessage

        case .idle,
             .signingOut,
             .confirmingDeletion,
             .deletingAccount:
            profileFailureMessage
        }
    }

    private var profileFailureMessage: String? {
        guard case .failed = store.profileLoad, store.profile == nil else { return nil }
        return Constant.profileFailureMessage
    }

    private var notificationValue: String? {
        switch store.notificationStatus {
        case .idle:
            nil

        case .allowed:
            Constant.notificationOnValue

        case .denied:
            Constant.notificationOffValue
        }
    }

}

// MARK: SettingsScreen.Constant

extension SettingsScreen {
    fileprivate enum Constant {
        static let title = "설정"
        static let learningSectionTitle = "학습 설정"
        static let notificationSectionTitle = "알림"
        static let generalSectionTitle = "일반"
        static let positionTitle = "개발 분야"
        static let careerLevelTitle = "개발 수준"
        static let notificationTitle = "세트 생성 완료 알림"
        static let notificationOnValue = "켜짐"
        static let notificationOffValue = "꺼짐"
        static let termsTitle = "서비스 약관 및 정책"
        static let signOutTitle = "로그아웃"
        static let deleteAccountTitle = "계정 삭제"
        static let accountActionFailureMessage = "요청을 처리하지 못했어요. 다시 시도해 주세요."
        static let profileFailureMessage = "프로필을 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        static let dividerHeight: CGFloat = 1
        static let failureTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 32
        static let headerControlRowHeight: CGFloat = 40
        static let headerTitleSpacing: CGFloat = 16
        static let headerBottomPadding: CGFloat = 10
        static let headerHeight: CGFloat = 99
    }
}
