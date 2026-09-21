import DesignSystem
import SwiftUI

// MARK: - PushedScreenOverlay

public struct PushedScreenOverlay<Content: View>: View {

    // MARK: Lifecycle

    public init(@ViewBuilder content: () -> Content) {
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
        static var transitionDuration: Double {
            0.3
        }
    }

    private var isPresented = false
    private let content: Content

}

// MARK: PushedScreenOverlay 상태 선언

extension PushedScreenOverlay {
    public func presented(_ isPresented: Bool) -> Self {
        var copy = self
        copy.isPresented = isPresented
        return copy
    }
}

#Preview("Pushed Screen Overlay") {
    ZStack {
        Color(designSystem: .grey700)

        PushedScreenOverlay {
            StyledText(text: "밀려 들어온 화면")
                .textStyle(.subtitle1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .designSystemBackground(.grey700)
        }
        .presented(true)
    }
    .frame(width: 390, height: 700)
}
