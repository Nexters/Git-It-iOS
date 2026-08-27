public protocol RegisterMemberDeviceUseCase: Sendable {
    func callAsFunction(_ device: MemberDeviceInfo) async throws
}
