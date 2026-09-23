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
        OverlayContainer {
            header
        } content: {
            content
        } footer: {
            footer
        }
        .refreshable { await send(.refreshRequested).finish() }
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
                ActionMenu(items: menuItems)
                    .padding(.trailing, LayoutToken.margin)
                    .offset(y: Constant.menuTopOffset)
                    .transition(.opacity)
                    .padding(.top, 10)
            }
        }
        .animation(
            .easeInOut(duration: Constant.menuTransitionDuration),
            value: store.mode,
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
                        imageURL: deletionTarget?.imageURL,
                        title: LocalizedText.ProjectList.deletionDialogTitle,
                        message: LocalizedText.ProjectList.deletionDialogMessage,
                        confirmTitle: LocalizedText.ProjectList.deletionDialogConfirmButtonTitle,
                        cancelTitle: LocalizedText.ProjectList.deletionDialogCancelButtonTitle,
                    ),
                    onConfirmTap: { send(.deletionConfirmed) },
                    onCancelTap: { send(.deletionCancelled) },
                )
            }
        }
        .overlay {
            if store.projectSummaries.load == .loading, store.projects.isEmpty {
                ProgressView()
                    .tint(Color(designSystem: .blue100))
            }
        }
        .toolbar(
            store.mode == .deleting ? .hidden : .visible,
            for: .tabBar,
        )
        .task { await send(.task).finish() }
    }

    // MARK: Internal

    var projects: [ProjectListDisplay] {
        ProjectListDisplay.list(projects: store.projects)
    }

    // MARK: Private

    private var isFailed: Bool {
        if case .failed = store.projectSummaries.load {
            return true
        }
        return false
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(
                alignment: .leading,
                spacing: Constant.headerTitleSpacing,
            ) {
                if let headerLeading {
                    IconGlassButton(
                        icon: headerLeading.icon,
                        label: headerLeading.label,
                        action: headerLeadingTapped,
                    )
                    .size(.medium)
                    .frame(minHeight: Constant.headerControlRowHeight)
                }

                ScreenHeaderTitle(displayModel: .init(title: headerTitle))
                    .frame(minHeight: Constant.headerControlRowHeight)
            }
            .designSystemScreenMargin()

            Spacer()

            if let headerTrailing, !isFailed, !projects.isEmpty {
                IconGlassButton(
                    icon: headerTrailing.icon,
                    label: headerTrailing.label,
                    action: headerTrailingTapped,
                )
                .size(.medium)
                .frame(minHeight: Constant.headerControlRowHeight)
                .designSystemScreenMargin()
            }
        }
        .padding(.vertical, Constant.headerBottomPadding)
    }

    private var content: some View {
        Self.ProjectCollectionView(
            projects: projects,
            isFailed: isFailed,
            row: { project in
                row(project)
                    .onAppear { rowAppeared(projectID: project.id) }
            },
        ) {
            Self.NextPageFooter(
                pagination: store.pagination.pagination,
                onRetry: { send(.nextPageRetryTapped) },
            )
        }
    }

    @ViewBuilder
    private var footer: some View {
        if isFailed {
            FeedbackActionButton(
                title: LocalizedText.ProjectList.retryButtonTitle,
                action: { send(.refreshRequested) },
            )
            .designSystemScreenMargin()
            .padding(.bottom, Constant.footerBottomPadding)
        }
    }

    private var deletionTarget: ProjectListDisplay? {
        guard case .confirming(let projectID) = store.deletion.deletion else { return nil }
        return projects.first { $0.id == projectID }
    }

    private var isDeletionConfirmationPresented: Bool {
        if case .confirming = store.deletion.deletion {
            return true
        }
        return false
    }

    private var headerTitle: String {
        store.mode == .deleting ? LocalizedText.ProjectList.deletingModeTitle : LocalizedText.ProjectList.title
    }

    private var headerLeading: ScreenControlBar.Control? {
        store.mode == .deleting ? .back : nil
    }

    private var headerTrailing: ScreenControlBar.Control? {
        store.mode == .deleting
            ? nil
            : ScreenControlBar.Control(
                icon: .menu,
                label: LocalizedText.ProjectList.menuOpenAccessibilityLabel,
            )
    }

    private var menuItems: [ActionMenu.Item] {
        [
            .init(
                id: "delete",
                title: LocalizedText.ProjectList.deletionMenuItemTitle,
                accessibilityLabel: LocalizedText.ProjectList.deletionMenuItemAccessibilityLabel,
                onSelect: { send(.deletionMenuItemTapped) },
            )
        ]
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
            displayModel: .init(
                name: project.name,
                supportingText: project.supportingText,
                progress: project.progress,
                currentSet: project.currentSet,
                setTitle: project.setTitle,
            ),
            onAccessoryTap: { accessoryTapped(projectID: project.id) },
        ) {
            Self.Thumbnail(imageURL: project.imageURL)
        }
        .deleting(store.mode == .deleting)
        .contentShape(Rectangle())
        .onTapGesture { send(.projectRowTapped(projectID: project.id)) }
    }

    private func rowAppeared(projectID: String) {
        guard projectID == store.projects.last?.id else { return }
        send(.listBottomReached)
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
        static let footerBottomPadding: CGFloat = 24
        static let menuTopOffset: CGFloat = 50
        static let menuTransitionDuration = 0.2
        static let headerControlRowHeight: CGFloat = 40
        static let headerTitleHeight: CGFloat = 32
        static let headerTitleSpacing: CGFloat = 16
        static let headerTopPadding: CGFloat = 4
        static let headerBottomPadding: CGFloat = 12
    }
}
