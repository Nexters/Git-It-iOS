import SwiftUI

// MARK: - LayoutReviewDetail

public struct LayoutReviewDetail<Content: View>: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onClose: @escaping () -> Void,
        onSelectVariant: @escaping (String) -> Void,
        onSetReviewChromeVisibility: @escaping (Bool) -> Void,
        @ViewBuilder content: () -> Content,
    ) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.onSelectVariant = onSelectVariant
        self.onSetReviewChromeVisibility = onSetReviewChromeVisibility
        self.content = content()
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            chrome: LayoutReviewChrome.ViewModel,
            isReviewChromeVisible: Bool,
        ) {
            self.chrome = chrome
            self.isReviewChromeVisible = isReviewChromeVisible
        }

        public let chrome: LayoutReviewChrome.ViewModel
        public let isReviewChromeVisible: Bool
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            if viewModel.isReviewChromeVisible == false {
                Button {
                    onSetReviewChromeVisibility(true)
                } label: {
                    Label("검토 제어 표시", systemImage: "eye")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color(.red))
                        .padding(Constant.revealPadding)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding()
                .accessibilityLabel("검토 제어 표시")
            }

            if viewModel.isReviewChromeVisible {
                LayoutReviewChrome(
                    viewModel: viewModel.chrome,
                    onClose: onClose,
                    onSelectVariant: onSelectVariant,
                    onHide: { onSetReviewChromeVisibility(false) },
                )
                .foregroundColor(Color(.red))
            }
        }
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let onClose: () -> Void
    private let onSelectVariant: (String) -> Void
    private let onSetReviewChromeVisibility: (Bool) -> Void
    private let content: Content

}

// MARK: - Constant

/// 제네릭 타입은 static 저장 프로퍼티를 소유할 수 없으므로 파일 범위에 둡니다.
private enum Constant {
    static let revealPadding: CGFloat = 12
}

#Preview("Layout Review Detail") {
    LayoutReviewDetail(
        viewModel: .init(
            chrome: .init(
                screenTitle: "홈",
                variants: [
                    .init(id: "empty", title: "프로젝트 없음"),
                    .init(id: "loaded", title: "프로젝트 있음"),
                ],
                selectedVariantID: "loaded",
            ),
            isReviewChromeVisible: true,
        ),
        onClose: { },
        onSelectVariant: { _ in },
        onSetReviewChromeVisibility: { _ in },
    ) {
        Color.gray
            .ignoresSafeArea()
    }
}
