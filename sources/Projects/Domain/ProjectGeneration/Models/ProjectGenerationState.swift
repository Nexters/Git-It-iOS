public struct ProjectGenerationState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(requests: [ProjectGenerationRequestState]) {
        self.requests = requests
    }

    // MARK: Public

    public let requests: [ProjectGenerationRequestState]

    public var hasRequestInProgress: Bool {
        requests.contains { $0.phase == .inProgress }
    }

}
