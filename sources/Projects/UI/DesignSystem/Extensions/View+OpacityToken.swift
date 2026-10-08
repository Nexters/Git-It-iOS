import SwiftUI

extension View {
    public func designSystemOpacity(_ token: OpacityToken) -> some View {
        opacity(token.percent / 100)
    }
}
