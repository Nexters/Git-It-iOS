import DesignSystem
import SwiftUI

// MARK: - PushedScreenOverlay

public struct PushedScreenOverlay<Content: View>: View {

    // MARK: Lifecycle

    public init(
        isPresented: Bool,
        @ViewBuilder content: () -> Content,
    ) {
        self.isPresented = isPresented
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            if isPresented {
                content
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: Constant.transitionDuration), value: isPresented)
    }

    // MARK: Private

    private enum Constant {
        static var transitionDuration: Double { 0.3 }
    }

    private let isPresented: Bool
    private let content: Content

}

#Preview("Pushed Screen Overlay") {
    ZStack {
        Color(designSystem: .grey700)

        PushedScreenOverlay(isPresented: true) {
            StyledText.subtitle1("밀려 들어온 화면", alignment: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .designSystemBackground(.screenBackground)
        }
    }
    .frame(width: 390, height: 700)
}
