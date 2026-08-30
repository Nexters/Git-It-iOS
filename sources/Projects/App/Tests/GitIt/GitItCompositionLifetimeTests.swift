import Testing

@testable import GitIt

@Suite("GitItApp composition 수명")
struct GitItCompositionLifetimeTests {

    @Test
    func `GitItApp은 production AppComposition으로 만든 root store를 앱 수명 동안 재사용한다`() {
        let app = GitItApp()

        let firstAccess = app.rootStore
        let secondAccess = app.rootStore

        #expect(firstAccess === secondAccess)
    }

    @Test
    func `GitItApp 인스턴스마다 독립된 production composition graph로 root store를 생성한다`() {
        let firstApp = GitItApp()
        let secondApp = GitItApp()

        #expect(firstApp.rootStore !== secondApp.rootStore)
    }

}
