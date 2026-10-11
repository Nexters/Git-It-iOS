import DesignSystem
import SwiftUI

// MARK: - IconPlainButton

public struct IconPlainButton: View {

    // MARK: Lifecycle

    public init(
        icon: Icon,
        iconSize: CGFloat = 36,
        size: CGFloat = 36,
        action: @escaping () -> Void = { },
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.size = size
        self.action = action
    }

    // MARK: Public

    public typealias Icon = ResourceImage.Asset.Icon

    public var body: some View {
        Button(action: action) {
            ZStack {
                ResourceImage(asset: .icon(icon))
                    .designSystemForeground(foregroundColor)
                    .frame(
                        width: iconSize,
                        height: iconSize,
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                    )
            }
            .frame(
                width: size,
                height: size,
            )
            .background(
                Color(designSystem: backgroundColor),
                in: Circle(),
            )
            .frame(
                width: max(size, Constant.minimumTouchSize),
                height: max(size, Constant.minimumTouchSize),
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private enum Constant {
        static let minimumTouchSize = ControlSizeToken.minimumTouch.cgFloatValue
    }

    private let icon: Icon
    private var foregroundColor = ColorToken.white
    private var backgroundColor = ColorToken.clear
    private let iconSize: CGFloat
    private let size: CGFloat
    private let action: () -> Void

}

// MARK: ForegroundColorConfigurable

extension IconPlainButton: ForegroundColorConfigurable {
    public func foregroundColorToken(_ color: ColorToken) -> Self {
        var copy = self
        copy.foregroundColor = color
        return copy
    }
}

// MARK: BackgroundColorConfigurable

extension IconPlainButton: BackgroundColorConfigurable {
    public func backgroundColorToken(_ color: ColorToken) -> Self {
        var copy = self
        copy.backgroundColor = color
        return copy
    }
}

#Preview("Icon Plain Button") {
    HStack(spacing: LayoutToken.gutter) {
        IconPlainButton(
            icon: .play
        )
        IconPlainButton(
            icon: .play
        )
        .foregroundColorToken(.grey700)
        .backgroundColorToken(.blue100)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.purple200)
}
