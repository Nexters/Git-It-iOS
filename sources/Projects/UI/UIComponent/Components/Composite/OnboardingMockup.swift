import DesignSystem
import SwiftUI

public struct OnboardingMockup: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(page: Int) {
            self.page = page
        }

        public let page: Int
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Image(systemName: "ellipsis")
            }
            .font(.caption)
            .designSystemForeground(.secondaryText)

            switch viewModel.page {
            case 1: projectOverview
            case 2: quizOverview
            default: savedOverview
            }
        }
        .padding(Constant.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color(designSystem: .screenBackground),
            in: RoundedRectangle(designSystem: .extraLarge),
        )
        .overlay {
            RoundedRectangle(designSystem: .extraLarge)
                .stroke(Color(designSystem: .raisedBackground), lineWidth: Constant.bezelWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("앱 화면 미리보기")
    }

    // MARK: Private

    private enum Constant {
        static let contentPadding: CGFloat = 16
        static let cardPadding: CGFloat = 10
        static let bezelWidth: CGFloat = 8
        static let tightestSpacing: CGFloat = 4
        static let badgeSpacing: CGFloat = 6
        static let tightSpacing: CGFloat = 8
        static let cardSpacing: CGFloat = 10
        static let avatarSize: CGFloat = 28
        static let projectCardWidth: CGFloat = 104
        static let projectCardHeight: CGFloat = 126
        static let projectImageWidth: CGFloat = 92
        static let projectImageHeight: CGFloat = 134
        static let projectImageRotation: Double = 14
        static let questionPrompt = "(Aligner) 혼자 요가하다 낙타 자세가 자꾸 무너진다면, Aligner를 가장 제대로 사용하는 방법은 무엇일까요?"
        static let savedQuestionPrompt = "sansio/blueprints.py에 정의된 BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?"
        static let choices: [(id: String, text: String)] = [
            (id: "A", text: "인기 요가 영상을 무작위로 재생하고, 될 때까지 같은 동작만 반복합니다."),
            (id: "B", text: "매일 걸음 수만 기록하고 목표를 채우면 새로운 요가복 쿠폰을 받습니다."),
            (id: "C", text: "운동 친구를 모집한 뒤 서로의 자세 사진에 점수와 순위를 매겨 경쟁합니다."),
        ]
    }

    private let viewModel: ViewModel

    private var projectOverview: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            HStack(spacing: Constant.tightSpacing) {
                ResourceImage(viewModel: .init(asset: .profile, contentMode: .fill))
                    .frame(width: Constant.avatarSize, height: Constant.avatarSize)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 0) {
                    StyledText.caption2("김이박")
                    StyledText.caption2("Junior Developer", color: .grey400)
                }
            }
            StyledText.subtitle1("Hello World\nLet's Git -it-!")
            HStack(alignment: .bottom, spacing: Constant.cardSpacing) {
                VStack(alignment: .leading, spacing: Constant.tightSpacing) {
                    StyledText.body3("Nexters")
                    StyledText.caption2("Kotlin · Compose ·\nCoroutines", color: .grey300)
                    Spacer()
                    TagBadge.neutral("세트 1")
                    StyledText.caption2("Compose 핵심 개념")
                }
                .padding(Constant.cardPadding)
                .frame(width: Constant.projectCardWidth, height: Constant.projectCardHeight, alignment: .leading)
                .background(
                    Color(designSystem: .purple300),
                    in: RoundedRectangle(designSystem: .small),
                )

                ResourceImage(viewModel: .init(asset: .projectNexters, contentMode: .fill))
                    .frame(width: Constant.projectImageWidth, height: Constant.projectImageHeight)
                    .rotationEffect(.degrees(Constant.projectImageRotation))
                    .designSystemCornerRadius(.small)
            }
            HStack {
                StyledText.caption2("오픈소스를 불러보세요")
                Spacer()
                TagBadge.accent("지금 불러오기")
            }
            .padding(Constant.cardPadding)
            .background(
                Color(designSystem: .cardBackground),
                in: RoundedRectangle(designSystem: .compact),
            )
        }
    }

    private var quizOverview: some View {
        VStack(alignment: .leading, spacing: Constant.cardSpacing) {
            HStack {
                Image(systemName: "xmark")
                Spacer()
                TagBadge.neutral("출처")
                Image(systemName: "bookmark")
            }
            .designSystemForeground(.brandAccent)
            TagBadge.selected("문제 1")
            StyledText.body3(Constant.questionPrompt)
            ForEach(Array(Constant.choices.enumerated()), id: \.offset) { _, choice in
                VStack(alignment: .leading, spacing: Constant.tightestSpacing) {
                    StyledText.body3(choice.id, color: .blue200)
                    StyledText.caption2(choice.text)
                }
                .padding(Constant.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color(designSystem: .cardBackground),
                    in: RoundedRectangle(designSystem: .compact),
                )
            }
        }
    }

    private var savedOverview: some View {
        VStack(alignment: .leading, spacing: Constant.cardSpacing) {
            StyledText.body1("저장한 문제")
            HStack(spacing: Constant.badgeSpacing) {
                TagBadge.accent("전체")
                TagBadge.neutral("Flask")
                TagBadge.neutral("Now in Android")
            }
            StyledText.caption2("4개", color: .grey400)
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Constant.tightSpacing) {
                    StyledText.caption2("Android · Set2 · 문제 1", color: .grey400)
                    StyledText.body3(Constant.savedQuestionPrompt)
                    HStack {
                        Spacer()
                        TagBadge.neutral("해설보기")
                        TagBadge.accent("문제 풀기")
                    }
                }
                .padding(Constant.cardPadding)
                .background(
                    Color(designSystem: .cardBackground),
                    in: RoundedRectangle(designSystem: .compact),
                )
            }
        }
    }

}

#Preview("Onboarding Mockup") {
    HStack(spacing: LayoutToken.margin.cgFloatValue) {
        OnboardingMockup(viewModel: .init(page: 1))
        OnboardingMockup(viewModel: .init(page: 2))
        OnboardingMockup(viewModel: .init(page: 3))
    }
    .frame(height: 400)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
