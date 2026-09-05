import Foundation
import InfrastructureAuthentication

/// 본 앱과 Share Extension이 함께 사용하는 저장 위치를 한곳에서 정의한다.
public enum SharedSessionLayout {

    // MARK: Public

    public static let appGroupIdentifier = "group.com.nexters.hytime.gitit"

    /// keychain access group은 프로비저닝 프로파일이 발급하는 팀 접두어를 포함해야 한다.
    /// entitlements의 `$(AppIdentifierPrefix)`는 빌드 시점에만 치환되므로 런타임에서는
    /// 같은 값을 DEVELOPMENT_TEAM과 동일한 접두어로 직접 구성한다.
    public static let keychainAccessGroup = KeychainAccessGroup(
        "\(teamIdentifierPrefix)com.nexters.hytime.gitit.shared"
    )

    /// 공유 자격 증명 저장소. 두 프로세스가 같은 접근 그룹으로 세션을 읽는다.
    public static func makeSharedKeychainStore() -> KeychainStore {
        KeychainStore(accessGroup: keychainAccessGroup)
    }

    /// 접근 그룹을 지정하기 전에 본 앱이 사용하던 저장소. 이전 절차에서만 사용한다.
    public static func makeLegacyKeychainStore() -> KeychainStore {
        KeychainStore()
    }

    public static func makeSharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: Internal

    static let teamIdentifierPrefix = "6924CABL23."

    static let namespace = "com.nexters.hytime.gitit.sharedSession"
    static let stateMarkerKey = "stateMarker"
    static let pendingGenerationRemindersKey = "pendingGenerationReminders"
    static let markerSchemaVersion = 1
    static let pendingReminderLimit = 32

}
