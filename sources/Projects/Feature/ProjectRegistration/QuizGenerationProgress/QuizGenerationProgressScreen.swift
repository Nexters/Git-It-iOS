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

    @ViewBuilder
    private var content: some View {
        if case .failed = store.progress {
            Self.FailureView(
                bottomButtonPadding: Constant.failureBottomButtonPadding,
                onDismiss: { send(.dismissTapped) },
                onRetry: { send(.retryTapped) },
            )
        } else {
            Self.GeneratingView(onWaitAtHome: { send(.waitAtHomeTapped) })
        }
    }

}

// MARK: QuizGenerationProgressScreen.Constant

extension QuizGenerationProgressScreen {
    fileprivate enum Constant {
        static let failureBottomButtonPadding: CGFloat = 24
    }
}
