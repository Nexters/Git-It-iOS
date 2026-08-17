import DesignSystem
import SwiftUI

public struct IconButton: View {

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
        case inverse
        case destructive

        var tintColor: ColorToken {
            switch self {
            case .neutral: .grey100
            case .accent: .blue100
            case .inverse: .grey700
            case .destructive: .error
            }
        }

        var backgroundColor: ColorToken {
            switch self {
            case .neutral: .white5
            case .accent: .grey500
            case .inverse: .grey100
            case .destructive: .grey700
            }
        }
    }

    public struct ViewModel: Sendable, Equatable {
        public init(
            symbol: String,
            label: String,
            style: Style = .neutral,
        ) {
            self.symbol = symbol
            self.label = label
            self.style = style
        }

        /// 심볼 이름은 렌더링 정보이므로 `label`이 사용자가 인지하는 이름을 따로 소유합니다.
        public let symbol: String
        public let label: String
        public let style: Style
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: viewModel.symbol)
                .font(.system(size: Constant.symbolSize, weight: .semibold))
                .designSystemForeground(viewModel.style.tintColor)
                .designSystemControlSize(.action)
        }
        .buttonStyle(.glass)
        .tint(Color(designSystem: viewModel.style.backgroundColor))
        .accessibilityLabel(viewModel.label)
    }

    public static func neutral(
        symbol: String,
        label: String,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .neutral),
            action: action,
        )
    }

    public static func accent(
        symbol: String,
        label: String,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .accent),
            action: action,
        )
    }

    public static func inverse(
        symbol: String,
        label: String,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .inverse),
            action: action,
        )
    }

    public static func destructive(
        symbol: String,
        label: String,
        action: @escaping () -> Void = { },
    ) -> Self {
        Self(
            viewModel: .init(symbol: symbol, label: label, style: .destructive),
            action: action,
        )
    }

    // MARK: Private

    private enum Constant {
        static let symbolSize: CGFloat = 17
    }

    private let viewModel: ViewModel
    private let action: () -> Void

}

#Preview("Icon Button") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        IconButton.neutral(symbol: "chevron.left", label: "뒤로 가기")
        IconButton.accent(symbol: "bookmark", label: "저장하기")
        IconButton.inverse(symbol: "play.fill", label: "학습 시작")
        IconButton.destructive(symbol: "trash", label: "삭제하기")
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
