import ComposableArchitecture
import DesignSystem
import DomainUseCaseInterface
import SwiftUI
import UIComponent

// MARK: - CareerSelectionScreen

@ViewAction(for: CareerSelectionFeature.self)
struct CareerSelectionScreen: View {

    @Bindable var store: StoreOf<CareerSelectionFeature>

    var body: some View {
        OverlayContainer {
            ScreenControlBar(
                displayModel: .init(leading: .back),
                onLeadingTap: { send(.backTapped) },
            )
            .designSystemScreenMargin()
        } content: {
            VStack(spacing: Constant.titleToOptionsSpacing) {
                VStack(spacing: LayoutToken.compactSpacing) {
                    StyledText(text: LocalizedText.Onboarding.CareerSelection.title)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)

                    if store.submission == .failed {
                        StyledText(text: LocalizedText.Onboarding.CareerSelection.SubmissionFailure.message)
                            .textStyle(.caption1)
                            .foregroundColorToken(.error)
                            .multilineTextAlignment(.center)
                    }
                }

                SelectionCardList(
                    items: Display.orderedLevels.map { level in
                        .init(
                            id: Display.identifier(for: level),
                            displayModel: .init(
                                title: Display.title(for: level),
                                supportingText: Display.description(for: level),
                                illust: Display.illust(for: level),
                            ),
                        )
                    },
                    selection: Binding(
                        get: { store.careerLevel.map(Display.identifier(for:)) },
                        set: { identifier in
                            if let identifier, let level = Display.level(forIdentifier: identifier) {
                                send(.careerLevelSelected(level))
                            }
                        },
                    ),
                )
            }
            .designSystemScreenMargin()
            .padding(.top, LayoutToken.margin)
        } footer: {
            BottomActionBar {
                VStack(spacing: LayoutToken.gutter) {
                    StyledText(text: LocalizedText.Onboarding.CareerSelection.guidance)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)

                    FeedbackActionButton(
                        title: LocalizedText.Onboarding.CareerSelection.Next.buttonTitle,
                        action: { send(.submitTapped) },
                    )
                    .enabled(store.careerLevel != nil && store.submission != .submitting)
                }
                .designSystemScreenMargin()
            }
        }
    }

}

extension CareerSelectionScreen {
    fileprivate enum Display {
        static let orderedLevels: [CareerLevel] = [.entry, .junior, .middle, .senior]

        static func identifier(for level: CareerLevel) -> String {
            switch level {
            case .entry: "entry"
            case .junior: "junior"
            case .middle: "midLevel"
            case .senior: "senior"
            }
        }

        static func level(forIdentifier identifier: String) -> CareerLevel? {
            orderedLevels.first { Self.identifier(for: $0) == identifier }
        }

        static func title(for level: CareerLevel) -> String {
            switch level {
            case .entry: LocalizedText.Onboarding.CareerSelection.Entry.title
            case .junior: LocalizedText.Onboarding.CareerSelection.Junior.title
            case .middle: LocalizedText.Onboarding.CareerSelection.Middle.title
            case .senior: LocalizedText.Onboarding.CareerSelection.Senior.title
            }
        }

        static func description(for level: CareerLevel) -> String {
            switch level {
            case .entry: LocalizedText.Onboarding.CareerSelection.Entry.description
            case .junior: LocalizedText.Onboarding.CareerSelection.Junior.description
            case .middle: LocalizedText.Onboarding.CareerSelection.Middle.description
            case .senior: LocalizedText.Onboarding.CareerSelection.Senior.description
            }
        }

        static func illust(for level: CareerLevel) -> ResourceImage.Asset.Illust {
            switch level {
            case .entry: .levelEntry
            case .junior: .levelJunior
            case .middle: .levelMiddle
            case .senior: .levelSenior
            }
        }
    }

    fileprivate enum Constant {
        static let titleToOptionsSpacing: CGFloat = 64
    }
}
