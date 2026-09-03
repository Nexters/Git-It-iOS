import ComposableArchitecture
import SwiftUI
import UIComponent

#Preview("레포지토리 확인 · 737:10890") {
    ScreenContainer {
        RepositoryConfirmationScreen(
            store: Store(
                initialState: RepositoryConfirmationFeature.State(
                    repository: ProjectRegistrationPreviewSupport.repository
                )
            ) { EmptyReducer() }
        )
    }
}

#Preview("레포지토리 확인 · 아바타 없음") {
    ScreenContainer {
        RepositoryConfirmationScreen(
            store: Store(
                initialState: RepositoryConfirmationFeature.State(
                    repository: ProjectRegistrationPreviewSupport.repositoryWithoutAvatar
                )
            ) { EmptyReducer() }
        )
    }
}
