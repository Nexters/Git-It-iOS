import DesignSystem
import SwiftUI

public struct StyledText: View, Sendable, Equatable {

    // MARK: Lifecycle

    public init(
        text: String,
        style: TextStyleToken,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) {
        self.text = text
        self.style = style
        self.color = color
        self.alignment = alignment
    }

    // MARK: Public

    public let text: String
    public let style: TextStyleToken
    public let color: ColorToken
    public let alignment: TextAlignment

    public var body: some View {
        Text.designSystemStyled(text, style: style)
            .designSystemLineSpacing(style)
            .designSystemForeground(color)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
    }

    public static func headline1(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .headline1, color: color, alignment: alignment)
    }

    public static func headline2(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .headline2, color: color, alignment: alignment)
    }

    public static func subtitle1(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .subtitle1, color: color, alignment: alignment)
    }

    public static func subtitle2(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .subtitle2, color: color, alignment: alignment)
    }

    public static func subtitle3(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .subtitle3, color: color, alignment: alignment)
    }

    public static func body1(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .body1, color: color, alignment: alignment)
    }

    public static func body2(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .body2, color: color, alignment: alignment)
    }

    public static func body3(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .body3, color: color, alignment: alignment)
    }

    public static func caption1(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .caption1, color: color, alignment: alignment)
    }

    public static func caption2(
        _ text: String,
        color: ColorToken = .grey100,
        alignment: TextAlignment = .leading,
    ) -> Self {
        styled(text, style: .caption2, color: color, alignment: alignment)
    }

    // MARK: Private

    private static func styled(
        _ text: String,
        style: TextStyleToken,
        color: ColorToken,
        alignment: TextAlignment,
    ) -> Self {
        Self(text: text, style: style, color: color, alignment: alignment)
    }

}

#Preview("Styled Text") {
    VStack(alignment: .leading, spacing: LayoutToken.gutter) {
        StyledText.headline1("Headline 1")
        StyledText.headline2("Headline 2")
        StyledText.subtitle1("Subtitle 1", color: .blue100)
        StyledText.subtitle2("Subtitle 2")
        StyledText.subtitle3("Subtitle 3")
        StyledText.body1("Body 1")
        StyledText.body2("본문 텍스트는 여러 줄에서도 지정된 행간과 정렬을 유지합니다.")
        StyledText.body3("Body 3")
        StyledText.caption1("Caption 1", color: .grey400)
        StyledText.caption2("Caption 2", color: .grey400)
    }
    .frame(width: 320, alignment: .leading)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
