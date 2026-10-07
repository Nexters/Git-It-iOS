import DataMember
import DomainAuthentication
import DomainMember
import Foundation
import InfrastructureNetworkClient

// MARK: - MemberAssembly

public struct MemberAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        loginSessionRepository: any LoginSessionRepository,
        accessTokenProvider: @escaping @Sendable () async -> String?,
        clearLocalStateAfterAccountDeletion: @escaping @Sendable () async -> Void = { },
        transport: (any HTTPTransport)? = nil,
        responseTimeout: Duration = HTTPClient.defaultResponseTimeout,
    ) {
        let client = makeHTTPClient(baseURL: baseURL, responseTimeout: responseTimeout, transport: transport)
        let baseRepository = MemberRepositoryAdapter(
            remote: HTTPMemberRemote(client: client, accessTokenProvider: accessTokenProvider)
        )
        let repository = CurationRepositoryAdapter(
            remote: baseRepository,
            loginSessionRepository: loginSessionRepository,
        )

        completeCuration = CompleteCuration(repository: repository)
        fetchMemberProfile = FetchMemberProfile(repository: repository)
        updateMemberPosition = UpdateMemberPosition(repository: repository)
        updateMemberCareerLevel = UpdateMemberCareerLevel(repository: repository)
        registerMemberDevice = RegisterMemberDevice(repository: repository)
        deleteMemberAccount = DeleteMemberAccount(
            repository: repository,
            clearLocalState: clearLocalStateAfterAccountDeletion,
        )
    }

    // MARK: Public

    public let completeCuration: any CompleteCurationUseCase
    public let fetchMemberProfile: any FetchMemberProfileUseCase
    public let updateMemberPosition: any UpdateMemberPositionUseCase
    public let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    public let registerMemberDevice: any RegisterMemberDeviceUseCase
    public let deleteMemberAccount: any DeleteMemberAccountUseCase

}
