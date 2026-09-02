import DesignSystem
import SwiftUI

/// 크기 결정 방식은 `SizingMode.fill`.
public struct SavedQuestionCard: View {

    // MARK: Lifecycle

    public init(
        metadata: String,
        prompt: String,
        actionTitle: String,
        onActionTap: @escaping () -> Void = { },
    ) {
        self.metadata = metadata
        self.prompt = prompt
        self.actionTitle = actionTitle
        self.onActionTap = onActionTap
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading) {
            StyledText.caption1(metadata, color: .grey300)
                .padding(.top, 14)
            StyledText.subtitle3(prompt)
                .padding(.top, 10)
            HStack {
                Image("ic-bookmark-filled", bundle: .module)
                    .designSystemForeground(.brandAccent)
                    .padding(.horizontal, 10)
                Spacer()
                Button(action: onActionTap) {
                    StyledText.body2(actionTitle, color: .grey700, alignment: .center)
                        .frame(height: Constant.actionHeight)
                        .frame(maxWidth: .infinity)
                        .designSystemBackground(.blue100)
                        .designSystemCornerRadius(.small)
                }
                .buttonStyle(.pressOverlay)
                .frame(maxWidth: Constant.actionMaximumWidth)
                .designSystemControlSize(.minimumTouch)
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, Constant.contentPadding)
        .background(
            Color(designSystem: .cardBackground),
            in: RoundedRectangle(designSystem: .large),
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let metadata: String
    private let prompt: String
    private let actionTitle: String
    private let onActionTap: () -> Void

}

#Preview("Saved Question Card") {
    SavedQuestionCard(
        metadata: "Now in Android · Set 2 · 문제 1",
        prompt: "BlueprintSetupState 클래스는 어떤 목적을 가진 객체인가?",
        actionTitle: "문제풀기",
    )
    .frame(width: 350)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
