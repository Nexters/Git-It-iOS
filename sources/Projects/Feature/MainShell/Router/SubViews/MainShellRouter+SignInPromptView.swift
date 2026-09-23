import DesignSystem
import SwiftUI
import UIComponent

extension MainShellRouter {
    struct SignInPromptView: View {

        let onSignIn: () -> Void

        var body: some View {
            ScreenContainer {
                VStack(spacing: LayoutToken.compactSpacing) {
                    Spacer()
                    StyledText(text: LocalizedText.MainShell.signInPromptTitle)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: LocalizedText.MainShell.signInPromptMessage)
                        .textStyle(.body2)
                        .multilineTextAlignment(.center)
                    Spacer()
                    AppleSignInButton(action: onSignIn)
                        .padding(.bottom, LayoutToken.margin)
                }
                .designSystemScreenMargin()
            }
        }

    }
}
