import SwiftUI
import UIComponent

extension HomeScreen {
    struct RegistrationPanelView: View {

        // MARK: Internal

        let isGenerationInProgress: Bool
        let onRegister: () -> Void

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 0,
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 5,
                ) {
                    StyledText(text: LocalizedText.Home.registrationPanelCaption)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                    VStack(
                        alignment: .leading,
                        spacing: 0,
                    ) {
                        StyledText(text: LocalizedText.Home.registrationPanelTitleFirstLine)
                            .textStyle(.subtitle3)
                        StyledText(text: LocalizedText.Home.registrationPanelTitleSecondLine)
                            .textStyle(.subtitle3)
                    }
                }

                HStack {
                    Spacer()

                    if isGenerationInProgress {
                        generationInProgressLabel
                    } else {
                        Button(action: onRegister) {
                            StyledText(text: LocalizedText.Home.registrationPanelRegisterButtonTitle)
                                .textStyle(.body2)
                                .foregroundColorToken(.grey700)
                                .frame(
                                    width: Constant.registerButtonWidth,
                                    height: Constant.actionSurfaceHeight,
                                )
                                .background(
                                    Color(designSystem: .blue100),
                                    in: RoundedRectangle(designSystem: .medium),
                                )
                                .padding(.vertical, Constant.touchAreaOutset)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, -Constant.touchAreaOutset)
                        .accessibilityLabel(LocalizedText.Home.registrationPanelRegisterAccessibilityLabel)
                    }
                }
            }
            .padding(EdgeInsets(
                top: 13,
                leading: 16,
                bottom: 12,
                trailing: 12,
            ))
            .frame(
                minHeight: 133,
                alignment: .topLeading,
            )
            .background(
                Color(designSystem: .grey600),
                in: RoundedRectangle(designSystem: .large),
            )
        }

        // MARK: Private

        private enum Constant {
            static let registerButtonWidth: CGFloat = 104
            static let actionSurfaceHeight: CGFloat = 37
            static let touchAreaOutset: CGFloat = (44 - actionSurfaceHeight) / 2
            static let progressLabelSpacing: CGFloat = 8
            static let progressIndicatorSize: CGFloat = 20
            static let progressLabelHorizontalPadding: CGFloat = 12
        }

        private var generationInProgressLabel: some View {
            HStack(spacing: Constant.progressLabelSpacing) {
                ResourceAnimation(asset: .generalLoading)
                    .frame(
                        width: Constant.progressIndicatorSize,
                        height: Constant.progressIndicatorSize,
                    )
                StyledText(text: LocalizedText.Home.registrationPanelGenerationInProgressLabel)
                    .textStyle(.body2)
                    .foregroundColorToken(.grey300)
            }
            .padding(.horizontal, Constant.progressLabelHorizontalPadding)
            .frame(height: Constant.actionSurfaceHeight)
            .background(
                Color(designSystem: .grey500),
                in: RoundedRectangle(designSystem: .medium),
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(LocalizedText.Home.registrationPanelGenerationInProgressLabel)
        }

    }
}
