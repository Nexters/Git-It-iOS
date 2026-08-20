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

    public enum Size: Sendable, Equatable {
        case medium
        case small

        // MARK: Internal

        var surfaceSize: CGFloat {
            switch self {
            case .medium:
                40
            case .small:
                36
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .medium:
                17
            case .small:
                15
            }
        }

        var touchSize: CGFloat {
            44
        }
    }

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            symbol: String,
            label: String,
            style: Style = .neutral,
            size: Size = .small,
        ) {
            self.symbol = symbol
            self.label = label
            self.style = style
            self.size = size
        }

        // MARK: Public

        /// SF Symbol 이름입니다. 심볼 이름은 렌더링 정보이므로 `label`이 사용자가
        /// 인지하는 이름을 따로 소유합니다.
        public let symbol: String
        public let label: String
        public let style: Style
        public let size: Size

    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: viewModel.symbol)
                .font(.system(size: viewModel.size.iconSize))
                .designSystemForeground(viewModel.style.tintColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(width: viewModel.size.surfaceSize, height: viewModel.size.surfaceSize)
                .glassEffect(
                    .regular
                        .tint(Color(designSystem: viewModel.style.backgroundColor))
                        .interactive(),
                    in: .circle,
                )
                .frame(width: viewModel.size.touchSize, height: viewModel.size.touchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.label)
    }

    public static func neutral(
        symbol: String,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .neutral, size: size),
            action: action,
        )
    }

    public static func accent(
        symbol: String,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .accent, size: size),
            action: action,
        )
    }

    public static func destructive(
        symbol: String,
        label: String,
        size: Size = .small,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .destructive, size: size),
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
            IconGlassButton.neutral(symbol: "chevron.left", label: "뒤로 가기", size: .small)
            IconGlassButton.accent(symbol: "bookmark", label: "저장하기", size: .medium)
        }
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.blue500)
}
