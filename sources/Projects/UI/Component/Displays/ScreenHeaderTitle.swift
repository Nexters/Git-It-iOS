import DesignSystem
import SwiftUI

// MARK: - ScreenHeaderTitle

public struct ScreenHeaderTitle: View {

    // MARK: Lifecycle

    public init(displayModel: DisplayModel) {
        self.displayModel = displayModel
    }

    // MARK: Public

    public var body: some View {
        if displayModel.title != nil || displayModel.subtitle != nil {
            VStack(alignment: .leading, spacing: 0) {
                if let title = displayModel.title {
                    StyledText(text: title)
                        .textStyle(.subtitle1)
                }

                if let subtitle = displayModel.subtitle {
                    StyledText(text: subtitle)
                        .textStyle(.body2)
                        .foregroundColorToken(.white30)
                }
            }
        }
    }

    // MARK: Private

    private let displayModel: DisplayModel

}

// MARK: ScreenHeaderTitle.DisplayModel

extension ScreenHeaderTitle {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String? = nil,
            subtitle: String? = nil,
        ) {
            self.title = title
            self.subtitle = subtitle
        }

        public let title: String?
        public let subtitle: String?
    }
}

#Preview("Screen Header Title") {
    VStack(alignment: .leading, spacing: LayoutToken.margin) {
        ScreenHeaderTitle(displayModel: .init(title: "제목만 있는 헤더"))
        ScreenHeaderTitle(displayModel: .init(title: "제목과 보조 설명", subtitle: "보조 설명입니다."))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
