import DesignSystem
import SwiftUI

// MARK: - WebSheet

public struct WebSheet: View {

    // MARK: Lifecycle

    public init(
        title: String,
        url: URL,
        onDismiss: @escaping () -> Void,
    ) {
        self.title = title
        self.url = url
        self.onDismiss = onDismiss
    }

    // MARK: Public

    public var body: some View {
        SheetSurface {
            VStack(spacing: 0) {
                HStack(spacing: LayoutToken.gutter) {
                    StyledText.subtitle1(title)

                    Spacer(minLength: 0)

                    IconGlassButton.neutral(icon: .x, label: "닫기", action: onDismiss)
                }
                .padding(.bottom, LayoutToken.gutter)

                WebContentView(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Private

    private let title: String
    private let url: URL
    private let onDismiss: () -> Void

}

#Preview("Web Sheet") {
    ZStack {
        Color(designSystem: .grey700)

        WebSheet(
            title: "서비스 이용 약관",
            url: URL(string: "https://example.com")!,
            onDismiss: { },
        )
    }
    .frame(width: 390, height: 700)
}
