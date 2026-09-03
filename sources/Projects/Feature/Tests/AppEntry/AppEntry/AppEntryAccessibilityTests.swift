import Testing

@testable import Feature

@Suite("AppEntry 접근성")
struct AppEntryAccessibilityTests {

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

}
