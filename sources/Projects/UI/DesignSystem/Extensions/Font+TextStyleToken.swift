import SwiftUI

extension Font {
    public static func designSystem(
        _ style: TextStyleToken,
        family: FontFamilyToken = .notoSans,
    ) -> Font {
        TextStyleResolver.font(
            family: family,
            style: style,
        )
    }
}
