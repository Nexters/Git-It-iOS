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
            VStack(spacing: Constant.contentSpacing) {
                Spacer()

                if store.isShowingRecoverableError {
                    Self.ErrorView(onRetry: { send(.retryTapped) })
                } else {
                    LaunchLogo(onCompletion: { send(.splashAnimationFinished) })
                }

                Spacer()
            }
            .designSystemScreenMargin()
        }
        .designSystemBackground(store.isShowingRecoverableError ? .gradient1 : Constant.backgroundGradient)
        .task { send(.task) }
    }

    // MARK: Private

    @Bindable private var store: StoreOf<AppEntryFeature>

    private func send(_ action: AppEntryFeature.Action.View) {
        store.send(.view(action))
    }

}

// MARK: AppEntryScreen.Constant

extension AppEntryScreen {
    fileprivate enum Constant {
        static let contentSpacing: CGFloat = 16

        static let backgroundGradient = GradientToken(
            name: "Gradient 2 · 스플래시 화면",
            start: .init(x: 0.5, y: 0.6868),
            end: .init(x: 0.5, y: 1.79211),
            stops: GradientToken.gradient2.stops,
        )
    }
}
