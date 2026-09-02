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
        ScreenContainer { layoutMetrics in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                    greeting
                        .padding(.top, Metric.greetingTopPadding)

                    registrationPanel
                        .padding(.top, Metric.registrationPanelTopPadding)
                }
                .designSystemScreenMargin()
                .padding(.bottom, Metric.projectSectionTopPadding)

                projectSection(layoutMetrics)
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
        static let generationInProgressLabel = "문제 생성 중"
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

    private enum CardLayout {

        static let cardHeight: CGFloat = 192
        static let cardSpacing: CGFloat = 2.5
        static let screenMargin: CGFloat = 20
        static let verticalPadding: CGFloat = 24

        /// 로딩·빈 상태 컨테이너가 실제 카드 영역과 같은 높이를 갖게 하는 값이다.
        static let sectionHeight = cardHeight + verticalPadding * 2

        /// 카드 폭은 화면에서 파생되므로 stride도 함께 계산한다.
        static func cardStride(cardWidth: CGFloat) -> CGFloat {
            cardWidth + cardSpacing
        }

        /// 마지막 카드도 P0까지 스냅될 수 있도록 viewport 나머지 전체를 trailing 여백으로 예약한다.
        static func trailingInset(
            viewportWidth: CGFloat,
            cardWidth: CGFloat,
        ) -> CGFloat {
            max(viewportWidth - screenMargin - cardWidth, screenMargin)
        }

    }

    /// 빈 상태 데크의 표현 상수. 실루엣 자체는 `HomeEmptyDeckShape`가 소유한다.
    private enum EmptyDeck {
        static let strokeWidth: CGFloat = 1
    }

    /// Figma `1542:19610`의 세로 리듬 실측값 (조회일 2026-09-01, 근거 A).
    ///
    /// 기준 y좌표: Toolbar 끝 127 → 인사말 147~221 → 등록 패널 242~375 →
    /// 섹션 헤더 411~435 → 카드 영역 434.
    private enum Metric {
        static let greetingTopPadding: CGFloat = 20
        static let registrationPanelTopPadding: CGFloat = 21
        static let projectSectionTopPadding: CGFloat = 36
        static let sectionHeaderSpacing: CGFloat = 0
        static let chevronSize: CGFloat = 16
        static let progressIndicatorSize: CGFloat = 16
        static let progressLabelSpacing: CGFloat = 6
        static let progressLabelHorizontalPadding: CGFloat = 16
    }

    @State private var cardListLeadingX: CGFloat?

    @ViewBuilder
    private var profileHeader: some View {
        switch store.profileLoad {
        case .loaded(let profile):
            ScreenHeader(
                style: .inlineUser,
                user: .init(name: profile.name, role: Display.profileSubtitle(profile) ?? ""),
                leading: nil,
            ) {
                ResourceImage(asset: .icon(.profile), contentMode: .fill)
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
            ScreenHeader(
                style: .inlineUser,
                user: nil,
                leading: nil,
            ) {
                ResourceImage(asset: .icon(.profile), contentMode: .fill)
            }
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
                registrationButton
            }
        }
        .padding(EdgeInsets(top: 13, leading: 16, bottom: 12, trailing: 12))
        .frame(minHeight: 133, alignment: .topLeading)
        .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
    }

    @ViewBuilder
    private var registrationButton: some View {
        if store.isGenerationInProgress {
            generationInProgressLabel
        } else {
            Button {
                send(.projectRegistrationTapped)
            } label: {
                StyledText.body2("지금 불러오기", color: .grey700)
                    .frame(width: 104, height: 37)
                    .background(Color(designSystem: .blue100), in: RoundedRectangle(designSystem: .medium))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Display.registrationLabel)
        }
    }

    /// Figma `1859:21645`의 진행 중 표기다. 새 불러오기를 시작할 수 없는 동안에는 버튼 대신
    /// 이 비활성 표시를 두어 탭 자체를 받지 않는다.
    private var generationInProgressLabel: some View {
        HStack(spacing: Metric.progressLabelSpacing) {
            ResourceAnimation(asset: .generalLoading)
                .frame(width: Metric.progressIndicatorSize, height: Metric.progressIndicatorSize)
            StyledText.body2(Display.generationInProgressLabel, color: .grey300)
        }
        .padding(.horizontal, Metric.progressLabelHorizontalPadding)
        .frame(height: 37)
        .background(Color(designSystem: .grey500), in: RoundedRectangle(designSystem: .medium))
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Display.generationInProgressLabel)
    }

    /// Figma `1542:19623` Union을 그대로 옮긴 빈 상태 데크다. 겹친 경계에는 테두리가 없다.
    ///
    /// 원본 크기(501×237)를 유지해 오른쪽이 잘리게 하되, 그 폭이 화면 레이아웃을 넓히지
    /// 않도록 스크롤 불가능한 가로 ScrollView 안에 둔다.
    private var emptyProjectCards: some View {
        ScrollView(.horizontal) {
            emptyDeckSilhouette
                .frame(
                    width: HomeEmptyDeckShape.designSize.width,
                    height: HomeEmptyDeckShape.designSize.height,
                )
                // 캔버스가 이미 상단 27.456pt 여백을 포함하므로 바깥에서 세로 여백을 더하지 않는다.
                .padding(.leading, CardLayout.screenMargin)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .accessibilityHidden(true)
    }

    private var emptyDeckSilhouette: some View {
        HomeEmptyDeckShape()
            .fill(Color(designSystem: .blue500))
            .overlay {
                // Figma는 inside stroke를 쓴다. 두 배 두께로 그린 뒤 실루엣으로 잘라 안쪽만 남긴다.
                HomeEmptyDeckShape()
                    .stroke(Color(designSystem: .blue300), lineWidth: EmptyDeck.strokeWidth * 2)
                    .clipShape(HomeEmptyDeckShape())
            }
    }

    /// 카드 목록 콘텐츠의 선행 가장자리에 놓는 0 크기 앵커다. 정지 상태에서 한 번 측정한 값이
    /// P0 기준 위치가 되므로 이후 스크롤 값으로 덮어쓰지 않는다.
    private var cardListLeadingAnchor: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .scrollView(axis: .horizontal)).minX
            } action: { minX in
                guard cardListLeadingX == nil else { return }
                cardListLeadingX = minX
            }
    }

    private func projectSection(_ layoutMetrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: Metric.sectionHeaderSpacing) {
            HStack {
                StyledText.subtitle3("학습 중인 레포지토리")
                Spacer()
                Button {
                    send(.showAllProjectsTapped)
                } label: {
                    HStack(spacing: 3) {
                        StyledText.caption1("전체 보기", color: .blue100)
                        ResourceImage(asset: .icon(.chevronRight))
                            .frame(width: Metric.chevronSize, height: Metric.chevronSize)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Display.showAllLabel)
            }
            .designSystemScreenMargin()

            projectContent(layoutMetrics)
        }
    }

    @ViewBuilder
    private func projectContent(_ layoutMetrics: LayoutMetrics) -> some View {
        switch store.projectLoad {
        case .loaded(let page) where !page.items.isEmpty:
            projectCards(Display.projects(page.items), layoutMetrics: layoutMetrics)

        case .idle,
             .loading:
            emptyProjects {
                ResourceAnimation(asset: .generalLoading).frame(width: 20, height: 20)
            }

        case .loaded:
            emptyProjects {
                StyledText.body2("아직 등록된 프로젝트가 없어요.", color: .blue200)
            }

        case .failed:
            emptyProjects {
                VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    StyledText.body2("프로젝트를 불러오지 못했어요.", color: .error, alignment: .center)
                    StyledText.caption1("잠시 후 다시 시도해 주세요.", color: .grey400, alignment: .center)

                    ActionButton.secondary("다시 시도", size: .small) { send(.projectRetryTapped) }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.top, 4)
                }
                .designSystemScreenMargin()
            }
        }
    }

    private func emptyProjects(@ViewBuilder accessary: () -> some View) -> some View {
        ZStack {
            emptyProjectCards
            accessary()
        }
        // 로딩·빈 목록·조회 실패 표시가 모두 실제 카드 영역과 같은 높이를 차지해, 목록이
        // 도착해도 아래 콘텐츠가 밀리지 않는다.
        .frame(height: CardLayout.sectionHeight)
        // 데크는 이미 accessibility에서 감춰져 있고, 겹쳐진 내용에 버튼이 올 수 있으므로
        // 하나로 합치지 않고 자식 요소를 그대로 노출한다.
        .accessibilityElement(children: .contain)
    }

    private func projectCards(
        _ projects: [Display.Project],
        layoutMetrics: LayoutMetrics,
    ) -> some View {
        GeometryReader { viewport in
            projectCardScroll(
                projects,
                layoutMetrics: layoutMetrics,
                viewportWidth: viewport.size.width,
            )
        }
        .frame(height: CardLayout.sectionHeight)
    }

    private func projectCardScroll(
        _ projects: [Display.Project],
        layoutMetrics: LayoutMetrics,
        viewportWidth: CGFloat,
    ) -> some View {
        let cardWidth = CGFloat(layoutMetrics.gridColumn2)
        // 기준 위치는 화면 좌표 상수가 아니라, 카드 중심과 같은 좌표 공간에서 읽은 카드 목록
        // 선행 가장자리 실측값이다. 측정 전에는 회전을 적용하지 않는다.
        let layout = cardListLeadingX.map {
            HomeCardScrollLayout(
                p0CenterX: $0 + cardWidth / 2,
                cardStride: CardLayout.cardStride(cardWidth: cardWidth),
            )
        }

        return ScrollView(.horizontal) {
            LazyHStack(spacing: CardLayout.cardSpacing) {
                ForEach(Array(projects.enumerated()), id: \.element.projectID) { _, project in
                    HomeProjectCard(
                        title: project.title,
                        technologies: project.technologies,
                        progress: project.progress,
                        currentSetLabel: project.currentSetLabel,
                        setTitle: project.setTitle,
                        variant: project.variant,
                        layoutMetrics: layoutMetrics,
                        isLearningEnabled: project.learningIntent != nil,
                        onSelect: { send(.projectCardTapped(projectID: project.projectID)) },
                        onStart: { send(.learningTapped(projectID: project.projectID)) },
                    )
                    .visualEffect { content, proxy in
                        content.rotationEffect(
                            .degrees(
                                layout?.angle(
                                    cardCenterX: proxy.frame(in: .scrollView(axis: .horizontal)).midX
                                ) ?? 0
                            )
                        )
                    }
                }
            }
            .background(alignment: .leading) { cardListLeadingAnchor }
            .scrollTargetLayout()
            .padding(.vertical, CardLayout.verticalPadding)
        }
        .safeAreaPadding(.leading, CardLayout.screenMargin)
        .safeAreaPadding(
            .trailing,
            CardLayout.trailingInset(viewportWidth: viewportWidth, cardWidth: cardWidth),
        )
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .leading))
    }

}
