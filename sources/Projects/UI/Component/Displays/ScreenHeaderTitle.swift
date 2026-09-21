import DesignSystem
import SwiftUI

public struct ScreenHeaderTitle: View {

    // MARK: Lifecycle

    public init(
        title: String? = nil,
        subtitle: String? = nil,
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    // MARK: Public

    public var body: some View {
        if title != nil || subtitle != nil {
            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    StyledText(text: title, style: .subtitle1)
                }

                if let subtitle {
                    StyledText(text: subtitle, style: .body2, color: .white30)
                }
            }
        }
    }

    // MARK: Private

    private let title: String?
    private let subtitle: String?

}

#Preview("Screen Header Title") {
    VStack(alignment: .leading, spacing: LayoutToken.margin) {
        ScreenHeaderTitle(title: "제목만 있는 헤더")
        ScreenHeaderTitle(title: "제목과 보조 설명", subtitle: "보조 설명입니다.")
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
