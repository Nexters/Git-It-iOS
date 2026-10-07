import DesignSystem
import SwiftUI
import UIComponent

// MARK: - CurationSplashScreen

struct CurationSplashScreen: View {

    // MARK: Internal

    let onCompletion: @MainActor @Sendable () -> Void

    var body: some View {
        ScreenContainer { _ in
            SplashView(onCompletion: onCompletion)
                .designSystemScreenMargin()
        }
    }

}
