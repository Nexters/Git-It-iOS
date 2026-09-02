import Testing

@testable import DesignSystem

@Suite("DesignTokenSet 검증")
struct DesignTokenSetValidationTests {
    @Test
    func `현재 카탈로그는 검증 위반을 하나도 남기지 않는다`() {
        #expect(DesignTokenSet.current.validate().isEmpty)
    }
}
