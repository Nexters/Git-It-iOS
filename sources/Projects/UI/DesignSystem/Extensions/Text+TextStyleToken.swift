import SwiftUI

extension Text {
    public static func designSystemStyled(
        _ string: String,
        style: TextStyleToken,
    ) -> Text {
        _ = FontRegistration.registerBundledFonts
        var attributed = AttributedString(string)
        attributed.kern = style.letterSpacing
        var index = attributed.startIndex
        while index < attributed.endIndex {
            let nextIndex = attributed.index(afterCharacter: index)
            let character = attributed.characters[index]
            attributed[index..<nextIndex].font = TextStyleResolver.font(
                for: character,
                style: style,
            )
            index = nextIndex
        }
        return Text(attributed)
    }
}

extension View {
    public func designSystemLineSpacing(_ style: TextStyleToken) -> some View {
        lineSpacing(TextStyleResolver.additionalLineSpacing(for: style))
    }
}
