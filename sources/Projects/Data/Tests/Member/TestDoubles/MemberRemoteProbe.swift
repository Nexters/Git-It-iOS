import Testing
@testable import DataMember

actor MemberRemoteProbe: MemberRemote {

    // MARK: Internal

    enum Call: Equatable, Sendable {
        case fetchProfile
        case registerDeviceInfo
        case curateMember
        case updatePosition
        case updateCareerLevel
        case withdrawMember
    }

    func fetchProfile() async throws -> MemberProfileResponseDTO {
        calls.append(.fetchProfile)
        return MemberProfileResponseDTO(
            name: "테스터",
            email: "tester@example.com",
            position: "BACKEND",
            careerLevel: "JUNIOR",
            thisWeekSolvedCount: 3,
            thisMonthSolvedCount: 12,
            streakDays: 5,
            weeklyChart: [],
        )
    }

    func registerDeviceInfo(_: DeviceInfoRequestDTO) async throws {
        calls.append(.registerDeviceInfo)
    }

    func curateMember(_: CurationRequestDTO) async throws {
        calls.append(.curateMember)
    }

    func updatePosition(_: PositionRequestDTO) async throws {
        calls.append(.updatePosition)
    }

    func updateCareerLevel(_: CareerLevelRequestDTO) async throws {
        calls.append(.updateCareerLevel)
    }

    func withdrawMember() async throws {
        calls.append(.withdrawMember)
    }

    func recordedCalls() -> [Call] {
        calls
    }

    // MARK: Private

    private var calls = [Call]()

}
