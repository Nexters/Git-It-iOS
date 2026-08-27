import Testing

@testable import InfrastructureCache

@Suite("InMemoryCache 제거와 전체 비우기")
struct RemoveAndClearTests {

    @Test
    func `키를 제거한 뒤 조회하면 nil이 반환된다`() async {
        let cache = InMemoryCache<String, String>()
        await cache.store("V", forKey: "A")

        await cache.removeValue(forKey: "A")

        #expect(await cache.value(forKey: "A") == nil)
    }

    @Test
    func `전체 비우기 뒤 모든 키가 nil을 반환한다`() async {
        let cache = InMemoryCache<String, String>()
        await cache.store("V1", forKey: "A")
        await cache.store("V2", forKey: "B")

        await cache.removeAll()

        #expect(await cache.value(forKey: "A") == nil)
        #expect(await cache.value(forKey: "B") == nil)
    }

    @Test
    func `존재하지 않는 키를 제거해도 오류 없이 완료된다`() async {
        let cache = InMemoryCache<String, String>()

        await cache.removeValue(forKey: "존재하지-않는-키")

        #expect(await cache.value(forKey: "존재하지-않는-키") == nil)
    }

    @Test
    func `저장된 적 없는 키를 조회해도 오류·예외 없이 nil이 반환된다`() async {
        let cache = InMemoryCache<String, String>()

        #expect(await cache.value(forKey: "저장된-적-없는-키") == nil)
    }

}
