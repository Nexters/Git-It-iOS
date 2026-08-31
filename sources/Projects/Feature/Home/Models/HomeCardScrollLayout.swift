import CoreGraphics

struct HomeCardScrollLayout: Equatable, Sendable {

    // MARK: Lifecycle

    init(
        p0CenterX: CGFloat,
        cardStride: CGFloat,
    ) {
        self.p0CenterX = p0CenterX
        self.cardStride = cardStride
    }

    // MARK: Internal

    func angle(cardCenterX: CGFloat) -> Double {
        let position = (cardCenterX - p0CenterX) / cardStride

        if position <= 0 {
            return 0
        }
        if position >= 2 {
            return -12
        }
        if position <= 1 {
            return Double(position) * 16
        }

        return 16 + Double(position - 1) * -28
    }

    func initialAngles(cardCount: Int) -> [Double] {
        (0..<max(cardCount, 0)).map { index in
            angle(cardCenterX: p0CenterX + CGFloat(index) * cardStride)
        }
    }

    // MARK: Private

    private let p0CenterX: CGFloat
    private let cardStride: CGFloat

}
