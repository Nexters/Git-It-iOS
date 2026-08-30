import SwiftUI

// MARK: - TextStyleResolver

enum TextStyleResolver {
    static func font(
        for character: Character,
        style: TextStyleToken,
    ) -> Font {
        let familyToken: FontFamilyToken =
            switch character.fontSelectionRole {
            case .default:
                .notoSans
            case .englishAlphabet:
                .plusJakartaSans
            }
        if let postScriptName = familyToken.postScriptNames[style.weight] {
            return Font.custom(
                postScriptName,
                size: style.size,
            )
        }
        return Font.custom(
            familyToken.name,
            size: style.size,
        ).weight(style.weight.swiftUIWeight)
    }

    static func additionalLineSpacing(for style: TextStyleToken) -> Double {
        let targetLineHeight = style.size * (style.lineHeightPercent / 100)
        let baselineLineHeight = style.size * 1.2
        return max(
            0,
            targetLineHeight - baselineLineHeight,
        )
    }
}

extension TextStyleToken.Weight {
    var swiftUIWeight: Font.Weight {
        switch self {
        case .bold: .bold
        case .medium: .medium
        case .regular: .regular
        }
    }
}

extension Character {
    fileprivate var fontSelectionRole: FontFamilyToken.FontSelectionRole {
        if
            unicodeScalars.contains(where: { scalar in
                (0x0041...0x005A).contains(scalar.value) || (0x0061...0x007A).contains(scalar.value)
            })
        {
            .englishAlphabet
        } else {
            .default
        }
    }
}
