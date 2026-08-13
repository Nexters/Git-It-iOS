import SwiftUI

extension View {
    public func designSystemControlSize(_ token: ControlSizeToken) -> some View {
        frame(
            minWidth: CGFloat(token.value),
            minHeight: CGFloat(token.value)
        )
    }
}
