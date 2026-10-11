import Testing

@testable import UIComponent

@Suite("LocalizedText 문구 조회")
struct LocalizedTextTests {
    @Test
    func `고정 문구는 카탈로그의 한국어 문구를 반환한다`() {
        #expect(LocalizedText.AppleSignInButton.title == "Apple로 시작하기")
    }
}
