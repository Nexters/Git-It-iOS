import DesignSystem
import SwiftUI

// MARK: - Chip

public struct Chip: View {

    // MARK: Lifecycle

    public init(
        label: String,
        isSelected: Bool,
        onTap: @escaping () -> Void,
    ) {
        self.label = label
        self.isSelected = isSelected
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            StyledText.body2(label, color: labelColor)
                .lineLimit(Constant.labelLineLimit)
                .padding(.horizontal, Constant.horizontalPadding)
                .frame(height: Constant.height)
                .designSystemBackground(backgroundColor)
                .designSystemCornerRadius(.small)
        }
        .buttonStyle(.plain)
        .designSystemControlSize(.minimumTouch)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Private

    private let label: String
    private let isSelected: Bool
    private let onTap: () -> Void

    private var backgroundColor: SemanticColorToken {
        isSelected ? .brandAccent : .cardBackground
    }

    private var labelColor: ColorToken {
        isSelected ? .grey700 : .grey100
    }

}

// MARK: Chip.Constant

extension Chip {
    fileprivate enum Constant {
        static let height: CGFloat = 36
        static let horizontalPadding: CGFloat = 8
        static let labelLineLimit = 1
    }
}

#Preview("Chip") {
    HStack(spacing: LayoutToken.compactSpacing) {
        Chip(label: "전체", isSelected: true) { }
        Chip(label: "SwiftUI", isSelected: false) { }
        Chip(label: "동시성", isSelected: false) { }
    }
    .padding(LayoutToken.margin)
    .designSystemBackground(.grey700)
}
