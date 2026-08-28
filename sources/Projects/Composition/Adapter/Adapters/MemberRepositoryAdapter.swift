import DataMember
import DomainMember
import Foundation

// MARK: - MemberRepositoryAdapter

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
                email: response.email ?? "tester@example.com",
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
        case .middle: CareerLevelDTO(rawValue: "MIDDLE")
        case .senior: CareerLevelDTO(rawValue: "SENIOR")
        @unknown default: CareerLevelDTO(rawValue: "UNKNOWN")
        }
    }

    private func domainCareerLevel(_ dto: String?) throws -> CareerLevel? {
        guard let dto else { return nil }
        switch dto.uppercased() {
        case "ENTRY": return .entry
        case "JUNIOR": return .junior
        case "MIDDLE": return .middle
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
