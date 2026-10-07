import DesignSystem
import SwiftUI

// MARK: - ScreenControlBar

public struct ScreenControlBar: View {

    // MARK: Lifecycle

    public init(
        leading: Control? = .back,
        trailing: Control? = nil,
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
    ) {
        self.leading = leading
        self.trailing = trailing
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
    }

    // MARK: Public

    public var body: some View {
        HStack(alignment: .top, spacing: LayoutToken.gutter) {
            if let leading {
                IconGlassButton.neutral(
                    icon: leading.icon,
                    label: leading.label,
                    size: .medium,
                    action: onLeadingTap,
                )
            }

            Spacer(minLength: 0)

            if let trailing {
                IconGlassButton.neutral(
                    icon: trailing.icon,
                    label: trailing.label,
                    size: .medium,
                    action: onTrailingTap,
                )
            }
        }
        .frame(height: Constant.controlRowHeight, alignment: .top)
        .padding(.bottom, Constant.bottomPadding)
    }

    // MARK: Private

    private let leading: Control?
    private let trailing: Control?
    private let onLeadingTap: () -> Void
    private let onTrailingTap: () -> Void

}

// MARK: ScreenControlBar.Constant

extension ScreenControlBar {
    fileprivate enum Constant {
        static let controlRowHeight: CGFloat = 40
        static let bottomPadding: CGFloat = 10
    }
}

#Preview("Screen Control Bar") {
    VStack(spacing: LayoutToken.margin) {
        ScreenControlBar()
        ScreenControlBar(trailing: .init(icon: .menu, label: "더 보기"))
        ScreenControlBar(leading: .close, trailing: .init(icon: .setting, label: "설정 열기"))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
