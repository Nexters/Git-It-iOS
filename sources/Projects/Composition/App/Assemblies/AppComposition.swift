import CompositionAuthentication
import DataAuthentication
import DataLearningProject
import DataNotification
import DataShared
import DomainAccount
import DomainAppSetting
import DomainExternalRepository
import DomainProject
import DomainProjectGeneration
import DomainQuizDetail
import DomainUserInfo
import Foundation
import Synchronization

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    private init(
        authentication: AuthenticationAssembly,
        makeConcerns: (PushQuizGenerationOutcomeSource, @escaping @Sendable () async throws -> DeviceToken)
            -> ConcernUseCaseAssembly,
    ) {
        let pushClientBox = PushClientBox()
        let deviceToken: @Sendable () async throws -> DeviceToken = {
            guard let pushClient = pushClientBox.client else {
                throw PushBootstrapError.notBootstrapped
            }
            return try await pushClient.registrationToken()
        }
        let generationOutcomeSource = PushQuizGenerationOutcomeSource()
        let concerns = makeConcerns(generationOutcomeSource, deviceToken)
        account = concerns.account
        userInfo = concerns.userInfo
        appSetting = concerns.appSetting
        externalRepository = concerns.externalRepository
        quizDetail = concerns.quizDetail
        project = concerns.project
        projectGeneration = concerns.projectGeneration

        let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void = { rawPayload in
            await generationOutcomeSource.ingest(rawPayload: rawPayload)
        }
        self.ingestGenerationOutcomePayload = ingestGenerationOutcomePayload
        let notificationAppCallbacks = NotificationAppCallbacks(
            forwardDeviceToken: { token in pushClientBox.client?.setDeviceToken(token) },
            ingestRemoteMessagePayload: ingestGenerationOutcomePayload,
        )

        recordSharedSessionState = authentication.recordSharedSessionState
        activatePushClient = { pushClientBox.activate() }
        configureAppDelegate = { appDelegate in appDelegate.configure(notificationAppCallbacks) }

        deviceTokenRefreshes = {
            guard let pushClient = pushClientBox.client else {
                return AsyncStream { $0.finish() }
            }
            return pushClient.registrationTokenRefreshes()
        }
    }

    // MARK: Public

    public struct Environment: Sendable {

        // MARK: Lifecycle

        public init(
            apiBaseURL: URL,
            externalRepositoryBaseURL: URL,
            appVersion: String,
            osVersion: String,
            generationReminderTitle: String,
            generationReminderBody: String,
            generationFailureReminderTitle: String,
            generationFailureReminderBody: String,
            policyDocuments: [PolicyDocument] = [],
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
            self.appVersion = appVersion
            self.osVersion = osVersion
            self.generationReminderTitle = generationReminderTitle
            self.generationReminderBody = generationReminderBody
            self.generationFailureReminderTitle = generationFailureReminderTitle
            self.generationFailureReminderBody = generationFailureReminderBody
            self.policyDocuments = policyDocuments
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL
        public let appVersion: String
        public let osVersion: String
        public let generationReminderTitle: String
        public let generationReminderBody: String
        public let generationFailureReminderTitle: String
        public let generationFailureReminderBody: String
        public let policyDocuments: [PolicyDocument]

    }

    public let account: any AccountUseCase
    public let userInfo: any UserInfoUseCase
    public let appSetting: any AppSettingUseCase
    public let quizDetail: any QuizDetailUseCase
    public let project: any ProjectUseCase
    public let projectGeneration: any ProjectGenerationUseCase
    public let externalRepository: any ExternalRepositoryUseCase

    public let recordSharedSessionState: @Sendable () async -> Void
    public let activatePushClient: @Sendable () -> Void
    public let configureAppDelegate: @MainActor @Sendable (PushNotificationAppDelegate) -> Void

    public let deviceTokenRefreshes: @Sendable () -> AsyncStream<String>
    public let ingestGenerationOutcomePayload: @Sendable ([String: String]) async -> Void

    public static func live(
        _ environment: Environment,
        secureStorage: (any SecureValueStorage)? = nil,
        transport: (any RequestTransport)? = nil,
    ) -> AppComposition {
        let authentication = AuthenticationAssembly(secureStorage: secureStorage)

        return AppComposition(
            authentication: authentication,
            makeConcerns: { generationOutcomeSource, deviceToken in
                ConcernUseCaseAssembly(
                    apiBaseURL: environment.apiBaseURL,
                    externalRepositoryBaseURL: environment.externalRepositoryBaseURL,
                    policyDocuments: environment.policyDocuments,
                    appVersion: environment.appVersion,
                    osVersion: environment.osVersion,
                    generationReminder: ConcernUseCaseAssembly.GenerationReminderContent(
                        completedTitle: environment.generationReminderTitle,
                        completedBody: environment.generationReminderBody,
                        failedTitle: environment.generationFailureReminderTitle,
                        failedBody: environment.generationFailureReminderBody,
                    ),
                    requestCredentialProvider: authentication.requestCredentialProvider,
                    secureStorage: secureStorage,
                    sharedStorage: StorageFactory.keyValueStorage(
                        namespace: SessionStorageLayout.sharedSessionNamespace,
                        location: .appGroup,
                    ),
                    generationOutcomeSource: generationOutcomeSource,
                    transport: transport,
                    memberResponseTimeout: memberResponseTimeout,
                    deviceToken: deviceToken,
                )
            },
        )
    }

    // MARK: Private

    private final class PushClientBox: Sendable {

        // MARK: Internal

        var client: (any RemoteMessageReceiver)? {
            storage.withLock { $0 }
        }

        func activate() {
            storage.withLock { client in
                guard client == nil else { return }
                client = NotificationFactory.remoteMessageReceiver()
            }
        }

        // MARK: Private

        private let storage = Mutex<(any RemoteMessageReceiver)?>(nil)

    }

    private enum PushBootstrapError: Error {
        case notBootstrapped
    }

    private static let memberResponseTimeout = Duration.seconds(10)

}
