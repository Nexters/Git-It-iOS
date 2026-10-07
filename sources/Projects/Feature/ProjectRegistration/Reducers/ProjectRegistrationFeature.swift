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
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.observeGenerationOutcomes = observeGenerationOutcomes
        self.requestGenerationReminder = requestGenerationReminder
        self.openNotificationSettings = openNotificationSettings
        self.waitPolicy = waitPolicy
        self.now = now
    }

    // MARK: Public

    public enum RegistrationStep: Equatable, Sendable {
        case repositoryConfirmation
        case quizLevelSelection
        case generationConfirmation
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(initialRepositoryURL: String = "") {
            repositoryURLInput = initialRepositoryURL
            pendingAutomaticValidation = !initialRepositoryURL.isEmpty
        }

        // MARK: Public

        public var repositoryURLInput = ""
        public var quizLevel = QuizLevel.l1
        public var validation = ValidationStatus.idle
        public var progress = RegistrationProgress.idle
        public var step = RegistrationStep.repositoryConfirmation
        public var validationRequestID = 0
        public var isGenerationReminderSheetPresented = false

        public var requestedAt: Date?

        public var pendingOutcome: GenerationOutcome?

        // MARK: Internal

        var pendingAutomaticValidation = false

    }

    public enum ValidationStatus: Equatable, Sendable {
        case idle
        case validating
        case validated(ExternalRepository)
        case failed
    }

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
            case task
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
            case minimumWaitElapsed
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
            case .view(.task):
                guard state.pendingAutomaticValidation else { return .none }
                state.pendingAutomaticValidation = false
                return startValidation(&state)

            case .view(.repositoryURLChanged(let text)):
                state.repositoryURLInput = text
                state.validation = .idle
                state.step = .repositoryConfirmation
                return .none

            case .view(.quizLevelSelected(let level)):
                state.quizLevel = level
                return .none

            case .view(.validateTapped):
                return startValidation(&state)

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

                let remaining = remainingWait(requestedAt: state.requestedAt, projectID: receipt.projectID)
                guard remaining > 0 else {
                    return applyOutcome(outcome, receipt: receipt, state: &state)
                }
                state.pendingOutcome = outcome
                return .run { send in
                    try await Task.sleep(for: .seconds(remaining))
                    await send(.effect(.minimumWaitElapsed))
                }
                .cancellable(id: CancelID.minimumWait, cancelInFlight: true)

            case .effect(.minimumWaitElapsed):
                guard
                    case .awaitingOutcome(let receipt) = state.progress,
                    let outcome = state.pendingOutcome
                else { return .none }
                return applyOutcome(outcome, receipt: receipt, state: &state)

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation

        case registrationPipeline

        case minimumWait
    }

    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let observeGenerationOutcomes: any ObserveGenerationOutcomesUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date

    private func startValidation(_ state: inout State) -> Effect<Action> {
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
    }

    private func submit(
        repository: ExternalRepository,
        quizLevel: QuizLevel,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .submitting
        state.requestedAt = now()
        state.pendingOutcome = nil
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

                break
            }
        }
        .cancellable(id: CancelID.registrationPipeline, cancelInFlight: true)
    }

    private func transitionToFailure(
        _ error: LearningProjectError,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .failed(error)
        state.isGenerationReminderSheetPresented = false
        state.pendingOutcome = nil
        return .merge(
            .cancel(id: CancelID.registrationPipeline),
            .cancel(id: CancelID.minimumWait),
        )
    }

    private func remainingWait(
        requestedAt: Date?,
        projectID: String,
    ) -> TimeInterval {
        guard let requestedAt else { return 0 }
        let progress = GenerationProgress(projectID: projectID, requestedAt: requestedAt)
        return waitPolicy.readyDate(for: progress).timeIntervalSince(now())
    }

    private func applyOutcome(
        _ outcome: GenerationOutcome,
        receipt: ProjectRegistrationReceipt,
        state: inout State,
    ) -> Effect<Action> {
        state.pendingOutcome = nil
        switch outcome.status {
        case .completed:
            return finishWaiting(receipt: receipt, isReminderEnabled: nil)

        case .failed:
            return transitionToFailure(.unexpected, state: &state)
        }
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
            .cancel(id: CancelID.minimumWait),
            .run { send in
                if let isReminderEnabled {
                    await send(.delegate(.generationReminderPreferenceSelected(isEnabled: isReminderEnabled)))
                }
                await send(.delegate(.projectRegistered(receipt)))
            },
        )
    }

}
