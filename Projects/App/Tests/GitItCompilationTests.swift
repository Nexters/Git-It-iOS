import Foundation
import Testing

@Suite("GitIt 컴파일 검증")
struct GitItCompilationTests {
    @Test("테스트 번들이 로드된다")
    func bundleLoads() {
        #expect(Bundle.main.bundleIdentifier != nil)
    }
}
