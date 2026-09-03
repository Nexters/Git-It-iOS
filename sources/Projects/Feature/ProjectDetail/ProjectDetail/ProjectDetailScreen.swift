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
                ErrorView(
                    onBack: { send(.backTapped) },
                    onRetry: { send(.retryTapped) },
                )
            } else {
                content
            }
        }
        .overlay {
            ModalOverlay(isPresented: store.isMenuPresented, onDismiss: { send(.menuDismissed) }) {
                MenuSheet(
                    onSavedQuestionsTap: { send(.savedQuestionsTapped) },
                    onRepositoryLinkTap: { send(.repositoryLinkTapped) },
                    onDeleteTap: { send(.deleteTapped) },
                )
            }
        }
        .alert("프로젝트를 삭제할까요?", isPresented: deletionConfirmBinding) {
            Button("취소", role: .cancel) { send(.deletionCancelled) }
            Button("삭제하기", role: .destructive) { send(.deletionConfirmed) }
        } message: {
            Text("삭제하면 학습 기록도 함께 사라집니다.")
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

    private var deletionConfirmBinding: Binding<Bool> {
        Binding(
            get: { store.deletion == .confirming },
            set: { isPresented in
                guard !isPresented else { return }
                send(.deletionCancelled)
            },
        )
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                style: .default,
                trailing: Constant.menuControl,
                onLeadingTap: { send(.backTapped) },
                onTrailingTap: { send(.menuTapped) },
            )
            .designSystemScreenMargin()

            ScrollView {
                VStack(alignment: .leading, spacing: Constant.sectionSpacing) {
                    RepositorySummaryView(
                        repositoryName: store.detail?.repositoryName ?? "",
                        repositoryImageURL: store.detail?.repositoryImageURL,
                        starCount: store.detail?.starCount ?? 0,
                        techStack: store.detail?.techStack ?? [],
                        overallProgressPercent: store.detail?.overallProgressPercent ?? 0,
                        isResumeEnabled: store.isResumeEnabled,
                        onResumeTap: { send(.resumeTapped) },
                    )

                    SetListSection(
                        sets: ProjectDetailSetDisplay.list(sets: store.detail?.sets ?? []),
                        onStart: { send(.setStartTapped(setID: $0)) },
                    )
                }
                .designSystemScreenMargin()
                .padding(.vertical, Constant.contentVerticalPadding)
            }
        }
    }

}

// MARK: ProjectDetailScreen.Constant

extension ProjectDetailScreen {
    fileprivate enum Constant {
        static let sectionSpacing: CGFloat = 24
        static let contentVerticalPadding: CGFloat = 16
        static let menuControl = ScreenHeader.Control(symbol: "line.3.horizontal", label: "메뉴 열기")
    }
}
