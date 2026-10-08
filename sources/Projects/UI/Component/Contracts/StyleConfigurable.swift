import SwiftUI

public protocol StyleConfigurable: View {
    associatedtype Style

    func style(_ style: Style) -> Self
}
