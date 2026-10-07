import DesignSystem
import SwiftUI
import UIComponent

extension OnboardingRouter {
    struct CurationSplashView: View {

        // MARK: Internal

        let onCompletion: @MainActor @Sendable () -> Void

        var body: some View {
            ScreenContainer {
                SplashView(onCompletion: onCompletion)
                    .designSystemScreenMargin()
            }
        }

    }
}
