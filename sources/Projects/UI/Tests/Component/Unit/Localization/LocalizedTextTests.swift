import Testing

@testable import UIComponent

@Suite("LocalizedText 문구 조회")
struct LocalizedTextTests {
    @Test
    func `고정 문구는 카탈로그의 한국어 문구를 반환한다`() {
        #expect(LocalizedText.WebSheet.closeAccessibilityLabel == "닫기")
    }

    @Test
    func `보간 문구는 인자를 채운 한국어 문구를 반환한다`() {
        #expect(LocalizedText.ProjectRow.deleteAccessibilityLabel(name: "Git It") == "Git It 삭제")
    }
}
