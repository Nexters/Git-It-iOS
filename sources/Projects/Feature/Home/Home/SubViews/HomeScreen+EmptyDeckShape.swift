import SwiftUI

// MARK: - HomeScreen.EmptyDeckShape

extension HomeScreen {
    struct EmptyDeckShape: Shape {

        // MARK: Internal

        let cards: [Card]

        var size: CGSize {
            unionPath.boundingRect.size
        }

        func path(in rect: CGRect) -> Path {
            let unionPath = unionPath
            let bounds = unionPath.boundingRect
            guard !bounds.isEmpty else { return unionPath }

            let scale = min(rect.width / bounds.width, rect.height / bounds.height)
            let transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -bounds.midX, y: -bounds.midY)

            return unionPath.applying(transform)
        }

        // MARK: Private

        private var unionPath: Path {
            cards.map(\.path).reduce(Path()) { $0.union($1) }
        }

    }
}

// MARK: - HomeScreen.EmptyDeckShape.Card

extension HomeScreen.EmptyDeckShape {
    struct Card: Sendable, Equatable {

        let frame: CGRect
        let rotation: Angle
        let cornerRadius: CGFloat

        fileprivate var path: Path {
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: rotation.radians)
                .translatedBy(x: -center.x, y: -center.y)

            return Path(roundedRect: frame, cornerRadius: cornerRadius)
                .applying(transform)
        }

    }
}
