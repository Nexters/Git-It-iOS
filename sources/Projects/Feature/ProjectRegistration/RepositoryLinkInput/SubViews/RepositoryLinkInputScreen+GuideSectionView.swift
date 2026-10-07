import DesignSystem
import SwiftUI
import UIComponent

extension RepositoryLinkInputScreen {
    struct GuideSectionView: View {

        // MARK: Internal

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    isGuideExpanded.toggle()
                } label: {
                    HStack(spacing: 0) {
                        StyledText.body2("불러오기 방법", color: .blue100)
                        Spacer(minLength: 0)
                        ResourceImage(asset: .icon(isGuideExpanded ? .chevronUp : .chevronDown), contentMode: .fit)
                            .frame(width: Constant.chevronSize, height: Constant.chevronSize)
                            .frame(width: Constant.chevronBoxSize, height: Constant.chevronBoxSize)
                    }
                    .padding(.leading, LayoutToken.margin)
                    .padding(.trailing, Constant.headerTrailingPadding)
                    .frame(height: Constant.headerHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("불러오기 방법")
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(isGuideExpanded ? "펼쳐짐" : "접힘")

                if isGuideExpanded {
                    VStack(alignment: .leading, spacing: Constant.guideStepSpacing) {
                        ForEach(Array(Constant.guideSteps.enumerated()), id: \.offset) { index, text in
                            HStack(alignment: .top, spacing: LayoutToken.gutter) {
                                ZStack {
                                    Circle()
                                        .fill(Color(designSystem: .grey500))
                                        .frame(width: 16, height: 16)
                                    StyledText.caption2("\(index + 1)", color: .grey300)
                                }
                                StyledText.caption1(text, color: .grey100)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutToken.margin)
                    .padding(.bottom, Constant.bodyVerticalPadding)
                }
            }
            .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
        }

        // MARK: Private

        private enum Constant {
            static let guideStepSpacing: CGFloat = 10
            static let headerHeight: CGFloat = 56
            static let headerTrailingPadding: CGFloat = 10
            static let chevronSize: CGFloat = 16
            static let chevronBoxSize: CGFloat = 36
            static let bodyVerticalPadding: CGFloat = 10
            static let guideSteps = [
                "학습하고싶은 레포지토리를 발견하셨나요?",
                "GitHub 리포지토리 페이지로 이동합니다.",
                "우측 상단의 [Code] 버튼을 클릭합니다.",
                "HTTPS 탭에서 주소 옆 복사 아이콘을 누릅니다.",
                "복사한 주소를 위에 입력해주세요.",
            ]
        }

        @State private var isGuideExpanded = false

    }
}
