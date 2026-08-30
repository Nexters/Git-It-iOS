import Foundation
import Testing

@testable import DataMember

// MARK: - MemberProfileResponseDTOTests

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
                {"dayLabel": "2026-08-19", "count": 2},
                {"dayLabel": "2026-08-17", "count": 1},
                {"dayLabel": "2026-08-18", "count": 0}
              ]
            }
            """#.utf8)

        let profile = try JSONDecoder().decode(MemberProfileResponseDTO.self, from: json)

        #expect(profile.weeklyChart.map(\.dayLabel) == ["2026-08-19", "2026-08-17", "2026-08-18"])
    }

    @Test
    func `position과 careerLevel이 모두 null이면 각각 nil로 보존한다`() throws {
        let profile = try JSONDecoder().decode(MemberProfileResponseDTO.self, from: profileJSON(
            position: "null",
            careerLevel: "null",
        ))

        #expect(profile.position == nil)
        #expect(profile.careerLevel == nil)
    }

    @Test
    func `한 필드만 null이면 다른 필드 값은 그대로 보존한다`() throws {
        let profile = try JSONDecoder().decode(MemberProfileResponseDTO.self, from: profileJSON(
            position: #""BACKEND""#,
            careerLevel: "null",
        ))

        #expect(profile.position == "BACKEND")
        #expect(profile.careerLevel == nil)
    }

    @Test
    func `미지원 non-null raw value 타입은 nil로 치환되지 않고 decoding 오류로 실패한다`() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MemberProfileResponseDTO.self, from: profileJSON(
                position: "123",
                careerLevel: #""JUNIOR""#,
            ))
        }
    }

}

extension MemberProfileResponseDTOTests {
    private func profileJSON(
        position: String,
        careerLevel: String,
    ) -> Data {
        Data(#"""
            {
              "name": "테스터",
              "email": "tester@example.com",
              "position": \#(position),
              "careerLevel": \#(careerLevel),
              "thisWeekSolvedCount": 3,
              "thisMonthSolvedCount": 12,
              "streakDays": 5,
              "weeklyChart": []
            }
            """#.utf8)
    }
}
