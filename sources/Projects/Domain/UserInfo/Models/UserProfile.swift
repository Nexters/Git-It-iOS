public struct UserProfile: Equatable, Sendable {

    // MARK: Lifecycle

    public init(
        detail: UserDetail,
        curation: Curation?,
    ) {
        self.detail = detail
        self.curation = curation
    }

    // MARK: Public

    public let detail: UserDetail
    public let curation: Curation?

}
