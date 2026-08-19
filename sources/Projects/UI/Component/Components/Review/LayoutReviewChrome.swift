import SwiftUI

public struct LayoutReviewChrome: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onClose: @escaping () -> Void,
        onSelectVariant: @escaping (String) -> Void,
        onHide: @escaping () -> Void,
    ) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.onSelectVariant = onSelectVariant
        self.onHide = onHide
    }

    // MARK: Public

    public struct Variant: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
        ) {
            self.id = id
            self.title = title
        }

        public let id: String
        public let title: String
    }

    public struct ViewModel: Sendable, Equatable {
        public init(
            screenTitle: String,
            variants: [Variant],
            selectedVariantID: String,
        ) {
            self.screenTitle = screenTitle
            self.variants = variants
            self.selectedVariantID = selectedVariantID
        }

        public let screenTitle: String
        public let variants: [Variant]
        public let selectedVariantID: String
    }

    public var body: some View {
        VStack(alignment: .center, spacing: Constant.verticalSpacing) {
            HStack(spacing: 0) {
                Button("메인으로", action: onClose)
                    .accessibilityLabel("검토 화면 목록으로 돌아가기")

                Spacer()

                Text(verbatim: "상태")
                    .foregroundStyle(.white)

                if viewModel.variants.count > 1 {
                    Picker(
                        "간이 상태",
                        selection: Binding(
                            get: { viewModel.selectedVariantID },
                            set: onSelectVariant,
                        ),
                    ) {
                        ForEach(viewModel.variants) { candidate in
                            Text(candidate.title)
                                .tag(candidate.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("\(viewModel.screenTitle) 간이 상태 선택")
                }

                Spacer()

                Button("제어 숨기기", action: onHide)
                    .accessibilityLabel("검토 제어 숨기기")
            }
            .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: Private

    private enum Constant {
        static let verticalSpacing: CGFloat = 10
    }

    private let viewModel: ViewModel
    private let onClose: () -> Void
    private let onSelectVariant: (String) -> Void
    private let onHide: () -> Void

}

#Preview("Layout Review Chrome") {
    LayoutReviewChrome(
        viewModel: .init(
            screenTitle: "홈",
            variants: [
                .init(id: "empty", title: "프로젝트 없음"),
                .init(id: "loaded", title: "프로젝트 있음"),
            ],
            selectedVariantID: "loaded",
        ),
        onClose: { },
        onSelectVariant: { _ in },
        onHide: { },
    )
    .foregroundStyle(.red)
}
