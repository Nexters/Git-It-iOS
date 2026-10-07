enum HomeProjectSectionState: Equatable, Sendable {

    case loading
    case empty
    case failed
    case loaded([HomeProjectDisplay])

    // MARK: Lifecycle

    init(_ projectLoad: HomeFeature.State.ProjectLoad) {
        switch projectLoad {
        case .idle,
             .loading:
            self = .loading

        case .loaded(let page) where page.items.isEmpty:
            self = .empty

        case .loaded(let page):
            self = .loaded(page.items.enumerated().map { HomeProjectDisplay($0.element, index: $0.offset) })

        case .failed:
            self = .failed
        }
    }

}
