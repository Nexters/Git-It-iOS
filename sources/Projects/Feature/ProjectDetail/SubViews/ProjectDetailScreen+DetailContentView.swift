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
                    StyledText(text: "프로젝트를 불러오지 못했어요")
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: "잠시 후 다시 시도해 주세요.")
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
