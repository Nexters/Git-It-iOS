import SwiftUI
import UIComponent

extension AppEntryScreen {
    struct ErrorView: View {
        let onRetry: () -> Void

        var body: some View {
            VStack(spacing: Constant.spacing) {
                StyledText.subtitle2("세션을 확인하지 못했어요", alignment: .center)
                StyledText.body2("네트워크 상태를 확인한 뒤 다시 시도해 주세요.", color: .grey400, alignment: .center)

                ActionButton.primary("다시 시도", action: onRetry)
            }
        }

        private enum Constant {
            static let spacing: CGFloat = 16
        }
    }
}
