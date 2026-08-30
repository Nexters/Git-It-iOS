import DesignSystem
import SwiftUI

// MARK: - ModalOverlay

public struct ModalOverlay<Content: View>: View {

    // MARK: Lifecycle

    public init(
        isPresented: Bool,
        onDismiss: @escaping () -> Void = { },
        @ViewBuilder content: () -> Content,
    ) {
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                Color(designSystem: .scrim)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .accessibilityHidden(true)
                    .onTapGesture(perform: onDismiss)

                content
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
    }

    // MARK: Private

    private let isPresented: Bool
    private let onDismiss: () -> Void
    private let content: Content

}

#Preview("Modal Overlay") {
    ZStack {
        Color(designSystem: .grey700)

        ModalOverlay(isPresented: true) {
            VStack {
                StyledText.body1("모달 콘텐츠")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .designSystemBackground(.cardBackground)
        }
    }
    .frame(width: 390, height: 700)
}
