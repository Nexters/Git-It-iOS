import DesignSystem
import SwiftUI
import UIComponent

extension ProjectDetailScreen {
    struct DetailContentView<Detail: View>: View {

        // MARK: Lifecycle

        init(
            isFailed: Bool,
            @ViewBuilder detail: () -> Detail,
        ) {
            self.isFailed = isFailed
            self.detail = detail()
        }

        // MARK: Internal

        var body: some View {
            if isFailed {
                failure
            } else {
                detail
            }
        }

        // MARK: Private

        private enum Constant {
            static var textSpacing: CGFloat {
                10
            }
        }

        private let isFailed: Bool
        private let detail: Detail

        private var failure: some View {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: Constant.textSpacing) {
                    StyledText(text: LocalizedText.ProjectDetail.detailContentLoadFailureTitle)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: LocalizedText.ProjectDetail.detailContentLoadFailureMessage)
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
            )
        }

    }
}
