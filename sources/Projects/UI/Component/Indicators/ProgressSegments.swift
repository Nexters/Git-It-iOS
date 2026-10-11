import DesignSystem
import SwiftUI

// MARK: - ProgressSegments

public struct ProgressSegments: View {

    // MARK: Lifecycle

    public init(displayModel: DisplayModel) {
        self.displayModel = displayModel
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: Constant.segmentSpacing) {
            ForEach(
                0..<displayModel.total,
                id: \.self,
            ) { index in
                RoundedRectangle(designSystem: .micro)
                    .fill(Color(designSystem: index < displayModel.completed ? .blue100 : .grey500))
                    .frame(height: Constant.segmentHeight)
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let segmentSpacing: CGFloat = 4
        static let segmentHeight: CGFloat = 10
    }

    private let displayModel: DisplayModel

}

// MARK: ProgressSegments.DisplayModel

extension ProgressSegments {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            completed: Int,
            total: Int,
        ) {
            self.completed = completed
            self.total = total
        }

        public let completed: Int
        public let total: Int
    }
}

#Preview("Progress Segments") {
    VStack(spacing: LayoutToken.margin) {
        ProgressSegments(displayModel: .init(
            completed: 0,
            total: 5,
        ))
        ProgressSegments(displayModel: .init(
            completed: 2,
            total: 5,
        ))
        ProgressSegments(displayModel: .init(
            completed: 5,
            total: 5,
        ))
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
