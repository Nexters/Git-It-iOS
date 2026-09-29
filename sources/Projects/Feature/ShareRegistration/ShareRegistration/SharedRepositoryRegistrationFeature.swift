import ComposableArchitecture
import DomainAccount
import DomainExternalRepository
import DomainIdentifier
import DomainProjectGeneration
import Foundation

@Reducer
public struct SharedRepositoryRegistrationFeature: Sendable {

    // MARK: Lifecycle

    public init(
        parseRepositoryLink: any ExternalRepositoryLocator,
        lookUpRepository: @escaping @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository,
        requestGeneration: @escaping @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt,
        currentGenerationState: @escaping @Sendable () async throws -> ProjectGenerationState,
        signInAvailability: @escaping @Sendable () async -> SignInAvailability,
        recordDiagnostic: @escaping @Sendable (ShareRegistrationDiagnosticEvent) -> Void,
    ) {
        self.parseRepositoryLink = parseRepositoryLink
        self.lookUpRepository = lookUpRepository
        self.requestGeneration = requestGeneration
        self.currentGenerationState = currentGenerationState
        self.signInAvailability = signInAvailability
        self.recordDiagnostic = recordDiagnostic
    }

    // MARK: Public

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(sharedURL: String? = nil) {
            self.sharedURL = sharedURL
        }

        // MARK: Public

        public enum RetryTarget: Equatable, Sendable {
            case lookup
            case registration
        }

        public enum Phase: Equatable, Sendable {
            case validating
            case ready(ExternalRepository)
            case invalidURL(reason: String)
            case signInRequired
            case appLaunchRequired
            case submitting
            case succeeded
            case failed(reason: String, retry: RetryTarget)
            case generationInProgress
            case generationUnverified(retry: RetryTarget)
        }

        public var sharedURL: String?
        public var phase = Phase.validating
        public var submission: Submission?

        public var isSubmitting: Bool {
            phase == .submitting
        }

    }

    public struct Submission: Equatable, Sendable {
        public let repository: ExternalRepository
        public let quizLevel: QuizLevel
    }

    public enum Action: Equatable, Sendable {
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum Input: Equatable, Sendable {
            case validate(sharedURL: String?)
            case submit(repository: ExternalRepository, quizLevel: QuizLevel)
            case retry
            case cancel
        }

        @CasePathable
        public enum EffectEvent: Equatable, Sendable {
            case validationFinished(State.Phase)
            case repositoryResolved(ExternalRepository)
            case registrationFinished(Result<ProjectID, ProjectGenerationError>)
        }

        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case repositoryResolved(ExternalRepository)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .input(let action):
                reduce(
                    into: &state,
                    input: action,
                )

            case .effect(let event):
                reduce(
                    into: &state,
                    effect: event,
                )

            case .delegate:
                .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation
        case registration
    }

    private let parseRepositoryLink: any ExternalRepositoryLocator
    private let lookUpRepository: @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository
    private let requestGeneration: @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
    private let currentGenerationState: @Sendable () async throws -> ProjectGenerationState
    private let signInAvailability: @Sendable () async -> SignInAvailability
    private let recordDiagnostic: @Sendable (ShareRegistrationDiagnosticEvent) -> Void

    private static func registrationFailureReason(for error: ProjectGenerationError) -> String {
        switch error {
        case .invalidRequest:
            LocalizedText.ShareRegistration.InvalidRequest.reason

        case .duplicateRequest:
            LocalizedText.ShareRegistration.DuplicateRequest.reason

        case .temporarilyUnavailable:
            LocalizedText.ShareRegistration.TemporarilyUnavailable.reason

        default:
            LocalizedText.ShareRegistration.RegistrationFailure.reason
        }
    }

    private static func generationBlockedPhase(
        currentGenerationState: @Sendable () async throws -> ProjectGenerationState,
        recordDiagnostic: @Sendable (ShareRegistrationDiagnosticEvent) -> Void,
        retry: State.RetryTarget,
    ) async -> State.Phase? {
        do {
            guard try await currentGenerationState().hasRequestInProgress else { return nil }
            recordDiagnostic(.generationInProgressBlocked)
            return .generationInProgress
        } catch {
            recordDiagnostic(.generationStateUnverified)
            return .generationUnverified(retry: retry)
        }
    }

    private static func lookupFailureReason(for error: ExternalRepositoryError) -> String {
        switch error {
        case .offline:
            LocalizedText.ShareRegistration.Offline.reason

        default:
            LocalizedText.ShareRegistration.Lookup.Failure.reason
        }
    }

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .validate(let sharedURL):
            state.sharedURL = sharedURL
            return validate(&state)

        case .submit(let repository, let quizLevel):
            guard !state.isSubmitting else { return .none }
            state.submission = Submission(
                repository: repository,
                quizLevel: quizLevel,
            )
            return submit(&state)

        case .retry:
            let retry: State.RetryTarget
            switch state.phase {
            case .failed(_, let target),
                 .generationUnverified(let target):
                retry = target

            default:
                return .none
            }
            return switch retry {
            case .lookup: validate(&state)
            case .registration: submit(&state)
            }

        case .cancel:
            return .merge(
                .cancel(id: CancelID.registration),
                .cancel(id: CancelID.validation),
            )
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .validationFinished(let phase):
            state.phase = phase
            return .none

        case .repositoryResolved(let repository):
            state.phase = .ready(repository)
            return .send(.delegate(.repositoryResolved(repository)))

        case .registrationFinished(let result):
            switch result {
            case .success:
                state.phase = .succeeded
                recordDiagnostic(.registrationSucceeded)
                return .none

            case .failure(let error):
                if error == .unauthorized {
                    state.phase = .signInRequired
                    recordDiagnostic(.signInAvailabilityResolved(.signInRequired))
                } else {
                    state.phase = .failed(
                        reason: Self.registrationFailureReason(for: error),
                        retry: .registration,
                    )
                    recordDiagnostic(.registrationFailed(reason: String(describing: error)))
                }
                return .none
            }
        }
    }

    private func validate(_ state: inout State) -> Effect<Action> {
        state.phase = .validating
        guard let sharedURL = state.sharedURL else {
            state.phase = .invalidURL(reason: LocalizedText.ShareRegistration.SharedItemUnavailable.reason)
            recordDiagnostic(.sharedItemUnavailable)
            return .none
        }
        guard parseRepositoryLink.location(from: sharedURL) != nil else {
            state.phase = .invalidURL(reason: LocalizedText.ShareRegistration.InvalidLink.reason)
            recordDiagnostic(.repositoryLinkRejected)
            return .none
        }

        return .run { [signInAvailability, currentGenerationState, lookUpRepository, recordDiagnostic] send in
            let availability = await signInAvailability()
            recordDiagnostic(.signInAvailabilityResolved(availability))
            switch availability {
            case .signInRequired:
                await send(.effect(.validationFinished(.signInRequired)))
                return

            case .appLaunchRequired:
                await send(.effect(.validationFinished(.appLaunchRequired)))
                return

            case .signedIn:
                break
            }

            if
                let blocked = await Self.generationBlockedPhase(
                    currentGenerationState: currentGenerationState,
                    recordDiagnostic: recordDiagnostic,
                    retry: .lookup,
                )
            {
                await send(.effect(.validationFinished(blocked)))
                return
            }

            do {
                let repository = try await lookUpRepository(sharedURL)
                await send(.effect(.repositoryResolved(repository)))
            } catch let error as ExternalRepositoryError {
                if error == .invalidURLFormat {
                    recordDiagnostic(.repositoryLinkRejected)
                    await send(.effect(.validationFinished(.invalidURL(reason: LocalizedText.ShareRegistration.InvalidLink
                            .reason))))
                } else {
                    recordDiagnostic(.repositoryLookupFailed(reason: String(describing: error)))
                    await send(.effect(.validationFinished(.failed(
                        reason: Self.lookupFailureReason(for: error),
                        retry: .lookup,
                    ))))
                }
            } catch {
                recordDiagnostic(.repositoryLookupFailed(reason: String(describing: error)))
                await send(.effect(.validationFinished(.failed(
                    reason: Self.lookupFailureReason(for: .other),
                    retry: .lookup,
                ))))
            }
        }
        .cancellable(
            id: CancelID.validation,
            cancelInFlight: true,
        )
    }

    private func submit(_ state: inout State) -> Effect<Action> {
        guard let submission = state.submission else { return .none }
        state.phase = .submitting
        return .run { [signInAvailability, currentGenerationState, requestGeneration, recordDiagnostic] send in
            let availability = await signInAvailability()
            guard availability == .signedIn else {
                recordDiagnostic(.signInAvailabilityResolved(availability))
                await send(.effect(.validationFinished(
                    availability == .signInRequired ? .signInRequired : .appLaunchRequired
                )))
                return
            }

            if
                let blocked = await Self.generationBlockedPhase(
                    currentGenerationState: currentGenerationState,
                    recordDiagnostic: recordDiagnostic,
                    retry: .registration,
                )
            {
                await send(.effect(.validationFinished(blocked)))
                return
            }

            do {
                let receipt = try await requestGeneration(ProjectGenerationRequest(
                    repositoryURL: submission.repository.canonicalURL,
                    quizLevel: submission.quizLevel,
                ))
                await send(.effect(.registrationFinished(.success(receipt.projectID))))
            } catch {
                let mapped = error as? ProjectGenerationError ?? .unexpected
                await send(.effect(.registrationFinished(.failure(mapped))))
            }
        }
        .cancellable(
            id: CancelID.registration,
            cancelInFlight: true,
        )
    }

}
