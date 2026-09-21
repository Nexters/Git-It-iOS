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

}

#Preview("Styled Text") {
    VStack(alignment: .leading, spacing: LayoutToken.gutter) {
        StyledText(text: "Headline 1", style: .headline1)
        StyledText(text: "Headline 2", style: .headline2)
        StyledText(text: "Subtitle 1", style: .subtitle1, color: .blue100)
        StyledText(text: "Subtitle 2", style: .subtitle2)
        StyledText(text: "Subtitle 3", style: .subtitle3)
        StyledText(text: "Body 1", style: .body1)
        StyledText(text: "본문 텍스트는 여러 줄에서도 지정된 행간과 정렬을 유지합니다.", style: .body2)
        StyledText(text: "Body 3", style: .body3)
        StyledText(text: "Caption 1", style: .caption1, color: .grey400)
        StyledText(text: "Caption 2", style: .caption2, color: .grey400)
    }
    .frame(width: 320, alignment: .leading)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
