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

        memberAccount = MemberAccount(repository: repository)
        self.repository = repository
        deleteMemberAccount = DeleteMemberAccount(
            repository: repository,
            clearLocalState: clearLocalStateAfterAccountDeletion,
        )
    }

    // MARK: Public

    public let memberAccount: any MemberAccountUseCase
    public let deleteMemberAccount: any DeleteMemberAccountUseCase

    public let repository: any MemberRepository

}
