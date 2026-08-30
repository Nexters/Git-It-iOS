import Testing

@testable import Feature

@Suite("Home 카드 스크롤 좌표")
struct HomeCardScrollLayoutTests {
    @Test
    func `세 앵커와 양쪽 경계에서 계약 각도를 반환한다`() {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        #expect(layout.angle(cardCenterX: 50) == 0)
        #expect(layout.angle(cardCenterX: 97) == 0)
        #expect(layout.angle(cardCenterX: 269) == 16)
        #expect(layout.angle(cardCenterX: 441) == -12)
        #expect(layout.angle(cardCenterX: 500) == -12)
    }

    @Test
    func `인접 앵커 중간점 각도를 선형 보간한다`() {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        #expect(abs(layout.angle(cardCenterX: 183) - 8) <= 0.5)
        #expect(abs(layout.angle(cardCenterX: 355) - 2) <= 0.5)
    }

    @Test
    func `한 개와 두 개 카드의 초기 포즈는 P0과 P1 계약을 따른다`() {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        #expect(layout.initialAngles(cardCount: 1) == [0])
        #expect(layout.initialAngles(cardCount: 2) == [0, 16])
    }
}
