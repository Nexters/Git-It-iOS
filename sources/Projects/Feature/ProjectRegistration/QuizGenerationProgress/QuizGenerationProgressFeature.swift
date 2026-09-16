import ComposableArchitecture
import DomainLearningProject
import Foundation

@Reducer
public struct QuizGenerationProgressFeature: Sendable {

    // MARK: Lifecycle

    public init(
        createLearningProject: any CreateLearningProjectUseCase,
        trackGeneration: any TrackGenerationUseCase,
        requestGenerationReminder: any RequestGenerationReminderUseCase,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
        waitPolicy: GenerationWaitPolicy = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.createLearningProject = createLearningProject
        self.trackGeneration = trackGeneration
        self.requestGenerationReminder = requestGenerationReminder
        self.openNotificationSettings = openNotificationSettings
        self.waitPolicy = waitPolicy
        self.now = now
    }

    // MARK: Public

    public enum RegistrationProgress: Equatable, Sendable {
        case idle
        case submitting
        case awaitingOutcome(ProjectRegistrationReceipt)
        case failed(LearningProjectError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init() { }

        public var progress = RegistrationProgress.idle
        public var isGenerationReminderSheetPresented = false
        public var requestedAt: Date?
        public var pendingOutcome: GenerationOutcome?

        var repository: ExternalRepository?
        var quizLevel = QuizLevel.l1

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case submit(repository: ExternalRepository, quizLevel: QuizLevel)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case waitAtHomeTapped
            case retryTapped
            case dismissTapped
            case generationReminderAccepted
            case generationReminderDeclined
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case submissionFinished(Result<ProjectRegistrationReceipt, LearningProjectError>)
            case generationOutcomeReceived(GenerationOutcome)
            case waitAtHomeAuthorizationChecked(isAuthorized: Bool)
            case minimumWaitElapsed
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistered(ProjectRegistrationReceipt)
            case generationReminderPreferenceSelected(isEnabled: Bool)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .submit(let repository, let quizLevel):
                state.repository = repository
                state.quizLevel = quizLevel
                return submit(repository: repository, quizLevel: quizLevel, state: &state)

            case .view(.retryTapped):
                guard
                    case .failed = state.progress,
                    let repository = state.repository
                else { return .none }
                return submit(repository: repository, quizLevel: state.quizLevel, state: &state)

            case .view(.dismissTapped):
                return .send(.delegate(.dismissRequested))

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

                let remaining = remainingWait(requestedAt: state.requestedAt)
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
        case registrationPipeline

        case minimumWait
    }

    private let createLearningProject: any CreateLearningProjectUseCase
    private let trackGeneration: any TrackGenerationUseCase
    private let requestGenerationReminder: any RequestGenerationReminderUseCase
    private let openNotificationSettings: @MainActor @Sendable () async -> Void
    private let waitPolicy: GenerationWaitPolicy
    private let now: @Sendable () -> Date

    private static func outcome(from record: GenerationRecord) -> GenerationOutcome? {
        guard let projectID = record.projectID else { return nil }
        switch record.status {
        case .inProgress:
            return nil

        case .completed:
            return GenerationOutcome(projectID: projectID, status: .completed)

        case .failed:
            return GenerationOutcome(projectID: projectID, status: .failed)
        }
    }

    private func submit(
        repository: ExternalRepository,
        quizLevel: QuizLevel,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .submitting
        state.requestedAt = now()
        state.pendingOutcome = nil
        return .run { [trackGeneration] send in
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

            for await generationState in await trackGeneration.states() {
                guard
                    let record = generationState.record(projectID: receipt.projectID),
                    let outcome = Self.outcome(from: record)
                else { continue }
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

    private func remainingWait(requestedAt: Date?) -> TimeInterval {
        guard let requestedAt else { return 0 }
        return requestedAt.addingTimeInterval(waitPolicy.minimumWait).timeIntervalSince(now())
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
