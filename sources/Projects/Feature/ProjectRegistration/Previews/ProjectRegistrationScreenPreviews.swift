import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private enum ProjectRegistrationPreviewSupport {
    static let repository = ExternalRepository(
        canonicalURL: "https://github.com/seaweedfs/seaweedfs",
        ownerName: "SeaweedFS",
        repositoryName: "SeaweedFS",
        imageURL: nil,
        starCount: 24000,
        techStack: ["Go"],
    )

    @MainActor
    static func store(
        repositoryURLInput: String = "",
        validation: ProjectRegistrationFeature.ValidationStatus = .idle,
        quizLevel: QuizLevel = .l1,
        submission: ProjectRegistrationFeature.SubmissionStatus = .idle,
        isNotificationOptionSheetPresented: Bool = false,
    ) -> StoreOf<ProjectRegistrationFeature> {
        Store(
            initialState: {
                var state = ProjectRegistrationFeature.State()
                state.repositoryURLInput = repositoryURLInput
                state.validation = validation
                state.quizLevel = quizLevel
                state.submission = submission
                state.isNotificationOptionSheetPresented = isNotificationOptionSheetPresented
                return state
            }(),
        ) {
            ProjectRegistrationFeature(
                fetchExternalRepository: PreviewFetchExternalRepositoryUseCase(),
                createLearningProject: PreviewCreateLearningProjectUseCase(),
                observeLearningProjectGenerationOutcomes: PreviewObserveLearningProjectGenerationOutcomesUseCase(),
            )
        }
    }
}

private struct PreviewFetchExternalRepositoryUseCase: FetchExternalRepositoryUseCase {
    func callAsFunction(url _: String) async throws -> ExternalRepository {
        ProjectRegistrationPreviewSupport.repository
    }
}

private struct PreviewCreateLearningProjectUseCase: CreateLearningProjectUseCase {
    func callAsFunction(githubRepoURL _: String, quizLevel: QuizLevel) async throws -> ProjectRegistrationReceipt {
        ProjectRegistrationReceipt(projectID: "preview-project", requestStatus: "accepted", quizLevel: quizLevel)
    }
}

private struct PreviewObserveLearningProjectGenerationOutcomesUseCase: ObserveLearningProjectGenerationOutcomesUseCase {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome> {
        AsyncStream { _ in }
    }
}

#Preview("링크 입력 · 986:13739") {
    ProjectRegistrationScreen(store: ProjectRegistrationPreviewSupport.store())
        .frame(width: 360, height: 800)
}

#Preview("링크 입력 · 검증 실패") {
    ProjectRegistrationScreen(
        store: ProjectRegistrationPreviewSupport.store(
            repositoryURLInput: "https://github.com/invalid",
            validation: .failed,
        ),
    )
    .frame(width: 360, height: 800)
}

#Preview("레포지토리 확인 · 737:10890") {
    ProjectRegistrationScreen(
        store: ProjectRegistrationPreviewSupport.store(
            repositoryURLInput: "https://github.com/seaweedfs/seaweedfs",
            validation: .validated(ProjectRegistrationPreviewSupport.repository),
        ),
    )
    .frame(width: 360, height: 800)
}

#Preview("이해도 선택 · 737:10882") {
    ProjectRegistrationQuizLevelSelectionScreen(
        selectedLevel: nil,
        onSelect: { _ in },
        onNext: { },
        onBack: { },
    )
    .designSystemBackgroundForPreview()
}

#Preview("이해도 선택 · 선택됨 · 737:10874") {
    ProjectRegistrationQuizLevelSelectionScreen(
        selectedLevel: .l1,
        onSelect: { _ in },
        onNext: { },
        onBack: { },
    )
    .designSystemBackgroundForPreview()
}

#Preview("생성 시작 확정 · 737:10830") {
    ProjectRegistrationGenerationConfirmationScreen(onStart: { }, onBack: { })
        .designSystemBackgroundForPreview()
}

#Preview("생성 진행 · 737:10800") {
    ProjectRegistrationScreen(
        store: ProjectRegistrationPreviewSupport.store(
            submission: .awaitingGeneration(
                ProjectRegistrationReceipt(projectID: "preview-project", requestStatus: "accepted", quizLevel: .l1)
            ),
        ),
    )
    .frame(width: 360, height: 800)
}

#Preview("알림 옵션 시트 · 824:12149") {
    ProjectRegistrationNotificationOptionSheet(onAccept: { }, onDecline: { })
        .designSystemBackgroundForPreview()
}

extension View {
    fileprivate func designSystemBackgroundForPreview() -> some View {
        ScreenContainer { self }
            .frame(width: 360, height: 800)
    }
}
