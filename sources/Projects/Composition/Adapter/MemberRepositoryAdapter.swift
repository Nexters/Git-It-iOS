import DataMember
import DomainMember
import Foundation

// MARK: - MemberRepositoryAdapter

/// `MemberProfileResponseDTO`(thisWeekSolvedCount/thisMonthSolvedCount/streakDays/weeklyChart)와
/// Domain `LearningStatistics`(totalAnsweredCount/totalCorrectCount/weeklyCounts) 사이에는
/// 서버 OpenAPI 확정 전이라 1:1 대응이 없다. `totalAnsweredCount`는 `thisMonthSolvedCount`로
/// 추정 매핑하고, 서버가 정답 수를 별도로 내려주지 않아 `totalCorrectCount`는 0으로 두며
/// (재계산 아님, 값 없음을 보존), `streakDays`는 대응 필드가 없어 보존하지 않는다. 실제
/// 서버 계약이 확정되면 이 매핑을 갱신해야 한다(추정 매핑, 사용자 승인 하에 진행).
struct MemberRepositoryAdapter: MemberRepository {

    // MARK: Lifecycle

    init(remote: MemberRemote) {
        self.remote = remote
    }

    // MARK: Internal

    func completeCuration(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        do {
            try await remote.curateMember(CurationRequestDTO(
                position: dtoPosition(position),
                careerLevel: dtoCareerLevel(careerLevel),
            ))
        } catch let error as DataMemberError {
            throw domainError(for: error)
        }
    }

    func fetchProfile() async throws -> MemberProfile {
        do {
            let response = try await remote.fetchProfile()
            return MemberProfile(
                name: response.name,
                email: response.email,
                position: try domainPosition(response.position),
                careerLevel: try domainCareerLevel(response.careerLevel),
                statistics: LearningStatistics(
                    totalAnsweredCount: response.thisMonthSolvedCount,
                    totalCorrectCount: 0,
                    weeklyCounts: response.weeklyChart.compactMap(weeklyCount(from:)),
                ),
            )
        } catch let error as DataMemberError {
            throw domainError(for: error)
        }
    }

    func updatePosition(_ position: MemberPosition) async throws {
        do {
            try await remote.updatePosition(PositionRequestDTO(position: dtoPosition(position)))
        } catch let error as DataMemberError {
            throw domainError(for: error)
        }
    }

    func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        do {
            try await remote.updateCareerLevel(CareerLevelRequestDTO(careerLevel: dtoCareerLevel(careerLevel)))
        } catch let error as DataMemberError {
            throw domainError(for: error)
        }
    }

    func registerDevice(_ device: MemberDeviceInfo) async throws {
        do {
            try await remote.registerDeviceInfo(DeviceInfoRequestDTO(
                deviceID: device.deviceID,
                deviceType: dtoDeviceType(device.deviceType),
                appVersion: device.appVersion,
                osVersion: device.osVersion,
                deviceToken: device.deviceToken,
            ))
        } catch let error as DataMemberError {
            throw domainError(for: error)
        }
    }

    func deleteAccount() async throws {
        do {
            try await remote.withdrawMember()
        } catch let error as DataMemberError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: MemberRemote
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func weeklyCount(from dto: WeeklyChartItemDTO) -> WeeklyLearningCount? {
        guard let date = dayFormatter.date(from: dto.date) else { return nil }
        return WeeklyLearningCount(weekStartDate: date, count: dto.solvedCount)
    }

    private func dtoPosition(_ position: MemberPosition) -> PositionDTO {
        switch position {
        case .ios: PositionDTO(rawValue: "IOS")
        case .android: PositionDTO(rawValue: "ANDROID")
        case .backend: PositionDTO(rawValue: "BACKEND")
        case .frontend: PositionDTO(rawValue: "FRONTEND")
        @unknown default: PositionDTO(rawValue: "UNKNOWN")
        }
    }

    /// 서버 null은 그대로 nil로 보존한다. non-null이지만 지원하지 않는 raw value는 nil로
    /// 치환하지 않고 계약/decoding 오류(`MemberError.temporarilyUnavailable`)로 처리한다.
    private func domainPosition(_ dto: String?) throws -> MemberPosition? {
        guard let dto else { return nil }
        switch dto.uppercased() {
        case "IOS": return .ios
        case "ANDROID": return .android
        case "BACKEND": return .backend
        case "FRONTEND": return .frontend
        default: throw MemberError.temporarilyUnavailable
        }
    }

    private func dtoCareerLevel(_ level: CareerLevel) -> CareerLevelDTO {
        switch level {
        case .entry: CareerLevelDTO(rawValue: "ENTRY")
        case .junior: CareerLevelDTO(rawValue: "JUNIOR")
        case .midLevel: CareerLevelDTO(rawValue: "MIDDLE")
        case .senior: CareerLevelDTO(rawValue: "SENIOR")
        @unknown default: CareerLevelDTO(rawValue: "UNKNOWN")
        }
    }

    /// 서버 null은 그대로 nil로 보존한다. non-null이지만 지원하지 않는 raw value는 nil로
    /// 치환하지 않고 계약/decoding 오류(`MemberError.temporarilyUnavailable`)로 처리한다.
    private func domainCareerLevel(_ dto: String?) throws -> CareerLevel? {
        guard let dto else { return nil }
        switch dto.uppercased() {
        case "ENTRY": return .entry
        case "JUNIOR": return .junior
        case "MIDDLE": return .midLevel
        case "SENIOR": return .senior
        default: throw MemberError.temporarilyUnavailable
        }
    }

    private func dtoDeviceType(_: MemberDeviceInfo.DeviceType) -> String {
        "ios"
    }

    private func domainError(for error: DataMemberError) -> MemberError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .memberUnavailable:
            .memberUnavailable

        case .temporarilyUnavailable,
             .transport,
             .decoding,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
