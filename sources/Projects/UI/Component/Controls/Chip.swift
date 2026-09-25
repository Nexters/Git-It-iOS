import DesignSystem
import SwiftUI

// MARK: - Chip

public struct Chip: View {

    // MARK: Lifecycle

    public init(
        label: String,
        isSelected: Binding<Bool>,
    ) {
        self.label = label
        _isSelected = isSelected
    }

    // MARK: Public

    public var body: some View {
        Button(action: { toggle() }) {
            StyledText(text: label)
                .textStyle(.body2)
                .foregroundColorToken(labelColor)
                .lineLimit(Constant.labelLineLimit)
                .padding(.horizontal, Constant.horizontalPadding)
                .frame(height: Constant.height)
                .designSystemBackground(backgroundColor)
                .designSystemCornerRadius(.small)
        }
        .buttonStyle(.plain)
        .designSystemControlSize(.minimumTouch)
    }

    // MARK: Internal

    func toggle() {
        isSelected.toggle()
    }

    // MARK: Private

    @Binding private var isSelected: Bool

    private let label: String

    private var backgroundColor: ColorToken {
        isSelected ? .blue100 : .grey600
    }

    private var labelColor: ColorToken {
        isSelected ? .grey700 : .grey100
    }

}

// MARK: Chip.Constant

extension Chip {
    enum Constant {
        static let height: CGFloat = 36
        static let horizontalPadding: CGFloat = 8
        static let labelLineLimit = 1
    }
}

#Preview("Chip") {
    HStack(spacing: LayoutToken.compactSpacing) {
        Chip(
            label: "전체",
            isSelected: .constant(true),
        )
        Chip(
            label: "SwiftUI",
            isSelected: .constant(false),
        )
        Chip(
            label: "동시성",
            isSelected: .constant(false),
        )
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
