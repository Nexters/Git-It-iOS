import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - AppEntryScreen

@ViewAction(for: AppEntryFeature.self)
public struct AppEntryScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<AppEntryFeature>) {
        self.store = store
    }

    // MARK: Public

    @Bindable public var store: StoreOf<AppEntryFeature>

    public var body: some View {
        ScreenContainer {
            LaunchLogo(onCompletion: { send(.splashAnimationFinished) })
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                )
                .designSystemScreenMargin()
                .designSystemBackground(.backgroundGradient)
        }
        .task { send(.task) }
        .alert(
            LocalizedText.AppEntry.RecoverableError.title,
            isPresented: recoverableErrorBinding,
        ) {
            Button(LocalizedText.AppEntry.Retry.buttonTitle) { send(.retryTapped) }
        } message: {
            Text(LocalizedText.AppEntry.RecoverableError.message)
        }
    }

    // MARK: Private

    private var recoverableErrorBinding: Binding<Bool> {
        Binding(
            get: { store.isShowingRecoverableError },
            set: { isPresented in
                guard !isPresented else { return }
                send(.retryTapped)
            },
        )
    }

}
