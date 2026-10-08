import DesignSystem
import SwiftUI

// MARK: - PageIndicator

public struct PageIndicator: View {

    // MARK: Lifecycle

    public init(displayModel: DisplayModel) {
        self.displayModel = displayModel
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: Constant.dotSpacing) {
            ForEach(
                0..<displayModel.totalPages,
                id: \.self,
            ) { index in
                Circle()
                    .fill(Color(designSystem: index == displayModel.currentPage ? .white : .grey500))
                    .frame(
                        width: Constant.dotSize,
                        height: Constant.dotSize,
                    )
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let dotSpacing: CGFloat = 10
        static let dotSize: CGFloat = 8
    }

    private let displayModel: DisplayModel

}

// MARK: PageIndicator.DisplayModel

extension PageIndicator {
    public struct DisplayModel: Sendable, Equatable {
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
}

#Preview("Page Indicator") {
    VStack(spacing: LayoutToken.margin) {
        PageIndicator(displayModel: .init(
            currentPage: 0,
            totalPages: 3,
        ))
        PageIndicator(displayModel: .init(
            currentPage: 1,
            totalPages: 3,
        ))
        PageIndicator(displayModel: .init(
            currentPage: 2,
            totalPages: 3,
        ))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
