import SwiftUI

extension Text {
    public static func designSystemStyled(
        _ string: String,
        style: TextStyleToken,
    ) -> Text {
        _ = FontRegistration.registerBundledFonts
        var attributed = AttributedString(string)
        attributed.kern = style.letterSpacing
        var runStart = attributed.startIndex
        var index = attributed.startIndex
        var runFont: Font?
        while index < attributed.endIndex {
            let nextIndex = attributed.index(afterCharacter: index)
            let font = TextStyleResolver.font(
                for: attributed.characters[index],
                style: style,
            )
            if let runFont, font != runFont {
                attributed[runStart..<index].font = runFont
                runStart = index
            }
            runFont = font
            index = nextIndex
        }
        if let runFont {
            attributed[runStart..<index].font = runFont
        }
        return Text(attributed)
    }
}

extension View {
    public func designSystemLineSpacing(_ style: TextStyleToken) -> some View {
        lineSpacing(TextStyleResolver.additionalLineSpacing(for: style))
    }
}
