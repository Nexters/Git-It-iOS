import ComposableArchitecture
import SwiftUI
import UIComponent

// MARK: - SettingsScreen

/// 설정 목록 화면(Figma `1465:19689`). 개발 분야·개발 수준·서비스 약관·로그아웃·계정 삭제 행을 담는다.
/// FR-014에 따라 "세트 생성 완료 알림" 섹션은 이번 범위에서 제외한다.
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
            ScreenOverlayHeader(
                title: Constant.title,
                style: .largeTitle,
                leading: .back,
                onLeadingTap: { send(.backTapped) },
            )
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                Self.SectionView(title: Constant.learningSectionTitle) {
                    SettingRow(
                        title: Constant.positionTitle,
                        value: PositionDisplay.settingValue(for: store.profile?.position),
                        onTap: { send(.positionRowTapped) },
                    )
                    rowDivider
                    SettingRow(
                        title: Constant.careerLevelTitle,
                        value: CareerLevelDisplay.settingValue(for: store.profile?.careerLevel),
                        onTap: { send(.careerLevelRowTapped) },
                    )
                }

                Self.SectionView(title: Constant.generalSectionTitle) {
                    SettingRow(
                        title: Constant.termsTitle,
                        onTap: { send(.termsTapped) },
                    )
                    rowDivider
                    AccountActionRow(
                        title: Constant.signOutTitle,
                        isDestructive: true,
                        onTap: { send(.signOutTapped) },
                    )
                    rowDivider
                    AccountActionRow(
                        title: Constant.deleteAccountTitle,
                        onTap: { send(.deleteAccountTapped) },
                    )
                }

                if let failureMessage {
                    StyledText.caption1(failureMessage, color: .error)
                        .padding(.top, Constant.failureTopPadding)
                }
            }
            .designSystemScreenMargin()
            .padding(.bottom, Constant.contentBottomPadding)
        }
        .task { await send(.task).finish() }
    }

    // MARK: Private

    private var rowDivider: some View {
        Rectangle()
            .fill(Color(designSystem: .grey500))
            .frame(height: Constant.dividerHeight)
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
        // 프로필을 한 번도 받지 못한 경우에만 조회 실패를 알린다(값이 있으면 유지, FR-007).
        guard case .failed = store.profileLoad, store.profile == nil else { return nil }
        return Constant.profileFailureMessage
    }

}

// MARK: SettingsScreen.Constant

extension SettingsScreen {
    fileprivate enum Constant {
        static let title = "설정"
        static let learningSectionTitle = "학습 설정"
        static let generalSectionTitle = "일반"
        static let positionTitle = "개발 분야"
        static let careerLevelTitle = "개발 수준"
        static let termsTitle = "서비스 약관 및 정책"
        static let signOutTitle = "로그아웃"
        static let deleteAccountTitle = "계정 삭제"
        static let accountActionFailureMessage = "요청을 처리하지 못했어요. 다시 시도해 주세요."
        static let profileFailureMessage = "프로필을 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        static let dividerHeight: CGFloat = 1
        static let failureTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 32
    }
}
