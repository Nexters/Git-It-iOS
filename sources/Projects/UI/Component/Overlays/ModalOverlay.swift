import DesignSystem
import SwiftUI

// MARK: - ModalOverlay

/// 크기 결정 방식은 `SizingMode.fill` — safe area를 무시하고 화면 전체를 덮는다.
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
                Color(designSystem: ColorToken.black)
                    .designSystemOpacity(.scrim)
                    .transition(.opacity)
                    .accessibilityHidden(true)
                    .onTapGesture(perform: onDismiss)

                content
                    .transition(.move(edge: .bottom))
            }
        }
        // 표시 방식은 화면 전체를 덮는 바텀 시트다. 상위 화면이 safe area 안에 놓여도
        // 어둠막과 시트가 화면 끝까지 닿도록 여기에서 safe area를 무시한다.
        .ignoresSafeArea()
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
