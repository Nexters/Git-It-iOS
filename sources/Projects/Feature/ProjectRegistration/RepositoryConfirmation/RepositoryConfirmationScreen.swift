import ComposableArchitecture
import DesignSystem
import DomainExternalRepository
import Foundation
import SwiftUI
import UIComponent

// MARK: - RepositoryConfirmationScreen

@ViewAction(for: RepositoryConfirmationFeature.self)
struct RepositoryConfirmationScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<RepositoryConfirmationFeature>

    var body: some View {
        VStack(spacing: 0) {
            ScreenControlBar(onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.textSetSpacing) {
                StyledText(text: LocalizedText.ProjectRegistration.repositoryConfirmationTitle)
                    .textStyle(.subtitle1)
                    .multilineTextAlignment(.center)

                HStack(spacing: Constant.thumbnailSpacing) {
                    Self.ThumbnailView(avatarURL: avatarURL)

                    VStack(
                        alignment: .leading,
                        spacing: 0,
                    ) {
                        StyledText(text: store.repository?.ownerName ?? "")
                            .textStyle(.body2)
                            .foregroundColorToken(.white70)
                        StyledText(text: store.repository?.repositoryName ?? "")
                            .textStyle(.subtitle3)
                    }
                }
                .padding(.top, Constant.thumbnailTopPadding)
            }
            .designSystemScreenMargin()
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            VStack(spacing: LayoutToken.compactSpacing) {
                FeedbackActionButton(
                    title: LocalizedText.ProjectRegistration.repositoryConfirmationNextButtonTitle,
                    action: { send(.confirmTapped) },
                )
                FeedbackActionButton(
                    title: LocalizedText.ProjectRegistration.repositoryConfirmationRejectButtonTitle,
                    action: { send(.rejectTapped) },
                )
                .style(.secondary)
            }
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

    // MARK: Private

    private var avatarURL: URL? {
        store.repository?.imageURL.flatMap(URL.init(string:))
    }

}

// MARK: RepositoryConfirmationScreen.Constant

extension RepositoryConfirmationScreen {
    fileprivate enum Constant {
        static let textSetSpacing: CGFloat = 16
        static let thumbnailSpacing: CGFloat = 21
        static let thumbnailTopPadding: CGFloat = 29
        static let bottomButtonPadding: CGFloat = 24
    }
}
