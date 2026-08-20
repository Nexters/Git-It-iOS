import Testing

@testable import DataLearningProject

@Suite("DataLearningProject 컴파일 검증")
struct DataLearningProjectCompilationTests {
    @Test
    func `플레이스홀더 모듈을 불러온다`() {
        #expect(DataLearningProjectPlaceholder.isCompilationAvailable)
    }
}
