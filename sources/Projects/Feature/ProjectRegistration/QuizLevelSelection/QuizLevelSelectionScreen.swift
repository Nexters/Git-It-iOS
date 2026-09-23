import ComposableArchitecture
import DesignSystem
import DomainProjectGeneration
import SwiftUI
import UIComponent

// MARK: - QuizLevelSelectionScreen

@ViewAction(for: QuizLevelSelectionFeature.self)
struct QuizLevelSelectionScreen: View {

    @Bindable var store: StoreOf<QuizLevelSelectionFeature>

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0,
        ) {
            ScreenControlBar(onLeadingTap: { send(.backTapped) })
                .designSystemScreenMargin()

            StyledText(text: LocalizedText.ProjectRegistration.quizLevelSelectionTitle)
                .textStyle(.subtitle1)
                .designSystemScreenMargin()
                .padding(.top, Constant.titleTopPadding)

            SelectionCardList(
                items: levelItems,
                selection: Binding(
                    get: { store.quizLevel.identifier },
                    set: { identifier in
                        guard let level = Self.levels.first(where: { $0.level.identifier == identifier })?.level
                        else { return }
                        send(.levelSelected(level))
                    },
                ),
            )
            .designSystemScreenMargin()
            .padding(.top, Constant.listTopPadding)

            Spacer(minLength: 0)

            FeedbackActionButton(
                title: LocalizedText.ProjectRegistration.quizLevelSelectionNextButtonTitle,
                action: { send(.nextTapped) },
            )
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
            (
                .l1,
                LocalizedText.ProjectRegistration.quizLevelSelectionBasicTitle,
                LocalizedText.ProjectRegistration.quizLevelSelectionBasicDescription,
                .knowledgeBasic,
            ),
            (
                .l2,
                LocalizedText.ProjectRegistration.quizLevelSelectionIntermediateTitle,
                LocalizedText.ProjectRegistration.quizLevelSelectionIntermediateDescription,
                .knowledgeIntermediate,
            ),
            (
                .l3,
                LocalizedText.ProjectRegistration.quizLevelSelectionAdvancedTitle,
                LocalizedText.ProjectRegistration.quizLevelSelectionAdvancedDescription,
                .knowledgeAdvanced,
            ),
        ]
    }

    // MARK: Private

    private var levelItems: [SelectionCardList.Item] {
        Self.levels.map { level, title, supportingText, illust in
            SelectionCardList.Item(
                id: level.identifier,
                displayModel: .init(
                    title: title,
                    supportingText: supportingText,
                    illust: illust,
                ),
            )
        }
    }

}
