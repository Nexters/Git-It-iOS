import ComposableArchitecture
import DesignSystem
import DomainMember
import SwiftUI
import UIComponent

// MARK: - CareerSelectionScreen

/// `entry`·`junior`·`midLevel`·`senior` 순서로 연차를 노출하고 전체 curation을 한 번에
/// 제출한다. 뒤로 가기는 position 단계로 돌아가며 두 선택을 모두 보존한다.
@ViewAction(for: OnboardingFeature.self)
struct CareerSelectionScreen: View {

    // MARK: Lifecycle

    init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    // MARK: Public

    enum Display {
        static let orderedLevels: [CareerLevel] = [.entry, .junior, .midLevel, .senior]

        static func identifier(for level: CareerLevel) -> String {
            switch level {
            case .entry: "entry"
            case .junior: "junior"
            case .midLevel: "midLevel"
            case .senior: "senior"
            }
        }

        static func level(forIdentifier identifier: String) -> CareerLevel? {
            orderedLevels.first { Self.identifier(for: $0) == identifier }
        }

        static func title(for level: CareerLevel) -> String {
            switch level {
            case .entry: "입문"
            case .junior: "주니어"
            case .midLevel: "미들"
            case .senior: "시니어"
            }
        }

        static func description(for level: CareerLevel) -> String {
            switch level {
            case .entry: "프로젝트 코드를 처음 살펴봐요."
            case .junior: "작은 기능 단위로 코드를 이해할 수 있어요."
            case .midLevel: "프로젝트 구조와 흐름을 함께 살펴봐요."
            case .senior: "설계 의도와 변경 영향을 분석할 수 있어요."
            }
        }
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: LayoutToken.margin.cgFloatValue) {
                        ScreenHeader(
                            viewModel: .init(title: "지금 어느 정도 경력이신가요?", style: .largeTitle),
                            onLeadingTap: { send(.careerBackTapped) },
                        )

                        if let progress = store.curationStepProgress {
                            ProgressSegments(viewModel: .init(completed: progress.currentPage + 1, total: progress.totalPages))
                        }

                        if store.curation.submission == .failed {
                            StyledText.caption1("제출에 실패했어요. 다시 시도해 주세요.", color: .error)
                        }

                        SelectionCardList(
                            viewModel: .init(
                                items: Display.orderedLevels.map { level in
                                    .init(
                                        id: Display.identifier(for: level),
                                        title: Display.title(for: level),
                                        supportingText: Display.description(for: level),
                                        isSelected: store.curation.careerLevel == level,
                                    )
                                }
                            ),
                            onSelect: { identifier in
                                if let level = Display.level(forIdentifier: identifier) {
                                    send(.careerLevelSelected(level))
                                }
                            },
                        )
                    }
                    .designSystemScreenMargin()
                    .padding(.vertical, LayoutToken.margin.cgFloatValue)
                }

                BottomActionBar {
                    ActionButton.primary(
                        "시작하기",
                        isEnabled: store.curation.careerLevel != nil && store.curation.submission != .submitting,
                        action: { send(.curationSubmitTapped) },
                    )
                }
                .designSystemBackground(.cardBackground)
            }
        }
    }

    // MARK: Private

    @Bindable var store: StoreOf<OnboardingFeature>

}

// Figma 737:10358
#Preview("Career Selection - idle") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .career
    state.curation.position = .ios
    return CareerSelectionScreen(store: OnboardingFeature.previewStore(state))
}

// Figma 737:10349
#Preview("Career Selection - 선택됨") {
    var state = OnboardingFeature.State(bundleVersion: "1.0.0")
    state.phase = .career
    state.curation.position = .ios
    state.curation.careerLevel = .junior
    return CareerSelectionScreen(store: OnboardingFeature.previewStore(state))
}

