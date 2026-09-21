import DesignSystem
import SwiftUI

// MARK: - SavedQuestionCard

public struct SavedQuestionCard: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        isBookmarked: Binding<Bool>,
        onActionTap: @escaping () -> Void = { },
    ) {
        self.displayModel = displayModel
        _isBookmarked = isBookmarked
        self.onActionTap = onActionTap
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StyledText(text: displayModel.metadata)
                .textStyle(.body2)
                .foregroundColorToken(.grey300)
                .padding(.top, LayoutToken.cardTopPadding)
            StyledText(text: displayModel.prompt)
                .textStyle(.subtitle3)
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
            Color(designSystem: .grey600),
            in: RoundedRectangle(designSystem: .large),
        )
    }

    // MARK: Internal

    func toggleBookmark() {
        isBookmarked.toggle()
    }

    // MARK: Private

    @Binding private var isBookmarked: Bool

    private let displayModel: DisplayModel
    private let onActionTap: () -> Void

    private var bookmarkButton: some View {
        let icon: ResourceImage.Asset.Icon = isBookmarked ? .bookmarkFilled : .bookmark
        let tint: ColorToken = isBookmarked ? .blue100 : .grey300
        let accessibilityLabel = isBookmarked ? "저장 해제하기" : "저장하기"
        let accessibilityTraits: AccessibilityTraits = isBookmarked ? [.isButton, .isSelected] : .isButton

        return Button(action: { toggleBookmark() }) {
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
            StyledText(text: displayModel.actionTitle)
                .textStyle(.body2)
                .foregroundColorToken(.grey700)
                .multilineTextAlignment(.center)
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

// MARK: SavedQuestionCard.DisplayModel

extension SavedQuestionCard {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            metadata: String,
            prompt: String,
            actionTitle: String,
        ) {
            self.metadata = metadata
            self.prompt = prompt
            self.actionTitle = actionTitle
        }

        public let metadata: String
        public let prompt: String
        public let actionTitle: String
    }
}

#Preview("Saved Question Card") {
    VStack(spacing: LayoutToken.gutter) {
        SavedQuestionCard(
            displayModel: .init(
                metadata: "Now in Android · Set 2 · 문제 1",
                prompt: "BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
                actionTitle: "문제풀기",
            ),
            isBookmarked: .constant(true),
        )
        SavedQuestionCard(
            displayModel: .init(
                metadata: "Now in Android · Set 2 · 문제 2",
                prompt: "BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
                actionTitle: "문제풀기",
            ),
            isBookmarked: .constant(false),
        )
    }
    .frame(width: 350)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
