import ComposableArchitecture
import DesignSystem
import DomainUserInfo
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
                    StyledText(text: LocalizedText.Onboarding.careerSelectionTitle)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)

                    if store.submission == .failed {
                        StyledText(text: LocalizedText.Onboarding.careerSelectionSubmissionFailureMessage)
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
                    StyledText(text: LocalizedText.Onboarding.careerSelectionGuidance)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)

                    FeedbackActionButton(
                        title: LocalizedText.Onboarding.careerSelectionNextButtonTitle,
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
            case .entry: LocalizedText.Onboarding.careerSelectionEntryTitle
            case .junior: LocalizedText.Onboarding.careerSelectionJuniorTitle
            case .middle: LocalizedText.Onboarding.careerSelectionMiddleTitle
            case .senior: LocalizedText.Onboarding.careerSelectionSeniorTitle
            }
        }

        static func description(for level: CareerLevel) -> String {
            switch level {
            case .entry: LocalizedText.Onboarding.careerSelectionEntryDescription
            case .junior: LocalizedText.Onboarding.careerSelectionJuniorDescription
            case .middle: LocalizedText.Onboarding.careerSelectionMiddleDescription
            case .senior: LocalizedText.Onboarding.careerSelectionSeniorDescription
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
