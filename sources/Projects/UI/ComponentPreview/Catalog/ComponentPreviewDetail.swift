import SwiftUI

struct ComponentPreviewDetail<Content: View>: View {
    let title: String
    let variants: [String]
    let selectedVariant: String
    let onSelectVariant: (String) -> Void
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .top) {
            content
            ComponentPreviewChrome(
                title: title,
                variants: variants,
                selectedVariant: selectedVariant,
                onSelectVariant: onSelectVariant,
                onClose: onClose,
            )
        }
    }
}
