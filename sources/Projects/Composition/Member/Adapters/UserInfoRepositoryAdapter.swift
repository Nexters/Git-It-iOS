import DataAuthentication
import DataMember
import DataShared
import DomainUserInfo

// MARK: - UserInfoRepositoryAdapter

public struct UserInfoRepositoryAdapter: UserInfoRepository {

    // MARK: Lifecycle

    public init(
        remote: MemberRemote,
        sessionStorage: any SecureValueStorage,
    ) {
        self.remote = remote
        coding = SessionRecordStorageCoding(storage: sessionStorage)
    }

    // MARK: Public

    public func profile() async throws -> UserProfile {
        do {
            let response = try await remote.fetchProfile()
            return UserProfile(
                detail: UserDetail(
                    name: response.name,
                    email: response.email ?? "",
                    statistics: LearningStatistics(
                        thisWeekSolvedCount: response.thisWeekSolvedCount,
                        thisMonthSolvedCount: response.thisMonthSolvedCount,
                        streakDays: response.streakDays,
                        weeklyCounts: response.weeklyChart.map {
                            WeeklyLearningCount(
                                dayLabel: $0.dayLabel,
                                count: $0.count,
                            )
                        },
                    ),
                ),
                curation: try curation(
                    position: response.position,
                    careerLevel: response.careerLevel,
                ),
            )
        } catch let error as MemberServiceError {
            throw domainError(for: error)
        }
    }

    public func updateCuration(_ curation: Curation) async throws {
        do {
            try await remote.curateMember(CurationRequestDTO(
                position: dtoPosition(curation.position),
                careerLevel: dtoCareerLevel(curation.careerLevel),
            ))
            clearCurationRequirement()
        } catch let error as MemberServiceError {
            throw domainError(for: error)
        }
    }

    public func updatePosition(_ position: MemberPosition) async throws {
        do {
            try await remote.updatePosition(PositionRequestDTO(position: dtoPosition(position)))
        } catch let error as MemberServiceError {
            throw domainError(for: error)
        }
    }

    public func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        do {
            try await remote.updateCareerLevel(CareerLevelRequestDTO(careerLevel: dtoCareerLevel(careerLevel)))
        } catch let error as MemberServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: MemberRemote
    private let coding: SessionRecordStorageCoding

    private func clearCurationRequirement() {
        guard let record = try? coding.load(), record.needsCuration else { return }
        try? coding.save(StoredSessionRecord(
            accessToken: record.accessToken,
            refreshToken: record.refreshToken,
            accessTokenExpiresAt: record.accessTokenExpiresAt,
            refreshTokenExpiresAt: record.refreshTokenExpiresAt,
            needsCuration: false,
            acceptedLegalVersions: record.acceptedLegalVersions,
            acceptedAt: record.acceptedAt,
        ))
    }

    private func curation(
        position: String?,
        careerLevel: String?,
    ) throws -> Curation? {
        guard
            let position = try domainPosition(position),
            let careerLevel = try domainCareerLevel(careerLevel)
        else { return nil }
        return Curation(
            position: position,
            careerLevel: careerLevel,
        )
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
        default: throw UserInfoError.temporarilyUnavailable
        }
    }

    private func dtoCareerLevel(_ careerLevel: CareerLevel) -> CareerLevelDTO {
        switch careerLevel {
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
        default: throw UserInfoError.temporarilyUnavailable
        }
    }

    private func domainError(for error: MemberServiceError) -> UserInfoError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .memberUnavailable:
            .memberUnavailable

        case .temporarilyUnavailable,
             .transport,
             .unexpectedStatus:
            .temporarilyUnavailable

        @unknown default:
            .temporarilyUnavailable
        }
    }

}
