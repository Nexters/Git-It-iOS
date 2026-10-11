import SwiftUI

extension View {
    public func designSystemCornerRadius(_ token: CornerRadiusToken) -> some View {
        clipShape(RoundedRectangle(designSystem: token))
    }
}

extension RoundedRectangle {
    public init(designSystem token: CornerRadiusToken) {
        self.init(cornerRadius: token.cgFloatValue)
    }
}

extension UnevenRoundedRectangle {
    public init(designSystemTopCorners token: CornerRadiusToken) {
        self.init(
            topLeadingRadius: token.cgFloatValue,
            topTrailingRadius: token.cgFloatValue,
        )
    }
}

extension CornerRadiusToken {
    public var cgFloatValue: CGFloat {
        CGFloat(value)
    }
}
