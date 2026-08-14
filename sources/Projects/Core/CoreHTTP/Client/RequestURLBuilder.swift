import Foundation

// MARK: - RequestURLBuilder

struct RequestURLBuilder {

    // MARK: Internal

    func build(
        baseURL: URL,
        path: String,
        queryItems: [HTTPRequest.QueryItem],
    ) throws(HTTPClientError) -> URL {
        let resolvedURL = baseURL.appending(path: path)
        guard
            resolvedURL.scheme != nil,
            resolvedURL.host != nil,
            var components = URLComponents(url: resolvedURL, resolvingAgainstBaseURL: false)
        else {
            throw .invalidURL
        }

        if !queryItems.isEmpty {
            components.percentEncodedQuery = try queryItems
                .map(encodedQueryItem)
                .joined(separator: "&")
        }

        guard let url = components.url, url.scheme != nil, url.host != nil else {
            throw .invalidURL
        }
        return url
    }

    // MARK: Private

    private let queryAllowedCharacters = CharacterSet.urlQueryAllowed.subtracting(
        CharacterSet(charactersIn: "+&=?#"),
    )

    private func encodedQueryItem(_ item: HTTPRequest.QueryItem) throws(HTTPClientError) -> String {
        guard
            let name = item.name.addingPercentEncoding(withAllowedCharacters: queryAllowedCharacters),
            let value = item.value.addingPercentEncoding(withAllowedCharacters: queryAllowedCharacters)
        else {
            throw .invalidURL
        }
        return "\(name)=\(value)"
    }
}
