import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - ProjectRegistrationPreviewSupport

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
            }()
        ) {
            ProjectRegistrationFeature(
                fetchExternalRepository: PreviewFetchExternalRepositoryUseCase(),
                createLearningProject: PreviewCreateLearningProjectUseCase(),
                learningProjectOutcomes: PreviewLearningProjectOutcomesUseCase(),
                requestGenerationReminder: PreviewRequestGenerationReminderUseCase(),
            )
        }
    }
}

// MARK: - PreviewFetchExternalRepositoryUseCase

private struct PreviewFetchExternalRepositoryUseCase: FetchExternalRepositoryUseCase {
    func callAsFunction(url _: String) async throws -> ExternalRepository {
        ProjectRegistrationPreviewSupport.repository
    }
}

// MARK: - PreviewCreateLearningProjectUseCase

private struct PreviewCreateLearningProjectUseCase: CreateLearningProjectUseCase {
    func callAsFunction(
        githubRepoURL _: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        ProjectRegistrationReceipt(
            projectID: "preview-project",
            requestStatus: "accepted",
            quizLevel: quizLevel,
        )
    }
}

// MARK: - PreviewLearningProjectOutcomesUseCase

private struct PreviewLearningProjectOutcomesUseCase: LearningProjectOutcomesUseCase {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome> {
        AsyncStream { _ in }
    }
}

// MARK: - PreviewRequestGenerationReminderUseCase

private struct PreviewRequestGenerationReminderUseCase: RequestGenerationReminderUseCase {
    func callAsFunction(projectID _: String) async -> NotificationAuthorizationOutcome {
        .authorized
    }

    func isAuthorized() async -> Bool {
        true
    }
}

#Preview("링크 입력 · 986:13739") {
    ProjectRegistrationScreen(store: ProjectRegistrationPreviewSupport.store())
//        .frame(width: 360, height: 800)
}

#Preview("링크 입력 · 검증 실패") {
    ProjectRegistrationScreen(
        store: ProjectRegistrationPreviewSupport.store(
            repositoryURLInput: "https://github.com/invalid",
            validation: .failed,
        )
    )
//    .frame(width: 360, height: 800)
}

#Preview("레포지토리 확인 · 737:10890") {
    ProjectRegistrationScreen(
        store: ProjectRegistrationPreviewSupport.store(
            repositoryURLInput: "https://github.com/seaweedfs/seaweedfs",
            validation: .validated(ProjectRegistrationPreviewSupport.repository),
        )
    )
//    .frame(width: 360, height: 800)
}

#Preview("이해도 선택 · 737:10882") {
    QuizLevelSelectionScreen(
        selectedLevel: nil,
        onSelect: { _ in },
        onNext: { },
        onBack: { },
    )
//    .designSystemBackgroundForPreview()
}

#Preview("이해도 선택 · 선택됨 · 737:10874") {
    QuizLevelSelectionScreen(
        selectedLevel: .l1,
        onSelect: { _ in },
        onNext: { },
        onBack: { },
    )
//    .designSystemBackgroundForPreview()
}

#Preview("생성 시작 확정 · 737:10830") {
    GenerationConfirmationScreen(onStart: { }, onBack: { })
//        .designSystemBackgroundForPreview()
}

#Preview("생성 진행 · 2026:29388") {
    ProjectRegistrationScreen(
        store: ProjectRegistrationPreviewSupport.store(
            submission: .awaitingGeneration(
                ProjectRegistrationReceipt(projectID: "preview-project", requestStatus: "accepted", quizLevel: .l1)
            )
        )
    )
//    .frame(width: 360, height: 800)
}

#Preview("알림 옵션 시트 · 824:12149") {
    NotificationOptionSheet(onAccept: { }, onDecline: { })
//        .designSystemBackgroundForPreview()
}

extension View {
    func designSystemBackgroundForPreview() -> some View {
        ScreenContainer { self }
            .frame(width: 360, height: 800)
    }
}
