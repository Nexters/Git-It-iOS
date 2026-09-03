import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

@ViewAction(for: TutorialFeature.self)
struct TutorialScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<TutorialFeature>

    var body: some View {
        ScreenContainer { _ in
            VStack(spacing: 0) {
                TabView(selection: pageBinding) {
                    ForEach(1...store.pageProgress.totalPages, id: \.self) { page in
                        Self.PageView(page: page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onAppear {
                    UIScrollView.appearance().bounces = false
                }
                .background {
                    Color(designSystem: ColorToken.blue500).ignoresSafeArea(edges: .top)
                }

                Self.SignInSection(
                    currentPage: store.pageProgress.currentPage,
                    totalPages: store.pageProgress.totalPages,
                    bundleVersion: store.bundleVersion,
                    isHintVisible: isLastPage,
                    onAppleSignIn: { send(.appleSignInTapped) },
                )
            }
        }
        .task { send(.appeared) }
    }

    // MARK: Private

    private var isLastPage: Bool { store.page == store.pageProgress.totalPages }

    private var pageBinding: Binding<Int> {
        Binding(
            get: { store.page },
            set: { send(.pageChanged($0)) },
        )
    }

}
