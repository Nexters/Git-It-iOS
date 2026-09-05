import Foundation

// MARK: - ShareExtensionEndpointHost

/// Extension 번들의 Info.plist에서 서버 호스트를 읽는다. 값의 출처는 본 앱과 같은
/// xcconfig이며 프로세스마다 자기 번들을 읽는다.
enum ShareExtensionEndpointHost: String {

    // MARK: Internal

    case api = "GIT_IT_API_HOST"
    case externalRepository = "GIT_IT_EXTERNAL_REPOSITORY_HOST"

    var url: URL {
        guard
            let host = Bundle.main.object(forInfoDictionaryKey: rawValue) as? String,
            let url = URL(string: "https://\(host)")
        else {
            fatalError("\(rawValue) 구성이 없습니다. xcconfig와 Info.plist를 확인하세요.")
        }
        return url
    }

}
