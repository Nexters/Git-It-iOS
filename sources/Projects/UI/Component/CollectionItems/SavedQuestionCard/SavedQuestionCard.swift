import DesignSystem
import SwiftUI

// MARK: - SavedQuestionCard

public struct SavedQuestionCard: View {

    // MARK: Lifecycle

    public init(
        metadata: String,
        prompt: String,
        actionTitle: String,
        isBookmarked: Bool = true,
        onActionTap: @escaping () -> Void = { },
        onBookmarkTap: @escaping () -> Void = { },
    ) {
        self.metadata = metadata
        self.prompt = prompt
        self.actionTitle = actionTitle
        self.isBookmarked = isBookmarked
        self.onActionTap = onActionTap
        self.onBookmarkTap = onBookmarkTap
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StyledText.body2(metadata, color: .grey300)
                .padding(.top, LayoutToken.cardTopPadding)
            StyledText.subtitle3(prompt)
                .padding(.top, Constant.promptTopPadding)
            HStack(spacing: Constant.actionRowSpacing) {
                bookmarkButton
                Spacer(minLength: 0)
                actionButton
            }
            .padding(.vertical, Constant.actionRowVerticalPadding)
        }
        .padding(.horizontal, Constant.contentPadding)
        .background(
            Color(designSystem: .cardBackground),
            in: RoundedRectangle(designSystem: .large),
        )
    }

    // MARK: Private

    private let metadata: String
    private let prompt: String
    private let actionTitle: String
    private let isBookmarked: Bool
    private let onActionTap: () -> Void
    private let onBookmarkTap: () -> Void

    private var bookmarkButton: some View {
        let icon: ResourceImage.Asset.Icon = isBookmarked ? .bookmarkFilled : .bookmark
        let tint: ColorToken = isBookmarked ? .blue100 : .grey300
        let accessibilityLabel = isBookmarked ? "저장 해제하기" : "저장하기"
        let accessibilityTraits: AccessibilityTraits = isBookmarked ? [.isButton, .isSelected] : .isButton

        return Button(action: onBookmarkTap) {
            ResourceImage(asset: .icon(icon), contentMode: .fit)
                .designSystemForeground(tint)
                .frame(width: Constant.bookmarkSize, height: Constant.bookmarkSize)
                .frame(
                    minWidth: ControlSizeToken.minimumTouch.cgFloatValue,
                    minHeight: ControlSizeToken.minimumTouch.cgFloatValue,
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(accessibilityTraits)
    }

    private var actionButton: some View {
        Button(action: onActionTap) {
            StyledText.body2(actionTitle, color: .grey700, alignment: .center)
                .frame(height: Constant.actionHeight)
                .frame(maxWidth: .infinity)
                .designSystemBackground(.blue100)
                .designSystemCornerRadius(.small)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: Constant.actionMaximumWidth)
        .designSystemControlSize(.minimumTouch)
    }

}

// MARK: SavedQuestionCard.Constant

extension SavedQuestionCard {
    fileprivate enum Constant {
        static let contentPadding: CGFloat = 18
        static let promptTopPadding: CGFloat = 10
        static let actionRowSpacing: CGFloat = 6
        static let actionRowVerticalPadding: CGFloat = 16
        static let bookmarkSize: CGFloat = 24
        static let actionHeight: CGFloat = 36
        static let actionMaximumWidth: CGFloat = 84
    }
}

#Preview("Saved Question Card") {
    VStack(spacing: LayoutToken.gutter) {
        SavedQuestionCard(
            metadata: "Now in Android · Set 2 · 문제 1",
            prompt: "BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
            actionTitle: "문제풀기",
            isBookmarked: true,
        )
        SavedQuestionCard(
            metadata: "Now in Android · Set 2 · 문제 2",
            prompt: "BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
            actionTitle: "문제풀기",
            isBookmarked: false,
        )
    }
    .frame(width: 350)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
