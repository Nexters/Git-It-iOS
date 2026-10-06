import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - QuizLevelSelectionScreen

struct QuizLevelSelectionScreen: View {

    let selectedLevel: QuizLevel?
    let onSelect: (QuizLevel) -> Void
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(style: .largeTitle, onLeadingTap: onBack)
                .designSystemScreenMargin()

            StyledText.subtitle1("이 레포지토리와 사용 기술을\n어느 정도 알고 있나요?")
                .designSystemScreenMargin()
                .padding(.top, Constant.titleTopPadding)

            SelectionCardList(
                items: Constant.levels.map { level, title, supportingText, illust in
                    .init(
                        id: level.identifier,
                        title: title,
                        supportingText: supportingText,
                        illust: illust,
                        isSelected: selectedLevel == level,
                    )
                },
                onSelect: { id in
                    guard let level = Constant.levels.first(where: { $0.level.identifier == id })?.level else { return }
                    onSelect(level)
                },
            )
            .designSystemScreenMargin()
            .padding(.top, Constant.listTopPadding)

            Spacer(minLength: 0)

            ActionButton.primary("다음", isEnabled: selectedLevel != nil, action: onNext)
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

}

extension QuizLevel {
    fileprivate var identifier: String {
        switch self {
        case .l1: "l1"
        case .l2: "l2"
        case .l3: "l3"
        @unknown default: "unknown"
        }
    }
}

// MARK: - QuizLevelSelectionScreen.Constant

extension QuizLevelSelectionScreen {
    private enum Constant {
        static let titleTopPadding: CGFloat = 24
        static let listTopPadding: CGFloat = 32
        static let bottomButtonPadding: CGFloat = 34

        static let levels: [(level: QuizLevel, title: String, supportingText: String, illust: ResourceImage.Asset.Illust)] = [
            (.l1, "기술 개념은 알아요", "실제 코드 작동 방식을 흐름 중심으로 학습", .knowledgeBasic),
            (.l2, "일부 코드를 봤어요", "구현 의도와 연결 영향까지 포함", .knowledgeIntermediate),
            (.l3, "유사 프로젝트 경험이 있어요", "심화 문제와 서술형 비중 확대", .knowledgeAdvanced),
        ]
    }
}
