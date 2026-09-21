import SwiftUI
import UIComponent

extension HomeScreen {
    struct GreetingView: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                StyledText(text: "Hello World", style: .headline1, color: .grey400)
                StyledText(text: "Let’s Git -it-!", style: .headline1)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
