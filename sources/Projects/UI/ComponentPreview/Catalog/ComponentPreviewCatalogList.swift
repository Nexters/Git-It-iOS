import SwiftUI

struct ComponentPreviewCatalogList: View {
    let entries: [ComponentPreviewEntry]
    let onSelect: (String) -> Void

    var body: some View {
        List(entries) { entry in
            Button(entry.displayName) { onSelect(entry.componentID) }
                .accessibilityIdentifier("component.preview.route.\(entry.componentID)")
        }
        .navigationTitle("UI Components")
    }
}
