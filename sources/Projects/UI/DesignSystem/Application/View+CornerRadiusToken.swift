import SwiftUI

extension View {
    public func designSystemCornerRadius(_ token: CornerRadiusToken) -> some View {
        clipShape(RoundedRectangle(cornerRadius: CGFloat(token.value)))
    }
}
