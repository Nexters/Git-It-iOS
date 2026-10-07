import ComposableArchitecture
import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - QuizLevelSelectionScreen

@ViewAction(for: QuizLevelSelectionFeature.self)
struct QuizLevelSelectionScreen: View {

    @Bindable var store: StoreOf<QuizLevelSelectionFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenControlBar(onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            StyledText.subtitle1("이 레포지토리와 사용 기술을\n어느 정도 알고 있나요?")
                .designSystemScreenMargin()
                .padding(.top, Constant.titleTopPadding)

            SelectionCardList(
                items: levelItems,
                onSelect: { identifier in
                    guard let level = Self.levels.first(where: { $0.level.identifier == identifier })?.level
                    else { return }
                    send(.levelSelected(level))
                },
            )
            .designSystemScreenMargin()
            .padding(.top, Constant.listTopPadding)

            Spacer(minLength: 0)

            ActionButton.primary("다음", action: { send(.nextTapped) })
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
    }

}

extension QuizLevelSelectionScreen {

    // MARK: Fileprivate

    fileprivate typealias Level = (level: QuizLevel, title: String, supportingText: String, illust: ResourceImage.Asset.Illust)

    fileprivate enum Constant {
        static let titleTopPadding: CGFloat = 20
        static let listTopPadding: CGFloat = 46
        static let bottomButtonPadding: CGFloat = 24
    }

    fileprivate static var levels: [Level] {
        [
            (.l1, "기술 개념은 알아요", "실제 코드 작동 방식을 흐름 중심으로 학습", .knowledgeBasic),
            (.l2, "일부 코드를 봤어요", "구현 의도와 연결 영향까지 포함", .knowledgeIntermediate),
            (.l3, "유사 프로젝트 경험이 있어요", "심화 문제와 서술형 비중 확대", .knowledgeAdvanced),
        ]
    }

    // MARK: Private

    private var levelItems: [SelectionCardList.Item] {
        Self.levels.map { level, title, supportingText, illust in
            SelectionCardList.Item(
                id: level.identifier,
                title: title,
                supportingText: supportingText,
                illust: illust,
                isSelected: store.quizLevel == level,
            )
        }
    }

}
