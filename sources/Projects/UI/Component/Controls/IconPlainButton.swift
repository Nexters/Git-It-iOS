import DesignSystem
import SwiftUI

public struct IconPlainButton: View {

    // MARK: Lifecycle

    public init(
        icon: Icon,
        label: String,
        tintColor: ColorToken = .white,
        backgroundColor: ColorToken = .clear,
        iconSize: CGFloat = 36,
        size: CGFloat = 36,
        action: @escaping () -> Void = { },
    ) {
        self.icon = icon
        self.label = label
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
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
                    .designSystemForeground(tintColor)
                    .frame(width: iconSize, height: iconSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: size, height: size)
            .background(Color(designSystem: backgroundColor), in: Circle())
            .frame(
                width: max(size, Constant.minimumTouchSize),
                height: max(size, Constant.minimumTouchSize),
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Private

    private enum Constant {
        static let minimumTouchSize = ControlSizeToken.minimumTouch.cgFloatValue
    }

    private let icon: Icon
    private let label: String
    private let tintColor: ColorToken
    private let backgroundColor: ColorToken
    private let iconSize: CGFloat
    private let size: CGFloat
    private let action: () -> Void

}

#Preview("Icon Plain Button") {
    HStack(spacing: LayoutToken.gutter) {
        IconPlainButton(icon: .play, label: "학습 시작")
        IconPlainButton(
            icon: .play,
            label: "학습 시작",
            tintColor: .grey700,
            backgroundColor: .blue100,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.purple200)
}
