import DesignSystem
import SwiftUI
import UIComponent

extension SavedScreen {
    struct ErrorView: View {

        // MARK: Internal

        let isBackControlPresented: Bool
        let onBack: () -> Void
        let onRetry: () -> Void

        var body: some View {
            VStack(spacing: LayoutToken.margin) {
                VStack(alignment: .leading, spacing: Constant.headerTitleSpacing) {
                    HStack(alignment: .top, spacing: LayoutToken.gutter) {
                        if isBackControlPresented {
                            IconGlassButton.neutral(
                                icon: ScreenControlBar.Control.back.icon,
                                label: ScreenControlBar.Control.back.label,
                                size: .medium,
                                action: onBack,
                            )
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(height: Constant.headerControlRowHeight, alignment: .top)

                    ScreenHeaderTitle(title: "저장한 문제")
                }
                .padding(.bottom, Constant.headerBottomPadding)
                .frame(height: Constant.headerHeight, alignment: .top)
                .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.textSpacing) {
                    StyledText.subtitle1("저장한 문제를 불러오지 못했어요", alignment: .center)
                    StyledText.body2("잠시 후 다시 시도해 주세요.", color: .grey400, alignment: .center)
                }

                Spacer(minLength: 0)

                ActionButton.primary("다시 시도하기", action: onRetry)
                    .designSystemScreenMargin()
                    .padding(.bottom, Constant.bottomButtonPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let textSpacing: CGFloat = 10
            static let bottomButtonPadding: CGFloat = 24
            static let headerControlRowHeight: CGFloat = 40
            static let headerTitleSpacing: CGFloat = 16
            static let headerBottomPadding: CGFloat = 10
            static let headerHeight: CGFloat = 99
        }

    }
}
