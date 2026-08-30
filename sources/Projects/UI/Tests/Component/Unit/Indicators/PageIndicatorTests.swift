import DesignSystem
import Testing

@testable import UIComponent

@Suite("PageIndicator 계약")
struct PageIndicatorTests {
    @Test
    func `accessibilityValue는 색상과 무관하게 현재 전체 페이지를 문자열로 전달한다`() {
        #expect(PageIndicator.accessibilityValue(currentPage: 0, totalPages: 3) == "전체 3페이지 중 1번째")
        #expect(PageIndicator.accessibilityValue(currentPage: 2, totalPages: 3) == "전체 3페이지 중 3번째")
    }

    @Test
    func `Reduce Motion 여부와 무관하게 같은 accessibilityValue를 반환한다`() {
        let first = PageIndicator.accessibilityValue(currentPage: 1, totalPages: 3)
        let second = PageIndicator.accessibilityValue(currentPage: 1, totalPages: 3)

        #expect(first == second)
    }

    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = PageIndicator(currentPage: 0, totalPages: 3)
    }
}
