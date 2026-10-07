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
    }
}
