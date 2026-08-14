import SwiftUI

extension View {
    public func designSystemScreenMargin(_ token: LayoutToken = .margin) -> some View {
        padding(
            .horizontal,
            token.cgFloatValue,
        )
    }
}

extension LayoutToken {
    public var cgFloatValue: CGFloat {
        CGFloat(value)
    }
}
