import DesignSystem
import Foundation
import SwiftUI
import UIComponent

extension ProjectDetailScreen {
    struct RepositorySummaryView: View {

        // MARK: Internal

        let repositoryName: String
        let repositoryImageURL: String?
        let starCount: Int
        let techStack: [String]
        let overallProgressPercent: Int
        let isResumeEnabled: Bool
        let onResumeTap: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: Constant.bannerToContentSpacing) {
                banner

                VStack(alignment: .leading, spacing: Constant.contentSpacing) {
                    HStack(alignment: .top, spacing: LayoutToken.gutter.cgFloatValue) {
                        VStack(alignment: .leading, spacing: Constant.textSpacing) {
                            StyledText.headline2(repositoryName)
                            metaRow
                        }

                        Spacer(minLength: 0)

                        resumeButton
                    }

                    LabeledProgressBar(
                        label: "전체 진행률",
                        progress: Double(overallProgressPercent) / 100,
                        valueText: "\(overallProgressPercent)%",
                        valueColor: .blue100,
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        // MARK: Private

        private enum Constant {
            static let bannerToContentSpacing: CGFloat = 31
            static let contentSpacing: CGFloat = 28
            static let textSpacing: CGFloat = 5
            static let metaSpacing: CGFloat = 9
            static let starSpacing: CGFloat = 5
            static let dividerHeight: CGFloat = 16
            static let bannerSize: CGFloat = 99
            static let starSize: CGFloat = 16
            static let resumeSurfaceSize: CGFloat = 40
            static let resumeTouchSize: CGFloat = 44
            static let disabledOpacity = 0.4
        }

        @ViewBuilder
        private var banner: some View {
            if let repositoryImageURL, let url = URL(string: repositoryImageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(designSystem: .grey500)
                }
                .frame(width: Constant.bannerSize, height: Constant.bannerSize)
                .designSystemCornerRadius(.medium)
                .accessibilityHidden(true)
            } else {
                Color(designSystem: .grey500)
                    .frame(width: Constant.bannerSize, height: Constant.bannerSize)
                    .designSystemCornerRadius(.medium)
                    .accessibilityHidden(true)
            }
        }

        private var metaRow: some View {
            HStack(spacing: Constant.metaSpacing) {
                HStack(spacing: Constant.starSpacing) {
                    ResourceImage(asset: .icon(.star))
                        .frame(width: Constant.starSize, height: Constant.starSize)
                    StyledText.caption1(formattedStarCount, color: .blue100)
                }

                if !techStack.isEmpty {
                    Rectangle()
                        .fill(Color(designSystem: .grey500))
                        .frame(width: 1, height: Constant.dividerHeight)

                    StyledText.caption1(techStack.joined(separator: " · "), color: .blue100)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
        }

        private var formattedStarCount: String {
            switch starCount {
            case 1_000_000...:
                "\(abbreviatedUnit(starCount, divisor: 1_000_000))m"

            case 1_000...:
                "\(abbreviatedUnit(starCount, divisor: 1_000))k"

            default:
                "\(starCount)"
            }
        }

        private var resumeButton: some View {
            Button(action: onResumeTap) {
                ResourceImage(asset: .icon(.playSmall))
                    .frame(width: Constant.resumeSurfaceSize, height: Constant.resumeSurfaceSize)
                    .opacity(isResumeEnabled ? 1 : Constant.disabledOpacity)
                    .frame(width: Constant.resumeTouchSize, height: Constant.resumeTouchSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isResumeEnabled)
            .accessibilityLabel("이어서 학습")
        }

        private func abbreviatedUnit(
            _ count: Int,
            divisor: Int,
        ) -> String {
            let scaled = (Double(count) / Double(divisor) * 10).rounded(.down) / 10
            return scaled.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", scaled)
                : String(format: "%.1f", scaled)
        }

    }
}
