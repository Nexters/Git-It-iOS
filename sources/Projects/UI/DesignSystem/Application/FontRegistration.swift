import CoreText
import Foundation

enum FontRegistration {

    static let registerBundledFonts: Void = {
        let fileNames = [
            "NotoSansKR-Regular",
            "NotoSansKR-Medium",
            "NotoSansKR-Bold",
            "PlusJakartaSans-Regular",
            "PlusJakartaSans-Medium",
            "PlusJakartaSans-Bold",
        ]
        for fileName in fileNames {
            guard let url = Bundle.module.url(
                forResource: fileName,
                withExtension: "ttf"
            ) else { continue }
            CTFontManagerRegisterFontsForURL(
                url as CFURL,
                .process,
                nil
            )
        }
    }()

}
