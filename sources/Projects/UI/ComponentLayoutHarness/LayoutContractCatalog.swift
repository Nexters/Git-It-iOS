import DesignSystem
import Foundation
import SwiftUI
import UIComponent

// MARK: - LayoutContractCatalog

struct LayoutContractCatalog: View {

    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutToken.margin.cgFloatValue) {
                Text("Figma 레이아웃 계약")
                    .font(.title2.bold())

                actionButtonContracts
                projectRowContracts
                sheetSurfaceContract
                progressBarContract
                actionMenuContract
                edgeScrimContracts

                GlassEffectContainer(spacing: LayoutToken.margin.cgFloatValue) {
                    HStack(spacing: LayoutToken.margin.cgFloatValue) {
                        IconGlassButton.neutral(
                            symbol: "chevron.left",
                            label: "Medium icon",
                            size: .medium,
                        )
                        .accessibilityIdentifier("iconGlass.medium.neutral")

                        IconGlassButton.neutral(
                            symbol: "chevron.left",
                            label: "Small icon",
                            size: .small,
                        )
                        .accessibilityIdentifier("iconGlass.small.neutral")
                    }
                }

                IconPlainButton(
                    viewModel: .init(symbol: "ic-play-1", label: "Plain icon")
                )
                .accessibilityIdentifier("iconPlain.default")

                TagBadge.accent("Layout")
                    .accessibilityIdentifier("tag.accent")
            }
            .designSystemScreenMargin()
            .padding(.vertical, LayoutToken.margin.cgFloatValue)
        }
        .accessibilityIdentifier("layout.contract.catalog")
        .designSystemBackground(.grey700)
        .dynamicTypeSize(usesMaximumDynamicType ? .accessibility5 : .large)
        .preferredColorScheme(.dark)
    }

    // MARK: Private

    private enum Constant {
        static let actionButtonWidth: CGFloat = 240
        static let componentWidth: CGFloat = 320
        static let sheetWidth: CGFloat = 360
        static let markerHeight: CGFloat = 20
        static let topScrimHeight: CGFloat = 103
        static let bottomScrimHeight: CGFloat = 127
    }

    @State private var selectedActionMenuItemID = "none"
    @State private var topScrimTapCount = 0
    @State private var bottomScrimTapCount = 0

    private var usesMaximumDynamicType: Bool {
        ProcessInfo.processInfo.arguments.contains("--maximum-dynamic-type")
    }

    private var actionButtonContracts: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ActionButton.primary("Large")
                .accessibilityIdentifier("action.large.primary")

            ActionButton.primary("Large Disabled", isEnabled: false)
                .accessibilityIdentifier("action.large.disabled")

            ActionButton.primary("Medium", size: .medium)
                .accessibilityIdentifier("action.medium.primary")

            ActionButton.primary("Small", size: .small)
                .accessibilityIdentifier("action.small.primary")
        }
        .frame(width: Constant.actionButtonWidth)
    }

    private var projectRowContracts: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ProjectRow(
                viewModel: .init(
                    name: usesMaximumDynamicType
                        ? "Git It iOS 접근성 레이아웃 검증"
                        : "Git It iOS",
                    supportingText: "Swift · SwiftUI · TCA",
                    progress: 0.65,
                    currentSet: 2,
                    setTitle: usesMaximumDynamicType
                        ? "Presentation 구조와 상태 흐름"
                        : "Presentation 구조",
                )
            ) {
                projectThumbnail(identifier: "project.row.default.thumbnail")
            }
            .frame(width: Constant.componentWidth)
            .accessibilityIdentifier("project.row.default")

            ProjectRow(
                viewModel: .init(
                    name: "삭제할 프로젝트",
                    supportingText: "Kotlin · Compose",
                    progress: 0,
                    currentSet: 1,
                    setTitle: "기본 개념",
                    isDeleting: true,
                )
            ) {
                projectThumbnail(identifier: "project.row.delete.thumbnail")
            }
            .frame(width: Constant.componentWidth)
            .accessibilityIdentifier("project.row.delete")
        }
    }

    private var sheetSurfaceContract: some View {
        SheetSurface {
            Rectangle()
                .fill(Color(designSystem: .purple300))
                .frame(height: Constant.markerHeight)
                .accessibilityElement()
                .accessibilityIdentifier("sheet.surface.content.marker")
        }
        .frame(width: Constant.sheetWidth)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.surface")
    }

    private var progressBarContract: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            progressBar(progress: 0, identifier: "progress.zero")
            progressBar(progress: 0.65, identifier: "progress.continuous")
            progressBar(progress: 1, identifier: "progress.complete")
        }
    }

    private var actionMenuContract: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            ActionMenu(
                viewModel: .init(items: [
                    .init(
                        id: "delete",
                        title: "프로젝트 삭제",
                        accessibilityLabel: "학습 프로젝트 삭제 모드 열기",
                    ),
                    .init(
                        id: "close",
                        title: "메뉴 닫기",
                        accessibilityLabel: "프로젝트 메뉴 닫기",
                    ),
                ]),
                onSelect: { selectedActionMenuItemID = $0 },
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("action.menu")

            stateMarker(
                label: "선택된 메뉴 항목 ID",
                value: selectedActionMenuItemID,
                identifier: "action.menu.selection",
            )
        }
    }

    private var edgeScrimContracts: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            VStack(spacing: LayoutToken.gutter.cgFloatValue) {
                Button {
                    topScrimTapCount += 1
                } label: {
                    Text("상단 스크림 뒤 버튼")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .frame(width: Constant.componentWidth, height: Constant.topScrimHeight)
                .background(Color(designSystem: .purple300))
                .overlay { ScreenEdgeScrim.top() }
                .accessibilityLabel("상단 스크림 뒤 컨트롤")
                .accessibilityIdentifier("scrim.top")

                stateMarker(
                    label: "상단 스크림 통과 탭 횟수",
                    value: String(topScrimTapCount),
                    identifier: "scrim.top.tap.count",
                )
            }

            VStack(spacing: LayoutToken.gutter.cgFloatValue) {
                Button {
                    bottomScrimTapCount += 1
                } label: {
                    Text("하단 스크림 뒤 버튼")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .frame(width: Constant.componentWidth, height: Constant.bottomScrimHeight)
                .background(Color(designSystem: .purple300))
                .overlay { ScreenEdgeScrim.bottom() }
                .accessibilityLabel("하단 스크림 뒤 컨트롤")
                .accessibilityIdentifier("scrim.bottom")

                stateMarker(
                    label: "하단 스크림 통과 탭 횟수",
                    value: String(bottomScrimTapCount),
                    identifier: "scrim.bottom.tap.count",
                )
            }
        }
    }

    private func progressBar(
        progress: Double,
        identifier: String,
    ) -> some View {
        ContinuousProgressBar(viewModel: .init(progress: progress))
            .frame(width: Constant.componentWidth)
            .accessibilityIdentifier(identifier)
    }

    private func stateMarker(
        label: String,
        value: String,
        identifier: String,
    ) -> some View {
        Text(value)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityIdentifier(identifier)
    }

    private func projectThumbnail(identifier: String) -> some View {
        RoundedRectangle(designSystem: .small)
            .fill(Color(designSystem: .purple300))
            .accessibilityElement()
            .accessibilityIdentifier(identifier)
    }

}
