import DesignSystem
import SwiftUI

public struct ScreenHeader: View {

    // MARK: Lifecycle

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        style: Style = .default,
        user: User? = nil,
        leading: Control? = .back,
        trailing: Control? = nil,
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.user = user
        self.leading = leading
        self.trailing = trailing
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
        avatar = nil
    }

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        style: Style = .default,
        user: User? = nil,
        leading: Control? = .back,
        trailing: Control? = nil,
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
        @ViewBuilder avatar: () -> some View,
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.user = user
        self.leading = leading
        self.trailing = trailing
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
        self.avatar = AnyView(avatar())
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: style.titleSpacing) {
            HStack(alignment: .top, spacing: LayoutToken.gutter.cgFloatValue) {
                if style.showsUserProfile {
                    userProfile
                } else if let leading {
                    IconGlassButton.neutral(
                        symbol: leading.symbol,
                        label: leading.label,
                        size: .small,
                        action: onLeadingTap,
                    )
                }

                if style.showsInlineTitle {
                    titleAndSubtitle
                }

                Spacer(minLength: 0)

                if let trailing {
                    IconGlassButton.neutral(
                        symbol: trailing.symbol,
                        label: trailing.label,
                        size: .small,
                        action: onTrailingTap,
                    )
                }
            }
            .frame(height: style.controlRowHeight, alignment: .top)

            if style.showsStackedTitle {
                titleAndSubtitle
            }
        }
        .padding(.top, style.topPadding)
        .padding(.bottom, Constant.bottomPadding)
    }

    // MARK: Private

    private let title: String?
    private let subtitle: String?
    private let style: Style
    private let user: User?
    private let leading: Control?
    private let trailing: Control?
    private let onLeadingTap: () -> Void
    private let onTrailingTap: () -> Void
    private let avatar: AnyView?

    @ViewBuilder
    private var userProfile: some View {
        if let user {
            HStack(spacing: Constant.userProfileSpacing) {
                avatar
                    .frame(width: Constant.avatarSize, height: Constant.avatarSize)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 0) {
                    StyledText.subtitle3(user.name)
                    StyledText.body3(user.role, color: .grey400)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var titleAndSubtitle: some View {
        if title != nil || subtitle != nil {
            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    StyledText.subtitle1(title)
                }

                if let subtitle {
                    StyledText.body2(subtitle, color: .white30)
                }
            }
        }
    }

}

#Preview("Screen Header") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ScreenHeader(
            title: "기본 헤더",
            trailing: .init(symbol: "ellipsis", label: "더 보기"),
        )
        ScreenHeader(
            title: "인라인 헤더",
            subtitle: "보조 설명",
            style: .inlineTitle,
            trailing: .init(symbol: "bookmark", label: "저장하기"),
        )
        ScreenHeader(
            style: .inlineUser,
            user: .init(name: "김이박", role: "Junior Developer"),
            leading: nil,
            trailing: .init(symbol: "gearshape", label: "설정 열기"),
        ) {
            ResourceImage(asset: .icon(.user), contentMode: .fill)
        }
        ScreenHeader(
            title: "큰 제목 헤더",
            subtitle: "화면의 주요 목적을 설명합니다.",
            style: .largeTitle,
            leading: nil,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
