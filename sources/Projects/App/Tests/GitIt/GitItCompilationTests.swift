import Foundation
import Testing

@testable import GitIt

@Suite("GitIt 컴파일 검증")
struct GitItCompilationTests {

    // MARK: Internal

    @Test
    func `테스트 번들이 로드된다`() {
        #expect(Bundle.main.bundleIdentifier != nil)
    }

}
