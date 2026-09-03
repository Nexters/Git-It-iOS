import SwiftUI
import UIComponent
import DesignSystem

extension HomeScreen {
    struct ProjectSection: View {

        // MARK: Internal

        let state: HomeProjectSectionState
        let layoutMetrics: LayoutMetrics

        @Binding var cardListLeadingX: CGFloat?

        let onShowAllTapped: () -> Void
        let onProjectRetryTapped: () -> Void
        let onProjectCardTapped: (String) -> Void
        let onLearningTapped: (String) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: Constant.sectionHeaderSpacing) {
                HStack {
                    StyledText.subtitle3("학습 중인 레포지토리")
                    Spacer()
                    Button(action: onShowAllTapped) {
                        HStack(spacing: 3) {
                            StyledText.caption1("전체 보기", color: .blue100)
                            ResourceImage(asset: .icon(.chevronRight))
                                .frame(width: Constant.chevronSize, height: Constant.chevronSize)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Constant.showAllLabel)
                }
                .designSystemScreenMargin()

                projectContent(layoutMetrics)
            }
        }

        // MARK: Private

        private var cardWidth: CGFloat {
            CGFloat(layoutMetrics.gridColumn2)
        }

        /// 카드가 최대 각도로 기울어져도 잘리지 않는 섹션 높이.
        private var sectionHeight: CGFloat {
            Constant.sectionHeight(cardWidth: cardWidth)
        }

        private var emptyProjectCards: some View {
            ScrollView(.horizontal) {
                emptyDeckSilhouette
                    .frame(
                        width: HomeScreen.EmptyDeckShape.designSize.width,
                        height: HomeScreen.EmptyDeckShape.designSize.height,
                    )
                    .padding(.leading, Constant.screenMargin)
            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
            .accessibilityHidden(true)
        }

        private var emptyDeckSilhouette: some View {
            HomeScreen.EmptyDeckShape()
                .fill(Color(designSystem: .blue500))
                .overlay {
                    HomeScreen.EmptyDeckShape()
                        .stroke(Color(designSystem: .blue300), lineWidth: Constant.strokeWidth * 2)
                        .clipShape(HomeScreen.EmptyDeckShape())
                }
        }

        @ViewBuilder
        private func projectContent(_ layoutMetrics: LayoutMetrics) -> some View {
            switch state {
            case .loaded(let projects):
                projectCards(projects, layoutMetrics: layoutMetrics)

            case .loading:
                emptyProjects {
                    ResourceAnimation(asset: .generalLoading).frame(width: 20, height: 20)
                }

            case .empty:
                emptyProjects {
                    StyledText.body2("아직 등록된 프로젝트가 없어요.", color: .purple200)
                }

            case .failed:
                emptyProjects {
                    VStack(spacing: 0) {
                        StyledText.body2("잠시 후 다시 시도해 주세요.", color: .grey400, alignment: .center)

                        ActionButton.secondary("다시 시도", size: .small, action: onProjectRetryTapped)                            .padding(.top, 4)
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
            .frame(height: sectionHeight)
            .accessibilityElement(children: .contain)
        }

        private func projectCards(
            _ projects: [HomeProjectDisplay],
            layoutMetrics: LayoutMetrics,
        ) -> some View {
            GeometryReader { viewport in
                projectCardScroll(
                    projects,
                    layoutMetrics: layoutMetrics,
                    viewportWidth: viewport.size.width,
                )
            }
            .frame(height: sectionHeight)
        }

        private func projectCardScroll(
            _ projects: [HomeProjectDisplay],
            layoutMetrics: LayoutMetrics,
            viewportWidth: CGFloat,
        ) -> some View {
            let layout = cardListLeadingX.map {
                HomeCardScrollLayout(
                    p0CenterX: $0 + cardWidth / 2,
                    cardStride: Constant.cardStride(cardWidth: cardWidth),
                )
            }

            return ScrollView(.horizontal) {
                LazyHStack(spacing: Constant.cardSpacing) {
                    ForEach(Array(projects.enumerated()), id: \.element.projectID) { _, project in
                        HomeProjectCard(
                            title: project.title,
                            technologies: project.technologies,
                            progress: project.progress,
                            currentSetLabel: project.currentSetLabel,
                            setTitle: project.setTitle,
                            variant: project.variant,
                            layoutMetrics: layoutMetrics,
                            isLearningEnabled: project.isLearningEnabled,
                            onSelect: { onProjectCardTapped(String(project.projectID)) },
                            onStart: { onLearningTapped(String(project.projectID)) },
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
                .background(alignment: .leading) {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .scrollView(axis: .horizontal)).minX
                        } action: { minX in
                            guard cardListLeadingX == nil else { return }
                            cardListLeadingX = minX
                        }
                }
                .scrollTargetLayout()
                .padding(.vertical, Constant.rotationSlack(cardWidth: cardWidth))
            }
            .safeAreaPadding(.leading, Constant.screenMargin)
            .safeAreaPadding(
                .trailing,
                Constant.trailingInset(viewportWidth: viewportWidth, cardWidth: cardWidth),
            )
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .leading))
        }

        private enum Constant {
            static let showAllLabel = "학습 중인 레포지토리 전체 보기"
            static let sectionHeaderSpacing: CGFloat = 16
            static let chevronSize: CGFloat = 24
            static let screenMargin: CGFloat = 16
            static let cardSpacing: CGFloat = 12
            static let strokeWidth: CGFloat = 2
            static let maximumCardRotationDegrees: CGFloat = 16

            static func cardStride(cardWidth: CGFloat) -> CGFloat { cardWidth + cardSpacing }

            static func rotationSlack(cardWidth: CGFloat) -> CGFloat {
                let radians = maximumCardRotationDegrees * .pi / 180
                let cardHeight = HomeProjectCard.designHeight
                let rotatedHeight = cardWidth * sin(radians) + cardHeight * cos(radians)

                return max((rotatedHeight - cardHeight) / 2, 0)
            }

            static func sectionHeight(cardWidth: CGFloat) -> CGFloat {
                HomeProjectCard.designHeight + rotationSlack(cardWidth: cardWidth) * 2
            }

            static func trailingInset(viewportWidth _: CGFloat, cardWidth _: CGFloat) -> CGFloat { 16 }
        }

    }
}
