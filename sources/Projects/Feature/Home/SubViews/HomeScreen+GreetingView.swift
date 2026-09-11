import SwiftUI
import UIComponent

extension HomeScreen {
    struct GreetingView: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                StyledText.headline1("Hello World", color: .grey400)
                StyledText.headline1("Let’s Git -it-!")
            }
            .accessibilityElement(children: .combine)
        }
    }
}
