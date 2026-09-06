import SwiftUI
import Testing

@testable import Feature

@Suite("Home 빈 덱 실루엣")
struct HomeScreenEmptyDeckShapeTests {

    @Test
    func `겹친 카드 경로를 하나의 외곽선으로 합친다`() {
        let shape = HomeScreen.EmptyDeckShape(
            cards: [
                .init(
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20),
                    rotation: .zero,
                    cornerRadius: 0,
                ),
                .init(
                    frame: CGRect(x: 10, y: 0, width: 20, height: 20),
                    rotation: .zero,
                    cornerRadius: 0,
                ),
            ]
        )

        let path = shape.path(in: CGRect(origin: .zero, size: shape.size))

        #expect(shape.size == CGSize(width: 30, height: 20))
        #expect(path.contains(CGPoint(x: 15, y: 10)))
        #expect(!path.contains(CGPoint(x: 31, y: 10)))
    }

}
