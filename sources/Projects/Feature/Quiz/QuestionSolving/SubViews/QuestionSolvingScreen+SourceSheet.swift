import DesignSystem
import Foundation
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct SourceSheet: View {

        // MARK: Internal

        let sources: [QuestionSourceDisplay]
        let onLinkTap: (URL) -> Void
        let onClose: () -> Void

        var body: some View {
            SheetSurface(isScrollable: true) {
                VStack(alignment: .leading, spacing: LayoutToken.margin.cgFloatValue) {
                    StyledText.subtitle2("출처")

                    ForEach(sources) { source in
                        row(source: source)
                    }

                    ActionButton.primary("닫기", action: onClose)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        // MARK: Private

        private enum Constant {
            static let rowSpacing: CGFloat = 6
        }

        @ViewBuilder
        private func row(source: QuestionSourceDisplay) -> some View {
            if let referenceURL = source.referenceURL {
                Button {
                    onLinkTap(referenceURL)
                } label: {
                    rowContent(source: source)
                }
                .buttonStyle(.plain)
                .designSystemControlSize(.minimumTouch)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(source.accessibilityLabel)
                .accessibilityAddTraits(.isLink)
            } else {
                rowContent(source: source)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(source.accessibilityLabel)
            }
        }

        private func rowContent(source: QuestionSourceDisplay) -> some View {
            VStack(alignment: .leading, spacing: Constant.rowSpacing) {
                StyledText.body2(source.title)

                if let detail = source.detail {
                    StyledText.caption1(detail, color: .grey400)
                }

                if let summary = source.summary {
                    StyledText.caption1(summary, color: .grey300)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }

    }
}
