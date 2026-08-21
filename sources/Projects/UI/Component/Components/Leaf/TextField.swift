import DesignSystem
import SwiftUI

public struct TextField: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        text: Binding<String>,
        onCommit: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        _text = text
        self.onCommit = onCommit
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            placeholder: String,
            errorMessage: String? = nil,
            isSecure: Bool = false,
        ) {
            self.placeholder = placeholder
            self.errorMessage = errorMessage
            self.isSecure = isSecure
        }

        public let placeholder: String
        public let errorMessage: String?
        public let isSecure: Bool
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Constant.errorSpacing) {
            field
                .padding(.horizontal, Constant.horizontalPadding)
                .frame(height: Constant.surfaceHeight)
                .designSystemBackground(state.backgroundColor)
                .designSystemCornerRadius(.small)
                .overlay {
                    RoundedRectangle(designSystem: .small)
                        .stroke(
                            Color(designSystem: state.borderColor),
                            lineWidth: Constant.borderWidth,
                        )
                }

            if let errorMessage = viewModel.errorMessage {
                StyledText.caption1(errorMessage, color: .error)
            }
        }
    }

    // MARK: Internal

    enum State: Sendable, Equatable {
        case `default`
        case active
        case filled
        case error

        // MARK: Internal

        var borderColor: ColorToken {
            switch self {
            case .default: .grey500
            case .active: .blue100
            case .filled: .grey400
            case .error: .error
            }
        }

        var backgroundColor: ColorToken {
            .grey600
        }
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 16
        static let surfaceHeight: CGFloat = 52
        static let borderWidth: CGFloat = 1
        static let errorSpacing: CGFloat = 4
    }

    @FocusState private var isFocused: Bool

    private let viewModel: ViewModel
    private let onCommit: () -> Void

    @Binding private var text: String

    private var state: State {
        if viewModel.errorMessage != nil {
            .error
        } else if isFocused {
            .active
        } else if !text.isEmpty {
            .filled
        } else {
            .default
        }
    }

    @ViewBuilder
    private var field: some View {
        Group {
            if viewModel.isSecure {
                SecureField(viewModel.placeholder, text: $text)
            } else {
                SwiftUI.TextField(viewModel.placeholder, text: $text)
            }
        }
        .focused($isFocused)
        .onSubmit(onCommit)
        .designSystemForeground(.grey100)
    }

}

#Preview("Text Field") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
        TextField(
            viewModel: .init(placeholder: "닉네임을 입력해주세요"),
            text: .constant(""),
        )
        TextField(
            viewModel: .init(placeholder: "닉네임을 입력해주세요"),
            text: .constant("Git It"),
        )
        TextField(
            viewModel: .init(
                placeholder: "닉네임을 입력해주세요",
                errorMessage: "이미 사용 중인 닉네임입니다",
            ),
            text: .constant("중복 닉네임"),
        )
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
