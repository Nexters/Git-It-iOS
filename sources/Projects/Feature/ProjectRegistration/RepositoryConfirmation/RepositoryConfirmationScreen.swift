import ComposableArchitecture
import DesignSystem
import DomainLearningProject
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
            ScreenHeader(style: .default, onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            Spacer(minLength: 0)

            VStack(spacing: Constant.textSetSpacing) {
                StyledText.subtitle1("이 레포지토리가 맞으면\n학습 설정을 진행할게요", alignment: .center)

                HStack(spacing: Constant.thumbnailSpacing) {
                    Self.ThumbnailView(avatarURL: avatarURL)

                    VStack(alignment: .leading, spacing: 0) {
                        StyledText.body2(store.repository?.ownerName ?? "", color: .white70)
                        StyledText.subtitle3(store.repository?.repositoryName ?? "")
                    }
                }
                .padding(.top, Constant.thumbnailTopPadding)
            }
            .designSystemScreenMargin()
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                ActionButton.primary("다음", action: { send(.confirmTapped) })
                ActionButton.secondary("이 레포지토리가 아니에요", action: { send(.rejectTapped) })
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
