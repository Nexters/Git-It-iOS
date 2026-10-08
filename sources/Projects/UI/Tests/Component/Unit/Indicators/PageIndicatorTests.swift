import DesignSystem
import Testing

@testable import UIComponent

@Suite("PageIndicator 계약")
struct PageIndicatorTests {
    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = PageIndicator(displayModel: .init(
            currentPage: 0,
            totalPages: 3,
        ))
    }
}
