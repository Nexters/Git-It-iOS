import Foundation

// MARK: - URLSessionTransport

struct URLSessionTransport: HTTPTransport {

    // MARK: Lifecycle

    init(configuration: URLSessionConfiguration = .default) {
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    // MARK: Internal

    func send(_ request: HTTPTransportRequest) async throws(HTTPClientError) -> HTTPTransportResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.requestValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.responseTimeout.timeInterval
        for (name, value) in request.headers.all {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        do {
            let (body, response) = try await session.data(for: urlRequest)
            if Task.isCancelled {
                throw HTTPClientError.cancelled
            }
            guard let response = response as? HTTPURLResponse else {
                throw HTTPClientError.connectionFailed
            }

            var headers = HTTPHeaders()
            for (name, value) in response.allHeaderFields {
                guard let name = name as? String else { continue }
                headers[name] = String(describing: value)
            }
            return HTTPTransportResponse(
                statusCode: response.statusCode,
                headers: headers,
                body: body,
            )
        } catch let error as HTTPClientError {
            throw error
        } catch {
            if Task.isCancelled {
                throw HTTPClientError.cancelled
            }
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cancelled:
                    throw HTTPClientError.cancelled
                case .timedOut:
                    throw HTTPClientError.timedOut
                default:
                    throw HTTPClientError.connectionFailed
                }
            }
            throw HTTPClientError.connectionFailed
        }
    }

    // MARK: Private

    private let session: URLSession
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
