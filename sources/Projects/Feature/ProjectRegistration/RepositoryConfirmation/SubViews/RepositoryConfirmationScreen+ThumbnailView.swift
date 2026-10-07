import DesignSystem
import Foundation
import SwiftUI
import UIComponent

extension RepositoryConfirmationScreen {
    struct ThumbnailView: View {

        // MARK: Internal

        let avatarURL: URL?

        var body: some View {
            placeholder
                .overlay { avatar }
                .frame(
                    width: Constant.size,
                    height: Constant.size,
                )
                .designSystemCornerRadius(.medium)
                .accessibilityHidden(true)
        }

        // MARK: Private

        @ViewBuilder
        private var avatar: some View {
            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)

                    case .empty:
                        ResourceAnimation(asset: .generalLoading)
                            .frame(
                                width: Constant.loadingSize,
                                height: Constant.loadingSize,
                            )

                    case .failure:
                        EmptyView()

                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }

        private var placeholder: some View {
            RoundedRectangle(designSystem: .medium)
                .fill(Color(designSystem: .grey600))
                .overlay {
                    LinearGradient(designSystem: .gradient3)
                        .opacity(Constant.overlayOpacity)
                }
        }

        private enum Constant {
            static let size: CGFloat = 80
            static let loadingSize: CGFloat = 28
            static let overlayOpacity = 0.2
        }

    }
}
