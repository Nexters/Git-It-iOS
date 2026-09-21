import DesignSystem
import SwiftUI

// MARK: - TextField

public struct TextField: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        text: Binding<String>,
        isSecure: Bool = false,
        onCommit: @escaping () -> Void = { },
    ) {
        self.displayModel = displayModel
        _text = text
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

            if let errorMessage = displayModel.errorMessage {
                StyledText(text: errorMessage)
                    .textStyle(.caption1)
                    .foregroundColorToken(.error)
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
                    name: ColorToken.grey400.name,
                    width: 1,
                    colorToken: .grey400,
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

        var backgroundColor: ColorToken {
            .grey600
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

    private let displayModel: DisplayModel
    private let isSecure: Bool
    private let onCommit: () -> Void

    private var state: State {
        if displayModel.errorMessage != nil {
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
                SecureField(displayModel.placeholder, text: $text)
            } else {
                SwiftUI.TextField(displayModel.placeholder, text: $text)
            }
        }
        .focused($isFocused)
        .onSubmit(onCommit)
        .designSystemForeground(.grey100)
    }

}

// MARK: TextField.DisplayModel

extension TextField {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            placeholder: String,
            errorMessage: String? = nil,
        ) {
            self.placeholder = placeholder
            self.errorMessage = errorMessage
        }

        public let placeholder: String
        public let errorMessage: String?
    }
}

#Preview("Text Field") {
    VStack(spacing: LayoutToken.gutter) {
        TextField(displayModel: .init(placeholder: "닉네임을 입력해주세요"), text: .constant(""))
        TextField(displayModel: .init(placeholder: "닉네임을 입력해주세요"), text: .constant("Git It"))
        TextField(
            displayModel: .init(placeholder: "닉네임을 입력해주세요", errorMessage: "이미 사용 중인 닉네임입니다"),
            text: .constant("중복 닉네임"),
        )
    }
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
