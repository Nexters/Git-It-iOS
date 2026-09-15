import Foundation
import Testing
@testable import DataAuthentication
@testable import InfrastructureAuthentication
@testable import InfrastructureStorage

// MARK: - SessionStorageCoordinateTests

@Suite("세션 저장 좌표")
struct SessionStorageCoordinateTests {

    @Test
    func `세션 레코드는 기존 Keychain 네임스페이스와 키를 그대로 쓴다`() {
        #expect(SessionKeychainLayout.namespace.rawValue == "com.nexters.hytime.gitit.session")
        #expect(SessionKeychainLayout.Key.sessionRecord.rawValue == "sessionRecord")
    }

    @Test
    func `Apple 식별자는 기존 Keychain 네임스페이스와 키를 그대로 쓴다`() {
        #expect(AppleIdentityKeychainLayout.namespace.rawValue == "com.nexters.hytime.gitit.authentication")
        #expect(AppleIdentityKeychainLayout.Key.appleUserID.rawValue == "appleUserID")
    }

    @Test
    func `공유 세션 마커는 기존 App Group 네임스페이스와 키와 스키마 버전을 그대로 쓴다`() {
        #expect(AppGroupUserDefaults.sharedSessionNamespace == "com.nexters.hytime.gitit.sharedSession")
        #expect(SharedSessionStateMarkerCoding.stateMarkerKey == "stateMarker")
        #expect(SharedSessionStateMarkerCoding.markerSchemaVersion == 1)
    }

    @Test
    func `공유 저장소는 기존 App Group 식별자와 Keychain 접근 그룹을 그대로 쓴다`() {
        #expect(AppGroupUserDefaults.appGroupIdentifier == "group.com.nexters.hytime.gitit")
        #expect(AppGroupKeychainStore.accessGroup.rawValue == "6924CABL23.com.nexters.hytime.gitit.shared")
    }

}
