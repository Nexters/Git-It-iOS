import DesignSystem
import SwiftUI
import UIComponent

extension RepositoryLinkInputScreen {
    struct GuideSectionView: View {

        // MARK: Internal

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 0,
            ) {
                Button {
                    isGuideExpanded.toggle()
                } label: {
                    HStack(spacing: 0) {
                        StyledText(text: LocalizedText.ProjectRegistration.guideSectionTitle)
                            .textStyle(.body2)
                            .foregroundColorToken(.blue100)
                        Spacer(minLength: 0)
                        ResourceImage(
                            asset: .icon(isGuideExpanded ? .chevronUp : .chevronDown),
                            contentMode: .fit,
                        )
                        .frame(
                            width: Constant.chevronSize,
                            height: Constant.chevronSize,
                        )
                        .frame(
                            width: Constant.chevronBoxSize,
                            height: Constant.chevronBoxSize,
                        )
                    }
                    .padding(.leading, LayoutToken.margin)
                    .padding(.trailing, Constant.headerTrailingPadding)
                    .frame(height: Constant.headerHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedText.ProjectRegistration.guideSectionAccessibilityLabel)
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(
                    isGuideExpanded
                        ? LocalizedText.ProjectRegistration.guideSectionExpandedAccessibilityValue
                        : LocalizedText.ProjectRegistration.guideSectionCollapsedAccessibilityValue
                )

                if isGuideExpanded {
                    VStack(
                        alignment: .leading,
                        spacing: Constant.guideStepSpacing,
                    ) {
                        ForEach(
                            Array(guideSteps.enumerated()),
                            id: \.offset,
                        ) { index, text in
                            HStack(
                                alignment: .top,
                                spacing: LayoutToken.gutter,
                            ) {
                                ZStack {
                                    Circle()
                                        .fill(Color(designSystem: .grey500))
                                        .frame(
                                            width: 16,
                                            height: 16,
                                        )
                                    StyledText(text: "\(index + 1)")
                                        .textStyle(.caption2)
                                        .foregroundColorToken(.grey300)
                                }
                                StyledText(text: text)
                                    .textStyle(.caption1)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutToken.margin)
                    .padding(.bottom, Constant.bodyVerticalPadding)
                }
            }
            .background(
                Color(designSystem: .grey600),
                in: RoundedRectangle(designSystem: .large),
            )
        }

        // MARK: Private

        private enum Constant {
            static let guideStepSpacing: CGFloat = 10
            static let headerHeight: CGFloat = 56
            static let headerTrailingPadding: CGFloat = 10
            static let chevronSize: CGFloat = 16
            static let chevronBoxSize: CGFloat = 36
            static let bodyVerticalPadding: CGFloat = 10
        }

        @State private var isGuideExpanded = false

        private var guideSteps: [String] {
            [
                LocalizedText.ProjectRegistration.guideSectionFirstStep,
                LocalizedText.ProjectRegistration.guideSectionSecondStep,
                LocalizedText.ProjectRegistration.guideSectionThirdStep,
                LocalizedText.ProjectRegistration.guideSectionFourthStep,
                LocalizedText.ProjectRegistration.guideSectionFifthStep,
            ]
        }

    }
}
