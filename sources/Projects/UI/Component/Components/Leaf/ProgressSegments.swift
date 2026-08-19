import DesignSystem
import SwiftUI

public struct ProgressSegments: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
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

    public var body: some View {
        HStack(spacing: Constant.segmentSpacing) {
            ForEach(0..<viewModel.total, id: \.self) { index in
                RoundedRectangle(designSystem: .micro)
                    .fill(Color(designSystem: index < viewModel.completed ? .blue100 : .grey500))
                    .frame(height: Constant.segmentHeight)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("전체 \(viewModel.total)문항 중 \(viewModel.completed)문항 완료")
    }

    // MARK: Private

    private enum Constant {
        static let segmentSpacing: CGFloat = 4
        static let segmentHeight: CGFloat = 10
    }

    private let viewModel: ViewModel

}

#Preview("Progress Segments") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ProgressSegments(viewModel: .init(completed: 0, total: 5))
        ProgressSegments(viewModel: .init(completed: 2, total: 5))
        ProgressSegments(viewModel: .init(completed: 5, total: 5))
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
