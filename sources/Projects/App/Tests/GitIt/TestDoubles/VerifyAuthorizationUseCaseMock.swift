import DomainAuthentication

actor VerifyAuthorizationUseCaseMock: VerifyAuthorizationUseCase {

    // MARK: Lifecycle

    init(result: AuthorizationStatus = .authorized) {
        self.result = result
    }

    // MARK: Internal

    private(set) var callCount = 0

    func callAsFunction() async -> AuthorizationStatus {
        callCount += 1
        return result
    }

    // MARK: Private

    private let result: AuthorizationStatus

}
