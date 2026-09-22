import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - ProjectDetailScreen

@ViewAction(for: ProjectDetailFeature.self)
struct ProjectDetailScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<ProjectDetailFeature>

    var body: some View {
        Group {
            if case .failed = store.detailLoad.loadStatus {
                ScreenContainer {
                    ErrorView(
                        onBack: { send(.backTapped) },
                        onRetry: { send(.retryTapped) },
                    )
                }
            } else {
                content
            }
        }
        .overlay {
            if store.isMenuPresented {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .onTapGesture { send(.menuDismissed) }
            }
        }
        .overlay(alignment: .topTrailing) {
            if store.isMenuPresented {
                ActionMenu(items: menuItems)
                    .padding(.trailing, LayoutToken.margin)
                    .offset(y: Constant.menuTopOffset)
                    .transition(.opacity)
            }
        }
        .animation(
            .easeInOut(duration: Constant.menuTransitionDuration),
            value: store.isMenuPresented,
        )
        .overlay {
            ModalOverlay(
                isPresented: Binding(
                    get: { isDeletionConfirmationPresented },
                    set: { isPresented in
                        if !isPresented {
                            send(.deletionCancelled)
                        }
                    },
                )
            ) {
                ConfirmationSheet(
                    displayModel: .init(
                        imageURL: store.detailLoad.detail?.repository.imageURL,
                        title: "프로젝트를 삭제할까요?",
                        message: "학습 문제와 진도가 모두 삭제되며,\n이 작업은 취소할 수 없습니다.",
                        confirmTitle: "삭제",
                        cancelTitle: "취소",
                    ),
                    onConfirmTap: { send(.deletionConfirmed) },
                    onCancelTap: { send(.deletionCancelled) },
                )
            }
        }
        .overlay {
            if store.detailLoad.loadStatus == .idle || store.detailLoad.loadStatus == .loading {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
        .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Private

    private var isDeletionConfirmationPresented: Bool {
        if case .confirming = store.deletion.deletion {
            return true
        }
        return false
    }

    private var content: some View {
        OverlayContainer {
            ScreenControlBar(
                displayModel: .init(trailing: Constant.menuControl),
                onLeadingTap: { send(.backTapped) },
                onTrailingTap: { send(.menuTapped) },
            )
            .designSystemScreenMargin()
        } content: {
            VStack(
                alignment: .leading,
                spacing: 0,
            ) {
                RepositorySummaryView(
                    repositoryName: store.detailLoad.detail?.repository.name ?? "",
                    repositoryImageURL: store.detailLoad.detail?.repository.imageURL,
                    starCount: store.detailLoad.detail?.repository.starCount ?? 0,
                    techStack: store.detailLoad.detail?.repository.techStack ?? [],
                    overallProgressPercent: store.detailLoad.detail?.progressPercent ?? 0,
                    isResumeEnabled: store.detailLoad.isResumeEnabled,
                    onResumeTap: { send(.resumeTapped) },
                )
                .designSystemScreenMargin()

                SetListSection(
                    sets: ProjectDetailSetDisplay.list(sets: store.detailLoad.detail?.sets ?? []),
                    onStart: { send(.setStartTapped(setID: $0)) },
                )
                .designSystemScreenMargin()
                .padding(.top, Constant.setListTopSpacing)
            }
            .padding(.top, Constant.summaryTopSpacing)
            .padding(.bottom, Constant.contentBottomPadding)
        } background: {
            heroBackground
        }
    }

    private var heroBackground: some View {
        LinearGradient(designSystem: Constant.heroGradient)
            .frame(height: Constant.heroGradientHeight)
            .accessibilityHidden(true)
    }

    private var menuItems: [ActionMenu.Item] {
        [
            .init(
                id: Constant.MenuItemID.savedQuestions,
                title: "저장한 문제",
                accessibilityLabel: "저장한 문제 보기",
                onSelect: { send(.savedQuestionsTapped) },
            ),
            .init(
                id: Constant.MenuItemID.repositoryLink,
                title: "GitHub에서 보기",
                accessibilityLabel: "GitHub에서 보기",
                onSelect: { send(.repositoryLinkTapped) },
            ),
            .init(
                id: Constant.MenuItemID.delete,
                title: "삭제하기",
                role: .destructive,
                accessibilityLabel: "프로젝트 삭제",
                onSelect: { send(.deleteTapped) },
            ),
        ]
    }

}

// MARK: ProjectDetailScreen.Constant

extension ProjectDetailScreen {
    fileprivate enum Constant {
        enum MenuItemID {
            static let savedQuestions = "savedQuestions"
            static let repositoryLink = "repositoryLink"
            static let delete = "delete"
        }

        static let summaryTopSpacing: CGFloat = 27
        static let menuControl = ScreenControlBar.Control(
            icon: .menu,
            label: "메뉴 열기",
        )

        static let setListTopSpacing: CGFloat = 53
        static let contentBottomPadding: CGFloat = 16
        static let heroGradientHeight: CGFloat = 179

        static let menuTopOffset: CGFloat = 50
        static let menuTransitionDuration = 0.2

        static let heroGradient = GradientToken(
            name: "Gradient 1 · 프로젝트 상세",
            start: .init(
                x: 0.5,
                y: 0,
            ),
            end: .init(
                x: 0.5,
                y: 1,
            ),
            stops: [
                GradientToken.Stop(
                    position: 0,
                    hex: "#56718A",
                ),
                GradientToken.Stop(
                    position: 0.5,
                    hex: "#485469",
                ),
                GradientToken.Stop(
                    position: 1,
                    hex: "#3B3749",
                ),
            ],
        )
    }
}
