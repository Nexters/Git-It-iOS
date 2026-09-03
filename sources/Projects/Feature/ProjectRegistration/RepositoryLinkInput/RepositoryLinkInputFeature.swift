import ComposableArchitecture
import DomainLearningProject
import Foundation

@Reducer
public struct RepositoryLinkInputFeature: Sendable {

    public init(fetchExternalRepository: any FetchExternalRepositoryUseCase) {
        self.fetchExternalRepository = fetchExternalRepository
    }

    public enum ValidationStatus: Equatable, Sendable {
        case idle
        case validating
        case validated(ExternalRepository)
        case failed
    }

    @ObservableState
    public struct State: Equatable, Sendable {

        public init(initialRepositoryURL: String = "") {
            repositoryURLInput = initialRepositoryURL
            pendingAutomaticValidation = !initialRepositoryURL.isEmpty
        }

        public var repositoryURLInput = ""
        public var validation = ValidationStatus.idle
        public var validationRequestID = 0

        var pendingAutomaticValidation = false

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
            validation == .validating ? "확인 중…" : "다음"
        }
    }

    public enum Action: ViewAction, Sendable, Equatable {
        case view(View)
        case effect(EffectEvent)
        case delegate(Delegate)

        @CasePathable
        public enum View: Sendable, Equatable {
            case task
            case repositoryURLChanged(String)
            case validateTapped
            case dismissTapped
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
            case .view(.task):
                guard state.pendingAutomaticValidation else { return .none }
                state.pendingAutomaticValidation = false
                return startValidation(&state)

            case .view(.repositoryURLChanged(let text)):
                state.repositoryURLInput = text
                state.validation = .idle
                return .none

            case .view(.validateTapped):
                return startValidation(&state)

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

    private enum CancelID: Hashable {
        case validation
    }

    private let fetchExternalRepository: any FetchExternalRepositoryUseCase

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

}
