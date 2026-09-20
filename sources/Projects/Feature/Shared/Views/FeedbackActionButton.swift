import SwiftUI
import UIComponent
import UIKit

// MARK: - FeedbackActionButton

public struct FeedbackActionButton: View {

    // MARK: Lifecycle

    public init(
        title: String,
        style: ActionButton.Style = .primary,
        size: ActionButton.Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) {
        label = .title(title)
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    public init(
        styledText: StyledText,
        style: ActionButton.Style = .primary,
        size: ActionButton.Size = .large,
        isEnabled: Bool = true,
        action: @escaping () -> Void = { },
    ) {
        label = .styled(styledText)
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        switch label {
        case .title(let title):
            ActionButton(
                title: title,
                style: style,
                size: size,
                isEnabled: isEnabled,
                action: actionWithTapFeedback,
            )

        case .styled(let styledText):
            ActionButton(
                styledText: styledText,
                style: style,
                size: size,
                isEnabled: isEnabled,
                action: actionWithTapFeedback,
            )
        }
    }

    // MARK: Private

    private enum Label {
        case title(String)
        case styled(StyledText)
    }

    private static let tapFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private let label: Label
    private let style: ActionButton.Style
    private let size: ActionButton.Size
    private let isEnabled: Bool
    private let action: () -> Void

    private func actionWithTapFeedback() {
        Self.tapFeedbackGenerator.impactOccurred()
        action()
    }

}
