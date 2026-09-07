import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - AppEntryScreen

public struct AppEntryScreen: View {

    // MARK: Lifecycle

    public init(store: StoreOf<AppEntryFeature>) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        ScreenContainer {
            LaunchLogo(onCompletion: { send(.splashAnimationFinished) })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .designSystemScreenMargin()
                .designSystemBackground(.backgroundGradient)
        }
        .task { send(.task) }
        .alert("세션을 확인하지 못했어요", isPresented: recoverableErrorBinding) {
            Button("다시 시도") { send(.retryTapped) }
        } message: {
            Text("네트워크 상태를 확인한 뒤\n다시 시도해 주세요.")
        }
    }

    // MARK: Private

    @Bindable private var store: StoreOf<AppEntryFeature>

    private var recoverableErrorBinding: Binding<Bool> {
        Binding(
            get: { store.isShowingRecoverableError },
            set: { isPresented in
                guard !isPresented else { return }
                send(.retryTapped)
            },
        )
    }

    private func send(_ action: AppEntryFeature.Action.View) {
        store.send(.view(action))
    }

}
