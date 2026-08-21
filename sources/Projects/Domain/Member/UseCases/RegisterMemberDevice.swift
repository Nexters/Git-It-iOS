public struct RegisterMemberDevice: RegisterMemberDeviceUseCase {

    // MARK: Lifecycle

    public init(repository: MemberRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(_ device: MemberDeviceInfo) async throws {
        try await repository.registerDevice(device)
    }

    // MARK: Private

    private let repository: MemberRepository

}
