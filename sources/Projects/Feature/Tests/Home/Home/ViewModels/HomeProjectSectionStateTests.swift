import Testing

@testable import Feature

@Suite("HomeProjectSectionState")
struct HomeProjectSectionStateTests {

    @Test
    func `대기와 로딩은 모두 loading으로 접힌다`() {
        #expect(HomeProjectSectionState(.idle) == .loading)
        #expect(HomeProjectSectionState(.loading) == .loading)
    }

    @Test
    func `항목이 없는 페이지는 empty로 구분한다`() {
        #expect(HomeProjectSectionState(.loaded(HomeTestFixture.emptyPage)) == .empty)
    }

    @Test
    func `항목이 있는 페이지는 순서를 유지한 표시 값으로 변환한다`() {
        guard case .loaded(let displays) = HomeProjectSectionState(.loaded(HomeTestFixture.manyProjectsPage)) else {
            Issue.record("loaded 상태가 아닙니다")
            return
        }

        #expect(displays.map(\.title) == ["Repository 0", "Repository 1", "Repository 2", "Repository 3"])
    }

    @Test
    func `로딩 실패는 failed로 변환한다`() {
        #expect(HomeProjectSectionState(.failed(.unexpected)) == .failed)
    }

}
