import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.fill`.
public struct ProgressSegments: View {

    // MARK: Lifecycle

    public init(
        completed: Int,
        total: Int,
    ) {
        self.completed = completed
        self.total = total
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: Constant.segmentSpacing) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(designSystem: .micro)
                    .fill(Color(designSystem: index < completed ? .blue100 : .grey500))
                    .frame(height: Constant.segmentHeight)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("전체 \(total)문항 중 \(completed)문항 완료")
    }

    // MARK: Private

    private enum Constant {
        static let segmentSpacing: CGFloat = 4
        static let segmentHeight: CGFloat = 10
    }

    private let completed: Int
    private let total: Int

}

#Preview("Progress Segments") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ProgressSegments(completed: 0, total: 5)
        ProgressSegments(completed: 2, total: 5)
        ProgressSegments(completed: 5, total: 5)
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
