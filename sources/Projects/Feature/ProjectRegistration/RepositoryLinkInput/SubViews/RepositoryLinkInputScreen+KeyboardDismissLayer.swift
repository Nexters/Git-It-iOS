import SwiftUI

extension RepositoryLinkInputScreen {
    struct KeyboardDismissLayer: View {

        let onTap: () -> Void

        var body: some View {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
        }

    }
}
