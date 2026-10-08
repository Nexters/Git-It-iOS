import CompositionAuthentication
import CompositionLearningProject
import CompositionMember
import DataAuthentication
import DataExternalRepository
import DataLearningProject
import DataLegalConsent
import DataMember
import DataNotification
import DataShared
import DomainAccount
import DomainAppSetting
import DomainExternalRepository
import DomainIdentifier
import DomainProject
import DomainProjectGeneration
import DomainQuizDetail
import DomainUserInfo
import Foundation

// MARK: - ConcernUseCaseAssembly

public struct ConcernUseCaseAssembly: Sendable {

    // MARK: Lifecycle

    public init(
        apiBaseURL: URL,
        externalRepositoryBaseURL: URL,
        policyDocuments: [PolicyDocument],
        appVersion: String,
        osVersion: String,
        requestCredentialProvider: RequestCredentialProvider,
        secureStorage: (any SecureValueStorage)?,
        sharedStorage: (any KeyValueStorage)?,
        notificationPermissionRequester: (any NotificationPermissionRequester)? = nil,
        generationOutcomeSource: PushQuizGenerationOutcomeSource = PushQuizGenerationOutcomeSource(),
        deliveredRemoteMessageReader: (any DeliveredRemoteMessageReader)? = nil,
        transport: (any RequestTransport)? = nil,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
        memberResponseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
        deviceToken: @escaping @Sendable () async throws -> DeviceToken,
    ) {
        let sessionStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: SessionStorageLayout.namespace,
            location: .appGroup,
        )
        let appleIdentityStorage = secureStorage ?? StorageFactory.secureValueStorage(
            namespace: AppleIdentityStorageLayout.namespace,
            location: .appGroup,
        )
        let credential: @Sendable () async -> RequestCredential = {
            await requestCredentialProvider.credential()
        }
        let credentialRejected: @Sendable () async -> Void = {
            await requestCredentialProvider.credentialRejected()
        }
        let memberRemote = MemberRemote(
            baseURL: apiBaseURL,
            transport: transport,
            responseTimeout: memberResponseTimeout,
            credential: credential,
            credentialRejected: credentialRejected,
        )
        let projectRemote = ProjectRemote(
            baseURL: apiBaseURL,
            transport: transport,
            responseTimeout: responseTimeout,
            credential: credential,
            credentialRejected: credentialRejected,
        )
        let account = Account(
            authenticationRepository: AuthenticationRepositoryAdapter(
                appleSignInSource: AppleSignInSource(),
                secureStorage: appleIdentityStorage,
            ),
            signInRepository: SignInRepositoryAdapter(
                remote: AuthenticationRemote(
                    baseURL: apiBaseURL,
                    transport: transport,
                    responseTimeout: responseTimeout,
                    credential: credential,
                ),
                sessionStorage: sessionStorage,
                appleIdentityStorage: appleIdentityStorage,
                requestCredentialProvider: requestCredentialProvider,
                sharedSessionStateMarkerCoding: sharedStorage.map(SharedSessionStateMarkerCoding.init(storage:)),
            ),
            withdrawalRepository: WithdrawalRepositoryAdapter(remote: memberRemote),
            policyConsentRepository: PolicyConsentRepositoryAdapter(
                store: LocalPolicyConsentStore(
                    storage: StorageFactory.keyValueStorage(
                        namespace: PolicyConsentStorageLayout.namespace,
                        location: .device,
                    )
                )
            ),
            policyDocuments: policyDocuments,
            signInInvalidations: { requestCredentialProvider.invalidations() },
        )
        self.account = account

        userInfo = UserInfo(
            repository: UserInfoRepositoryAdapter(
                remote: memberRemote,
                sessionStorage: sessionStorage,
            )
        )
        let permissionRequester = notificationPermissionRequester ?? NotificationFactory.notificationPermissionRequester()
        appSetting = AppSetting(
            notificationAuthorization: NotificationAuthorizationAdapter(permissionRequester: permissionRequester),
            deviceRegistrationRepository: DeviceRegistrationRepositoryAdapter(remote: memberRemote),
            deviceIdentifierRepository: DeviceIdentifierRepositoryAdapter(
                secureStorage: secureStorage ?? StorageFactory.secureValueStorage(
                    namespace: SessionStorageLayout.namespace,
                    location: .appGroup,
                )
            ),
            appVersion: appVersion,
            osVersion: osVersion,
            deviceToken: deviceToken,
        )
        externalRepository = Self.makeExternalRepository(
            baseURL: externalRepositoryBaseURL,
            transport: transport,
            responseTimeout: responseTimeout,
        )
        quizDetail = QuizDetail(
            quizSetRepository: QuizSetRepositoryAdapter(remote: LearningSetRemote(
                baseURL: apiBaseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )),
            answerRepository: QuizAnswerRepositoryAdapter(remote: AnswerRemote(
                baseURL: apiBaseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )),
            bookmarkRepository: QuizBookmarkRepositoryAdapter(remote: BookmarkRemote(
                baseURL: apiBaseURL,
                transport: transport,
                responseTimeout: responseTimeout,
                credential: credential,
                credentialRejected: credentialRejected,
            )),
        )

        let signedOutEvents: @Sendable () async -> AsyncStream<Void> = {
            await Self.signedOutEvents(from: account.signInStates())
        }
        let projectGeneration = ProjectGeneration(
            repository: ProjectGenerationRepositoryAdapter(remote: projectRemote),
            pendingGenerations: PendingGenerationRepositoryAdapter(
                store: LocalPendingGenerationStore(
                    storage: sharedStorage ?? StorageFactory.keyValueStorage(
                        namespace: LocalPendingGenerationStore.namespace,
                        location: .appGroup,
                    )
                )
            ),
            outcomes: GenerationOutcomeRepositoryAdapter(
                source: generationOutcomeSource,
                deliveredMessages: deliveredRemoteMessageReader ?? NotificationFactory.deliveredRemoteMessageReader(),
            ),
            signedOutEvents: signedOutEvents,
        )
        self.projectGeneration = projectGeneration

        project = Project(
            repository: ProjectRepositoryAdapter(remote: projectRemote),
            signedOutEvents: signedOutEvents,
            projectDeleted: { await projectGeneration.release($0) },
            projectsListed: { await projectGeneration.confirmCompletion(of: $0) },
        )
    }

    // MARK: Public

    public let account: any AccountUseCase
    public let userInfo: any UserInfoUseCase
    public let appSetting: any AppSettingUseCase
    public let externalRepository: any ExternalRepositoryUseCase
    public let quizDetail: any QuizDetailUseCase
    public let project: any ProjectUseCase
    public let projectGeneration: any ProjectGenerationUseCase

    public static func makeExternalRepository(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration = RequestClientFactory.defaultResponseTimeout,
    ) -> any ExternalRepositoryUseCase {
        ExternalRepositoryResolver(
            lookup: ExternalRepositoryLookupAdapter(
                remote: ExternalRepositoryRemote(
                    baseURL: baseURL,
                    transport: transport,
                    responseTimeout: responseTimeout,
                )
            ),
            locator: ExternalRepositoryLocatorAdapter(parser: GitHubRepositoryURLParser()),
        )
    }

    public static func signedOutEvents(from states: AsyncStream<SignInState>) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await state in states where state == .signedOut {
                    continuation.yield(())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

}
