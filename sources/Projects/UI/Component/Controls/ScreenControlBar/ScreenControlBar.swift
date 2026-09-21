import DesignSystem
import SwiftUI

// MARK: - ScreenControlBar

public struct ScreenControlBar: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel = .init(),
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
    ) {
        self.displayModel = displayModel
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
    }

    // MARK: Public

    public var body: some View {
        HStack(alignment: .top, spacing: LayoutToken.gutter) {
            if let leading = displayModel.leading {
                IconGlassButton(
                    icon: leading.icon,
                    label: leading.label,
                    action: onLeadingTap,
                )
                .size(.medium)
            }

            Spacer(minLength: 0)

            if let trailing = displayModel.trailing {
                IconGlassButton(
                    icon: trailing.icon,
                    label: trailing.label,
                    action: onTrailingTap,
                )
                .size(.medium)
            }
        }
        .frame(height: Constant.controlRowHeight, alignment: .top)
        .padding(.bottom, Constant.bottomPadding)
    }

    // MARK: Private

    private let displayModel: DisplayModel
    private let onLeadingTap: () -> Void
    private let onTrailingTap: () -> Void

}

// MARK: ScreenControlBar.DisplayModel

extension ScreenControlBar {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            leading: Control? = .back,
            trailing: Control? = nil,
        ) {
            self.leading = leading
            self.trailing = trailing
        }

        public let leading: Control?
        public let trailing: Control?
    }
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
        ScreenControlBar(displayModel: .init(trailing: .init(icon: .menu, label: "더 보기")))
        ScreenControlBar(displayModel: .init(leading: .close, trailing: .init(icon: .setting, label: "설정 열기")))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
