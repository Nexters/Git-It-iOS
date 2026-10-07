import Testing

@testable import Feature

@Suite("HomeProfileDisplay")
struct HomeProfileDisplayTests {

    @Test
    func `프로필 보조 문구는 존재하는 값만 조합한다`() {
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithBoth)).role == "iOS · 주니어")
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithPosition)).role == "Back-end")
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithCareer)).role == "미들")
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithNameOnly)).role.isEmpty)
    }

    @Test
    func `로딩 성공은 이름을 노출하고 실패 표시를 세우지 않는다`() {
        let display = HomeProfileDisplay(.loaded(HomeTestFixture.profileWithBoth))

        #expect(display.name == HomeTestFixture.profileWithBoth.name)
        #expect(!display.isFailed)
    }

    @Test
    func `로딩 실패만 실패 표시를 세우고 대기 상태는 세우지 않는다`() {
        #expect(HomeProfileDisplay(.failed(.temporarilyUnavailable)).isFailed)
        #expect(HomeProfileDisplay(.failed(.temporarilyUnavailable)).name == nil)

        #expect(!HomeProfileDisplay(.idle).isFailed)
        #expect(!HomeProfileDisplay(.loading).isFailed)
    }

}
