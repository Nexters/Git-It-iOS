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
                            lineWidth: state.borderWidth,
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

        var borderToken: BorderToken {
            switch self {
            case .default:
                .default

            case .active:
                .focus

            case .filled:
                BorderToken(
                    name: SemanticColorToken.mutedText.name,
                    width: 1,
                    colorToken: SemanticColorToken.mutedText.colorToken,
                )

            case .error:
                .error
            }
        }

        var borderColor: ColorToken {
            borderToken.colorToken
        }

        var borderWidth: CGFloat {
            CGFloat(borderToken.width)
        }

        var backgroundColor: SemanticColorToken {
            .cardBackground
        }
    }

    enum Constant {
        static let horizontalPadding: CGFloat = 16
        static let surfaceHeight: CGFloat = 52
        static let errorSpacing: CGFloat = 4
    }

    // MARK: Private

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
