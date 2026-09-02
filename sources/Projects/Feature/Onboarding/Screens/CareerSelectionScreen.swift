import ComposableArchitecture
import DesignSystem
import DomainMember
import SwiftUI
import UIComponent

// MARK: - CareerSelectionScreen

@ViewAction(for: CurationFeature.self)
struct CareerSelectionScreen: View {

    // MARK: Internal

    enum Display {
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
            case .entry: "입문"
            case .junior: "주니어"
            case .middle: "미들"
            case .senior: "시니어"
            }
        }

        static func description(for level: CareerLevel) -> String {
            switch level {
            case .entry: "프로젝트 코드를 처음 살펴봐요."
            case .junior: "작은 기능 단위로 코드를 이해할 수 있어요."
            case .middle: "프로젝트 구조와 흐름을 함께 살펴봐요."
            case .senior: "설계 의도와 변경 영향을 분석할 수 있어요."
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

    @Bindable var store: StoreOf<CurationFeature>

    var body: some View {
        ScreenContainer { layoutMetrics in
            VStack(spacing: 0) {
                ScreenHeader(
                    leading: .back,
                    onLeadingTap: { send(.careerBackTapped) },
                )

                ScrollView {
                    VStack(spacing: Constant.titleToOptionsSpacing) {
                        VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                            StyledText.subtitle1(Constant.title, alignment: .center)

                            if store.selection.submission == .failed {
                                StyledText.caption1(
                                    "제출에 실패했어요. 다시 시도해 주세요.",
                                    color: .error,
                                    alignment: .center,
                                )
                            }
                        }

                        SelectionCardList(
                            items: Display.orderedLevels.map { level in
                                .init(
                                    id: Display.identifier(for: level),
                                    title: Display.title(for: level),
                                    supportingText: Display.description(for: level),
                                    illust: Display.illust(for: level),
                                    isSelected: store.selection.careerLevel == level,
                                )
                            },
                            onSelect: { identifier in
                                if let level = Display.level(forIdentifier: identifier) {
                                    send(.careerLevelSelected(level))
                                }
                            },
                        )
                    }
                    .padding(.top, LayoutToken.margin.cgFloatValue)
                }

                BottomActionBar(layoutMetrics: layoutMetrics) {
                    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
                        StyledText.caption1(Constant.guidance, color: .grey400, alignment: .center)

                        ActionButton.primary(
                            "다음",
                            isEnabled: store.selection.careerLevel != nil && store.selection.submission != .submitting,
                            action: { send(.curationSubmitTapped) },
                        )
                    }
                }
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let title = "실제 프로젝트 코드를\n어느 정도 이해할 수 있나요?"
        static let guidance = "정답은 없어요. 현재 가장 가까운 수준을 선택해주세요."
        static let titleToOptionsSpacing: CGFloat = 64
    }

}
