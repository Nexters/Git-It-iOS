public struct LoginSessionStartRequestDTO: CustomDebugStringConvertible, CustomStringConvertible, Sendable {
    public init(
        methodIdentifier: String,
        opaquePayload: AuthenticationEvidence.OpaquePayload,
    ) {
        self.methodIdentifier = methodIdentifier
        self.opaquePayload = opaquePayload
    }

    public let methodIdentifier: String
    public let opaquePayload: AuthenticationEvidence.OpaquePayload

    public var description: String {
        "LoginSessionStartRequestDTO(methodIdentifier: \(methodIdentifier), opaquePayload: <redacted>)"
    }

    public var debugDescription: String {
        description
    }
}
