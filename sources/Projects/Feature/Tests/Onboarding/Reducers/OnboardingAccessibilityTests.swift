import DomainMember
import Testing

@testable import Feature

@Suite("Onboarding 접근성")
struct OnboardingAccessibilityTests {

    @Test
    func `tutorial 페이지 진행도는 0-index 현재 페이지와 전체 3페이지를 함께 전달한다`() {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")

        state.screen = .tutorial(page: 1)
        #expect(state.tutorialPageProgress == .init(currentPage: 0, totalPages: 3))

        state.screen = .tutorial(page: 3)
        #expect(state.tutorialPageProgress == .init(currentPage: 2, totalPages: 3))

        state.screen = .legalAgreement
        #expect(state.tutorialPageProgress == nil)
    }

    @Test
    func `AppEntryFeature의 재시도 가능한 오류는 authentication 값만으로 결정된다`() {
        var state = AppEntryFeature.State()
        #expect(!state.isShowingRecoverableError)

        state.authentication = .retryableFailure
        #expect(state.isShowingRecoverableError)

        state.authentication = .idle
        #expect(!state.isShowingRecoverableError)

        state.authentication = .restoring
        #expect(!state.isShowingRecoverableError)
    }

    @Test
    func `OnboardingGuideFeature의 재시도 가능한 오류는 retryableFailure와 cancelled를 모두 포함한다`() {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        #expect(!state.isShowingRecoverableError)

        state.authentication = .retryableFailure
        #expect(state.isShowingRecoverableError)

        state.authentication = .cancelled
        #expect(state.isShowingRecoverableError)

        state.authentication = .idle
        #expect(!state.isShowingRecoverableError)
    }

    @Test
    func `Career 표시 문구는 계약된 네 값을 순서대로 매핑한다`() {
        #expect(CareerSelectionScreen.Display.title(for: .entry) == "입문")
        #expect(CareerSelectionScreen.Display.description(for: .entry) == "프로젝트 코드를 처음 살펴봐요.")

        #expect(CareerSelectionScreen.Display.title(for: .junior) == "주니어")
        #expect(CareerSelectionScreen.Display.description(for: .junior) == "작은 기능 단위로 코드를 이해할 수 있어요.")

        #expect(CareerSelectionScreen.Display.title(for: .middle) == "미들")
        #expect(CareerSelectionScreen.Display.description(for: .middle) == "프로젝트 구조와 흐름을 함께 살펴봐요.")

        #expect(CareerSelectionScreen.Display.title(for: .senior) == "시니어")
        #expect(CareerSelectionScreen.Display.description(for: .senior) == "설계 의도와 변경 영향을 분석할 수 있어요.")
    }

    @Test
    func `Position 표시 문구는 지원하는 네 값 각각에 고유한 이름을 부여한다`() {
        let titles = MemberPosition.allCases.map(PositionSelectionScreen.Display.title(for:))

        #expect(Set(titles).count == MemberPosition.allCases.count)
        #expect(titles.allSatisfy { !$0.isEmpty })
    }

}
