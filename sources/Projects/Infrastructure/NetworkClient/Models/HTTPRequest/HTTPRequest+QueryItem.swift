// MARK: - HTTPRequest.QueryItem

extension HTTPRequest {
    public struct QueryItem: Equatable, Sendable {

        // MARK: Lifecycle

        public init(
            name: String,
            value: String,
        ) {
            self.name = name
            self.value = value
        }

        // MARK: Public

        public let name: String
        public let value: String

    }
}
