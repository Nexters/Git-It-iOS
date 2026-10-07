import Testing

@testable import Feature

@Suite("Tutorial 접근성")
struct TutorialAccessibilityTests {

    @Test
    func `tutorial 페이지 진행도는 0-index 현재 페이지와 전체 3페이지를 함께 전달한다`() {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")

        state.page = 1
        #expect(state.pageProgress == .init(currentPage: 0, totalPages: 3))

        state.page = 3
        #expect(state.pageProgress == .init(currentPage: 2, totalPages: 3))
    }

    @Test
    func `TutorialFeature의 재시도 가능한 오류는 retryableFailure와 cancelled를 모두 포함한다`() {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        #expect(!state.isShowingRecoverableError)

        state.authentication = .retryableFailure
        #expect(state.isShowingRecoverableError)

        state.authentication = .cancelled
        #expect(state.isShowingRecoverableError)

        state.authentication = .idle
        #expect(!state.isShowingRecoverableError)
    }

}
