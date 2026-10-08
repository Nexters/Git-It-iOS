import SwiftUI

extension View {
    public func designSystemScreenMargin(_ margin: CGFloat = LayoutToken.margin) -> some View {
        padding(.horizontal, margin)
    }
}
