import ComposableArchitecture
import DesignSystem
import DomainUserInfo
import SwiftUI
import UIComponent

// MARK: - PositionSelectionScreen

@ViewAction(for: PositionSelectionFeature.self)
struct PositionSelectionScreen: View {

    @Bindable var store: StoreOf<PositionSelectionFeature>

    var body: some View {
        OverlayContainer {
            ScreenControlBar(
                leading: .close,
                onLeadingTap: { send(.backTapped) },
            )
            .designSystemScreenMargin()
        } content: {
            VStack(spacing: Constant.titleToOptionsSpacing) {
                VStack(spacing: LayoutToken.compactSpacing) {
                    StyledText(text: Constant.title, style: .subtitle1, alignment: .center)

                    if store.exitStatus == .failed {
                        StyledText(
                            text: "이전 화면으로 돌아가지 못했어요. 다시 시도해 주세요.",
                            style: .caption1,
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
                            isSelected: store.position == position,
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
            .padding(.top, LayoutToken.margin)
        } footer: {
            BottomActionBar {
                FeedbackActionButton(
                    title: "다음",
                    style: .primary,
                    isEnabled: store.position != nil,
                    action: { send(.nextTapped) },
                )
                .designSystemScreenMargin()
            }
        }
    }

}

// MARK: PositionSelectionScreen.Display

extension PositionSelectionScreen {
    fileprivate enum Display {
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
}

// MARK: PositionSelectionScreen.Constant

extension PositionSelectionScreen {
    fileprivate enum Constant {
        static let title = "어떤 분야의 코드를\n학습하고 싶나요?"
        static let titleToOptionsSpacing: CGFloat = 64
    }
}
