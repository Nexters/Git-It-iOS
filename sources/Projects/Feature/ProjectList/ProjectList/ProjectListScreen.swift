import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - ProjectListScreen

@ViewAction(for: ProjectListFeature.self)
public struct ProjectListScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<ProjectListFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<ProjectListFeature>

    public var body: some View {
        screen
            .overlay {
                if store.mode == .menuPresented {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                        .onTapGesture { send(.menuDismissed) }
                }
            }
            .overlay(alignment: .topTrailing) {
                if store.mode == .menuPresented {
                    ActionMenu(items: Constant.menuItems) { _ in send(.deletionMenuItemTapped) }
                        .padding(.trailing, LayoutToken.margin)
                        .offset(y: Constant.menuTopOffset)
                        .transition(.opacity)
                        .padding(.top, 10)
                }
            }
            .animation(.easeInOut(duration: Constant.menuTransitionDuration), value: store.mode)
            .overlay {
                ModalOverlay(
                    isPresented: isDeletionConfirmationPresented,
                    onDismiss: { send(.deletionCancelled) },
                ) {
                    ConfirmationSheet(
                        imageURL: deletionTarget?.imageURL,
                        title: "프로젝트를 삭제할까요?",
                        message: "학습 문제와 진도가 모두 삭제되며,\n이 작업은 취소할 수 없습니다.",
                        confirmTitle: "삭제",
                        cancelTitle: "취소",
                        onConfirmTap: { send(.deletionConfirmed) },
                        onCancelTap: { send(.deletionCancelled) },
                    )
                    .designSystemScreenMargin()
                }
            }
            .overlay {
                if store.initialLoad == .loading, store.projects.isEmpty {
                    ProgressView()
                        .tint(Color(designSystem: .blue100))
                }
            }
            .toolbar(store.mode == .deleting ? .hidden : .visible, for: .tabBar)
            .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Internal

    var projects: [ProjectListDisplay] {
        ProjectListDisplay.list(projects: store.projects)
    }

    // MARK: Private

    @ViewBuilder
    private var screen: some View {
        switch (store.initialLoad, store.projects.isEmpty) {
        case (.failed, _):
            ScreenContainer {
                Self.FailureView(onRetry: { send(.refreshRequested) })
            }

        case (_, true):
            ScreenContainer {
                Self.EmptyProjectsView()
            }

        case (_, false):
            content
        }
    }

    private var content: some View {
        OverlayContainer {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constant.headerTitleSpacing) {
                    if let headerLeading {
                        IconGlassButton.neutral(
                            icon: headerLeading.icon,
                            label: headerLeading.label,
                            size: .medium,
                            action: headerLeadingTapped,
                        )
                    }
                    ScreenHeaderTitle(title: headerTitle)
                        .frame(height: 32)
                }

                Spacer()

                if let headerTrailing {
                    IconGlassButton.neutral(
                        icon: headerTrailing.icon,
                        label: headerTrailing.label,
                        size: .medium,
                        action: headerTrailingTapped,
                    )
                }
            }
            .padding(.vertical, Constant.headerBottomPadding)
            .frame(minHeight: Constant.headerControlRowHeight)
            .designSystemScreenMargin()

        } content: {
            VStack(spacing: LayoutToken.compactSpacing) {
                ForEach(projects) { project in
                    row(project)
                }
            }
            .designSystemScreenMargin()
            .padding(.vertical, Constant.contentVerticalPadding)
        }
        .refreshable { await store.send(.view(.refreshRequested)).finish() }
    }

    private var deletionTarget: ProjectListDisplay? {
        guard case .confirming(let projectID) = store.deletion else { return nil }
        return projects.first { $0.id == projectID }
    }

    private var isDeletionConfirmationPresented: Bool {
        if case .confirming = store.deletion {
            return true
        }
        return false
    }

    private var headerTitle: String {
        store.mode == .deleting ? "프로젝트 삭제" : "프로젝트"
    }

    private var headerLeading: ScreenControlBar.Control? {
        store.mode == .deleting ? .back : nil
    }

    private var headerTrailing: ScreenControlBar.Control? {
        store.mode == .deleting ? nil : Constant.menuControl
    }

    private func headerLeadingTapped() {
        if store.mode == .deleting {
            send(.backTapped)
        }
    }

    private func headerTrailingTapped() {
        if store.mode != .deleting {
            send(.menuTapped)
        }
    }

    private func row(_ project: ProjectListDisplay) -> some View {
        ProjectRow(
            name: project.name,
            supportingText: project.supportingText,
            progress: project.progress,
            currentSet: project.currentSet,
            setTitle: project.setTitle,
            isDeleting: store.mode == .deleting,
            onAccessoryTap: { accessoryTapped(projectID: project.id) },
        ) {
            Self.Thumbnail(imageURL: project.imageURL)
        }
        .contentShape(Rectangle())
        .onTapGesture { send(.projectRowTapped(projectID: project.id)) }
    }

    private func accessoryTapped(projectID: String) {
        if store.mode == .deleting {
            send(.deleteButtonTapped(projectID: projectID))
        } else {
            send(.learningTapped(projectID: projectID))
        }
    }

}

// MARK: ProjectListScreen.Constant

extension ProjectListScreen {
    fileprivate enum Constant {
        static let contentVerticalPadding: CGFloat = 16
        static let menuControl = ScreenControlBar.Control(icon: .menu, label: "메뉴 열기")
        static let menuItems: [ActionMenu.Item] = [
            .init(id: "delete", title: "프로젝트 삭제", accessibilityLabel: "프로젝트 삭제 화면 열기")
        ]

        static let menuTopOffset: CGFloat = 50
        static let menuTransitionDuration = 0.2
        static let headerControlRowHeight: CGFloat = 40
        static let headerTitleHeight: CGFloat = 32
        static let headerTitleSpacing: CGFloat = 16
        static let headerTopPadding: CGFloat = 4
        static let headerBottomPadding: CGFloat = 10
    }
}
