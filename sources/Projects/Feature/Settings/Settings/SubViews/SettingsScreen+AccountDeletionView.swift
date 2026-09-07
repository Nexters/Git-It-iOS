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
                VStack(alignment: .leading, spacing: Constant.headerTitleSpacing) {
                    HStack(alignment: .top, spacing: LayoutToken.gutter) {
                        IconGlassButton.neutral(
                            icon: ScreenControlBar.Control.back.icon,
                            label: ScreenControlBar.Control.back.label,
                            size: .medium,
                            action: { send(.deleteAccountCancelled) },
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
                VStack(alignment: .leading, spacing: Constant.paragraphSpacing) {
                    ForEach(Constant.paragraphs, id: \.self) { paragraph in
                        StyledText.body1(paragraph)
                    }

                    if case .failed = store.accountAction {
                        StyledText.caption1(Constant.failureMessage, color: .error)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .designSystemScreenMargin()
                .padding(.top, Constant.contentTopPadding)
            } footer: {
                BottomActionBar {
                    ActionButton.text(
                        styledText: StyledText.body1(Constant.confirmTitle, color: .error, alignment: .center),
                        isEnabled: store.accountAction != .deletingAccount,
                        action: { send(.deleteAccountConfirmed) },
                    )
                    .designSystemScreenMargin()
                }
            }
            .toolbar(.hidden, for: .tabBar)

        }

        // MARK: Private

        private enum Constant {
            static let title = "계정 삭제"
            static let confirmTitle = "계정 삭제"
            static let paragraphs = [
                "계속 진행하면 깃잇에 저장된 모든 개인정보가 삭제됩니다. 학습 진도와 제작한 문제 또한 잃게 되니 주의하세요. 이 절차가 완료된 후에는 다시 되돌릴 수 없습니다.",
                "개인정보 삭제는 최대 30일까지 소요될 수 있습니다. 계정 비활성화 절차를 취소하고 계정을 복구하길 원하시면 서비스 메일로 문의해주세요.",
                "주의하세요.\n아래 “계정 삭제”를 클릭하면 즉시 삭제됩니다.",
            ]
            static let failureMessage = "계정을 삭제하지 못했어요. 다시 시도해 주세요."
            static let paragraphSpacing: CGFloat = 24
            static let contentTopPadding: CGFloat = 8
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

    }
}
