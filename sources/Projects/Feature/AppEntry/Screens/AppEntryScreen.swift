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
        ScreenContainer { _ in
            VStack(spacing: Constant.contentSpacing) {
                Spacer()

                if store.isShowingRecoverableError {
                    errorContent
                } else {
                    loadingContent
                }

                Spacer()
            }
            .designSystemScreenMargin()
        }
        .task { send(.task) }
    }

    // MARK: Private

    private enum Constant {
        static let contentSpacing: CGFloat = 16
    }

    @Bindable private var store: StoreOf<AppEntryFeature>

    private var loadingContent: some View {
        LaunchLogo(onCompletion: { send(.splashAnimationFinished) })
    }

    @ViewBuilder
    private var errorContent: some View {
        StyledText.subtitle2("세션을 확인하지 못했어요", alignment: .center)
        StyledText.body2("네트워크 상태를 확인한 뒤 다시 시도해 주세요.", color: .grey400, alignment: .center)

        ActionButton.primary("다시 시도", action: { send(.retryTapped) })
    }

    private func send(_ action: AppEntryFeature.Action.View) {
        store.send(.view(action))
    }

}
