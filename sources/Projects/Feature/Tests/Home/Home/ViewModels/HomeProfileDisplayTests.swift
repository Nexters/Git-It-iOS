import Testing

@testable import Feature

@Suite("HomeProfileDisplay")
struct HomeProfileDisplayTests {

    @Test
    func `역할 문구는 큐레이션 연차를 Developer 앞에 붙인다`() {
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithBoth)).role == "Junior Developer")
        #expect(
            HomeProfileDisplay(.loaded(HomeTestFixture.profile(position: .backend, careerLevel: .senior)))
                .role == "Senior Developer"
        )
    }

    @Test
    func `큐레이션이 없는 프로필은 연차 없이 Developer만 남긴다`() {
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithNameOnly)).role == " Developer")
        #expect(HomeProfileDisplay(.loaded(HomeTestFixture.profileWithPosition)).role == " Developer")
    }

    @Test
    func `조회 성공은 이름을 노출하고 실패 표시를 세우지 않는다`() {
        let display = HomeProfileDisplay(.loaded(HomeTestFixture.profileWithBoth))

        #expect(display.name == HomeTestFixture.profileWithBoth.detail.name)
        #expect(!display.isFailed)
    }

    @Test
    func `조회 실패만 실패 표시를 세우고 대기 상태는 세우지 않는다`() {
        #expect(HomeProfileDisplay(.failed(.temporarilyUnavailable)).isFailed)
        #expect(HomeProfileDisplay(.failed(.temporarilyUnavailable)).name == nil)

        #expect(!HomeProfileDisplay(.idle).isFailed)
        #expect(!HomeProfileDisplay(.loading).isFailed)
        #expect(HomeProfileDisplay(.idle).name == nil)
        #expect(HomeProfileDisplay(.loading).name == nil)
    }

}
