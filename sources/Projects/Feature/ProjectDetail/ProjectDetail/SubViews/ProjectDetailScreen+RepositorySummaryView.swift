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
            VStack(alignment: .leading, spacing: Constant.contentSpacing) {
                HStack(alignment: .center, spacing: LayoutToken.gutter.cgFloatValue) {
                    banner

                    VStack(alignment: .leading, spacing: Constant.textSpacing) {
                        StyledText.subtitle2(repositoryName)
                        StyledText.caption1("★ \(starCount)", color: .grey400)
                    }

                    Spacer(minLength: 0)

                    resumeButton
                }

                if !techStack.isEmpty {
                    HStack(spacing: Constant.tagSpacing) {
                        ForEach(techStack, id: \.self) { technology in
                            TagBadge.neutral(technology)
                        }
                    }
                }

                LabeledProgressBar(
                    label: "전체 진행률",
                    progress: Double(overallProgressPercent) / 100,
                    valueText: "\(overallProgressPercent)%",
                )
            }
            .padding(Constant.contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.large)
        }

        // MARK: Private

        private enum Constant {
            static let contentSpacing: CGFloat = 16
            static let textSpacing: CGFloat = 4
            static let tagSpacing: CGFloat = 6
            static let contentPadding: CGFloat = 16
            static let bannerSize: CGFloat = 44
            static let resumeSymbolSize: CGFloat = 16
            static let resumeSurfaceSize: CGFloat = 40
            static let resumeTouchSize: CGFloat = 44
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
                .clipShape(Circle())
                .accessibilityHidden(true)
            } else {
                Circle()
                    .fill(Color(designSystem: .grey500))
                    .frame(width: Constant.bannerSize, height: Constant.bannerSize)
                    .accessibilityHidden(true)
            }
        }

        private var resumeButton: some View {
            Button(action: onResumeTap) {
                Image(systemName: "play.fill")
                    .font(.system(size: Constant.resumeSymbolSize, weight: .bold))
                    .designSystemForeground(.grey100)
                    .frame(width: Constant.resumeSurfaceSize, height: Constant.resumeSurfaceSize)
                    .background(
                        Color(designSystem: isResumeEnabled ? .blue300 : .grey500),
                        in: Circle(),
                    )
                    .frame(width: Constant.resumeTouchSize, height: Constant.resumeTouchSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isResumeEnabled)
            .accessibilityLabel("이어서 학습")
        }

    }
}
