import SwiftUI
import UIComponent

extension HomeScreen {
    struct GreetingView: View {
        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 0,
            ) {
                StyledText(text: "Hello World")
                    .textStyle(.headline1)
                    .foregroundColorToken(.grey400)
                StyledText(text: "Let’s Git -it-!")
                    .textStyle(.headline1)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
