import DesignSystem
import SwiftUI

extension HomeProjectCard {
    public enum Variant: Sendable, Equatable {
        case purple
        case lightBlue
        case darkBlue

        // MARK: Lifecycle

        public init(index: Int) {
            self =
                switch index % 3 {
                case 1: .lightBlue
                case 2: .darkBlue
                default: .purple
                }
        }

        // MARK: Internal

        var rotationDegrees: Double {
            switch self {
            case .purple: 0
            case .lightBlue: 16
            case .darkBlue: -12
            }
        }

        var cardColor: ColorToken {
            switch self {
            case .purple: .purple300
            case .lightBlue: .blue100
            case .darkBlue: .blue500
            }
        }

        var titleColor: ColorToken {
            .grey100
        }

        var technologyColor: ColorToken {
            switch self {
            case .purple: .grey200
            case .lightBlue: .grey500
            case .darkBlue: .grey400
            }
        }

        var trackColor: ColorToken {
            switch self {
            case .purple: .purple200
            case .lightBlue: .grey200
            case .darkBlue: .purple300
            }
        }

        var progressColor: ColorToken {
            switch self {
            case .purple: .purple400
            case .lightBlue: .blue200
            case .darkBlue: .blue400
            }
        }

        var setTitleColor: ColorToken {
            switch self {
            case .lightBlue: .grey500
            case .purple,
                 .darkBlue: .grey100
            }
        }
    }
}
