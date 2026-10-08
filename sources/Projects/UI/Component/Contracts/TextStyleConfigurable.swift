import DesignSystem
import SwiftUI

public protocol TextStyleConfigurable: View {
    func textStyle(_ textStyle: TextStyleToken) -> Self
}
