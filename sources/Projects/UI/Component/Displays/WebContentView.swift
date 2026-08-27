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
    }

    // MARK: Private

    private let url: URL

}

#Preview("Web Content View") {
    WebContentView(url: URL(string: "https://example.com")!)
}
