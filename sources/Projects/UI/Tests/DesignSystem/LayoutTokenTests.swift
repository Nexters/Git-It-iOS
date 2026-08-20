import Testing

@testable import DesignSystem

@Suite("LayoutToken")
struct LayoutTokenTests {

    @Test
    func `Margin은 20, Gutter는 12다`() {
        #expect(LayoutToken.all.first { $0.name == "Margin" }?.value == 20)
        #expect(LayoutToken.all.first { $0.name == "Gutter" }?.value == 12)
    }

    @Test
    func `CompactSpacing은 반복 사용하는 8pt 간격이다`() {
        #expect(LayoutToken.compactSpacing.name == "CompactSpacing")
        #expect(LayoutToken.compactSpacing.value == 8)
        #expect(LayoutToken.all.contains(.compactSpacing))
    }

    @Test
    func `레이아웃 토큰 총 개수는 3개다`() {
        #expect(LayoutToken.all.count == 3)
    }

}
