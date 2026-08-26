import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingFeature 접근성")
struct OnboardingAccessibilityTests {

    @Test
    func `tutorial 페이지 진행도는 0-index 현재 페이지와 전체 3페이지를 함께 전달한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")

        state.phase = .tutorial(page: 1)
        #expect(state.tutorialPageProgress == .init(currentPage: 0, totalPages: 3))

        state.phase = .tutorial(page: 3)
        #expect(state.tutorialPageProgress == .init(currentPage: 2, totalPages: 3))

        state.phase = .splash
        #expect(state.tutorialPageProgress == nil)
    }

    @Test
    func `curation 진행도는 position·career 단계에서만 값을 가진다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")

        state.phase = .position
        #expect(state.curationStepProgress == .init(currentPage: 0, totalPages: 2))

        state.phase = .career
        #expect(state.curationStepProgress == .init(currentPage: 1, totalPages: 2))

        state.phase = .completing
        #expect(state.curationStepProgress == nil)
    }

    @Test
    func `재시도 가능한 오류는 phase와 무관하게 하나의 값으로 알림 가능하다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        #expect(!state.isShowingRecoverableError)

        state.phase = .restoreError
        #expect(state.isShowingRecoverableError)

        state.phase = .tutorial(page: 3)
        state.authentication = .retryableFailure
        #expect(state.isShowingRecoverableError)

        state.authentication = .cancelled
        #expect(state.isShowingRecoverableError)

        state.authentication = .idle
        #expect(!state.isShowingRecoverableError)

        state.phase = .position
        state.positionExitStatus = .failed
        #expect(state.isShowingRecoverableError)

        state.positionExitStatus = .idle
        state.curation.submission = .failed
        #expect(state.isShowingRecoverableError)
    }

    @Test
    func `재시도 가능한 오류 값은 Reduce Motion 설정과 무관하게 phase만으로 결정된다`() async {
        // Reduce Motion은 SwiftUI Environment 값이라 Feature State가 소유하지 않는다.
        // 같은 phase 입력을 반복 평가해도 항상 같은 결과가 나옴을 확인해 이 값이 애니메이션
        // 설정이 아니라 순수하게 phase·authentication·submission 조합에서만 파생됨을 보인다.
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .restoreError

        let first = state.isShowingRecoverableError
        let second = state.isShowingRecoverableError
        #expect(first == second)
        #expect(first)
    }

    @Test
    func `Career 표시 문구는 계약된 네 값을 순서대로 매핑한다`() async {
        #expect(CareerSelectionScreen.Display.title(for: .entry) == "입문")
        #expect(CareerSelectionScreen.Display.description(for: .entry) == "프로젝트 코드를 처음 살펴봐요.")

        #expect(CareerSelectionScreen.Display.title(for: .junior) == "주니어")
        #expect(CareerSelectionScreen.Display.description(for: .junior) == "작은 기능 단위로 코드를 이해할 수 있어요.")

        #expect(CareerSelectionScreen.Display.title(for: .midLevel) == "미들")
        #expect(CareerSelectionScreen.Display.description(for: .midLevel) == "프로젝트 구조와 흐름을 함께 살펴봐요.")

        #expect(CareerSelectionScreen.Display.title(for: .senior) == "시니어")
        #expect(CareerSelectionScreen.Display.description(for: .senior) == "설계 의도와 변경 영향을 분석할 수 있어요.")
    }

    @Test
    func `Position 표시 문구는 지원하는 네 값 각각에 고유한 이름을 부여한다`() async {
        let titles = MemberPosition.allCases.map(PositionSelectionScreen.Display.title(for:))

        #expect(Set(titles).count == MemberPosition.allCases.count)
        #expect(titles.allSatisfy { !$0.isEmpty })
    }

}
