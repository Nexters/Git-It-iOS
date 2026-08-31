import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - RepositoryConfirmationScreen

struct RepositoryConfirmationScreen: View {

    // MARK: Internal

    let repository: ExternalRepository
    let onConfirm: () -> Void
    let onReject: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(style: .largeTitle, onLeadingTap: onBack)
                .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.textSetSpacing) {
                StyledText.subtitle1("이 레포지토리가 맞으면\n학습 설정을 진행할게요", alignment: .center)

                VStack(spacing: Constant.thumbnailSpacing) {
                    thumbnail

                    VStack(spacing: 0) {
                        StyledText.caption1(repository.ownerName, color: .white70)
                        StyledText.body1(repository.repositoryName)
                    }
                }
                .padding(.top, Constant.thumbnailTopPadding)
            }
            .designSystemScreenMargin()
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                ActionButton.primary("다음", action: onConfirm)
                ActionButton.secondary("이 레포지토리가 아니에요", action: onReject)
            }
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

    // MARK: Private

    private var thumbnail: some View {
        Group {
            if let imageURL = repository.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
        .designSystemCornerRadius(.medium)
        .clipped()
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(designSystem: .medium)
            .fill(Color(designSystem: .grey600))
            .overlay {
                LinearGradient(designSystem: .gradient3)
                    .opacity(Constant.thumbnailOverlayOpacity)
            }
    }

}

// MARK: RepositoryConfirmationScreen.Constant

extension RepositoryConfirmationScreen {
    private enum Constant {
        static let textSetSpacing: CGFloat = 16
        static let thumbnailSpacing: CGFloat = 12
        static let thumbnailTopPadding: CGFloat = 40
        static let thumbnailSize: CGFloat = 80
        static let thumbnailOverlayOpacity = 0.2
        static let bottomButtonPadding: CGFloat = 34
    }
}
