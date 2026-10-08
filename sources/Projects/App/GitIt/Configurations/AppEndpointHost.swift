import Foundation

enum AppEndpointHost: String {

    case api = "GIT_IT_API_HOST"
    case externalRepository = "GIT_IT_EXTERNAL_REPOSITORY_HOST"

    var url: URL {
        guard
            let host = Bundle.main.object(forInfoDictionaryKey: rawValue) as? String,
            let url = URL(string: "https://\(host)")
        else {
            fatalError("\(rawValue) 설정이 올바른 호스트가 아닙니다.")
        }
        return url
    }

}
