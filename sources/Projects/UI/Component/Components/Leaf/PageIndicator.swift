import DesignSystem
import SwiftUI

// MARK: - PageIndicator

/// 현재/전체 페이지를 점의 색상뿐 아니라 `accessibilityValue`로도 전달합니다. 애니메이션에
/// 의존하지 않는 정적 렌더링이라 Reduce Motion 설정과 무관하게 항상 같은 값을 표시합니다.
public struct PageIndicator: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            currentPage: Int,
            totalPages: Int,
        ) {
            self.currentPage = currentPage
            self.totalPages = totalPages
        }

        public let currentPage: Int
        public let totalPages: Int
    }

    public var body: some View {
        HStack(spacing: Constant.dotSpacing) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                Circle()
                    .fill(Color(designSystem: index == viewModel.currentPage ? .blue100 : .grey500))
                    .frame(width: Constant.dotSize, height: Constant.dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("페이지 안내")
        .accessibilityValue(Self.accessibilityValue(currentPage: viewModel.currentPage, totalPages: viewModel.totalPages))
    }

    // MARK: Internal

    static func accessibilityValue(currentPage: Int, totalPages: Int) -> String {
        "전체 \(totalPages)페이지 중 \(currentPage + 1)번째"
    }

    // MARK: Private

    private enum Constant {
        static let dotSpacing: CGFloat = 6
        static let dotSize: CGFloat = 6
    }

    private let viewModel: ViewModel

}

#Preview("Page Indicator") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        PageIndicator(viewModel: .init(currentPage: 0, totalPages: 3))
        PageIndicator(viewModel: .init(currentPage: 1, totalPages: 3))
        PageIndicator(viewModel: .init(currentPage: 2, totalPages: 3))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
