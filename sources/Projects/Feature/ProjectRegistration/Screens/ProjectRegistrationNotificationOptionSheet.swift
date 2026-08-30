import DesignSystem
import SwiftUI
import UIComponent

struct ProjectRegistrationNotificationOptionSheet: View {

    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            SheetSurface {
                VStack(spacing: Constant.contentSpacing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: Constant.bellIconSize))
                        .designSystemForeground(.blue200)
                        .frame(width: Constant.bellSize, height: Constant.bellSize)

                    VStack(spacing: Constant.textSetSpacing) {
                        StyledText.subtitle1("세트 생성이 완료되면\n리마인드 알림을 보내드려요.", alignment: .center)
                        StyledText.caption1("프로필 설정페이지에서 언제든 설정할 수 있어요.", color: .grey400, alignment: .center)
                    }

                    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                        ActionButton.primary("리마인드 알림 설정하기", action: onAccept)
                        ActionButton.text("다시 보지 않기", size: .medium, action: onDecline)
                    }
                }
                .padding(.top, Constant.contentTopPadding)
            }
        }
        .designSystemBackground(.clear)
        .presentationBackground(.clear)
    }

}

extension ProjectRegistrationNotificationOptionSheet {
    private enum Constant {
        static let contentSpacing: CGFloat = 24
        static let textSetSpacing: CGFloat = 8
        static let bellSize: CGFloat = 120
        static let bellIconSize: CGFloat = 48
        static let contentTopPadding: CGFloat = 16
    }
}
