import ComposableArchitecture
import DomainLearningProject
import Foundation

// MARK: - ShareRegistrationFeature

@Reducer
public struct ShareRegistrationFeature: Sendable {

    // MARK: Lifecycle

    public init(
        parseRepositoryLink: any ExternalRepositoryURLParser,
        fetchExternalRepository: any FetchExternalRepositoryUseCase,
        createLearningProject: any CreateLearningProjectUseCase,
        resolveSession: @escaping @Sendable () async -> ShareRegistrationSessionState,
        isNotificationAuthorized: @escaping @Sendable () async -> Bool = { false },
        enqueueGenerationReminder: @escaping @Sendable (String) async -> Void = { _ in },
        recordDiagnostic: @escaping @Sendable (ShareRegistrationDiagnosticEvent) -> Void = { _ in },
        dismiss: @escaping @MainActor @Sendable () -> Void = { },
    ) {
        self.parseRepositoryLink = parseRepositoryLink
        self.fetchExternalRepository = fetchExternalRepository
        self.createLearningProject = createLearningProject
        self.resolveSession = resolveSession
        self.isNotificationAuthorized = isNotificationAuthorized
        self.enqueueGenerationReminder = enqueueGenerationReminder
        self.recordDiagnostic = recordDiagnostic
        self.dismiss = dismiss
    }

    // MARK: Public

    public enum RetryTarget: Equatable, Sendable {
        case lookup
        case registration
    }

    public enum Status: Equatable, Sendable {
        case validating
        case repositoryConfirmation
        case quizLevelSelection
        case quizGenerationConfirmation
        case invalidURL(reason: String)
        case signInRequired
        case appLaunchRequired
        case submitting
        case succeeded
        case failed(reason: String, retry: RetryTarget)
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init(sharedURL: String? = nil) {
            self.sharedURL = sharedURL
        }

        // MARK: Public

        public var sharedURL: String?
        public var status = Status.validating

        public var repositoryConfirmation = RepositoryConfirmationFeature.State()
        public var quizLevelSelection = QuizLevelSelectionFeature.State()
        public var quizGenerationConfirmation = QuizGenerationConfirmationFeature.State()

        public var repository: ExternalRepository? {
            repositoryConfirmation.repository
        }

        public var quizLevel: QuizLevel {
            quizLevelSelection.quizLevel
        }

        public var isBusy: Bool {
            if case .submitting = status {
                return true
            }
            return false
        }

        public var canDismiss: Bool {
            !isBusy
        }

        public var canRetry: Bool {
            if case .failed = status {
                return true
            }
            return false
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case repositoryConfirmation(RepositoryConfirmationFeature.Action)
        case quizLevelSelection(QuizLevelSelectionFeature.Action)
        case quizGenerationConfirmation(QuizGenerationConfirmationFeature.Action)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case sharedURLResolved(String?)
            case retryTapped
            case dismissTapped
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case validationFinished(Status)
            case repositoryResolved(ExternalRepository)
            case registrationFinished(Result<String, LearningProjectError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.repositoryConfirmation, action: \.repositoryConfirmation) {
            RepositoryConfirmationFeature()
        }
        Scope(state: \.quizLevelSelection, action: \.quizLevelSelection) {
            QuizLevelSelectionFeature()
        }
        Scope(state: \.quizGenerationConfirmation, action: \.quizGenerationConfirmation) {
            QuizGenerationConfirmationFeature()
        }
        Reduce { state, action in
            switch action {
            case .view(.task):
                guard state.sharedURL != nil else { return .none }
                return validate(&state)

            case .view(.sharedURLResolved(let sharedURL)):
                state.sharedURL = sharedURL
                return validate(&state)

            case .view(.retryTapped):
                guard case .failed(_, let retry) = state.status else { return .none }
                return switch retry {
                case .lookup: validate(&state)
                case .registration: submit(&state)
                }

            case .view(.dismissTapped):
                return dismissIfIdle(&state)

            case .repositoryConfirmation(.delegate(.confirmed)):
                state.status = .quizLevelSelection
                return .none

            case .repositoryConfirmation(.delegate(.rejected)):
                return dismissIfIdle(&state)

            case .quizLevelSelection(.delegate(.confirmed)):
                state.status = .quizGenerationConfirmation
                return .none

            case .quizLevelSelection(.delegate(.backRequested)):
                state.status = .repositoryConfirmation
                return .none

            case .quizGenerationConfirmation(.delegate(.submitRequested)):
                return submit(&state)

            case .quizGenerationConfirmation(.delegate(.backRequested)):
                state.status = .quizLevelSelection
                return .none

            case .effect(.validationFinished(let status)):
                state.status = status
                return .none

            case .effect(.repositoryResolved(let repository)):
                state.repositoryConfirmation.repository = repository
                state.status = .repositoryConfirmation
                return .none

            case .effect(.registrationFinished(let result)):
                switch result {
                case .success(let projectID):
                    state.status = .succeeded
                    recordDiagnostic(.registrationSucceeded)
                    return enqueueReminderIfAuthorized(projectID: projectID)

                case .failure(let error):
                    if error == .unauthorized {
                        state.status = .signInRequired
                        recordDiagnostic(.sessionResolved(.signInRequired))
                    } else {
                        state.status = .failed(
                            reason: Self.registrationFailureReason(for: error),
                            retry: .registration,
                        )
                        recordDiagnostic(.registrationFailed(reason: String(describing: error)))
                    }
                    return .none
                }

            case .repositoryConfirmation,
                 .quizGenerationConfirmation,
                 .quizLevelSelection:
                return .none

            case .delegate(.dismissRequested):
                return .run { _ in await dismiss() }
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation
        case registration
    }

    private static let sharedItemUnavailableReason = "공유한 항목에서 링크를 찾지 못했어요."
    private static let invalidLinkReason = "GitHub 저장소 주소가 아니에요."

    private let parseRepositoryLink: any ExternalRepositoryURLParser
    private let fetchExternalRepository: any FetchExternalRepositoryUseCase
    private let createLearningProject: any CreateLearningProjectUseCase
    private let resolveSession: @Sendable () async -> ShareRegistrationSessionState
    private let isNotificationAuthorized: @Sendable () async -> Bool
    private let enqueueGenerationReminder: @Sendable (String) async -> Void
    private let recordDiagnostic: @Sendable (ShareRegistrationDiagnosticEvent) -> Void
    private let dismiss: @MainActor @Sendable () -> Void

    private static func registrationFailureReason(for error: LearningProjectError) -> String {
        switch error {
        case .invalidRequest:
            "등록할 수 없는 저장소예요. 앱에서 다시 확인해 주세요."

        case .notFound:
            "저장소를 찾지 못했어요."

        case .temporarilyUnavailable:
            "지금은 연결할 수 없어요. 잠시 후 다시 시도해 주세요."

        default:
            "등록에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    private static func lookupFailureReason(for error: ExternalRepositoryError) -> String {
        switch error {
        case .offline:
            "네트워크에 연결할 수 없어요."

        default:
            "저장소 정보를 가져오지 못했어요."
        }
    }

    private func dismissIfIdle(_ state: inout State) -> Effect<Action> {
        guard state.canDismiss else { return .none }
        return .merge(
            .cancel(id: CancelID.registration),
            .cancel(id: CancelID.validation),
            .send(.delegate(.dismissRequested)),
        )
    }

    private func validate(_ state: inout State) -> Effect<Action> {
        state.status = .validating
        guard let sharedURL = state.sharedURL else {
            state.status = .invalidURL(reason: Self.sharedItemUnavailableReason)
            recordDiagnostic(.sharedItemUnavailable)
            return .none
        }
        guard parseRepositoryLink.location(from: sharedURL) != nil else {
            state.status = .invalidURL(reason: Self.invalidLinkReason)
            recordDiagnostic(.repositoryLinkRejected)
            return .none
        }

        return .run { send in
            let session = await resolveSession()
            recordDiagnostic(.sessionResolved(session))
            switch session {
            case .signInRequired:
                await send(.effect(.validationFinished(.signInRequired)))
                return

            case .appLaunchRequired:
                await send(.effect(.validationFinished(.appLaunchRequired)))
                return

            case .available:
                break
            }

            do {
                let repository = try await fetchExternalRepository(url: sharedURL)
                await send(.effect(.repositoryResolved(repository)))
            } catch let error as ExternalRepositoryError {
                if error == .invalidURLFormat {
                    recordDiagnostic(.repositoryLinkRejected)
                    await send(.effect(.validationFinished(.invalidURL(reason: Self.invalidLinkReason))))
                } else {
                    recordDiagnostic(.repositoryLookupFailed(reason: String(describing: error)))
                    await send(.effect(.validationFinished(.failed(
                        reason: Self.lookupFailureReason(for: error),
                        retry: .lookup,
                    ))))
                }
            } catch let error as LearningProjectError where error == .unauthorized {
                recordDiagnostic(.sessionResolved(.signInRequired))
                await send(.effect(.validationFinished(.signInRequired)))
            } catch {
                recordDiagnostic(.repositoryLookupFailed(reason: String(describing: error)))
                await send(.effect(.validationFinished(.failed(
                    reason: Self.lookupFailureReason(for: .other),
                    retry: .lookup,
                ))))
            }
        }
        .cancellable(id: CancelID.validation, cancelInFlight: true)
    }

    private func submit(_ state: inout State) -> Effect<Action> {
        guard let repository = state.repository, !state.isBusy else { return .none }
        state.status = .submitting
        let quizLevel = state.quizLevel
        return .run { send in
            do {
                let receipt = try await createLearningProject(
                    githubRepoURL: repository.canonicalURL,
                    quizLevel: quizLevel,
                )
                await send(.effect(.registrationFinished(.success(receipt.projectID))))
            } catch {
                let mapped = error as? LearningProjectError ?? .unexpected
                await send(.effect(.registrationFinished(.failure(mapped))))
            }
        }
        .cancellable(id: CancelID.registration, cancelInFlight: true)
    }

    private func enqueueReminderIfAuthorized(projectID: String) -> Effect<Action> {
        .run { _ in
            guard await isNotificationAuthorized() else { return }
            await enqueueGenerationReminder(projectID)
            recordDiagnostic(.generationReminderEnqueued)
        }
    }

}
