public struct ExternalAuthenticationEvidence: Sendable {

    // MARK: Lifecycle

    public init(
        methodIdentifier: String,
        providerSubjectReference: String,
        opaquePayload: OpaquePayload,
    ) {
        self.methodIdentifier = methodIdentifier
        self.providerSubjectReference = providerSubjectReference
        self.opaquePayload = opaquePayload
    }

    // MARK: Public

    public struct OpaquePayload: CustomDebugStringConvertible, CustomStringConvertible, Sendable {
        public init(bytes: [UInt8]) {
            self.bytes = bytes
        }

        public let bytes: [UInt8]

        public var description: String {
            "<redacted>"
        }

        public var debugDescription: String {
            description
        }
    }

    public let methodIdentifier: String
    public let providerSubjectReference: String
    public let opaquePayload: OpaquePayload

}
