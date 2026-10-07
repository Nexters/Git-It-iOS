import Foundation
import Testing
@testable import DomainMember

// MARK: - RegisterCurrentDeviceTests

@Suite("RegisterCurrentDevice")
struct RegisterCurrentDeviceTests {

    // MARK: Internal

    @Test
    func `주입한 앱 버전과 OS 버전과 푸시 토큰을 등록 정보에 담는다`() async throws {
        let spy = SpyMemberRepository()
        let register = RegisterCurrentDevice(
            repository: spy,
            deviceIdentifierRepository: StubDeviceIdentifierRepository(deviceID: "device-1"),
            appVersion: "1.2.3",
            osVersion: "Version 26.0",
            deviceTokenProvider: { "token-1" },
        )

        try await register()

        let device = try #require(await spy.registeredDevice)
        #expect(device.deviceID == "device-1")
        #expect(device.deviceType == .ios)
        #expect(device.appVersion == "1.2.3")
        #expect(device.osVersion == "Version 26.0")
        #expect(device.deviceToken == "token-1")
    }

    @Test
    func `푸시 토큰을 받지 못하면 등록을 시도하지 않고 오류를 그대로 전달한다`() async {
        let spy = SpyMemberRepository()
        let register = RegisterCurrentDevice(
            repository: spy,
            deviceIdentifierRepository: StubDeviceIdentifierRepository(deviceID: "device-1"),
            appVersion: "1.2.3",
            osVersion: "Version 26.0",
            deviceTokenProvider: { throw SampleError.tokenUnavailable },
        )

        await #expect(throws: SampleError.tokenUnavailable) { try await register() }
        #expect(await spy.registeredDevice == nil)
    }

    // MARK: Private

    private enum SampleError: Equatable, Error {
        case tokenUnavailable
    }

    private actor SpyMemberRepository: MemberRepository {
        var registeredDevice: MemberDeviceInfo?

        func registerDevice(_ device: MemberDeviceInfo) async throws {
            registeredDevice = device
        }

        func completeCuration(
            position _: MemberPosition,
            careerLevel _: CareerLevel,
        ) async throws { }

        func fetchProfile() async throws -> MemberProfile {
            throw SampleError.tokenUnavailable
        }

        func updatePosition(_: MemberPosition) async throws { }

        func updateCareerLevel(_: CareerLevel) async throws { }

        func deleteAccount() async throws { }
    }

    private struct StubDeviceIdentifierRepository: DeviceIdentifierRepository {
        let deviceID: String

        func currentDeviceID() async -> String {
            deviceID
        }
    }

}
