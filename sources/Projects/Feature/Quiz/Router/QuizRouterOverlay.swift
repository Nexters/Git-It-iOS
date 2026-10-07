import ComposableArchitecture
import SwiftUI
import UIComponent

public struct QuizRouterOverlay: View {

    // MARK: Lifecycle

    public init(store: StoreOf<QuizRouterFeature>?) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        PushedScreenOverlay(isPresented: store != nil) {
            if let store {
                QuizRouter(store: store)
            }
        }
    }

    // MARK: Private

    private let store: StoreOf<QuizRouterFeature>?

}
