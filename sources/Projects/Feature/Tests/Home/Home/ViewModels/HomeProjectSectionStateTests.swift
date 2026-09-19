import DomainProject
import Testing

@testable import Feature

@Suite("HomeProjectSectionState")
struct HomeProjectSectionStateTests {

    @Test
    func `대기와 로딩은 모두 loading으로 접힌다`() {
        #expect(HomeProjectSectionState(.idle, access: .member) == .loading)
        #expect(HomeProjectSectionState(.loading, access: .member) == .loading)
    }

    @Test
    func `항목이 없는 목록은 empty로 구분한다`() {
        #expect(HomeProjectSectionState(.loaded(HomeTestFixture.emptyPage), access: .member) == .empty)
    }

    @Test
    func `항목이 있는 목록은 순서를 유지한 표시 값으로 변환한다`() {
        guard case .loaded(let displays) = HomeProjectSectionState(.loaded(HomeTestFixture.manyProjectsPage), access: .member) else {
            Issue.record("loaded 상태가 아닙니다")
            return
        }

        #expect(displays.map(\.title) == ["Repository 0", "Repository 1", "Repository 2", "Repository 3"])
        #expect(displays.map(\.projectID) == ["project-0", "project-1", "project-2", "project-3"])
    }

    @Test
    func `다음 퀴즈가 없는 항목만 학습 진입이 막힌다`() {
        let list = ProjectList(
            summaries: [
                HomeTestFixture.project(index: 0),
                HomeTestFixture.project(index: 1, hasLearningIDs: false),
            ],
            hasNextPage: false,
            isLoaded: true,
        )

        guard case .loaded(let displays) = HomeProjectSectionState(.loaded(list), access: .member) else {
            Issue.record("loaded 상태가 아닙니다")
            return
        }

        #expect(displays.map(\.isLearningEnabled) == [true, false])
    }

    @Test
    func `조회 실패는 failed로 변환한다`() {
        #expect(HomeProjectSectionState(.failed(.unexpected), access: .member) == .failed)
    }

    @Test
    func `비로그인이면 조회 상태와 무관하게 signInRequired다`() {
        #expect(HomeProjectSectionState(.idle, access: .guest) == .signInRequired)
        #expect(HomeProjectSectionState(.loading, access: .guest) == .signInRequired)
        #expect(HomeProjectSectionState(.loaded(HomeTestFixture.manyProjectsPage), access: .guest) == .signInRequired)
        #expect(HomeProjectSectionState(.failed(.unexpected), access: .guest) == .signInRequired)
    }

}
