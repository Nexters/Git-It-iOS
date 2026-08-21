import Testing

@testable import CompositionAdapter

@Suite("CompositionAdapter 컴파일 검증")
struct CompositionAdapterCompilationTests {
    @Test
    func `플레이스홀더 모듈을 불러온다`() {
        #expect(CompositionAdapterPlaceholder.isCompilationAvailable)
    }
}
