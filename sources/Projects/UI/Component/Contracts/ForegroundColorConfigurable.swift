import DesignSystem
import SwiftUI

public protocol ForegroundColorConfigurable: View {
    func foregroundColorToken(_ color: ColorToken) -> Self
}
