import CompositionAdapter
import DomainLearningProject
import Foundation
import InfrastructureAuthentication
import InfrastructureLocalNotification
import InfrastructureNetworkClient

// MARK: - ShareExtensionComposition

/// Share Extension이 사용하는 조립 루트다. 원격 푸시와 세션 갱신을 조립하지 않아
/// Extension 프로세스가 필요한 최소 의존성만 링크한다.
public struct ShareExtensionComposition: Sendable {

    // MARK: Lifecycle

    private init(
        externalRepository: ExternalRepositoryAssembly,
        learningProject: LearningProjectAssembly,
        resolveSessionAvailability: @escaping @Sendable () async -> SessionAvailability,
        localNotificationClient: any LocalNotificationClient,
        pendingReminderCoding: PendingGenerationReminderCoding?,
    ) {
        parseRepositoryLink = externalRepository.urlParser
        fetchExternalRepository = externalRepository.fetchExternalRepository
        createLearningProject = learningProject.createLearningProject
        self.resolveSessionAvailability = resolveSessionAvailability
        isNotificationAuthorized = { await localNotificationClient.isAuthorized() }
        enqueueGenerationReminder = { projectID in
            await pendingReminderCoding?.append(projectID: projectID)
        }
    }

    // MARK: Public

    public struct Environment: Sendable {

        // MARK: Lifecycle

        public init(
            apiBaseURL: URL,
            externalRepositoryBaseURL: URL,
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL

    }

    /// 네트워크 호출 없이 공유된 URL이 GitHub 저장소인지 판정한다.
    public let parseRepositoryLink: any ExternalRepositoryURLParser
    public let fetchExternalRepository: any FetchExternalRepositoryUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    /// 저장된 세션을 읽기만 한다. 갱신 경로는 조립하지 않는다.
    public let resolveSessionAvailability: @Sendable () async -> SessionAvailability
    /// 권한 상태를 조회만 한다. 권한 요청은 제공하지 않는다.
    public let isNotificationAuthorized: @Sendable () async -> Bool
    /// 등록에 성공한 프로젝트를 본 앱의 리마인더 대기 목록에 남긴다.
    public let enqueueGenerationReminder: @Sendable (String) async -> Void

    public static func live(
        _ environment: Environment,
        keychainStore: KeychainStore = SharedSessionLayout.makeSharedKeychainStore(),
        sharedDefaults: UserDefaults? = SharedSessionLayout.makeSharedDefaults(),
        localNotificationClient: any LocalNotificationClient = UserNotificationCenterLocalClient(),
        transport: (any HTTPTransport)? = nil,
    ) -> ShareExtensionComposition {
        let markerCoding = sharedDefaults.map(SharedSessionStateMarkerCoding.init(userDefaults:))
        let resolveSessionAvailability: @Sendable () async -> SessionAvailability = {
            guard let markerCoding else { return .appLaunchRequired }
            return await SessionAvailabilityResolver(
                markerCoding: markerCoding,
                keychainStore: keychainStore,
            )()
        }
        // 등록 요청은 저장된 접근 토큰을 그대로 사용한다. 만료·인증 오류는 화면 상태로
        // 처리하며 Extension에서 갱신하지 않는다.
        let accessTokenProvider: @Sendable () async -> String? = {
            guard case .available(let accessToken) = await resolveSessionAvailability() else { return nil }
            return accessToken
        }

        return ShareExtensionComposition(
            externalRepository: ExternalRepositoryAssembly(
                baseURL: environment.externalRepositoryBaseURL,
                transport: transport,
            ),
            learningProject: LearningProjectAssembly(
                baseURL: environment.apiBaseURL,
                accessTokenProvider: accessTokenProvider,
                transport: transport,
            ),
            resolveSessionAvailability: resolveSessionAvailability,
            localNotificationClient: localNotificationClient,
            pendingReminderCoding: sharedDefaults.map(PendingGenerationReminderCoding.init(userDefaults:)),
        )
    }

}
