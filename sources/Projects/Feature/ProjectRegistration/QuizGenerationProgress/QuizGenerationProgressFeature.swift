import ComposableArchitecture
import DomainAppSetting
import DomainExternalRepository
import DomainProjectGeneration
import Foundation

@Reducer
public struct QuizGenerationProgressFeature: Sendable {

    // MARK: Lifecycle

    public init(
        requestGeneration: @escaping @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt,
        generationStates: @escaping @Sendable () async -> AsyncStream<ProjectGenerationState>,
        notificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus,
        requestNotificationAuthorization: @escaping @Sendable () async -> NotificationAuthorizationStatus,
        openNotificationSettings: @escaping @MainActor @Sendable () async -> Void = { },
    ) {
        self.requestGeneration = requestGeneration
        self.generationStates = generationStates
        self.notificationAuthorization = notificationAuthorization
        self.requestNotificationAuthorization = requestNotificationAuthorization
        self.openNotificationSettings = openNotificationSettings
    }

    // MARK: Public

    public enum RegistrationProgress: Equatable, Sendable {
        case idle
        case submitting
        case awaitingOutcome(ProjectGenerationReceipt)
        case failed(ProjectGenerationError)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init() { }

        public var progress = RegistrationProgress.idle
        public var isGenerationReminderSheetPresented = false

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
            case submissionFinished(Result<ProjectGenerationReceipt, ProjectGenerationError>)
            case generationPhaseReceived(ProjectGenerationPhase)
            case waitAtHomeAuthorizationChecked(NotificationAuthorizationStatus)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case projectRegistered(ProjectGenerationReceipt)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(let action):
                return reduce(
                    into: &state,
                    view: action,
                )

            case .effect(let event):
                return reduce(
                    into: &state,
                    effect: event,
                )

            case .submit(let repository, let quizLevel):
                state.repository = repository
                state.quizLevel = quizLevel
                return submit(
                    repository: repository,
                    quizLevel: quizLevel,
                    state: &state,
                )

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case registrationPipeline
    }

    private let requestGeneration: @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
    private let generationStates: @Sendable () async -> AsyncStream<ProjectGenerationState>
    private let notificationAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    private let requestNotificationAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    private let openNotificationSettings: @MainActor @Sendable () async -> Void

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .waitAtHomeTapped:
            guard case .awaitingOutcome = state.progress else { return .none }
            return .run { [notificationAuthorization] send in
                await send(.effect(.waitAtHomeAuthorizationChecked(await notificationAuthorization())))
            }

        case .retryTapped:
            guard
                case .failed = state.progress,
                let repository = state.repository
            else { return .none }
            return submit(
                repository: repository,
                quizLevel: state.quizLevel,
                state: &state,
            )

        case .dismissTapped:
            return .send(.delegate(.dismissRequested))

        case .generationReminderAccepted:
            guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
            state.isGenerationReminderSheetPresented = false
            return acceptGenerationReminder(receipt: receipt)

        case .generationReminderDeclined:
            guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
            state.isGenerationReminderSheetPresented = false
            return finishWaiting(receipt: receipt)
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .submissionFinished(let result):
            switch result {
            case .success(let receipt):
                state.progress = .awaitingOutcome(receipt)
                return .none

            case .failure(let error):
                return transitionToFailure(
                    error,
                    state: &state,
                )
            }

        case .generationPhaseReceived(let phase):
            guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
            switch phase {
            case .inProgress:
                return .none

            case .ready:
                return finishWaiting(receipt: receipt)

            case .failed:
                return transitionToFailure(
                    .unexpected,
                    state: &state,
                )
            }

        case .waitAtHomeAuthorizationChecked(let status):
            guard case .awaitingOutcome(let receipt) = state.progress else { return .none }
            guard status == .authorized else {
                state.isGenerationReminderSheetPresented = true
                return .none
            }
            return finishWaiting(receipt: receipt)
        }
    }

    private func submit(
        repository: ExternalRepository,
        quizLevel: QuizLevel,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .submitting
        return .run { [generationStates] send in
            let receipt: ProjectGenerationReceipt
            do {
                receipt = try await requestGeneration(ProjectGenerationRequest(
                    repositoryURL: repository.canonicalURL,
                    quizLevel: quizLevel,
                ))
            } catch {
                let mapped = error as? ProjectGenerationError ?? .unexpected
                await send(.effect(.submissionFinished(.failure(mapped))))
                return
            }
            await send(.effect(.submissionFinished(.success(receipt))))

            for await generationState in await generationStates() {
                guard
                    let request = generationState.requests.first(where: { $0.projectID == receipt.projectID })
                else { continue }
                await send(.effect(.generationPhaseReceived(request.phase)))
            }
        }
        .cancellable(
            id: CancelID.registrationPipeline,
            cancelInFlight: true,
        )
    }

    private func transitionToFailure(
        _ error: ProjectGenerationError,
        state: inout State,
    ) -> Effect<Action> {
        state.progress = .failed(error)
        state.isGenerationReminderSheetPresented = false
        return .cancel(id: CancelID.registrationPipeline)
    }

    private func acceptGenerationReminder(receipt: ProjectGenerationReceipt) -> Effect<Action> {
        .merge(
            .run { [requestNotificationAuthorization, openNotificationSettings] _ in
                if await requestNotificationAuthorization() != .authorized {
                    await openNotificationSettings()
                }
            },
            finishWaiting(receipt: receipt),
        )
    }

    private func finishWaiting(receipt: ProjectGenerationReceipt) -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.registrationPipeline),
            .run { send in
                await send(.delegate(.projectRegistered(receipt)))
            },
        )
    }

}
