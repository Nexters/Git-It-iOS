import Testing

@testable import DomainMember

// MARK: - RegisterMemberDeviceTests

@Suite("RegisterMemberDevice")
struct RegisterMemberDeviceTests {
    @Test
    func `필드를 정확히 전달한다`() async throws {
        let repository = RegisterMemberDeviceRepository()
        let registerMemberDevice = RegisterMemberDevice(repository: repository)
        let device = MemberDeviceInfo(
            deviceID: "device-1",
            deviceType: .ios,
            appVersion: "1.0",
            osVersion: "26.0",
            deviceToken: "token",
        )

        try await registerMemberDevice(device)

        #expect(await repository.requestedDevice == device)
    }

    @Test
    func `알림 권한이 없으면 nil token을 허용한다`() async throws {
        let repository = RegisterMemberDeviceRepository()
        let registerMemberDevice = RegisterMemberDevice(repository: repository)
        let device = MemberDeviceInfo(
            deviceID: "device-1",
            deviceType: .ios,
            appVersion: "1.0",
            osVersion: "26.0",
            deviceToken: nil,
        )

        try await registerMemberDevice(device)

        #expect(await repository.requestedDevice?.deviceToken == nil)
    }
}

// MARK: - RegisterMemberDeviceRepository

private actor RegisterMemberDeviceRepository: MemberRepository {
    private(set) var requestedDevice: MemberDeviceInfo?

    func completeCuration(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }
    func fetchProfile() async throws -> MemberProfile {
        throw MemberError.memberUnavailable
    }

    func updatePosition(_: MemberPosition) async throws { }
    func updateCareerLevel(_: CareerLevel) async throws { }

    func registerDevice(_ device: MemberDeviceInfo) async throws {
        requestedDevice = device
    }

    func deleteAccount() async throws { }
}
