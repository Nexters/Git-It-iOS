import SwiftUI
import Testing

@testable import Feature

@Suite("Home 카드 스크롤 좌표")
struct HomeCardScrollLayoutTests {
    @Test
    func `세 앵커와 양쪽 경계에서 계약 각도를 반환한다`() {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        #expect(layout.angle(cardCenterX: 97 - 172) == -16)
        #expect(layout.angle(cardCenterX: 97 - 200) == -16)
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
        #expect(abs(layout.angle(cardCenterX: 97 - 86) - -8) <= 0.5)
    }

    @Test
    func `기준 위치가 어떤 값이어도 그 자리의 각도는 정확히 0이다`() {
        for p0CenterX in [0, 20, 97, 123.5, 250] as [CGFloat] {
            let layout = HomeCardScrollLayout(p0CenterX: p0CenterX, cardStride: 172)

            #expect(layout.angle(cardCenterX: p0CenterX) == 0)
        }
    }

    @Test
    func `기준 위치 좌우로 각도가 끊기지 않고 이어진다`() {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        let justBefore = layout.angle(cardCenterX: 97 - 0.5)
        let justAfter = layout.angle(cardCenterX: 97 + 0.5)

        #expect(justBefore < 0)
        #expect(justAfter > 0)
        #expect(abs(justAfter - justBefore) <= 0.5)
    }

    @Test
    func `한 개와 두 개 카드의 초기 포즈는 P0과 P1 계약을 따른다`() {
        let layout = HomeCardScrollLayout(p0CenterX: 97, cardStride: 172)

        #expect(layout.initialAngles(cardCount: 1) == [0])
        #expect(layout.initialAngles(cardCount: 2) == [0, 16])
    }
}
