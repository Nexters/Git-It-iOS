import ComposableArchitecture
import DesignSystem
import DomainLearningProject
import DomainMember
import SwiftUI
import UIComponent

@ViewAction(for: HomeFeature.self)
public struct HomeScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<HomeFeature>

    public var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                        .designSystemScreenMargin()

                    greeting
                        .designSystemScreenMargin()
                        .padding(.top, 8)

                    registrationPanel
                        .designSystemScreenMargin()
                        .padding(.top, 24)

                    projectSection
                        .padding(.top, 32)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .task { await send(.task).finish() }
    }

    // MARK: Internal

    enum Display {

        // MARK: Internal

        struct LearningIntent: Equatable, Sendable {
            let projectID: String
            let nextSetID: String
            let nextQuestionID: String
        }

        struct Project: Equatable, Sendable {
            let projectID: String
            let title: String
            let technologies: String
            let progress: Double
            let currentSetLabel: String
            let setTitle: String
            let variant: HomeProjectCard.Variant
            let learningIntent: LearningIntent?
        }

        static let usesDefaultAvatar = true
        static let registrationLabel = "프로젝트 지금 불러오기"
        static let showAllLabel = "학습 중인 레포지토리 전체 보기"
        static let disabledLearningHint = "다음 학습 위치가 없습니다"

        static func projects(_ projects: [LearningProjectSummary]) -> [Project] {
            projects.enumerated().map { project($0.element, index: $0.offset) }
        }

        static func project(
            _ project: LearningProjectSummary,
            index: Int,
        ) -> Project {
            let variants: [HomeProjectCard.Variant] = [.purple, .lightBlue, .darkBlue]
            let learningIntent: LearningIntent? =
                if
                    let nextSetID = project.nextSetID,
                    let nextQuestionID = project.nextQuestionID
                {
                    LearningIntent(
                        projectID: project.projectID,
                        nextSetID: nextSetID,
                        nextQuestionID: nextQuestionID,
                    )
                } else {
                    nil
                }

            return Project(
                projectID: project.projectID,
                title: project.repositoryName,
                technologies: project.techStack.joined(separator: " · "),
                progress: Double(project.overallProgressPercent) / 100,
                currentSetLabel: project.currentSetLabel,
                setTitle: project.currentSetTitle,
                variant: variants[index % variants.count],
                learningIntent: learningIntent,
            )
        }

        static func profileSubtitle(_ profile: MemberProfile) -> String? {
            let parts = [profile.position.map(positionTitle), profile.careerLevel.map(careerTitle)].compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }

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

    // MARK: Private

    @ViewBuilder
    private var profileHeader: some View {
        switch store.profileLoad {
        case .loaded(let profile):
            ScreenHeader(
                style: .inlineUser,
                user: .init(name: profile.name, role: Display.profileSubtitle(profile) ?? ""),
                leading: nil,
            ) {
                ResourceImage(asset: .icon(.user), contentMode: .fill)
            }

        case .failed:
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    StyledText.subtitle3("프로필을 불러오지 못했어요")
                    StyledText.caption1("잠시 후 다시 시도해 주세요.", color: .grey400)
                }
                Spacer()
                ActionButton.secondary("다시 시도", size: .small) { send(.profileRetryTapped) }
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(minHeight: 88)

        case .idle,
             .loading:
            HStack(spacing: 12) {
                ProgressView().tint(Color(designSystem: .blue100))
                StyledText.body2("프로필을 불러오는 중이에요", color: .grey400)
            }
            .frame(minHeight: 88)
            .accessibilityElement(children: .combine)
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 0) {
            StyledText.headline1("Hello World", color: .grey400)
            StyledText.headline1("Let’s Git -it-!")
        }
        .accessibilityElement(children: .combine)
    }

    private var registrationPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                StyledText.caption1("프로젝트 문제 생성", color: .grey400)
                VStack(alignment: .leading, spacing: 0) {
                    StyledText.subtitle3("오픈소스를 불러오고")
                    StyledText.subtitle3("문제로 익혀보세요")
                }
            }

            Spacer(minLength: 12)

            HStack {
                Spacer()
                ActionButton.primary("지금 불러오기", size: .small) {
                    send(.projectRegistrationTapped)
                }
                .accessibilityLabel(Display.registrationLabel)
            }
        }
        .padding(EdgeInsets(top: 13, leading: 16, bottom: 12, trailing: 12))
        .frame(minHeight: 133, alignment: .topLeading)
    }

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                StyledText.subtitle3("학습 중인 레포지토리")
                Spacer()
                Button {
                    send(.showAllProjectsTapped)
                } label: {
                    HStack(spacing: 3) {
                        StyledText.caption1("전체 보기", color: .blue100)
                        ResourceImage(asset: .icon(.chevronRight))
                            .frame(width: 6, height: 10)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Display.showAllLabel)
            }
            .designSystemScreenMargin()

            projectContent
        }
    }

    @ViewBuilder
    private var projectContent: some View {
        switch store.projectLoad {
        case .idle,
             .loading:
            HStack {
                Spacer()
                ResourceAnimation(asset: .generalLoading)
                    .frame(width: 96, height: 96)
                    .accessibilityLabel("프로젝트를 불러오는 중입니다")
                Spacer()
            }
            .frame(minHeight: 220)

        case .loaded(let page) where !page.items.isEmpty:
            projectCards(Display.projects(page.items))

        case .loaded,
             .failed:
            emptyProjects
        }
    }

    private var emptyProjects: some View {
        ZStack {
            emptyProjectCards
            StyledText.body2("아직 등록된 프로젝트가 없어요.", color: .purple200, alignment: .center)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyProjectCards: some View {
        let cardSize = CGSize(width: 154, height: 192)
        let cardSpacing: CGFloat = 2.5
        let angles = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172).initialAngles(cardCount: 3)
        let centers = angles.indices.map {
            CGPoint(
                x: cardSize.width / 2 + CGFloat($0) * (cardSize.width + cardSpacing),
                y: cardSize.height / 2,
            )
        }
        let bounds = Self.cardGroupBounds(centers: centers, size: cardSize, angles: angles)

        return ScrollView(.horizontal) {
            ZStack {
                RoundedRectangle(designSystem: .large)
                    .stroke(Color(designSystem: .purple300).opacity(0.3), lineWidth: 1)
                    .frame(width: bounds.width, height: bounds.height)
                    .position(x: bounds.midX, y: bounds.midY)

                HStack(spacing: cardSpacing) {
                    ForEach(angles.indices, id: \.self) { index in
                        emptyProjectCard(size: cardSize)
                            .rotationEffect(.degrees(angles[index]))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .accessibilityHidden(true)
    }

    private static func cardGroupBounds(
        centers: [CGPoint],
        size: CGSize,
        angles: [Double],
    ) -> CGRect {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let corners: [(dx: CGFloat, dy: CGFloat)] = [
            (-halfWidth, -halfHeight),
            (halfWidth, -halfHeight),
            (halfWidth, halfHeight),
            (-halfWidth, halfHeight),
        ]

        let points = zip(centers, angles).flatMap { center, angle -> [CGPoint] in
            let radians = angle * .pi / 180
            return corners.map { corner in
                CGPoint(
                    x: center.x + corner.dx * cos(radians) - corner.dy * sin(radians),
                    y: center.y + corner.dx * sin(radians) + corner.dy * cos(radians),
                )
            }
        }

        guard
            let minX = points.map(\.x).min(),
            let maxX = points.map(\.x).max(),
            let minY = points.map(\.y).min(),
            let maxY = points.map(\.y).max()
        else {
            return .zero
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func emptyProjectCard(size: CGSize) -> some View {
        RoundedRectangle(designSystem: .large)
            .fill(Color(designSystem: .blue500).opacity(0.3))
            .frame(width: size.width, height: size.height)
    }

    private func projectCards(_ projects: [Display.Project]) -> some View {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        return ScrollView(.horizontal) {
            LazyHStack(spacing: 2.5) {
                ForEach(Array(projects.enumerated()), id: \.element.projectID) { _, project in
                    HomeProjectCard(
                        title: project.title,
                        technologies: project.technologies,
                        progress: project.progress,
                        currentSetLabel: project.currentSetLabel,
                        setTitle: project.setTitle,
                        variant: project.variant,
                        isLearningEnabled: project.learningIntent != nil,
                        onSelect: { send(.projectCardTapped(projectID: project.projectID)) },
                        onStart: { send(.learningTapped(projectID: project.projectID)) },
                    )
                    .visualEffect { content, proxy in
                        content.rotationEffect(
                            .degrees(layout.angle(cardCenterX: proxy.frame(in: .scrollView(axis: .horizontal)).midX))
                        )
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .leading))
    }

}
