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
                }
            }
            .overlay {
                if store.initialLoad == .loading, store.projects.isEmpty {
                    ProgressView()
                        .tint(Color(designSystem: .blue100))
                }
            }
            .task { await store.send(.view(.task)).finish() }
    }

    // MARK: Internal

    var projects: [ProjectListDisplay] {
        ProjectListDisplay.list(projects: store.projects)
    }

    // MARK: Private

    @State private var isEditing = false

    @ViewBuilder
    private var screen: some View {
        switch (store.initialLoad, store.projects.isEmpty) {
        case (.failed, _):
            ScreenContainer { _ in
                Self.FailureView(onRetry: { send(.refreshRequested) })
            }

        case (_, true):
            ScreenContainer { _ in
                Self.EmptyProjectsView()
            }

        case (_, false):
            content
        }
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

    private var editingControl: ScreenHeader.Control {
        isEditing
            ? .init(symbol: "checkmark", label: "편집 마치기")
            : .init(symbol: "trash", label: "프로젝트 편집")
    }

    private var content: some View {
        OverlayContainer { layoutMetrics in
            ScreenOverlayHeader(
                title: "프로젝트",
                style: .largeTitle,
                leading: nil,
                trailing: editingControl,
                layoutMetrics: layoutMetrics,
                onTrailingTap: { isEditing.toggle() },
            )
        } content: { _ in
            VStack(spacing: LayoutToken.gutter.cgFloatValue) {
                ForEach(projects) { project in
                    row(project)
                }
            }
            .designSystemScreenMargin()
            .padding(.vertical, Constant.contentVerticalPadding)
        }
        .refreshable { await store.send(.view(.refreshRequested)).finish() }
    }

    private func row(_ project: ProjectListDisplay) -> some View {
        ProjectRow(
            name: project.name,
            supportingText: project.supportingText,
            progress: project.progress,
            currentSet: project.currentSet,
            setTitle: project.setTitle,
            isDeleting: isEditing,
            onAccessoryTap: { accessoryTapped(projectID: project.id) },
        ) {
            Self.Thumbnail(imageURL: project.imageURL)
        }
        .contentShape(Rectangle())
        .onTapGesture { send(.projectRowTapped(projectID: project.id)) }
    }

    private func accessoryTapped(projectID: String) {
        if isEditing {
            send(.deleteButtonTapped(projectID: projectID))
        } else {
            send(.projectRowTapped(projectID: projectID))
        }
    }

}

// MARK: ProjectListScreen.Constant

extension ProjectListScreen {
    fileprivate enum Constant {
        static let contentVerticalPadding: CGFloat = 16
    }
}
