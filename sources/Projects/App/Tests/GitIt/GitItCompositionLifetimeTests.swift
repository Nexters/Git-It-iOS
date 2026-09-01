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

    @Test
    func `조립만 수행하면 기기 등록이 시작되지 않는다`() {
        let app = GitItApp()

        #expect(app.rootStore.deviceRegistration == .idle)
    }

    @Test
    func `bootstrap 이전에는 푸시 client가 없어 기기 등록이 실패한다`() async {
        let app = GitItApp()

        await #expect(throws: (any Error).self) {
            try await app.composition.registerCurrentDevice()
        }
    }

    @Test
    func `bootstrap 이전의 등록 token 갱신 스트림은 즉시 종료돼 외부 SDK를 만들지 않는다`() async {
        let app = GitItApp()

        var receivedCount = 0
        for await _ in app.composition.deviceTokenRefreshes() {
            receivedCount += 1
        }

        #expect(receivedCount == 0)
    }

}
