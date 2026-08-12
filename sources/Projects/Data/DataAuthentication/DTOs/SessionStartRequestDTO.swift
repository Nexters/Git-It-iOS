public struct SessionStartRequestDTO: CustomDebugStringConvertible, CustomStringConvertible, Sendable {
    public init(
        methodIdentifier: String,
        opaquePayload: ExternalAuthenticationEvidence.OpaquePayload,
    ) {
        self.methodIdentifier = methodIdentifier
        self.opaquePayload = opaquePayload
    }

    public let methodIdentifier: String
    public let opaquePayload: ExternalAuthenticationEvidence.OpaquePayload

    public var description: String {
        "SessionStartRequestDTO(methodIdentifier: \(methodIdentifier), opaquePayload: <redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
