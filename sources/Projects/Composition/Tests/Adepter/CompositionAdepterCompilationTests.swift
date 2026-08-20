import Testing

@testable import CompositionAdepter

@Suite("CompositionAdepter 컴파일 검증")
struct CompositionAdepterCompilationTests {
    @Test
    func `플레이스홀더 모듈을 불러온다`() {
        #expect(CompositionAdepterPlaceholder.isCompilationAvailable)
    }
}
