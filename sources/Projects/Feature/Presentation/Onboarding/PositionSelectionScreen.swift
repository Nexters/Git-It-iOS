import ComposableArchitecture
import DesignSystem
import DomainMember
import SwiftUI
import UIComponent

// MARK: - PositionSelectionScreen

/// 지원하는 네 position을 1:1로 노출하고 선택 즉시 career 단계로 전환한다. 뒤로 가기는 명시적
/// sign-out을 호출해 인증 상태를 정리한 뒤 tutorial 3페이지로 되돌아간다.
@ViewAction(for: OnboardingFeature.self)
struct PositionSelectionScreen: View {

    // MARK: Lifecycle

    init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    // MARK: Public

    enum Display {
        static func identifier(for position: MemberPosition) -> String {
            switch position {
            case .ios: "ios"
            case .android: "android"
            case .backend: "backend"
            case .frontend: "frontend"
            }
        }

        static func position(forIdentifier identifier: String) -> MemberPosition? {
            MemberPosition.allCases.first { Self.identifier(for: $0) == identifier }
        }

        static func title(for position: MemberPosition) -> String {
            switch position {
            case .ios: "iOS 개발"
            case .android: "Android 개발"
            case .backend: "백엔드 개발"
            case .frontend: "프론트엔드 개발"
            }
        }

        static func supportingText(for position: MemberPosition) -> String {
            switch position {
            case .ios: "Swift·SwiftUI 기반 iOS 앱을 만들어요."
            case .android: "Kotlin 기반 Android 앱을 만들어요."
            case .backend: "서버와 API를 설계하고 운영해요."
            case .frontend: "웹 UI와 클라이언트 로직을 구현해요."
            }
        }
    }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(spacing: LayoutToken.margin.cgFloatValue) {
                    ScreenHeader(
                        viewModel: .init(title: "어떤 분야를 학습하고 싶나요?", style: .largeTitle),
                        onLeadingTap: { send(.positionBackTapped) },
                    )

                    if let progress = store.curationStepProgress {
                        ProgressSegments(viewModel: .init(completed: progress.currentPage + 1, total: progress.totalPages))
                    }

                    if store.positionExitStatus == .failed {
                        StyledText.caption1("이전 화면으로 돌아가지 못했어요. 다시 시도해 주세요.", color: .error)
                    }

                    SelectionCardList(
                        viewModel: .init(
                            items: MemberPosition.allCases.map { position in
                                .init(
                                    id: Display.identifier(for: position),
                                    title: Display.title(for: position),
                                    supportingText: Display.supportingText(for: position),
                                    isSelected: store.curation.position == position,
                                )
                            }
                        ),
                        onSelect: { identifier in
                            if let position = Display.position(forIdentifier: identifier) {
                                send(.positionSelected(position))
                            }
                        },
                    )
                }
                .designSystemScreenMargin()
                .padding(.vertical, LayoutToken.margin.cgFloatValue)
            }
        }
    }

    // MARK: Private

    @Bindable var store: StoreOf<OnboardingFeature>

}

// Figma 737:10367 (idle)
#Preview("Position Selection - idle") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .position
    return PositionSelectionScreen(store: OnboardingFeature.previewStore(state))
}

#Preview("Position Selection - 뒤로 가기 진행 중") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .position
    state.curation.position = .ios
    state.positionExitStatus = .inProgress
    return PositionSelectionScreen(store: OnboardingFeature.previewStore(state))
}
