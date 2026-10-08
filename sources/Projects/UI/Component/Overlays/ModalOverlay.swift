import DesignSystem
import SwiftUI

// MARK: - ModalOverlay

public struct ModalOverlay<Content: View>: View {

    // MARK: Lifecycle

    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content,
    ) {
        _isPresented = isPresented
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                Color(designSystem: ColorToken.black)
                    .designSystemOpacity(.scrim)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismiss() }

                content
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(
            .easeInOut(duration: Constant.transitionDuration),
            value: isPresented,
        )
    }

    // MARK: Internal

    func dismiss() {
        isPresented = false
    }

    // MARK: Private

    private enum Constant {
        static var transitionDuration: Double {
            0.25
        }
    }

    @Binding private var isPresented: Bool

    private let content: Content

}

#Preview("Modal Overlay") {
    ZStack {
        Color(designSystem: .grey700)

        ModalOverlay(isPresented: .constant(true)) {
            VStack {
                StyledText(text: "모달 콘텐츠")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .designSystemBackground(.grey600)
        }
    }
    .frame(
        width: 390,
        height: 700,
    )
}
