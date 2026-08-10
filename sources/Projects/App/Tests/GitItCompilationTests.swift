import Foundation
import Testing

@Suite("GitIt 컴파일 검증")
struct GitItCompilationTests {
    @Test
    func `테스트 번들이 로드된다`() {
        #expect(Bundle.main.bundleIdentifier != nil)
    }
}
