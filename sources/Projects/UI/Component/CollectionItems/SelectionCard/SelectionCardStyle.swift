import DesignSystem
import SwiftUI

public enum SelectionCardStyle: Sendable, Equatable {
    case detailed
    case compact

    // MARK: Internal

    var minimumHeight: CGFloat {
        switch self {
        case .detailed:
            80
        case .compact:
            52
        }
    }

    var showsThumbnail: Bool {
        self == .detailed
    }
}
