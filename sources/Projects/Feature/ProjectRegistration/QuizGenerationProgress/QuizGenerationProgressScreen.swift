import ComposableArchitecture
import SwiftUI
import UIComponent

// MARK: - QuizGenerationProgressScreen

@ViewAction(for: QuizGenerationProgressFeature.self)
struct QuizGenerationProgressScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<QuizGenerationProgressFeature>

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .sheet(
                isPresented: Binding(
                    get: { store.isGenerationReminderSheetPresented },
                    set: { _ in },
                )
            ) {
                Self.GenerationReminderSheet(
                    onAccept: { send(.generationReminderAccepted) },
                    onDecline: { send(.generationReminderDeclined) },
                )
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
            }
    }

    // MARK: Private

    private var generationState: Self.GenerationStateView.State {
        switch store.progress {
        case .idle,
             .submitting,
             .awaitingOutcome:
            .generating

        case .failed:
            .failed
        }
    }

    private var content: some View {
        Self.GenerationStateView(
            state: generationState,
            onWaitAtHome: { send(.waitAtHomeTapped) },
            onDismiss: { send(.dismissTapped) },
            onRetry: { send(.retryTapped) },
        )
    }

}
