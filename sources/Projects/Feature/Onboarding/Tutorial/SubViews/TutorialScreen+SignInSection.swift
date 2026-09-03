import DesignSystem
import SwiftUI
import UIComponent

extension TutorialScreen {
    struct SignInSection: View {
        
        // MARK: Internal
        
        let currentPage: Int
        let totalPages: Int
        let bundleVersion: String
        let isHintVisible: Bool
        let onAppleSignIn: () -> Void
        
        var body: some View {
            VStack {
                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                    .padding(Constant.indicatorPadding)
                
                
                StyledText.caption1(Constant.hintTitle, color: .grey400, alignment: .center)
                    .opacity(isHintVisible ? 1 : 0)
                    .accessibilityHidden(!isHintVisible)
                    .padding(.bottom, LayoutToken.compactSpacing.cgFloatValue)
                
                AppleSignInButton(action: onAppleSignIn)
                
                StyledText.body2("버전 \(bundleVersion)", color: .grey500, alignment: .center)
                    .padding(.top, Constant.versionTopSpacing)
            }
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomInset)
        }
        
        // MARK: Private
        
        private enum Constant {
            static let hintTitle = "3초만에 가입하기"
            static let indicatorPadding: CGFloat = 12
            static let versionTopSpacing: CGFloat = 21
            static let bottomInset: CGFloat = 29
        }
        
    }
}
