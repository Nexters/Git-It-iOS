import DomainMember

struct HomeProfileDisplay: Equatable, Sendable {

    // MARK: Lifecycle

    init(_ profileLoad: HomeFeature.State.ProfileLoad) {
        switch profileLoad {
        case .loaded(let profile):
            name = profile.name
            role = [
                profile.position.map(Self.positionTitle),
                profile.careerLevel.map(Self.careerTitle),
            ]
            .compactMap { $0 }
            .joined(separator: " · ")
            isFailed = false

        case .failed:
            name = nil
            role = ""
            isFailed = true

        case .idle,
             .loading:
            name = nil
            role = ""
            isFailed = false
        }
    }

    // MARK: Internal

    let name: String?
    let role: String
    let isFailed: Bool

    // MARK: Private

    private static func positionTitle(_ position: MemberPosition) -> String {
        switch position {
        case .ios: "iOS"
        case .android: "Android"
        case .backend: "Back-end"
        case .frontend: "Front-end"
        @unknown default: ""
        }
    }

    private static func careerTitle(_ career: CareerLevel) -> String {
        switch career {
        case .entry: "입문"
        case .junior: "주니어"
        case .middle: "미들"
        case .senior: "시니어"
        @unknown default: ""
        }
    }

}
