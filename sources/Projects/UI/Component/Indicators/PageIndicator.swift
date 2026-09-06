import DesignSystem
import SwiftUI

// MARK: - PageIndicator

public struct PageIndicator: View {

    // MARK: Lifecycle

    public init(
        currentPage: Int,
        totalPages: Int,
    ) {
        self.currentPage = currentPage
        self.totalPages = totalPages
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: Constant.dotSpacing) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(Color(designSystem: index == currentPage ? .white : .grey500))
                    .frame(width: Constant.dotSize, height: Constant.dotSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("페이지 안내")
        .accessibilityValue(Self.accessibilityValue(currentPage: currentPage, totalPages: totalPages))
    }

    // MARK: Internal

    static func accessibilityValue(
        currentPage: Int,
        totalPages: Int,
    ) -> String {
        "전체 \(totalPages)페이지 중 \(currentPage + 1)번째"
    }

    // MARK: Private

    private enum Constant {
        static let dotSpacing: CGFloat = 10
        static let dotSize: CGFloat = 8
    }

    private let currentPage: Int
    private let totalPages: Int

}

#Preview("Page Indicator") {
    VStack(spacing: LayoutToken.margin) {
        PageIndicator(currentPage: 0, totalPages: 3)
        PageIndicator(currentPage: 1, totalPages: 3)
        PageIndicator(currentPage: 2, totalPages: 3)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
