enum HomeProjectSectionState: Equatable, Sendable {

    case loading
    case empty
    case failed
    case loaded([HomeProjectDisplay])
    case signInRequired

    // MARK: Lifecycle

    init(
        _ projectLoad: HomeFeature.State.ProjectLoad,
        access: MainShellAccess,
    ) {
        guard access == .member else {
            self = .signInRequired
            return
        }

        switch projectLoad {
        case .idle,
             .loading:
            self = .loading

        case .loaded(let list) where list.summaries.isEmpty:
            self = .empty

        case .loaded(let list):
            self = .loaded(list.summaries.enumerated().map { HomeProjectDisplay($0.element, index: $0.offset) })

        case .failed:
            self = .failed
        }
    }

}
