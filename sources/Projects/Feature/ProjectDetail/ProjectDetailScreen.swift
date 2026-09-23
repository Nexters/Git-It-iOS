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
        OverlayContainer {
            header
        } content: {
            content
        } background: {
            background
        } footer: {
            footer
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
                        title: LocalizedText.ProjectDetail.deletionDialogTitle,
                        message: LocalizedText.ProjectDetail.deletionDialogMessage,
                        confirmTitle: LocalizedText.ProjectDetail.deletionDialogConfirmButtonTitle,
                        cancelTitle: LocalizedText.ProjectDetail.deletionDialogCancelButtonTitle,
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
        .task { await send(.task).finish() }
    }

    // MARK: Private

    private var isDeletionConfirmationPresented: Bool {
        if case .confirming = store.deletion.deletion {
            return true
        }
        return false
    }

    private var isFailed: Bool {
        if case .failed = store.detailLoad.loadStatus {
            return true
        }
        return false
    }

    private var header: some View {
        ScreenControlBar(
            displayModel: .init(
                trailing: isFailed
                    ? nil
                    : ScreenControlBar.Control(
                        icon: .menu,
                        label: LocalizedText.ProjectDetail.menuOpenAccessibilityLabel,
                    )
            ),
            onLeadingTap: { send(.backTapped) },
            onTrailingTap: { send(.menuTapped) },
        )
        .designSystemScreenMargin()
    }

    private var content: some View {
        Self.DetailContentView(isFailed: isFailed) {
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
        }
    }

    @ViewBuilder
    private var footer: some View {
        if isFailed {
            FeedbackActionButton(
                title: LocalizedText.ProjectDetail.retryButtonTitle,
                action: { send(.retryTapped) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.footerBottomPadding)
        }
    }

    @ViewBuilder
    private var background: some View {
        if !isFailed {
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
                title: LocalizedText.ProjectDetail.savedQuestionsMenuItemTitle,
                accessibilityLabel: LocalizedText.ProjectDetail.savedQuestionsMenuItemAccessibilityLabel,
                onSelect: { send(.savedQuestionsTapped) },
            ),
            .init(
                id: Constant.MenuItemID.repositoryLink,
                title: LocalizedText.ProjectDetail.repositoryLinkMenuItemTitle,
                accessibilityLabel: LocalizedText.ProjectDetail.repositoryLinkMenuItemAccessibilityLabel,
                onSelect: { send(.repositoryLinkTapped) },
            ),
            .init(
                id: Constant.MenuItemID.delete,
                title: LocalizedText.ProjectDetail.deletionMenuItemTitle,
                role: .destructive,
                accessibilityLabel: LocalizedText.ProjectDetail.deletionMenuItemAccessibilityLabel,
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

        static let setListTopSpacing: CGFloat = 53
        static let contentBottomPadding: CGFloat = 16
        static let heroGradientHeight: CGFloat = 179

        static let footerBottomPadding: CGFloat = 24
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
