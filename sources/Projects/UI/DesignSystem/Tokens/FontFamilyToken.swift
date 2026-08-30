// MARK: - FontFamilyToken

public struct FontFamilyToken: Sendable, Equatable {
    public init(
        name: String,
        selectionRole: FontSelectionRole,
        postScriptNames: [TextStyleToken.Weight: String] = [:],
    ) {
        self.name = name
        self.selectionRole = selectionRole
        self.postScriptNames = postScriptNames
    }

    public let name: String
    public let selectionRole: FontSelectionRole
    public let postScriptNames: [TextStyleToken.Weight: String]
}

// MARK: FontFamilyToken.FontSelectionRole

extension FontFamilyToken {
    public enum FontSelectionRole: Sendable {
        case `default`
        case englishAlphabet
    }
}

extension FontFamilyToken {
    public static let notoSans = FontFamilyToken(
        name: "Noto Sans",
        selectionRole: .`default`,
        postScriptNames: [
            .regular: "NotoSansKR-Regular",
            .medium: "NotoSansKR-Medium",
            .bold: "NotoSansKR-Bold",
        ],
    )
    public static let plusJakartaSans = FontFamilyToken(
        name: "Plus Jakarta Sans",
        selectionRole: .englishAlphabet,
        postScriptNames: [
            .regular: "PlusJakartaSans-Regular",
            .medium: "PlusJakartaSans-Medium",
            .bold: "PlusJakartaSans-Bold",
        ],
    )

    public static let all: [FontFamilyToken] = [notoSans, plusJakartaSans]
}
