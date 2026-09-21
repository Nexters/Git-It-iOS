import DesignSystem
import SwiftUI

// MARK: - WebSheet

public struct WebSheet: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        onDismiss: @escaping () -> Void,
    ) {
        self.displayModel = displayModel
        self.onDismiss = onDismiss
    }

    // MARK: Public

    public var body: some View {
        SheetSurface {
            VStack(spacing: 0) {
                HStack(spacing: LayoutToken.gutter) {
                    StyledText(text: displayModel.title)
                        .textStyle(.subtitle1)

                    Spacer(minLength: 0)

                    IconGlassButton(icon: .close, label: "닫기", action: onDismiss)
                }
                .padding(.bottom, LayoutToken.gutter)

                WebContentView(url: displayModel.url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Private

    private let displayModel: DisplayModel
    private let onDismiss: () -> Void

}

// MARK: WebSheet.DisplayModel

extension WebSheet {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String,
            url: URL,
        ) {
            self.title = title
            self.url = url
        }

        public let title: String
        public let url: URL
    }
}

#Preview("Web Sheet") {
    ZStack {
        Color(designSystem: .grey700)

        WebSheet(
            displayModel: .init(title: "서비스 이용 약관", url: URL(string: "https://example.com")!),
            onDismiss: { },
        )
    }
    .frame(width: 390, height: 700)
}
