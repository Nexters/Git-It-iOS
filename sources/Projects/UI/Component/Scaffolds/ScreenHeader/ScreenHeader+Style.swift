import DesignSystem
import SwiftUI

extension ScreenHeader {
    public enum Style: Sendable, Equatable {
        case `default`
        case inlineTitle
        case inlineUser
        case largeTitle

        // MARK: Internal

        /// 규격이 확정한 헤더 높이. `.default`가 규격의 plain에 해당한다.
        var layoutMetricsHeaderStyle: LayoutMetrics.HeaderStyle {
            switch self {
            case .default:
                .plain
            case .inlineTitle:
                .inlineTitle
            case .inlineUser:
                .inlineUser
            case .largeTitle:
                .largeTitle
            }
        }

        var height: CGFloat {
            CGFloat(layoutMetricsHeaderStyle.height)
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
