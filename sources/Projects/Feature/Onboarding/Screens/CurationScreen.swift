import ComposableArchitecture
import SwiftUI

// MARK: - CurationScreen

struct CurationScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<CurationFeature>

    var body: some View {
        switch store.screen {
        case .position:
            PositionSelectionScreen(store: store)

        case .career:
            CareerSelectionScreen(store: store)
        }
    }

}
