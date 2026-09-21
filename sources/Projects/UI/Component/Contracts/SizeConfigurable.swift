import SwiftUI

public protocol SizeConfigurable: View {
    associatedtype Size

    func size(_ size: Size) -> Self
}
