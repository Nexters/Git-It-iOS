import SwiftUI

extension View {
    public func designSystemControlSize(_ token: ControlSizeToken) -> some View {
        frame(
            minWidth: token.cgFloatValue,
            minHeight: token.cgFloatValue,
        )
    }

    public func designSystemControlHeight(_ token: ControlSizeToken) -> some View {
        frame(height: token.cgFloatValue)
    }
}

extension ControlSizeToken {
    public var cgFloatValue: CGFloat {
        CGFloat(value)
    }
}
