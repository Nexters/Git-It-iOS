import Testing

@testable import InfrastructureCache

@Suite("InMemoryCache 동시 접근 안전성")
struct ConcurrentAccessTests {

    @Test
    func `서로 다른 키에 대한 동시 저장이 유실·혼선 없이 모두 반영된다`() async {
        let cache = InMemoryCache<Int, Int>()

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 100 {
                group.addTask {
                    await cache.store(index, forKey: index)
                }
            }
        }

        for index in 0 ..< 100 {
            #expect(await cache.value(forKey: index) == index)
        }
    }

    @Test
    func `같은 키에 대한 동시 저장 후 요청 중 하나의 값이 손상 없이 남는다`() async throws {
        let cache = InMemoryCache<String, Int>()
        let candidates = Array(0 ..< 50)

        await withTaskGroup(of: Void.self) { group in
            for candidate in candidates {
                group.addTask {
                    await cache.store(candidate, forKey: "key")
                }
            }
        }

        let result = await cache.value(forKey: "key")
        #expect(result != nil)
        #expect(candidates.contains(try #require(result)))
    }

}
