import DesignSystem
import SwiftUI

extension ScreenHeader {
    public enum Style: Sendable, Equatable {
        case `default`
        case inlineTitle
        case inlineUser
        case largeTitle

        // MARK: Internal

        var height: CGFloat {
            switch self {
            case .default:
                50
            case .inlineTitle:
                43
            case .inlineUser:
                74
            case .largeTitle:
                99
            }
        }

        var controlRowHeight: CGFloat {
            switch self {
            case .inlineUser:
                66
            case .default,
                 .inlineTitle,
                 .largeTitle:
                40
            }
        }

        var topPadding: CGFloat {
            switch self {
            case .inlineUser:
                22
            case .default,
                 .inlineTitle,
                 .largeTitle:
                0
            }
        }

        var titleSpacing: CGFloat {
            switch self {
            case .largeTitle:
                16
            case .default,
                 .inlineTitle,
                 .inlineUser:
                0
            }
        }

        var showsInlineTitle: Bool {
            self == .inlineTitle
        }

        var showsStackedTitle: Bool {
            self == .largeTitle
        }

        var showsUserProfile: Bool {
            self == .inlineUser
        }
    }
}
