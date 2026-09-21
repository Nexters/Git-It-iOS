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
        externalRepository: any ExternalRepositoryUseCase,
        projectGeneration: any ProjectGenerationUseCase,
        signInAvailability: @escaping @Sendable () async -> SignInAvailability,
        recordDiagnostic: @escaping @Sendable (ShareRegistrationDiagnosticEvent) -> Void,
    ) {
        self.parseRepositoryLink = parseRepositoryLink
        self.externalRepository = externalRepository
        self.projectGeneration = projectGeneration
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
            case .input(.validate(let sharedURL)):
                state.sharedURL = sharedURL
                return validate(&state)

            case .input(.submit(let repository, let quizLevel)):
                guard !state.isSubmitting else { return .none }
                state.submission = Submission(repository: repository, quizLevel: quizLevel)
                return submit(&state)

            case .input(.retry):
                guard case .failed(_, let retry) = state.phase else { return .none }
                return switch retry {
                case .lookup: validate(&state)
                case .registration: submit(&state)
                }

            case .input(.cancel):
                return .merge(
                    .cancel(id: CancelID.registration),
                    .cancel(id: CancelID.validation),
                )

            case .effect(.validationFinished(let phase)):
                state.phase = phase
                return .none

            case .effect(.repositoryResolved(let repository)):
                state.phase = .ready(repository)
                return .send(.delegate(.repositoryResolved(repository)))

            case .effect(.registrationFinished(.success)):
                state.phase = .succeeded
                recordDiagnostic(.registrationSucceeded)
                return .none

            case .effect(.registrationFinished(.failure(let error))):
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

            case .delegate:
                return .none
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

    private let parseRepositoryLink: any ExternalRepositoryLocator
    private let externalRepository: any ExternalRepositoryUseCase
    private let projectGeneration: any ProjectGenerationUseCase
    private let signInAvailability: @Sendable () async -> SignInAvailability
    private let recordDiagnostic: @Sendable (ShareRegistrationDiagnosticEvent) -> Void

    private static func registrationFailureReason(for error: ProjectGenerationError) -> String {
        switch error {
        case .invalidRequest:
            "등록할 수 없는 저장소예요. 앱에서 다시 확인해 주세요."

        case .duplicateRequest:
            "이미 등록 중인 저장소예요."

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

    private func validate(_ state: inout State) -> Effect<Action> {
        state.phase = .validating
        guard let sharedURL = state.sharedURL else {
            state.phase = .invalidURL(reason: Self.sharedItemUnavailableReason)
            recordDiagnostic(.sharedItemUnavailable)
            return .none
        }
        guard parseRepositoryLink.location(from: sharedURL) != nil else {
            state.phase = .invalidURL(reason: Self.invalidLinkReason)
            recordDiagnostic(.repositoryLinkRejected)
            return .none
        }

        return .run { [signInAvailability, externalRepository, recordDiagnostic] send in
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

            do {
                let repository = try await externalRepository.repository(at: sharedURL)
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
        guard let submission = state.submission else { return .none }
        state.phase = .submitting
        return .run { [signInAvailability, projectGeneration, recordDiagnostic] send in
            let availability = await signInAvailability()
            guard availability == .signedIn else {
                recordDiagnostic(.signInAvailabilityResolved(availability))
                await send(.effect(.validationFinished(
                    availability == .signInRequired ? .signInRequired : .appLaunchRequired
                )))
                return
            }

            do {
                let receipt = try await projectGeneration.request(ProjectGenerationRequest(
                    repositoryURL: submission.repository.canonicalURL,
                    quizLevel: submission.quizLevel,
                ))
                await send(.effect(.registrationFinished(.success(receipt.projectID))))
            } catch {
                let mapped = error as? ProjectGenerationError ?? .unexpected
                await send(.effect(.registrationFinished(.failure(mapped))))
            }
        }
        .cancellable(id: CancelID.registration, cancelInFlight: true)
    }

}
