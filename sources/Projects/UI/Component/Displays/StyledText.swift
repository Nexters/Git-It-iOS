import DesignSystem
import SwiftUI

// MARK: - StyledText

public struct StyledText: View, Sendable, Equatable {

    // MARK: Lifecycle

    public init(text: String) {
        self.text = text
    }

    // MARK: Public

    public let text: String

    public var body: some View {
        Text.designSystemStyled(
            text,
            style: textStyle,
        )
        .designSystemLineSpacing(textStyle)
        .designSystemForeground(foregroundColor)
        .fixedSize(
            horizontal: false,
            vertical: true,
        )
    }

    // MARK: Private

    private var textStyle = TextStyleToken.body1
    private var foregroundColor = ColorToken.grey100

}

// MARK: TextStyleConfigurable

extension StyledText: TextStyleConfigurable {
    public func textStyle(_ textStyle: TextStyleToken) -> Self {
        var copy = self
        copy.textStyle = textStyle
        return copy
    }
}

// MARK: ForegroundColorConfigurable

extension StyledText: ForegroundColorConfigurable {
    public func foregroundColorToken(_ color: ColorToken) -> Self {
        var copy = self
        copy.foregroundColor = color
        return copy
    }
}

#Preview("Styled Text") {
    VStack(
        alignment: .leading,
        spacing: LayoutToken.gutter,
    ) {
        StyledText(text: "Headline 1")
            .textStyle(.headline1)
        StyledText(text: "Headline 2")
            .textStyle(.headline2)
        StyledText(text: "Subtitle 1")
            .textStyle(.subtitle1)
            .foregroundColorToken(.blue100)
        StyledText(text: "Subtitle 2")
            .textStyle(.subtitle2)
        StyledText(text: "Subtitle 3")
            .textStyle(.subtitle3)
        StyledText(text: "Body 1")
        StyledText(text: "본문 텍스트는 여러 줄에서도 지정된 행간과 정렬을 유지합니다.")
            .textStyle(.body2)
        StyledText(text: "Body 3")
            .textStyle(.body3)
        StyledText(text: "Caption 1")
            .textStyle(.caption1)
            .foregroundColorToken(.grey400)
        StyledText(text: "Caption 2")
            .textStyle(.caption2)
            .foregroundColorToken(.grey400)
    }
    .frame(
        width: 320,
        alignment: .leading,
    )
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
