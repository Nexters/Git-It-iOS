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
            if case .failed = store.loadStatus {
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
                MenuSheet(
                    onSavedQuestionsTap: { send(.savedQuestionsTapped) },
                    onRepositoryLinkTap: { send(.repositoryLinkTapped) },
                    onDeleteTap: { send(.deleteTapped) },
                )
                .padding(.trailing, LayoutToken.margin.cgFloatValue)
                .offset(y: Constant.menuTopOffset)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: Constant.menuTransitionDuration), value: store.isMenuPresented)
        .overlay {
            ModalOverlay(isPresented: isDeletionConfirmationPresented, onDismiss: { send(.deletionCancelled) }) {
                ConfirmationSheet(
                    imageURL: store.detail?.repositoryImageURL,
                    title: "프로젝트를 삭제할까요?",
                    message: "학습 문제와 진도가 모두 삭제되며,\n이 작업은 취소할 수 없습니다.",
                    confirmTitle: "삭제",
                    cancelTitle: "취소",
                    onConfirmTap: { send(.deletionConfirmed) },
                    onCancelTap: { send(.deletionCancelled) },
                )
            }
        }
        .overlay {
            if store.loadStatus == .idle || store.loadStatus == .loading {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
        .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Private

    private var isDeletionConfirmationPresented: Bool {
        store.deletion == .confirming
    }

    private var content: some View {
        OverlayContainer {
            ScreenOverlayHeader(
                trailing: Constant.menuControl,
                onLeadingTap: { send(.backTapped) },
                onTrailingTap: { send(.menuTapped) },
            )
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                RepositorySummaryView(
                    repositoryName: store.detail?.repositoryName ?? "",
                    repositoryImageURL: store.detail?.repositoryImageURL,
                    starCount: store.detail?.starCount ?? 0,
                    techStack: store.detail?.techStack ?? [],
                    overallProgressPercent: store.detail?.overallProgressPercent ?? 0,
                    isResumeEnabled: store.isResumeEnabled,
                    onResumeTap: { send(.resumeTapped) },
                )
                .designSystemScreenMargin()

                SetListSection(
                    sets: ProjectDetailSetDisplay.list(sets: store.detail?.sets ?? []),
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

}

// MARK: ProjectDetailScreen.Constant

extension ProjectDetailScreen {
    fileprivate enum Constant {
        static let summaryTopSpacing: CGFloat = 24
        static let menuControl = ScreenHeader.Control(symbol: "line.3.horizontal", label: "메뉴 열기")

        static let setListTopSpacing: CGFloat = 54
        static let contentBottomPadding: CGFloat = 16
        static let heroGradientHeight: CGFloat = 179

        /// plain 스타일 헤더 높이(50)만큼 내려 메뉴를 헤더 바로 아래에 붙인다.
        static let menuTopOffset: CGFloat = 50
        static let menuTransitionDuration = 0.2

        static let heroGradient = GradientToken(
            name: "Gradient 1 · 프로젝트 상세",
            start: .init(x: 0.5, y: 0),
            end: .init(x: 0.5, y: 1),
            stops: [
                GradientToken.Stop(position: 0, hex: "#56718A"),
                GradientToken.Stop(position: 0.5, hex: "#485469"),
                GradientToken.Stop(position: 1, hex: "#3B3749"),
            ],
        )
    }
}
