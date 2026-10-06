import Foundation

// MARK: - SharedRepositoryLinkContainer

/// 공유 확장과 컨테이너 앱이 URL 1건을 주고받는 App Group 저장소다. 앱은 읽는 즉시 값을
/// 지우므로 확장은 언제나 마지막 공유 1건만 남긴다.
enum SharedRepositoryLinkContainer {

    // MARK: Internal

    static let appGroupIdentifier = "group.com.nexters.hytime.gitit"
    static let storageKey = "sharedRepositoryURL"
    static let containerAppURL = "gitit://shared-link"

    static func store(_ urlString: String) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        defaults.set(urlString, forKey: storageKey)
    }

}
