import SwiftUI
import UIComponent

extension MainShellRouter {
    struct PlaceholderView: View {
        let title: String

        var body: some View {
            ScreenContainer { _ in
                StyledText.subtitle1(title, alignment: .center)
                    .designSystemScreenMargin()
            }
        }
    }
}
