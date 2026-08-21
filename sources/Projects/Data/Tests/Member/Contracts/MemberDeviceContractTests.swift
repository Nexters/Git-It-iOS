import Testing

@testable import DataMember

@Suite("MemberRemote 계약 — 기기 정보 등록")
struct MemberDeviceContractTests {

    @Test
    func `iOS 기기 정보를 deviceType 고정값으로 등록한다`() async throws {
        let remote = MemberRemoteProbe()
        let request = DeviceInfoRequestDTO(
            deviceID: "device-1",
            deviceType: "ios",
            appVersion: "1.0.0",
            osVersion: "18.0",
            deviceToken: "token-abc",
        )

        try await remote.registerDeviceInfo(request)

        #expect(request.deviceType == "ios")
        #expect(await remote.recordedCalls() == [.registerDeviceInfo])
    }

}
