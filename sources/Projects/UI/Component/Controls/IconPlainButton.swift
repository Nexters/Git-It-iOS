import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.hug` — 표면은 규격 정사각이고 히트 영역만 44 이상으로 넓힌다.
public struct IconPlainButton: View {

    // MARK: Lifecycle

    public init(
        symbol: String,
        label: String,
        tintColor: ColorToken = .white,
        backgroundColor: ColorToken = .clear,
        iconSize: CGFloat = 36,
        size: CGFloat = 36,
        action: @escaping () -> Void = { },
    ) {
        self.symbol = symbol
        self.label = label
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        self.iconSize = iconSize
        self.size = size
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(action: action) {
            ZStack {
                Image(symbol, bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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
        .buttonStyle(.pressOverlay)
        .accessibilityLabel(label)
    }

    // MARK: Private

    private enum Constant {
        static let minimumTouchSize = ControlSizeToken.minimumTouch.cgFloatValue
    }

    private let symbol: String
    private let label: String
    private let tintColor: ColorToken
    private let backgroundColor: ColorToken
    private let iconSize: CGFloat
    private let size: CGFloat
    private let action: () -> Void

}

#Preview("Icon Plain Button") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        IconPlainButton(symbol: "ic-play-1", label: "학습 시작")
        IconPlainButton(
            symbol: "ic-play-1",
            label: "학습 시작",
            tintColor: .grey700,
            backgroundColor: .blue100,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.purple200)
}
