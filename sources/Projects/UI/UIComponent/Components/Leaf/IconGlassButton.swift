import DesignSystem
import SwiftUI

public struct IconGlassButton: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        action: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.action = action
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case neutral
        case accent
        case destructive

        var tintColor: ColorToken {
            switch self {
            case .neutral: .grey100
            case .accent: .blue100
            case .destructive: .error
            }
        }

        var backgroundColor: ColorToken {
            switch self {
            case .neutral: .white5
            case .accent: .grey500
            case .destructive: .grey700
            }
        }
    }

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            symbol: String,
            label: String,
            style: Style = .neutral,
            iconSize: CGFloat = 17,
            size: CGFloat = 36,
        ) {
            self.symbol = symbol
            self.label = label
            self.style = style
            self.iconSize = iconSize
            self.size = size
        }

        // MARK: Public

        /// SF Symbol 이름입니다. 심볼 이름은 렌더링 정보이므로 `label`이 사용자가
        /// 인지하는 이름을 따로 소유합니다.
        public let symbol: String
        public let label: String
        public let style: Style
        public let iconSize: CGFloat
        public let size: CGFloat

    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: viewModel.symbol)
                .font(.system(size: viewModel.iconSize))
                .designSystemForeground(viewModel.style.tintColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(Color(designSystem: viewModel.style.backgroundColor))
        .frame(width: viewModel.size, height: viewModel.size)
        .accessibilityLabel(viewModel.label)
        .frame(width: viewModel.size + 2, height: viewModel.size + 2)
    }

    public static func neutral(
        symbol: String,
        label: String,
        iconSize: CGFloat = 17,
        size: CGFloat = 36,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .neutral, iconSize: iconSize, size: size),
            action: action,
        )
    }

    public static func accent(
        symbol: String,
        label: String,
        iconSize: CGFloat = 17,
        size: CGFloat = 36,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .accent, iconSize: iconSize, size: size),
            action: action,
        )
    }

    public static func destructive(
        symbol: String,
        label: String,
        iconSize: CGFloat = 17,
        size: CGFloat = 36,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .destructive, iconSize: iconSize, size: size),
            action: action,
        )
    }

    // MARK: Private

    private let viewModel: ViewModel
    private let action: () -> Void

}

#Preview("Icon Glass Button") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        HStack(spacing: LayoutToken.gutter.cgFloatValue) {
            IconGlassButton.neutral(symbol: "chevron.left", label: "뒤로 가기")
            IconGlassButton.accent(symbol: "bookmark", label: "저장하기")
            IconGlassButton.destructive(symbol: "trash", label: "삭제하기")
        }
        HStack(spacing: LayoutToken.gutter.cgFloatValue) {
            IconGlassButton.neutral(symbol: "chevron.left", label: "뒤로 가기", iconSize: 12, size: 32)
            IconGlassButton.accent(symbol: "bookmark", label: "저장하기", iconSize: 24, size: 56)
        }
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.blue500)
}
