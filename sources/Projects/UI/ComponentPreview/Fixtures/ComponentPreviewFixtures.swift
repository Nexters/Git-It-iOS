import DesignSystem
import SwiftUI
import UIComponent

struct ComponentPreviewFixtures: View {

    // MARK: Internal

    static let entries: [ComponentPreviewEntry] = [
        entry(
            "action-button",
            .leaf,
            ["primary", "secondary", "destructive", "text"],
            ["large", "medium", "small"],
            ["enabled", "disabled", "pressing"],
        ),
        entry("continuous-progress-bar", .leaf, [], [], ["zero", "partial", "complete", "clamped"]),
        entry("icon-glass-button", .leaf, ["neutral", "accent", "destructive"], ["medium", "small"], ["enabled"]),
        entry("icon-plain-button", .leaf, ["asset"], ["default"], ["enabled"]),
        entry("progress-segments", .leaf, [], [], ["empty", "partial", "complete", "out-of-range"]),
        entry("resource-animation", .leaf, ["supported"], [], ["looping", "completion", "reduce-motion-fallback"]),
        entry("resource-image", .leaf, ["fit", "fill"], [], ["supported", "fallback"]),
        entry("screen-edge-scrim", .leaf, ["top", "bottom"], [], ["pass-through"]),
        entry("styled-text", .leaf, ["typography", "color", "alignment"], [], ["long-text", "maximum-dynamic-type"]),
        entry("tag-badge", .leaf, ["neutral", "accent", "selected"], [], ["long-text"]),
        entry("action-menu", .composite, ["items"], [], ["selection", "long-text"]),
        entry("bottom-action-bar", .composite, ["content"], [], ["default"]),
        entry("empty-state", .composite, ["illustration"], [], ["default", "long-text"]),
        entry("home-project-card", .composite, ["purple", "light-blue", "dark-blue"], [], ["progress", "callback"]),
        entry("onboarding-mockup", .composite, ["page-1", "page-2", "page-3"], [], ["mapped"]),
        entry("project-row", .composite, ["default", "deleting"], [], ["progress", "callback", "long-text"]),
        entry("saved-question-card", .composite, ["content"], [], ["action", "long-text"]),
        entry("screen-container", .composite, ["default-background", "explicit-background"], [], ["content"]),
        entry(
            "screen-header",
            .composite,
            ["default", "inline-title", "inline-user", "large-title"],
            [],
            ["controls", "avatar", "callbacks"],
        ),
        entry("selection-card", .composite, ["selected", "unselected"], [], ["optional-text", "thumbnail"]),
        entry("selection-card-list", .composite, ["items"], [], ["nil-selection", "selection", "external-update", "reorder"]),
        entry("sheet-surface", .composite, ["grabber"], [], ["content"]),
        entry("tab-shell", .composite, ["home", "project", "saved", "profile"], [], ["selection", "parent-update"]),
    ]

    let environment: ComponentPreviewEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.margin.cgFloatValue) {
            actionButtons
            projectRows
            sheetSurface
            progressBars
            actionMenu
            edgeScrims
            iconButtons
            TagBadge.accent("Layout")
                .accessibilityIdentifier("tag.accent")
        }
    }

    // MARK: Private

    @State private var selectedActionMenuItemID = "none"
    @State private var topScrimTapCount = 0
    @State private var bottomScrimTapCount = 0

    private var actionButtons: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ActionButton.primary("Large").accessibilityIdentifier("action.large.primary")
            ActionButton.primary("Large Disabled", isEnabled: false)
                .accessibilityIdentifier("action.large.disabled")
            ActionButton.primary("Medium", size: .medium)
                .accessibilityIdentifier("action.medium.primary")
            ActionButton.primary("Small", size: .small)
                .accessibilityIdentifier("action.small.primary")
        }
        .frame(width: 240)
    }

    private var projectRows: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ProjectRow(
                name: environment.usesMaximumDynamicType ? "Git It iOS 접근성 레이아웃 검증" : "Git It iOS",
                supportingText: "Swift · SwiftUI · TCA",
                progress: 0.65,
                currentSet: 2,
                setTitle: environment.usesMaximumDynamicType ? "Presentation 구조와 상태 흐름" : "Presentation 구조",
            ) { projectThumbnail(identifier: "project.row.default.thumbnail") }
                .frame(width: 320)
                .accessibilityIdentifier("project.row.default")

            ProjectRow(
                name: "삭제할 프로젝트",
                supportingText: "Kotlin · Compose",
                progress: 0,
                currentSet: 1,
                setTitle: "기본 개념",
                isDeleting: true,
            ) { projectThumbnail(identifier: "project.row.delete.thumbnail") }
                .frame(width: 320)
                .accessibilityIdentifier("project.row.delete")
        }
    }

    private var sheetSurface: some View {
        SheetSurface {
            Rectangle()
                .fill(Color(designSystem: .purple300))
                .frame(height: 20)
                .accessibilityElement()
                .accessibilityIdentifier("sheet.surface.content.marker")
        }
        .frame(width: 360)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.surface")
    }

    private var progressBars: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            progressBar(0, identifier: "progress.zero")
            progressBar(0.65, identifier: "progress.continuous")
            progressBar(1, identifier: "progress.complete")
        }
    }

    private var actionMenu: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            ActionMenu(
                items: [
                    .init(id: "delete", title: "프로젝트 삭제", accessibilityLabel: "학습 프로젝트 삭제 모드 열기"),
                    .init(id: "close", title: "메뉴 닫기", accessibilityLabel: "프로젝트 메뉴 닫기"),
                ],
                onSelect: { selectedActionMenuItemID = $0 },
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("action.menu")

            stateMarker(label: "선택된 메뉴 항목 ID", value: selectedActionMenuItemID, identifier: "action.menu.selection")
        }
    }

    private var edgeScrims: some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            scrimButton(
                title: "상단 스크림 뒤 버튼",
                label: "상단 스크림 뒤 컨트롤",
                identifier: "scrim.top",
                marker: "scrim.top.tap.count",
                height: 103,
                count: $topScrimTapCount,
                scrim: { ScreenEdgeScrim.top() },
            )
            scrimButton(
                title: "하단 스크림 뒤 버튼",
                label: "하단 스크림 뒤 컨트롤",
                identifier: "scrim.bottom",
                marker: "scrim.bottom.tap.count",
                height: 127,
                count: $bottomScrimTapCount,
                scrim: { ScreenEdgeScrim.bottom() },
            )
        }
    }

    private var iconButtons: some View {
        VStack(alignment: .leading) {
            GlassEffectContainer(spacing: LayoutToken.margin.cgFloatValue) {
                HStack(spacing: LayoutToken.margin.cgFloatValue) {
                    IconGlassButton.neutral(symbol: "chevron.left", label: "Medium icon", size: .medium)
                        .accessibilityIdentifier("iconGlass.medium.neutral")
                    IconGlassButton.neutral(symbol: "chevron.left", label: "Small icon", size: .small)
                        .accessibilityIdentifier("iconGlass.small.neutral")
                }
            }
            IconPlainButton(symbol: "ic-play-1", label: "Plain icon")
                .accessibilityIdentifier("iconPlain.default")
        }
    }

    private static func entry(
        _ id: String,
        _ category: ComponentPreviewEntry.Category,
        _ variants: [String],
        _ sizes: [String],
        _ states: [String],
    ) -> ComponentPreviewEntry {
        ComponentPreviewEntry(
            componentID: id,
            displayName: id,
            category: category,
            variants: variants,
            sizes: sizes,
            states: states,
            factoryIDs: ["fixture.\(id)"],
        )
    }

    private func progressBar(
        _ progress: Double,
        identifier: String,
    ) -> some View {
        ContinuousProgressBar(progress: progress)
            .frame(width: 320)
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

    private func scrimButton(
        title: String,
        label: String,
        identifier: String,
        marker: String,
        height: CGFloat,
        count: Binding<Int>,
        @ViewBuilder scrim: () -> some View,
    ) -> some View {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            Button { count.wrappedValue += 1 } label: {
                Text(title).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .frame(width: 320, height: height)
            .background(Color(designSystem: .purple300))
            .overlay { scrim() }
            .accessibilityLabel(label)
            .accessibilityIdentifier(identifier)

            stateMarker(label: "통과 탭 횟수", value: String(count.wrappedValue), identifier: marker)
        }
    }

}
