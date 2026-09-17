import Foundation
import Testing

@testable import DomainAppSetting

@Suite("AppSetting")
struct AppSettingTests {

    // MARK: Internal

    @Test
    func `현재 알림 권한과 요청 결과를 그대로 전달한다`() async {
        let appSetting = Self.makeAppSetting(
            authorization: StubNotificationAuthorization(currentStatus: .notDetermined, requestedStatus: .denied)
        )

        #expect(await appSetting.notificationAuthorization() == .notDetermined)
        #expect(await appSetting.requestNotificationAuthorization() == .denied)
    }

    @Test
    func `기기를 등록하면 기기 정보와 현재 토큰으로 등록 정보를 만든다`() async throws {
        let repository = SpyDeviceRegistrationRepository()
        let appSetting = Self.makeAppSetting(repository: repository, deviceToken: { "token-1" })

        try await appSetting.registerDevice()

        #expect(await repository.registrations == [
            DeviceRegistration(
                deviceID: "device-1",
                platform: .ios,
                appVersion: "1.0.0",
                osVersion: "26.0",
                token: "token-1",
            )
        ])
    }

    @Test
    func `토큰을 가져오지 못하면 등록하지 않고 오류를 전달한다`() async {
        let repository = SpyDeviceRegistrationRepository()
        let appSetting = Self.makeAppSetting(
            repository: repository,
            deviceToken: { throw AppSettingError.temporarilyUnavailable },
        )

        await #expect(throws: AppSettingError.temporarilyUnavailable) {
            try await appSetting.registerDevice()
        }
        #expect(await repository.registrations.isEmpty)
    }

    @Test
    func `토큰이 바뀌면 새 토큰으로 기기를 다시 등록한다`() async throws {
        let repository = SpyDeviceRegistrationRepository()
        let appSetting = Self.makeAppSetting(repository: repository)

        try await appSetting.updateDeviceToken("token-2")

        #expect(await repository.registrations.map(\.token) == ["token-2"])
    }

    // MARK: Private

    private static func makeAppSetting(
        authorization: StubNotificationAuthorization = StubNotificationAuthorization(
            currentStatus: .authorized,
            requestedStatus: .authorized,
        ),
        repository: SpyDeviceRegistrationRepository = SpyDeviceRegistrationRepository(),
        deviceToken: @escaping @Sendable () async throws -> DeviceToken = { "token-1" },
    ) -> AppSetting {
        AppSetting(
            notificationAuthorization: authorization,
            deviceRegistrationRepository: repository,
            deviceIdentifierRepository: repository,
            appVersion: "1.0.0",
            osVersion: "26.0",
            deviceToken: deviceToken,
        )
    }

}
