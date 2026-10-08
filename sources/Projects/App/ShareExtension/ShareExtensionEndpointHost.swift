import Foundation

// MARK: - ShareExtensionEndpointHost

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
