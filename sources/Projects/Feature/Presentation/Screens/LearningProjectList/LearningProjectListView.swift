import ComposableArchitecture
import DesignSystem
import DomainLearningProject
import SwiftUI
import UIComponent

// MARK: - LearningProjectListView

public struct LearningProjectListView: View {

    // MARK: Lifecycle

    public init(store: StoreOf<LearningProjectListFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        ScreenContainer {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    header
                    content
                }

                edgeScrims

                if store.isMenuPresented {
                    menu
                }

                if store.pendingDeletion != nil {
                    deletionConfirmation
                }
            }
            .accessibilityIdentifier("project.screen")
        }
        .task {
            await store.send(.onAppear).finish()
        }
    }

    // MARK: Private

    private enum MenuItemID {
        static let delete = "delete"
        static let close = "close"
    }

    private enum Constant {
        static let contentTopInset: CGFloat = 8
        static let contentHorizontalInset: CGFloat = 20
        static let rowSpacing: CGFloat = 8
        static let topScrimHeight: CGFloat = 103
        static let bottomScrimHeight: CGFloat = 127
        static let menuLeading: CGFloat = 160
        static let menuTop: CGFloat = 91
        static let menuWidth: CGFloat = 181
        static let menuHeight: CGFloat = 126
        static let deletionSheetHeight: CGFloat = 475
        static let failureSpacing: CGFloat = 16
    }

    @Bindable private var store: StoreOf<LearningProjectListFeature>

    private var header: some View {
        ScreenHeader(
            viewModel: .init(
                title: "프로젝트",
                style: .inlineTitle,
                leading: nil,
                trailing: .init(symbol: "ellipsis", label: "프로젝트 메뉴 열기"),
            ),
            onTrailingTap: {
                store.send(.menuButtonTapped)
            },
        )
        .padding(.horizontal, Constant.contentHorizontalInset)
    }

    @ViewBuilder
    private var content: some View {
        switch store.loadState {
        case .idle,
             .loading:
            ProgressView()
                .tint(Color(designSystem: .grey100))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("프로젝트 목록 불러오는 중")
                .accessibilityIdentifier("project.list.loading")

        case .failed:
            VStack(spacing: Constant.failureSpacing) {
                StyledText.subtitle2(
                    "프로젝트를 불러오지 못했어요",
                    alignment: .center,
                )
                StyledText.body2(
                    "잠시 후 다시 시도해 주세요.",
                    color: .grey400,
                    alignment: .center,
                )
                ActionButton.primary("다시 시도", action: {
                    store.send(.retryButtonTapped)
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Constant.contentHorizontalInset)
            .accessibilityIdentifier("project.list.failed")

        case .loaded where store.projects.isEmpty:
            EmptyState(
                viewModel: .init(
                    title: "아직 학습 프로젝트가 없어요",
                    message: "새 프로젝트를 추가하면 학습 진행 상황을 확인할 수 있어요.",
                )
            ) {
                ResourceImage(viewModel: .init(asset: .emptyState))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("project.list.empty")

        case .loaded:
            projectList
        }
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: Constant.rowSpacing) {
                ForEach(store.projects) { project in
                    ProjectRow(
                        viewModel: projectRowViewModel(project),
                        onAccessoryTap: {
                            if store.isDeleteMode {
                                store.send(.deleteButtonTapped(project.id))
                            } else {
                                store.send(.learningStartButtonTapped(project.id))
                            }
                        },
                    ) {
                        ResourceImage(
                            viewModel: .init(
                                asset: .projectNexters,
                                contentMode: .fill,
                            )
                        )
                    }
                    .accessibilityIdentifier("project.row.\(project.id.rawValue)")
                }
            }
            .padding(.top, Constant.contentTopInset)
            .padding(.horizontal, Constant.contentHorizontalInset)
        }
        .accessibilityIdentifier("project.list")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.isDeleteMode {
                BottomActionBar {
                    ActionButton.secondary("삭제 모드 종료", action: {
                        store.send(.deleteModeExited)
                    })
                }
                .designSystemBackground(.screenBackground)
            }
        }
    }

    private var edgeScrims: some View {
        VStack(spacing: 0) {
            ScreenEdgeScrim.top()
                .frame(height: Constant.topScrimHeight)
                .accessibilityIdentifier("project.edge.top")

            Spacer(minLength: 0)

            ScreenEdgeScrim.bottom()
                .frame(height: Constant.bottomScrimHeight)
                .accessibilityIdentifier("project.edge.bottom")
        }
    }

    private var menu: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.menuDismissed)
                }

            ActionMenu(
                viewModel: .init(items: [
                    .init(
                        id: MenuItemID.delete,
                        title: "프로젝트 삭제",
                        accessibilityLabel: "학습 프로젝트 삭제 모드 열기",
                    ),
                    .init(
                        id: MenuItemID.close,
                        title: "메뉴 닫기",
                        accessibilityLabel: "프로젝트 메뉴 닫기",
                    ),
                ]),
                onSelect: { id in
                    switch id {
                    case MenuItemID.delete:
                        store.send(.deleteModeEntered)
                    default:
                        store.send(.menuDismissed)
                    }
                },
            )
            .frame(width: Constant.menuWidth, height: Constant.menuHeight)
            .offset(x: Constant.menuLeading, y: Constant.menuTop)
            .accessibilityIdentifier("project.menu")
        }
    }

    private var deletionConfirmation: some View {
        ZStack(alignment: .bottom) {
            Color(designSystem: .scrim)
                .ignoresSafeArea()
                .onTapGesture {
                    store.send(.deletionCancelled)
                }

            SheetSurface {
                VStack(spacing: LayoutToken.margin.cgFloatValue) {
                    StyledText.subtitle2(
                        "프로젝트를 삭제할까요?",
                        alignment: .center,
                    )
                    StyledText.body2(
                        "삭제한 학습 기록은 복구할 수 없어요.",
                        color: .grey400,
                        alignment: .center,
                    )

                    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                        ActionButton.destructive("프로젝트 삭제", action: {
                            store.send(.deletionConfirmed)
                        })
                        .accessibilityLabel("프로젝트 삭제 확인, 되돌릴 수 없음")

                        ActionButton.secondary("취소", action: {
                            store.send(.deletionCancelled)
                        })
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: Constant.deletionSheetHeight)
            .accessibilityIdentifier("project.delete.sheet")
        }
    }

    private func projectRowViewModel(
        _ project: LearningProjectSummary
    ) -> ProjectRow<ResourceImage>.ViewModel {
        .init(
            name: project.name,
            supportingText: project.technologies,
            progress: project.progress.completedRatio,
            currentSet: project.nextSet.order,
            setTitle: project.nextSet.title,
            isDeleting: store.isDeleteMode,
        )
    }

}

#if DEBUG
private enum LearningProjectListPreview {
    struct FetchProjects: FetchLearningProjects {
        func callAsFunction(
            page _: Int,
            size _: Int,
        ) async throws -> LearningProjectPage {
            .init(projects: [], hasNextPage: false)
        }
    }

    struct DeleteProject: DeleteLearningProject {
        func callAsFunction(_: LearningProjectID) async throws { }
    }

    static let projectID = LearningProjectID(rawValue: "preview-project")!
    static let projects: IdentifiedArrayOf<LearningProjectSummary> = [
        .init(
            id: projectID,
            name: "Git It iOS",
            technologies: "Swift · SwiftUI · TCA",
            progress: .init(completedRatio: 0.65),
            nextSet: .init(order: 2, title: "Presentation 구조"),
        )
    ]

    @MainActor
    static func view(
        loadState: LearningProjectListFeature.LoadState,
        projects: IdentifiedArrayOf<LearningProjectSummary> = [],
        isMenuPresented: Bool = false,
        isDeleteMode: Bool = false,
        pendingDeletion: LearningProjectID? = nil,
    ) -> some View {
        LearningProjectListView(
            store: Store(
                initialState: .init(
                    projects: projects,
                    loadState: loadState,
                    isMenuPresented: isMenuPresented,
                    isDeleteMode: isDeleteMode,
                    pendingDeletion: pendingDeletion,
                )
            ) {
                LearningProjectListFeature(
                    fetchLearningProjects: FetchProjects(),
                    deleteLearningProject: DeleteProject(),
                )
            }
        )
        .frame(width: 360, height: 800)
    }
}

#Preview("프로젝트 목록 · Loaded") {
    LearningProjectListPreview.view(
        loadState: .loaded,
        projects: LearningProjectListPreview.projects,
    )
}

#Preview("프로젝트 목록 · Empty") {
    LearningProjectListPreview.view(loadState: .loaded)
}

#Preview("프로젝트 목록 · Menu") {
    LearningProjectListPreview.view(
        loadState: .loaded,
        projects: LearningProjectListPreview.projects,
        isMenuPresented: true,
    )
}

#Preview("프로젝트 목록 · Deleting") {
    LearningProjectListPreview.view(
        loadState: .loaded,
        projects: LearningProjectListPreview.projects,
        isDeleteMode: true,
    )
}

#Preview("프로젝트 목록 · Confirming Deletion") {
    LearningProjectListPreview.view(
        loadState: .loaded,
        projects: LearningProjectListPreview.projects,
        isDeleteMode: true,
        pendingDeletion: LearningProjectListPreview.projectID,
    )
}

#Preview("프로젝트 목록 · Loading") {
    LearningProjectListPreview.view(loadState: .loading)
}

#Preview("프로젝트 목록 · Failed") {
    LearningProjectListPreview.view(loadState: .failed)
}
#endif
