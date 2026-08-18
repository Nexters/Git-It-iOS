import DesignSystem
import SwiftUI

public struct IconPlainButton: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        action: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.action = action
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            symbol: String,
            label: String,
            tintColor: ColorToken = .white,
            backgroundColor: ColorToken = .clear,
            iconSize: CGFloat = 36,
            size: CGFloat = 36,
        ) {
            self.symbol = symbol
            self.label = label
            self.tintColor = tintColor
            self.backgroundColor = backgroundColor
            self.iconSize = iconSize
            self.size = size
        }

        // MARK: Public

        /// `UIComponent`의 `Assets.xcassets`에 등록된 아이콘 자산 이름입니다. 심볼 이름은
        /// 렌더링 정보이므로 `label`이 사용자가 인지하는 이름을 따로 소유합니다.
        public let symbol: String
        public let label: String
        public let tintColor: ColorToken
        public let backgroundColor: ColorToken
        public let iconSize: CGFloat
        public let size: CGFloat

    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Image(viewModel.symbol, bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .designSystemForeground(viewModel.tintColor)
                    .frame(width: viewModel.iconSize, height: viewModel.iconSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: viewModel.size, height: viewModel.size)
            .background(Color(designSystem: viewModel.backgroundColor), in: Circle())
            .frame(
                width: max(viewModel.size, Constant.minimumTouchSize),
                height: max(viewModel.size, Constant.minimumTouchSize),
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.label)
    }

    // MARK: Private

    private enum Constant {
        static let minimumTouchSize: CGFloat = 44
    }

    private let viewModel: ViewModel
    private let action: () -> Void

}

#Preview("Icon Plain Button") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        IconPlainButton(viewModel: .init(symbol: "ic-play-1", label: "학습 시작"))
        IconPlainButton(
            viewModel: .init(
                symbol: "ic-play-1",
                label: "학습 시작",
                tintColor: .grey700,
                backgroundColor: .blue100,
            )
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.purple200)
}
