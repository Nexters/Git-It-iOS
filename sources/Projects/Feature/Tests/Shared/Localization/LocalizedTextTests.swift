import Testing

@testable import Feature

@Suite("LocalizedText 문구 조회")
struct LocalizedTextTests {
    @Test
    func `AppEntry 고정 문구는 카탈로그의 한국어 문구를 반환한다`() {
        #expect(LocalizedText.AppEntry.recoverableErrorTitle == "세션을 확인하지 못했어요")
        #expect(LocalizedText.AppEntry.recoverableErrorMessage == "네트워크 상태를 확인한 뒤\n다시 시도해 주세요.")
    }
}
