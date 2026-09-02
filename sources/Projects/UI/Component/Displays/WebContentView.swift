import DesignSystem
import SwiftUI
import WebKit

// MARK: - WebContentView

public struct WebContentView: View {

    // MARK: Lifecycle

    public init(url: URL) {
        self.url = url
    }

    // MARK: Public

    public var body: some View {
        WebView(url: url)
            .webViewContentBackground(.hidden)
            .background(Color(designSystem: .cardBackground))
    }

    // MARK: Private

    private let url: URL

}

#Preview("Web Content View") {
    WebContentView(url: URL(string: "https://example.com")!)
}
