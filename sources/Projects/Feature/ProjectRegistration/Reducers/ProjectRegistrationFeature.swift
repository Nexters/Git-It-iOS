import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ProjectRegistrationFeature

@Reducer
public struct ProjectRegistrationFeature: Sendable {

    // MARK: Lifecycle

    public init(
        fetchExternalRepository: any FetchExternalRepositoryUseCase,
        createLearningProject: any CreateLearningProjectUseCase,
        observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.observeGenerationOutcomes = observeGenerationOutcomes
        self.requestGenerationReminder = requestGenerationReminder
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    /// 저장소 확인 → 이해도 선택 → 생성 확정으로 이어지는 배타적 단계다.
    /// View 재생성으로 손실되면 사용자 흐름이 바뀌므로 Feature 상태가 소유한다.
    public enum RegistrationStep: Equatable, Sendable {
        case repositoryConfirmation
        case quizLevelSelection
        case generationConfirmation
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public init() { }

        public var repositoryURLInput = ""
        public var quizLevel = QuizLevel.l1
        public var validation = ValidationStatus.idle
        public var progress = RegistrationProgress.idle
        public var step = RegistrationStep.repositoryConfirmation
        public var validationRequestID = 0
        public var isGenerationReminderSheetPresented = false
    }

    public enum ValidationStatus: Equatable, Sendable {
        case idle
        case validating
        case validated(ExternalRepository)
        case failed
    }

    /// 제출부터 생성 결과 판정까지의 수명을 함께 소유하므로 이름이 그 범위를 드러낸다.
    public enum RegistrationProgress: Equatable, Sendable {
        case idle
        case submitting
        case awaitingOutcome(ProjectRegistrationReceipt)
        case failed(LearningProjectError)
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case repositoryURLChanged(String)
            case quizLevelSelected(QuizLevel)
            case validateTapped
            case repositoryConfirmed
            case quizLevelConfirmed
            case stepBackTapped
            case submitTapped
            case waitAtHomeTapped
            case generationReminderAccepted
            case generationReminderDeclined
            case retryTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case validationFinished(requestID: Int, result: Result<ExternalRepository, ExternalRepositoryError>)
            case submissionFinished(Result<ProjectRegistrationReceipt, LearningProjectError>)
            case generationOutcomeReceived(GenerationOutcome)
            case waitAtHomeAuthorizationChecked(isAuthorized: Bool)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistered(ProjectRegistrationReceipt)
            case generationReminderPreferenceSelected(isEnabled: Bool)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.repositoryURLChanged(let text)):
                state.repositoryURLInput = text
                state.validation = .idle
                state.step = .repositoryConfirmation
                return .none

            case .view(.quizLevelSelected(let level)):
                state.quizLevel = level
                return .none

            case .view(.validateTapped):
                guard !state.repositoryURLInput.isEmpty else { return .none }
                state.validationRequestID += 1
                let currentRequestID = state.validationRequestID
                state.validation = .validating
                let url = state.repositoryURLInput
                return .run { send in
                    do {
                        let repository = try await fetchExternalRepository(url: url)
                        await send(.effect(.validationFinished(requestID: currentRequestID, result: .success(repository))))
                    } catch {
                        let mapped = error as? ExternalRepositoryError ?? .other
                        await send(.effect(.validationFinished(requestID: currentRequestID, result: .failure(mapped))))
                    }
                }
                .cancellable(id: CancelID.validation, cancelInFlight: true)

            case .view(.repositoryConfirmed):
                guard case .validated = state.validation else { return .none }
                state.step = .quizLevelSelection
                return .none

            case .view(.quizLevelConfirmed):
                guard state.step == .quizLevelSelection else { return .none }
                state.step = .generationConfirmation
                return .none

            case .view(.stepBackTapped):
                switch state.step {
                case .generationConfirmation:
                    state.step = .quizLevelSelection

                case .quizLevelSelection:
                    state.step = .repositoryConfirmation

                case .repositoryConfirmation:
                    break
                }
                return .none

            case .view(.submitTapped):
                guard
                    case .validated(let repository) = state.validation,
                    state.progress != .submitting
                else { return .none }
                return submit(repository: repository, quizLevel: state.quizLevel, state: &state)

            case .view(.retryTapped):
                guard
                    case .failed = state.progress,
                    case .validated(let repository) = state.validation
                else { return .none }
                return submit(repository: repository, quizLevel: state.quizLevel, state: &state)

            case .view(.waitAtHomeTapped):
                guard case .awaitingOutcome = state.progress else { return .none }
                return .run { [requestGenerationReminder] send in
                    let isAuthorized = await requestGenerationReminder.isAuthorized()
                    await send(.effect(.waitAtHomeAuthorizationChecked(isAuthorized: isAuthorized)))
                }

            case .effect(.waitAtHomeAuthorizationChecked(let isAuthorized)):
                guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
                guard isAuthorized else {
                    state.isGenerationReminderSheetPresented = true
                    return .none
                }
                return acceptGenerationReminder(receipt: receipt)

            case .view(.generationReminderAccepted):
                guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
                state.isGenerationReminderSheetPresented = false
                return acceptGenerationReminder(receipt: receipt)

            case .view(.generationReminderDeclined):
                guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
                state.isGenerationReminderSheetPresented = false
                return finishWaiting(receipt: receipt, isReminderEnabled: false)

            case .effect(.validationFinished(let requestID, let result)):
                guard requestID == state.validationRequestID else { return .none }
                switch result {
                case .success(let repository):
                    state.validation = .validated(repository)
                    state.step = .repositoryConfirmation

                case .failure:
                    state.validation = .failed
                    state.step = .repositoryConfirmation
                }
                return .none

            case .effect(.submissionFinished(.success(let receipt))):
                state.progress = .awaitingOutcome(receipt)
                return .none

            case .effect(.submissionFinished(.failure(let error))):
                return transitionToFailure(error, state: &state)

            case .effect(.generationOutcomeReceived(let outcome)):
                guard
                    case .awaitingOutcome(let receipt) = state.progress,
                    outcome.projectID == receipt.projectID
                else { return .none }
                switch outcome.status {
                case .completed:
                    return finishWaiting(receipt: receipt, isReminderEnabled: nil)

                case .failed:
                    return transitionToFailure(.unexpected, state: &state)
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation
        /// 구독 확립과 생성 요청, 결과 관찰이 하나의 실행 경로이므로 취소 단위도 하나다.
        case registrationPipeline
    }

    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    /// 생성 결과 구독을 먼저 확립한 뒤에 생성을 요청하고, 응답으로 받은 `projectID`로
    /// 이미 확립된 스트림을 필터링한다. 세 단계가 순서가 보장되는 단일 실행 경로에 있으므로
    /// 요청과 응답 사이에 도착한 결과도 스트림 버퍼에 남아 유실되지 않는다.
    private func submit(
        repository: ExternalRepository,
        quizLevel: QuizLevel,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .submitting
        return .run { send in
            let outcomes = await observeGenerationOutcomes()

            let receipt: ProjectRegistrationReceipt
            do {
                receipt = try await createLearningProject(
                    githubRepoURL: repository.canonicalURL,
                    quizLevel: quizLevel,
                )
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.submissionFinished(.failure(mapped))))
                return
            }
            await send(.effect(.submissionFinished(.success(receipt))))

            for await outcome in outcomes where outcome.projectID == receipt.projectID {
                await send(.effect(.generationOutcomeReceived(outcome)))
                // 생성 결과는 종료 신호다. 첫 결과만 전달해 중복 수신을 구조적으로 막는다.
                break
            }
        }
        .cancellable(id: CancelID.registrationPipeline, cancelInFlight: true)
    }

    /// 실패로 전이할 때 표시 중인 리마인드 시트를 함께 닫아 사용자가 재시도나 종료를
    /// 선택할 수 있게 한다.
    private func transitionToFailure(
        _ error: LearningProjectError,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .failed(error)
        state.isGenerationReminderSheetPresented = false
        return .cancel(id: CancelID.registrationPipeline)
    }

    private func acceptGenerationReminder(receipt: ProjectRegistrationReceipt) -> Effect<Action> {
        .merge(
            .run { [requestGenerationReminder, openNotificationSettings, projectID = receipt.projectID] _ in
                if await requestGenerationReminder(projectID: projectID) == .previouslyDenied {
                    await openNotificationSettings()
                }
            },
            finishWaiting(receipt: receipt, isReminderEnabled: true),
        )
    }

    private func finishWaiting(
        receipt: ProjectRegistrationReceipt,
        isReminderEnabled: Bool?,
    ) -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.registrationPipeline),
            .run { send in
                if let isReminderEnabled {
                    await send(.delegate(.generationReminderPreferenceSelected(isEnabled: isReminderEnabled)))
                }
                await send(.delegate(.projectRegistered(receipt)))
            },
        )
    }

}
