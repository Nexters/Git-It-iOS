import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - TutorialScreen

@ViewAction(for: OnboardingGuideFeature.self)
struct TutorialScreen: View {

    // MARK: Internal

    @Bindable var store: StoreOf<OnboardingGuideFeature>

    var body: some View {
        ScreenContainer { _ in
            VStack(spacing: 0) {
                TabView(selection: pageBinding) {
                    ForEach(1...Constant.pageCount, id: \.self) { page in
                        pageContent(page)
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
                signInSection
            }
        }
        .task { send(.tutorialAppeared) }
        .overlay {
            ModalOverlay(
                isPresented: store.screen == .legalAgreement,
                onDismiss: { send(.legalSheetCancelTapped) },
            ) {
                LegalAgreementScreen(store: store)
            }
        }
        .overlay {
            ModalOverlay(
                isPresented: store.legal.presentedDocument != nil,
                onDismiss: { send(.legalDocumentSheetDismissed) },
            ) {
                if let document = store.legal.presentedDocument {
                    WebSheet(
                        title: document.displayName,
                        url: document.approvedURL,
                        onDismiss: { send(.legalDocumentSheetDismissed) },
                    )
                }
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let pageCount = 3
        static let titleTopInset: CGFloat = 68
        static let mockupWidth: CGFloat = 212
        static let versionTopSpacing: CGFloat = 21
        static let bottomInset: CGFloat = 29
    }

    private var currentPage: Int {
        if case .tutorial(let page) = store.screen {
            return page
        }
        return Constant.pageCount
    }

    private var pageBinding: Binding<Int> {
        Binding(
            get: { currentPage },
            set: { send(.tutorialPageChanged($0)) },
        )
    }

    private var signInSection: some View {
        VStack {
            if let progress = store.tutorialPageProgress {
                PageIndicator(
                    currentPage: progress.currentPage,
                    totalPages: progress.totalPages,
                ).padding(12)
            }

            hint
                .padding(.bottom, LayoutToken.compactSpacing.cgFloatValue)

            AppleSignInButton {
                send(.appleSignInTapped)
            }

            StyledText.body2("버전 \(store.bundleVersion)", color: .grey500, alignment: .center)
                .padding(.top, Constant.versionTopSpacing)
        }
        .designSystemScreenMargin()
        .padding(.bottom, Constant.bottomInset)
    }

    private var hint: some View {
        StyledText.caption1("3초만에 가입하기", color: .grey400, alignment: .center)
            .opacity(currentPage == Constant.pageCount ? 1 : 0)
            .accessibilityHidden(currentPage != Constant.pageCount)
    }

    private static func title(for page: Int) -> String {
        switch page {
        case 1: "오픈소스를 문제화하고\n나만의 덱으로 만들어보세요"
        case 2: "복잡한 코드말고 자연어로\n언제 어디서든 가볍게!"
        default: "다시보고 싶은 문제는\n저장하고 나중에 확인해요"
        }
    }

    private func pageContent(_ page: Int) -> some View {
        VStack(spacing: 0) {
            StyledText.subtitle1(Self.title(for: page), alignment: .center)
                .padding(.top, Constant.titleTopInset)

            Spacer(minLength: LayoutToken.margin.cgFloatValue)

            OnboardingMockup(page: page)
                .frame(width: Constant.mockupWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .designSystemScreenMargin()
    }

}
