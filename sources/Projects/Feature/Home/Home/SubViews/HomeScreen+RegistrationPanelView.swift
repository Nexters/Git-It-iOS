import SwiftUI
import UIComponent

extension HomeScreen {
    struct RegistrationPanelView: View {

        // MARK: Internal

        let isGenerationInProgress: Bool
        let onRegister: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    StyledText.caption1("프로젝트 문제 생성", color: .grey400)
                    VStack(alignment: .leading, spacing: 0) {
                        StyledText.subtitle3("오픈소스를 불러오고")
                        StyledText.subtitle3("문제로 익혀보세요")
                    }
                }

                Spacer(minLength: 12)

                HStack {
                    Spacer()

                    if isGenerationInProgress {
                        generationInProgressLabel
                    } else {
                        Button(action: onRegister) {
                            StyledText.body2("지금 불러오기", color: .grey700)
                                .frame(width: 104, height: 37)
                                .background(Color(designSystem: .blue100), in: RoundedRectangle(designSystem: .medium))
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Constant.registrationLabel)
                    }
                }
            }
            .padding(EdgeInsets(top: 13, leading: 16, bottom: 12, trailing: 12))
            .frame(minHeight: 133, alignment: .topLeading)
            .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
        }

        // MARK: Private

        private var generationInProgressLabel: some View {
            HStack(spacing: Constant.progressLabelSpacing) {
                ResourceAnimation(asset: .generalLoading)
                    .frame(width: Constant.progressIndicatorSize, height: Constant.progressIndicatorSize)
                StyledText.body2(Constant.generationInProgressLabel, color: .grey300)
            }
            .padding(.horizontal, Constant.progressLabelHorizontalPadding)
            .frame(height: 37)
            .background(Color(designSystem: .grey500), in: RoundedRectangle(designSystem: .medium))
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Constant.generationInProgressLabel)
        }


        private enum Constant {
            static let registrationLabel = "프로젝트 지금 불러오기"
            static let generationInProgressLabel = "학습세트 생성 중..."
            static let progressLabelSpacing: CGFloat = 8
            static let progressIndicatorSize: CGFloat = 20
            static let progressLabelHorizontalPadding: CGFloat = 12
        }

    }
}
