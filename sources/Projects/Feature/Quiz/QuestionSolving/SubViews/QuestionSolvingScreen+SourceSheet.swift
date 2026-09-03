import DesignSystem
import Foundation
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct SourceSheet: View {

        // MARK: Internal

        let questionNumber: Int?
        let sources: [QuestionSourceDisplay]
        let onLinkTap: (URL) -> Void
        let onClose: () -> Void

        var body: some View {
            SheetSurface(isScrollable: true) {
                VStack(alignment: .leading, spacing: 0) {
                    StyledText.subtitle1(title)
                        .padding(.top, Constant.titleTopPadding)

                    VStack(alignment: .leading, spacing: Constant.sourceSpacing) {
                        ForEach(sources) { source in
                            sourceBlock(source: source)
                        }
                    }
                    .padding(.top, Constant.titleToSourcesSpacing)

                    ActionButton.primary("닫기", action: onClose)
                        .padding(.top, Constant.buttonTopPadding)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        // MARK: Private

        private enum Constant {
            static let titleTopPadding: CGFloat = 12
            static let titleToSourcesSpacing: CGFloat = 20
            static let sourceSpacing: CGFloat = 20
            static let descriptionToLinkSpacing: CGFloat = 8
            static let buttonTopPadding: CGFloat = 4
            static let linkHorizontalPadding: CGFloat = 12
            static let linkVerticalPadding: CGFloat = 15
            static let linkIconSize: CGFloat = 16
        }

        private var title: String {
            guard let questionNumber else { return "출처" }
            return "문제 \(questionNumber) 출처"
        }

        @ViewBuilder
        private func sourceBlock(source: QuestionSourceDisplay) -> some View {
            VStack(alignment: .leading, spacing: Constant.descriptionToLinkSpacing) {
                if let summary = source.summary {
                    StyledText.body2(summary)
                }

                linkChip(source: source)
            }
        }

        @ViewBuilder
        private func linkChip(source: QuestionSourceDisplay) -> some View {
            if let referenceURL = source.referenceURL {
                Button {
                    onLinkTap(referenceURL)
                } label: {
                    linkChipContent(source: source, showsIcon: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(source.accessibilityLabel)
                .accessibilityAddTraits(.isLink)
            } else {
                linkChipContent(source: source, showsIcon: false)
                    .accessibilityLabel(source.accessibilityLabel)
            }
        }

        private func linkChipContent(source: QuestionSourceDisplay, showsIcon: Bool) -> some View {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(source.linkLabel, color: .white70)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showsIcon {
                    ResourceImage(asset: .icon(.link))
                        .frame(width: Constant.linkIconSize, height: Constant.linkIconSize)
                }
            }
            .padding(.horizontal, Constant.linkHorizontalPadding)
            .padding(.vertical, Constant.linkVerticalPadding)
            .frame(maxWidth: .infinity)
            .background(Color(designSystem: .grey500), in: RoundedRectangle(designSystem: .large))
        }

    }
}
