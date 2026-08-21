import SwiftUI

struct ComponentPreviewChrome: View {
    let title: String
    let variants: [String]
    let selectedVariant: String
    let onSelectVariant: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button("목록", action: onClose)
            Text(title)
            Spacer()
            if variants.count > 1 {
                Picker("Variant", selection: Binding(get: { selectedVariant }, set: onSelectVariant)) {
                    ForEach(variants, id: \.self) { Text($0).tag($0) }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
