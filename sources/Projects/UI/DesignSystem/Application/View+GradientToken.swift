import SwiftUI

extension View {
    public func designSystemBackground(_ token: GradientToken) -> some View {
        background(LinearGradient(designSystem: token))
    }
}

extension LinearGradient {
    public init(designSystem token: GradientToken) {
        self.init(
            gradient: Gradient(
                stops: token.stops.map { stop in
                    .init(
                        color: Color(designSystemHex: stop.hex),
                        location: stop.position
                    )
                }
            ),
            startPoint: UnitPoint(
                x: token.start.x,
                y: token.start.y
            ),
            endPoint: UnitPoint(
                x: token.end.x,
                y: token.end.y
            ),
        )
    }
}
