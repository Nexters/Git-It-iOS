import ComposableArchitecture
import DesignSystem
import DomainMember
import SwiftUI
import UIComponent

// MARK: - PositionSelectionScreen

@ViewAction(for: CurationFeature.self)
struct PositionSelectionScreen: View {

    // MARK: Internal

    enum Display {
        static let orderedPositions: [MemberPosition] = [.frontend, .backend, .ios, .android]

        static func identifier(for position: MemberPosition) -> String {
            switch position {
            case .ios: "ios"
            case .android: "android"
            case .backend: "backend"
            case .frontend: "frontend"
            }
        }

        static func position(forIdentifier identifier: String) -> MemberPosition? {
            orderedPositions.first { Self.identifier(for: $0) == identifier }
        }

        static func title(for position: MemberPosition) -> String {
            switch position {
            case .ios: "iOS"
            case .android: "Android"
            case .backend: "Back-end"
            case .frontend: "Front-end"
            }
        }
    }

    @Bindable var store: StoreOf<CurationFeature>

    var body: some View {
        ScreenContainer { layoutMetrics in
            VStack(spacing: 0) {
                ScreenHeader(
                    leading: .close,
                    onLeadingTap: { send(.positionBackTapped) },
                )
                .designSystemScreenMargin()

                ScrollView {
                    VStack(spacing: Constant.titleToOptionsSpacing) {
                        VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                            StyledText.subtitle1(Constant.title, alignment: .center)

                            if store.exitStatus == .failed {
                                StyledText.caption1(
                                    "이전 화면으로 돌아가지 못했어요. 다시 시도해 주세요.",
                                    color: .error,
                                    alignment: .center,
                                )
                            }
                        }

                        SelectionCardList(
                            items: Display.orderedPositions.map { position in
                                .init(
                                    id: Display.identifier(for: position),
                                    title: Display.title(for: position),
                                    isSelected: store.selection.position == position,
                                )
                            },
                            style: .compact,
                            onSelect: { identifier in
                                if let position = Display.position(forIdentifier: identifier) {
                                    send(.positionSelected(position))
                                }
                            },
                        )
                    }
                    .designSystemScreenMargin()
                    .padding(.top, LayoutToken.margin.cgFloatValue)
                }

                BottomActionBar(layoutMetrics: layoutMetrics) {
                    ActionButton.primary(
                        "다음",
                        isEnabled: store.selection.position != nil,
                        action: { send(.positionNextTapped) },
                    )
                }
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let title = "어떤 분야의 코드를\n학습하고 싶나요?"
        static let titleToOptionsSpacing: CGFloat = 64
    }

}
