import ComposableArchitecture
import DomainUseCaseInterface

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
                ? LocalizedText.ProjectRegistration.RepositoryLinkInput.Validating.buttonTitle
                : LocalizedText.ProjectRegistration.RepositoryLinkInput.Next.buttonTitle
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
            case .view(let action):
                reduce(
                    into: &state,
                    view: action,
                )

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
    }

    private let repository: @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository

    private func reduce(
        into state: inout State,
        view action: Action.View,
    ) -> Effect<Action> {
        switch action {
        case .repositoryURLChanged(let text):
            state.repositoryURLInput = text
            state.validation = .idle
            return .none

        case .validateTapped:
            return startValidation(&state)

        case .dismissTapped:
            return .send(.delegate(.dismissRequested))
        }
    }

    private func reduce(
        into state: inout State,
        input action: Action.Input,
    ) -> Effect<Action> {
        switch action {
        case .validationReset:
            state.validation = .idle
            return .none
        }
    }

    private func reduce(
        into state: inout State,
        effect event: Action.EffectEvent,
    ) -> Effect<Action> {
        switch event {
        case .validationFinished(let requestID, let result):
            guard requestID == state.validationRequestID else { return .none }
            switch result {
            case .success(let repository):
                state.validation = .validated(repository)
                return .send(.delegate(.repositoryValidated(repository)))

            case .failure:
                state.validation = .failed
                return .none
            }
        }
    }

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
