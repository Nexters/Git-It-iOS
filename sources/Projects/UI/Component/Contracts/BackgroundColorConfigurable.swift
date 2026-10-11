import DesignSystem
import SwiftUI

public protocol BackgroundColorConfigurable: View {
    func backgroundColorToken(_ color: ColorToken) -> Self
}
