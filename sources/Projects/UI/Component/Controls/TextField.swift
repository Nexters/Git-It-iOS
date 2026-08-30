import DesignSystem
import SwiftUI

public struct TextField: View {

    // MARK: Lifecycle

    public init(
        placeholder: String,
        text: Binding<String>,
        errorMessage: String? = nil,
        isSecure: Bool = false,
        onCommit: @escaping () -> Void = { },
    ) {
        self.placeholder = placeholder
        _text = text
        self.errorMessage = errorMessage
        self.isSecure = isSecure
        self.onCommit = onCommit
    }

    // MARK: Public

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

            if let errorMessage {
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

    @Binding private var text: String

    private let placeholder: String
    private let errorMessage: String?
    private let isSecure: Bool
    private let onCommit: () -> Void

    private var state: State {
        if errorMessage != nil {
            .error
        } else if isFocused {
            .active
        } else if !text.isEmpty {
            .filled
        } else {
            .default
        }
    }

    private var field: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                SwiftUI.TextField(placeholder, text: $text)
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
            placeholder: "닉네임을 입력해주세요",
            text: .constant(""),
        )
        TextField(
            placeholder: "닉네임을 입력해주세요",
            text: .constant("Git It"),
        )
        TextField(
            placeholder: "닉네임을 입력해주세요",
            text: .constant("중복 닉네임"),
            errorMessage: "이미 사용 중인 닉네임입니다",
        )
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
