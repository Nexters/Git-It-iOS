import Testing

@testable import InfrastructureCache

@Suite("InMemoryCache 저장과 조회")
struct StoreAndRetrieveTests {

    @Test
    func `빈 캐시에 저장한 직후 같은 키로 조회하면 저장한 값이 그대로 반환된다`() async {
        let cache = InMemoryCache<String, String>()

        await cache.store("V", forKey: "A")

        #expect(await cache.value(forKey: "A") == "V")
    }

    @Test
    func `같은 키에 값을 다시 저장하면 이전 값이 아닌 새 값이 반환된다`() async {
        let cache = InMemoryCache<String, String>()
        await cache.store("V1", forKey: "A")

        await cache.store("V2", forKey: "A")

        #expect(await cache.value(forKey: "A") == "V2")
    }

}
