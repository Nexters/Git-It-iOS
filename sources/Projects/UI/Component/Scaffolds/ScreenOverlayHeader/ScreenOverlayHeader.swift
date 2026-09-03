import DesignSystem
import SwiftUI

// MARK: - ScreenOverlayHeader

public struct ScreenOverlayHeader: View {

    // MARK: Lifecycle

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        style: ScreenHeader.Style = .default,
        leading: ScreenHeader.Control? = .back,
        trailing: ScreenHeader.Control? = nil,
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.leading = leading
        self.trailing = trailing
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
    }

    // MARK: Public

    public var body: some View {
        ScreenHeader(
            title: title,
            subtitle: subtitle,
            style: style,
            leading: leading,
            trailing: trailing,
            onLeadingTap: onLeadingTap,
            onTrailingTap: onTrailingTap,
        )
        .designSystemScreenMargin()
        .background(alignment: .top) { scrim }
    }

    // MARK: Private

    private let title: String?
    private let subtitle: String?
    private let style: ScreenHeader.Style
    private let leading: ScreenHeader.Control?
    private let trailing: ScreenHeader.Control?
    private let onLeadingTap: () -> Void
    private let onTrailingTap: () -> Void

    private var scrim: some View {
        GeometryReader { proxy in
            ScreenEdgeScrim.top(height: proxy.safeAreaInsets.top + style.height)
        }
        .ignoresSafeArea(edges: .top)
    }

}

#Preview("Screen Overlay Header") {
    OverlayContainer {
        ScreenOverlayHeader(
            title: "저장한 문제",
            style: .largeTitle,
        )
    } content: {
        VStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ForEach(0..<12, id: \.self) { index in
                LabeledCard.neutral(label: "항목 \(index)", text: "스크롤하면 헤더 뒤로 지나갑니다.")
            }
        }
        .designSystemScreenMargin()
    }
}
