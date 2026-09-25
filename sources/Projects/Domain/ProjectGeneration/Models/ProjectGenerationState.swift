public struct ProjectGenerationState: Equatable, Sendable {

    // MARK: Lifecycle

    public init(requests: [ProjectGenerationRequestState]) {
        self.requests = requests
    }

    // MARK: Public

    public let requests: [ProjectGenerationRequestState]

}
