import Foundation
import Testing

@testable import CompositionAdapter
@testable import DataAuthentication
@testable import DomainAuthentication

/// UC12(RefreshSession)·UC14(SignOut revoke)는 서버 endpoint 미확보(`INT-API-001`)로 구조만
/// 조립되어 있다. 이 테스트는 그 capability 부재가 임의 성공으로 감춰지지 않고 명시적으로
/// 드러나는지 검증한다(production 차단 상태를 release blocker로 유지).
@Suite("UC12·UC14 release blocker")
struct RefreshSessionReleaseBlockerTests {

    @Test
    func `RefreshSession은 서버 refresh endpoint가 없어 항상 temporarilyUnavailable을 반환한다`() async throws {
        let assembly = AuthenticationAssembly(baseURL: try #require(URL(string: "https://api.git-it.example.com")))

        let outcome = await assembly.refreshSession()

        #expect(outcome == .temporarilyUnavailable)
    }

    @Test
    func `동시에 여러 번 호출해도 임의의 refreshed 결과를 만들지 않는다`() async throws {
        let assembly = AuthenticationAssembly(baseURL: try #require(URL(string: "https://api.git-it.example.com")))

        async let first = assembly.refreshSession()
        async let second = assembly.refreshSession()
        let outcomes = await [first, second]

        #expect(outcomes.allSatisfy { $0 == .temporarilyUnavailable })
    }

}
