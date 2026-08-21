import Foundation
import Testing

@testable import DataMember

@Suite("MemberProfileResponseDTO 디코딩")
struct MemberProfileResponseDTOTests {

    @Test
    func `weeklyChart는 서버 응답 순서를 유지한다`() throws {
        let json = Data(#"""
            {
              "name": "테스터",
              "email": "tester@example.com",
              "position": "BACKEND",
              "careerLevel": "JUNIOR",
              "thisWeekSolvedCount": 3,
              "thisMonthSolvedCount": 12,
              "streakDays": 5,
              "weeklyChart": [
                {"date": "2026-08-19", "solvedCount": 2},
                {"date": "2026-08-17", "solvedCount": 1},
                {"date": "2026-08-18", "solvedCount": 0}
              ]
            }
            """#.utf8)

        let profile = try JSONDecoder().decode(MemberProfileResponseDTO.self, from: json)

        #expect(profile.weeklyChart.map(\.date) == ["2026-08-19", "2026-08-17", "2026-08-18"])
    }

}
