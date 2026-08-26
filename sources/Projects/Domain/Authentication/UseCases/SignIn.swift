public struct SignIn: SignInUseCase, Sendable {

    // MARK: Lifecycle

    public init(
        authenticationRepository: any AuthenticationRepository,
        loginSessionRepository: any LoginSessionRepository,
    ) {
        self.authenticationRepository = authenticationRepository
        self.loginSessionRepository = loginSessionRepository
    }

    // MARK: Public

    public func callAsFunction(_ method: AuthenticationMethod) async -> SignInResult {
        let grant: AuthenticationGrant

        do {
            grant = try await authenticationRepository.authenticate(using: method)
        } catch AuthenticationError.cancelled {
            return .cancelled
        } catch {
            return .retryableFailure
        }

        do {
            let user = try await loginSessionRepository.start(with: grant)
            let needsCuration = await loginSessionRepository.currentSession()?.onboarding.needsCuration ?? false
            return .success(user, needsCuration: needsCuration)
        } catch {
            await clearAuthentication()
            return .retryableFailure
        }
    }

    // MARK: Private

    private let authenticationRepository: any AuthenticationRepository
    private let loginSessionRepository: any LoginSessionRepository

    private func clearAuthentication() async {
        do {
            try await authenticationRepository.clearAuthentication()
        } catch { }
    }

}
