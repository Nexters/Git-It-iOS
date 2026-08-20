import Testing

@testable import DesignSystem

@Suite("ControlSizeToken")
struct ControlSizeTokenTests {

    @Test
    func `Action 컨트롤 크기는 54다`() {
        #expect(ControlSizeToken.all.first { $0.name == "Action" }?.value == 54)
    }

    @Test
    func `모든 컨트롤 크기 토큰이 최소 터치 대상 44pt 이상이다`() {
        for token in ControlSizeToken.all {
            #expect(token.value >= 44, "\(token.name)이 44pt 미만이다")
        }
    }

    @Test
    func `컨트롤 크기 토큰 총 개수는 1개다`() {
        #expect(ControlSizeToken.all.count == 1)
    }

}
