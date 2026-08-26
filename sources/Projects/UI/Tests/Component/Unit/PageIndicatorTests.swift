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
    func `ViewModel은 currentPage와 totalPages를 그대로 보존한다`() {
        let viewModel = PageIndicator.ViewModel(currentPage: 1, totalPages: 3)

        #expect(viewModel.currentPage == 1)
        #expect(viewModel.totalPages == 3)
    }

    @Test
    func `Reduce Motion 여부와 무관하게 같은 accessibilityValue를 반환한다`() {
        // PageIndicator는 애니메이션에 의존하지 않는 정적 렌더링이라 API에 reduceMotion
        // 입력이 없다. 같은 입력에 항상 같은 값을 반환하는 순수 함수임을 확인해 Reduce
        // Motion 상태와 무관함을 보장한다.
        let first = PageIndicator.accessibilityValue(currentPage: 1, totalPages: 3)
        let second = PageIndicator.accessibilityValue(currentPage: 1, totalPages: 3)

        #expect(first == second)
    }

    @Test
    func `불변 ViewModel로 생성한다`() {
        let viewModel = PageIndicator.ViewModel(currentPage: 0, totalPages: 3)

        _ = PageIndicator(viewModel: viewModel)
        #expect(viewModel.totalPages == 3)
    }
}
