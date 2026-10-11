import SwiftUI
import UIComponent
import UIKit

// MARK: - FeedbackActionButton

public struct FeedbackActionButton: View {

    // MARK: Lifecycle

    public init(
        title: String,
        action: @escaping () -> Void = { },
    ) {
        label = .title(title)
        self.action = action
    }

    public init(
        styledText: StyledText,
        action: @escaping () -> Void = { },
    ) {
        label = .styled(styledText)
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        switch label {
        case .title(let title):
            ActionButton(
                title: title,
                action: actionWithTapFeedback,
            )
            .style(style)
            .size(size)
            .enabled(isEnabled)

        case .styled(let styledText):
            ActionButton(
                styledText: styledText,
                action: actionWithTapFeedback,
            )
            .style(style)
            .size(size)
            .enabled(isEnabled)
        }
    }

    // MARK: Private

    private enum Label {
        case title(String)
        case styled(StyledText)
    }

    private static let tapFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private let label: Label
    private var style = ActionButton.Style.primary
    private var size = ActionButton.Size.large
    private var isEnabled = true
    private let action: () -> Void

    private func actionWithTapFeedback() {
        Self.tapFeedbackGenerator.impactOccurred()
        action()
    }

}

// MARK: FeedbackActionButton 상태 선언

extension FeedbackActionButton {
    public func enabled(_ isEnabled: Bool) -> Self {
        var copy = self
        copy.isEnabled = isEnabled
        return copy
    }
}

// MARK: StyleConfigurable

extension FeedbackActionButton: StyleConfigurable {
    public func style(_ style: ActionButton.Style) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: SizeConfigurable

extension FeedbackActionButton: SizeConfigurable {
    public func size(_ size: ActionButton.Size) -> Self {
        var copy = self
        copy.size = size
        return copy
    }
}
