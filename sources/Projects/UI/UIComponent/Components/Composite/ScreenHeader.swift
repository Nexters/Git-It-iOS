import DesignSystem
import SwiftUI

public struct ScreenHeader: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel = .init(),
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
        avatar = nil
    }

    /// 아바타 슬롯을 `AnyView`로 지워 비제네릭을 유지하고 보조 타입을 계속 중첩합니다.
    public init(
        viewModel: ViewModel = .init(),
        onLeadingTap: @escaping () -> Void = { },
        onTrailingTap: @escaping () -> Void = { },
        @ViewBuilder avatar: () -> some View,
    ) {
        self.viewModel = viewModel
        self.onLeadingTap = onLeadingTap
        self.onTrailingTap = onTrailingTap
        self.avatar = AnyView(avatar())
    }

    // MARK: Public

    public enum Style: Sendable, Equatable {
        case `default`
        case inlineTitle
        case inlineUser
        case largeTitle

        // MARK: Internal

        /// `inlineUser`만 아바타를 세로로 감싸므로 컨트롤 행이 더 높습니다.
        var controlRowHeight: CGFloat {
            switch self {
            case .inlineUser:
                66
            case .default,
                 .inlineTitle,
                 .largeTitle:
                40
            }
        }

        var topPadding: CGFloat {
            switch self {
            case .inlineUser:
                22
            case .default,
                 .inlineTitle,
                 .largeTitle:
                0
            }
        }

        /// 제목을 컨트롤 행 아래에 따로 쌓는 `largeTitle`에만 간격이 필요합니다.
        var titleSpacing: CGFloat {
            switch self {
            case .largeTitle:
                16
            case .default,
                 .inlineTitle,
                 .inlineUser:
                0
            }
        }

        var showsInlineTitle: Bool {
            self == .inlineTitle
        }

        var showsStackedTitle: Bool {
            self == .largeTitle
        }

        var showsUserProfile: Bool {
            self == .inlineUser
        }
    }

    public struct Control: Sendable, Equatable {
        public init(
            symbol: String,
            label: String,
        ) {
            self.symbol = symbol
            self.label = label
        }

        public static let back = Control(
            symbol: "chevron.left",
            label: "뒤로 가기",
        )
        public static let close = Control(
            symbol: "xmark",
            label: "닫기",
        )

        public let symbol: String
        public let label: String
    }

    public struct User: Sendable, Equatable {
        public init(
            name: String,
            role: String,
        ) {
            self.name = name
            self.role = role
        }

        public let name: String
        public let role: String
    }

    public struct ViewModel: Sendable, Equatable {

        // MARK: Lifecycle

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            style: Style = .default,
            user: User? = nil,
            leading: Control? = .back,
            trailing: Control? = nil,
        ) {
            self.title = title
            self.subtitle = subtitle
            self.style = style
            self.user = user
            self.leading = leading
            self.trailing = trailing
        }

        // MARK: Public

        public let title: String?
        public let subtitle: String?
        public let style: Style
        public let user: User?
        public let leading: Control?
        public let trailing: Control?

    }

    public var body: some View {
        VStack(alignment: .leading, spacing: viewModel.style.titleSpacing) {
            HStack(alignment: .top, spacing: LayoutToken.gutter.cgFloatValue) {
                if viewModel.style.showsUserProfile {
                    userProfile
                } else if let leading = viewModel.leading {
                    IconGlassButton.neutral(
                        symbol: leading.symbol,
                        label: leading.label,
                        action: onLeadingTap,
                    )
                }

                if viewModel.style.showsInlineTitle {
                    titleAndSubtitle
                }

                Spacer(minLength: 0)

                if let trailing = viewModel.trailing {
                    IconGlassButton.neutral(
                        symbol: trailing.symbol,
                        label: trailing.label,
                        action: onTrailingTap,
                    )
                }
            }
            .frame(height: viewModel.style.controlRowHeight, alignment: .top)

            if viewModel.style.showsStackedTitle {
                titleAndSubtitle
            }
        }
        .padding(.top, viewModel.style.topPadding)
        .padding(.bottom, Constant.bottomPadding)
    }

    // MARK: Private

    private enum Constant {
        static let bottomPadding: CGFloat = 10
        static let userProfileSpacing: CGFloat = 11
        static let avatarSize: CGFloat = 40
    }

    private let viewModel: ViewModel
    private let onLeadingTap: () -> Void
    private let onTrailingTap: () -> Void
    private let avatar: AnyView?

    @ViewBuilder
    private var userProfile: some View {
        if let user = viewModel.user {
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
        if viewModel.title != nil || viewModel.subtitle != nil {
            VStack(alignment: .leading, spacing: 0) {
                if let title = viewModel.title {
                    StyledText.subtitle1(title)
                }

                if let subtitle = viewModel.subtitle {
                    StyledText.body2(subtitle, color: .white30)
                }
            }
        }
    }

}

#Preview("Screen Header") {
    VStack(spacing: LayoutToken.margin.cgFloatValue) {
        ScreenHeader(
            viewModel: .init(
                title: "기본 헤더",
                trailing: .init(symbol: "ellipsis", label: "더 보기"),
            )
        )
        ScreenHeader(
            viewModel: .init(
                title: "인라인 헤더",
                subtitle: "보조 설명",
                style: .inlineTitle,
                trailing: .init(symbol: "bookmark", label: "저장하기"),
            )
        )
        ScreenHeader(
            viewModel: .init(
                style: .inlineUser,
                user: .init(name: "김이박", role: "Junior Developer"),
                leading: nil,
                trailing: .init(symbol: "gearshape", label: "설정 열기"),
            )
        ) {
            ResourceImage(viewModel: .init(asset: .profile, contentMode: .fill))
        }
        ScreenHeader(
            viewModel: .init(
                title: "큰 제목 헤더",
                subtitle: "화면의 주요 목적을 설명합니다.",
                style: .largeTitle,
                leading: nil,
            )
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
