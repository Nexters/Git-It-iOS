import DesignSystem
import SwiftUI
import UIComponent

extension ProjectListScreen {
    struct Thumbnail: View {

        // MARK: Internal

        let imageURL: String?

        var body: some View {
            if let imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }

        // MARK: Private

        private var placeholder: some View {
            Color(designSystem: .grey500)
        }

    }
}
