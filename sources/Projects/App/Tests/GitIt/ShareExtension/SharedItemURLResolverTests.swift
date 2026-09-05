import Foundation
import Testing

// MARK: - SharedItemURLResolverTests

@Suite("SharedItemURLResolver")
struct SharedItemURLResolverTests {

    @Test
    func `URL 항목이 있으면 텍스트보다 먼저 사용한다`() async throws {
        let resolver = SharedItemURLResolver()
        let attachments: [any SharedItemAttachment] = [
            StubAttachment(text: "https://github.com/apple/swift-nio"),
            StubAttachment(url: try #require(URL(string: "https://github.com/apple/swift"))),
        ]

        let resolved = await resolver.resolve(from: attachments)

        #expect(resolved?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func `URL 항목이 없으면 텍스트를 URL로 변환한다`() async {
        let resolver = SharedItemURLResolver()
        let attachments: [any SharedItemAttachment] = [
            StubAttachment(text: "  https://github.com/apple/swift  ")
        ]

        let resolved = await resolver.resolve(from: attachments)

        #expect(resolved?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func `URL로 해석되는 첫 항목을 사용한다`() async throws {
        let resolver = SharedItemURLResolver()
        let attachments: [any SharedItemAttachment] = [
            StubAttachment(),
            StubAttachment(url: try #require(URL(string: "https://github.com/apple/swift"))),
            StubAttachment(url: try #require(URL(string: "https://github.com/apple/swift-nio"))),
        ]

        let resolved = await resolver.resolve(from: attachments)

        #expect(resolved?.absoluteString == "https://github.com/apple/swift")
    }

    @Test
    func `URL도 텍스트도 얻지 못하면 결과가 없다`() async {
        let resolver = SharedItemURLResolver()

        #expect(await resolver.resolve(from: [StubAttachment()]) == nil)
        #expect(await resolver.resolve(from: []) == nil)
    }

    @Test
    func `웹 주소가 아닌 텍스트는 변환하지 않는다`() {
        #expect(SharedItemURLResolver.url(fromText: "그냥 메모") == nil)
        #expect(SharedItemURLResolver.url(fromText: "gitit://project/1") == nil)
        #expect(SharedItemURLResolver.url(fromText: "") == nil)
    }

    // MARK: Private

    private struct StubAttachment: SharedItemAttachment {

        // MARK: Lifecycle

        init(
            url: URL? = nil,
            text: String? = nil,
        ) {
            self.url = url
            self.text = text
        }

        // MARK: Internal

        func loadURL() async -> URL? {
            url
        }

        func loadText() async -> String? {
            text
        }

        // MARK: Private

        private let url: URL?
        private let text: String?

    }

}
