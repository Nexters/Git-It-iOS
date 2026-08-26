import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIComponent

// MARK: - TutorialScreen

/// 3페이지 tutorial과 3페이지의 Apple 로그인 CTA를 보여준다. `phase`가 `tutorial`일 때만
/// 표시되며 `legalAgreement`는 이 화면 위 sheet로 나타난다. Figma는 Google 로그인을 보여주지만
/// 명세(FR-009 계열)가 Apple 로그인만 정의하므로 이 화면은 Apple 버튼만 렌더링한다(승인된 차이,
/// [plan.md](../../../../../../specs/016-onboarding-login-tutorial-app-integration/plan.md) 참고).
@ViewAction(for: OnboardingFeature.self)
struct TutorialScreen: View {

    // MARK: Lifecycle

    init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    // MARK: Public

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                TabView(selection: pageBinding) {
                    ForEach(1...3, id: \.self) { page in
                        pageContent(page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if let progress = store.tutorialPageProgress {
                    PageIndicator(viewModel: .init(currentPage: progress.currentPage, totalPages: progress.totalPages))
                        .padding(.bottom, LayoutToken.margin.cgFloatValue)
                }
            }
        }
        .task { send(.tutorialAppeared) }
        .sheet(isPresented: legalSheetBinding) {
            LegalAgreementScreen(store: store)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: Private

    private enum Constant {
        static let tooltipSpacing: CGFloat = 8
    }

    @Bindable var store: StoreOf<OnboardingFeature>

    private var pageBinding: Binding<Int> {
        Binding(
            get: {
                if case .tutorial(let page) = store.phase { return page }
                return 1
            },
            set: { send(.tutorialPageChanged($0)) },
        )
    }

    private var legalSheetBinding: Binding<Bool> {
        Binding(
            get: { store.phase == .legalAgreement },
            set: { isPresented in
                if !isPresented { send(.legalSheetCancelTapped) }
            },
        )
    }

    @ViewBuilder
    private func pageContent(_ page: Int) -> some View {
        VStack(spacing: LayoutToken.margin.cgFloatValue) {
            OnboardingMockup(viewModel: .init(page: page))

            StyledText.subtitle1(Self.title(for: page), alignment: .center)
            StyledText.body2(Self.subtitle(for: page), color: .grey400, alignment: .center)

            if page == 3 {
                signInSection
            }
        }
        .designSystemScreenMargin()
    }

    @ViewBuilder
    private var signInSection: some View {
        VStack(spacing: Constant.tooltipSpacing) {
            StyledText.caption1("Apple 계정으로 가입하고 학습을 시작해요", color: .grey400, alignment: .center)

            if store.authentication == .cancelled {
                StyledText.caption1("로그인이 취소됐어요. 다시 시도해 주세요.", color: .error, alignment: .center)
            } else if store.authentication == .retryableFailure {
                StyledText.caption1("로그인에 실패했어요. 다시 시도해 주세요.", color: .error, alignment: .center)
            }

            ActionButton.primary(
                "Apple로 계속하기",
                isEnabled: store.authentication != .signingIn,
                action: { send(.appleSignInTapped) },
            )

            StyledText.caption2("버전 \(store.bundleVersion)", color: .grey500, alignment: .center)
        }
    }

    private static func title(for page: Int) -> String {
        switch page {
        case 1: "실제 코드로 배우는 실전 학습"
        case 2: "당신의 속도에 맞춘 큐레이션"
        default: "지금 바로 시작해보세요"
        }
    }

    private static func subtitle(for page: Int) -> String {
        switch page {
        case 1: "오픈소스 프로젝트의 실제 코드를 보며 학습해요."
        case 2: "포지션과 연차에 맞는 문제를 추천받아요."
        default: "Apple 계정 하나로 바로 시작할 수 있어요."
        }
    }

}

// Figma 779:33450
#Preview("Tutorial - 1페이지") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .tutorial(page: 1)
    return TutorialScreen(store: OnboardingFeature.previewStore(state))
}

// Figma 779:33529
#Preview("Tutorial - 2페이지") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .tutorial(page: 2)
    return TutorialScreen(store: OnboardingFeature.previewStore(state))
}

// Figma 779:33564
#Preview("Tutorial - 3페이지 로그인") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .tutorial(page: 3)
    return TutorialScreen(store: OnboardingFeature.previewStore(state))
}
