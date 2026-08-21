public protocol MemberRemote: Sendable {
    func fetchProfile() async throws -> MemberProfileResponseDTO
    func registerDeviceInfo(_ request: DeviceInfoRequestDTO) async throws
    func curateMember(_ request: CurationRequestDTO) async throws
    func updatePosition(_ request: PositionRequestDTO) async throws
    func updateCareerLevel(_ request: CareerLevelRequestDTO) async throws
    func withdrawMember() async throws
}
