import DesignSystem
import SwiftUI
import UIComponent

struct LayoutContractCatalog: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutToken.margin.cgFloatValue) {
                Text("Figma 레이아웃 계약")
                    .font(.title2.bold())

                VStack(spacing: LayoutToken.gutter.cgFloatValue) {
                    ActionButton.primary("Large")
                        .accessibilityIdentifier("action.large.primary")

                    ActionButton.primary("Large Disabled", isEnabled: false)
                        .accessibilityIdentifier("action.large.disabled")

                    ActionButton.primary("Small", size: .small)
                        .accessibilityIdentifier("action.small.primary")
                }
                .frame(width: 240)

                GlassEffectContainer(spacing: LayoutToken.margin.cgFloatValue) {
                    HStack(spacing: LayoutToken.margin.cgFloatValue) {
                        IconGlassButton.neutral(
                            symbol: "chevron.left",
                            label: "Medium icon",
                            size: .medium,
                        )
                        .accessibilityIdentifier("iconGlass.medium.neutral")

                        IconGlassButton.neutral(
                            symbol: "chevron.left",
                            label: "Small icon",
                            size: .small,
                        )
                        .accessibilityIdentifier("iconGlass.small.neutral")
                    }
                }

                IconPlainButton(
                    viewModel: .init(symbol: "ic-play-1", label: "Plain icon")
                )
                .accessibilityIdentifier("iconPlain.default")

                TagBadge.accent("Layout")
                    .accessibilityIdentifier("tag.accent")
            }
            .designSystemScreenMargin()
            .padding(.vertical, LayoutToken.margin.cgFloatValue)
        }
        .accessibilityIdentifier("layout.contract.catalog")
        .designSystemBackground(.grey700)
        .preferredColorScheme(.dark)
    }
}
