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
            attributed[index..<nextIndex].font = TextStyleModifier.font(
                for: character,
                style: style
            )
            index = nextIndex
        }
        return Text(attributed)
    }
}

extension View {
    public func designSystemLineSpacing(_ style: TextStyleToken) -> some View {
        lineSpacing(TextStyleModifier.additionalLineSpacing(for: style))
    }
}

// MARK: - TextStyleModifier

enum TextStyleModifier {
    static func font(
        for character: Character,
        style: TextStyleToken,
    ) -> Font {
        let familyToken: FontFamilyToken =
            switch character.script {
            case .korean,
                 .default:
                .notoSans
            case .english:
                .plusJakartaSans
            }
        if let postScriptName = familyToken.postScriptNames[style.weight] {
            return Font.custom(
                postScriptName,
                size: style.size
            )
        }
        return Font.custom(
            familyToken.name,
            size: style.size
        ).weight(style.weight.swiftUIWeight)
    }

    static func additionalLineSpacing(for style: TextStyleToken) -> Double {
        let targetLineHeight = style.size * (style.lineHeightPercent / 100)
        let baselineLineHeight = style.size * 1.2
        return max(
            0,
            targetLineHeight - baselineLineHeight
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
    fileprivate enum Script {
        case korean
        case english
        case `default`
    }

    fileprivate var script: Script {
        let isKorean = unicodeScalars.contains { scalar in
            (0xAC00...0xD7A3).contains(scalar.value)
                || (0x1100...0x11FF).contains(scalar.value)
                || (0x3130...0x318F).contains(scalar.value)
        }
        if isKorean {
            return .korean
        }
        let isEnglish = unicodeScalars.contains { scalar in
            (0x0041...0x005A).contains(scalar.value) || (0x0061...0x007A).contains(scalar.value)
        }
        if isEnglish {
            return .english
        }
        return .default
    }
}
