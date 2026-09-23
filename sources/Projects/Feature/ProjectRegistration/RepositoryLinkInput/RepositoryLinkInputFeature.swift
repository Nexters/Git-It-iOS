import ComposableArchitecture
import DomainExternalRepository
import DomainIdentifier

@Reducer
public struct RepositoryLinkInputFeature: Sendable {

    // MARK: Lifecycle

    public init(repository: @escaping @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository) {
        self.repository = repository
    }

    // MARK: Public

    public enum ValidationStatus: Equatable, Sendable {
        case idle
        case validating
        case validated(ExternalRepository)
        case failed
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        // MARK: Lifecycle

        public init() { }

        // MARK: Public

        public var repositoryURLInput = ""
        public var validation = ValidationStatus.idle
        public var validationRequestID = 0

        public var canValidate: Bool {
            !repositoryURLInput.isEmpty && validation != .validating
        }

        public var isValidationFailed: Bool {
            if case .failed = validation {
                return true
            }
            return false
        }

        public var validateButtonTitle: String {
            validation == .validating
                ? LocalizedText.ProjectRegistration.repositoryLinkInputValidatingButtonTitle
                : LocalizedText.ProjectRegistration.repositoryLinkInputNextButtonTitle
        }

    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case input(Input)
        case effect(EffectEvent)
        case delegate(Delegate)

        // MARK: Public

        @CasePathable
        public enum View: Sendable, Equatable {
            case repositoryURLChanged(String)
            case validateTapped
            case dismissTapped
        }

        @CasePathable
        public enum Input: Sendable, Equatable {
            case validationReset
        }

        @CasePathable
        public enum EffectEvent: Sendable, Equatable {
            case validationFinished(requestID: Int, result: Result<ExternalRepository, ExternalRepositoryError>)
        }

        @CasePathable
        public enum Delegate: Sendable, Equatable {
            case repositoryValidated(ExternalRepository)
            case dismissRequested
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.repositoryURLChanged(let text)):
                state.repositoryURLInput = text
                state.validation = .idle
                return .none

            case .view(.validateTapped):
                return startValidation(&state)

            case .input(.validationReset):
                state.validation = .idle
                return .none

            case .view(.dismissTapped):
                return .send(.delegate(.dismissRequested))

            case .effect(.validationFinished(let requestID, let result)):
                guard requestID == state.validationRequestID else { return .none }
                switch result {
                case .success(let repository):
                    state.validation = .validated(repository)
                    return .send(.delegate(.repositoryValidated(repository)))

                case .failure:
                    state.validation = .failed
                    return .none
                }

            case .delegate:
                return .none
            }
        }
    }

    // MARK: Private

    private enum CancelID: Hashable {
        case validation
    }

    private let repository: @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository

    private func startValidation(_ state: inout State) -> Effect<Action> {
        guard !state.repositoryURLInput.isEmpty else { return .none }
        state.validationRequestID += 1
        let currentRequestID = state.validationRequestID
        state.validation = .validating
        let url = state.repositoryURLInput
        return .run { send in
            do {
                let resolved = try await repository(url)
                await send(.effect(.validationFinished(
                    requestID: currentRequestID,
                    result: .success(resolved),
                )))
            } catch {
                let mapped = error as? ExternalRepositoryError ?? .other
                await send(.effect(.validationFinished(
                    requestID: currentRequestID,
                    result: .failure(mapped),
                )))
            }
        }
        .cancellable(
            id: CancelID.validation,
            cancelInFlight: true,
        )
    }

}
