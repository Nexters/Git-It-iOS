// MARK: - FontFamilyToken

public struct FontFamilyToken: Sendable, Equatable {
    public init(
        name: String,
        scriptScope: ScriptScope,
        postScriptNames: [TextStyleToken.Weight: String] = [:],
    ) {
        self.name = name
        self.scriptScope = scriptScope
        self.postScriptNames = postScriptNames
    }

    public let name: String
    public let scriptScope: ScriptScope
    public let postScriptNames: [TextStyleToken.Weight: String]
}

// MARK: FontFamilyToken.ScriptScope

extension FontFamilyToken {
    public enum ScriptScope: Sendable {
        case korean
        case english
    }
}

extension FontFamilyToken {
    public static let notoSans = FontFamilyToken(
        name: "Noto Sans",
        scriptScope: .korean,
        postScriptNames: [
            .regular: "NotoSansKR-Regular",
            .medium: "NotoSansKR-Medium",
            .bold: "NotoSansKR-Bold",
        ],
    )
    public static let plusJakartaSans = FontFamilyToken(
        name: "Plus Jakarta Sans",
        scriptScope: .english,
        postScriptNames: [
            .regular: "PlusJakartaSans-Regular",
            .medium: "PlusJakartaSans-Medium",
            .bold: "PlusJakartaSans-Bold",
        ],
    )

    public static let all: [FontFamilyToken] = [notoSans, plusJakartaSans]
}
