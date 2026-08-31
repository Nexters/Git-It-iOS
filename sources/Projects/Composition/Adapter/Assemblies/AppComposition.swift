import DataExternalRepository
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient
import InfrastructurePushMessaging

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    private init(
        authentication: AuthenticationAssembly,
        learningProject: LearningProjectAssembly,
        member: MemberAssembly,
        externalRepository: ExternalRepositoryAssembly,
        keychainStore: KeychainStore,
    ) {
        signIn = authentication.signIn
        signOut = authentication.signOut
        restoreSession = authentication.restoreSession
        authenticationOutcomes = authentication.authenticationOutcomes
        refreshSession = authentication.refreshSession
        verifyAccessToken = authentication.verifyAccessToken
        policyConsent = authentication.policyConsent
        completeCuration = member.completeCuration

        fetchLearningProjects = learningProject.fetchLearningProjects
        fetchLearningProjectDetail = learningProject.fetchLearningProjectDetail
        createLearningProject = learningProject.createLearningProject
        deleteLearningProject = learningProject.deleteLearningProject
        fetchLearningSet = learningProject.fetchLearningSet
        submitChoiceAnswer = learningProject.submitChoiceAnswer
        submitEssayAnswer = learningProject.submitEssayAnswer
        setQuestionBookmark = learningProject.setQuestionBookmark
        fetchBookmarkedQuestions = learningProject.fetchBookmarkedQuestions
        learningProjectOutcomes = learningProject.learningProjectOutcomes

        fetchMemberProfile = member.fetchMemberProfile
        updateMemberPosition = member.updateMemberPosition
        updateMemberCareerLevel = member.updateMemberCareerLevel
        registerMemberDevice = member.registerMemberDevice
        deleteMemberAccount = member.deleteMemberAccount

        fetchExternalRepository = externalRepository.fetchExternalRepository

        let pushClient = FirebaseMessagingPushClient()
        let forwardAPNsToken: @Sendable (Data) -> Void = { token in
            pushClient.setAPNsToken(token)
        }
        let ingestPushPayload: @Sendable ([String: String]) async -> Void = { rawPayload in
            await learningProject.ingestGenerationOutcomePayload(rawPayload)
        }
        PushNotificationAppDelegate.configure(
            PushNotificationHandlers(
                forwardAPNsToken: forwardAPNsToken,
                ingestPushPayload: ingestPushPayload,
            )
        )

        let registerMemberDevice = member.registerMemberDevice
        let deviceID = AppComposition.deviceID(keychainStore: keychainStore)
        Task {
            guard let token = try? await pushClient.registrationToken() else { return }
            try? await registerMemberDevice(MemberDeviceInfo(
                deviceID: deviceID,
                deviceType: .ios,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                deviceToken: token,
            ))
        }
    }

    // MARK: Public

    public struct Environment: Sendable {

        // MARK: Lifecycle

        public init(
            apiBaseURL: URL,
            externalRepositoryBaseURL: URL,
            policyDocuments: [PolicyDocument] = [],
        ) {
            self.apiBaseURL = apiBaseURL
            self.externalRepositoryBaseURL = externalRepositoryBaseURL
            self.policyDocuments = policyDocuments
        }

        // MARK: Public

        public let apiBaseURL: URL
        public let externalRepositoryBaseURL: URL
        public let policyDocuments: [PolicyDocument]

    }

    public let signIn: any SignInUseCase
    public let signOut: any SignOutUseCase
    public let restoreSession: any RestoreSessionUseCase
    public let authenticationOutcomes: any AuthenticationOutcomesUseCase
    public let refreshSession: any RefreshSessionUseCase
    public let verifyAccessToken: any VerifyAccessTokenUseCase
    public let policyConsent: any PolicyConsentUseCase
    public let completeCuration: any CompleteCurationUseCase

    public let fetchLearningProjects: any FetchLearningProjectsUseCase
    public let fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase
    public let createLearningProject: any CreateLearningProjectUseCase
    public let deleteLearningProject: any DeleteLearningProjectUseCase
    public let fetchLearningSet: any FetchLearningSetUseCase
    public let submitChoiceAnswer: any SubmitChoiceAnswerUseCase
    public let submitEssayAnswer: any SubmitEssayAnswerUseCase
    public let setQuestionBookmark: any SetQuestionBookmarkUseCase
    public let fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase

    public let fetchMemberProfile: any FetchMemberProfileUseCase
    public let updateMemberPosition: any UpdateMemberPositionUseCase
    public let updateMemberCareerLevel: any UpdateMemberCareerLevelUseCase
    public let registerMemberDevice: any RegisterMemberDeviceUseCase
    public let deleteMemberAccount: any DeleteMemberAccountUseCase

    public let fetchExternalRepository: any FetchExternalRepositoryUseCase

    public let learningProjectOutcomes: any LearningProjectOutcomesUseCase

    public static func live(
        _ environment: Environment,
        keychainStore: KeychainStore = KeychainStore(),
        transport: (any HTTPTransport)? = nil,
    ) -> AppComposition {
        let authentication = AuthenticationAssembly(
            baseURL: environment.apiBaseURL,
            policyDocuments: environment.policyDocuments,
            keychainStore: keychainStore,
            transport: transport,
        )
        let sessionCoding = SessionRecordKeychainCoding(keychainStore: keychainStore)
        let accessTokenProvider: @Sendable () async -> String? = {
            (try? sessionCoding.load())?.tokens.accessToken
        }
        let learningProject = LearningProjectAssembly(
            baseURL: environment.apiBaseURL,
            accessTokenProvider: accessTokenProvider,
            transport: transport,
        )
        let member = MemberAssembly(
            baseURL: environment.apiBaseURL,
            loginSessionRepository: authentication.loginSessionRepository,
            accessTokenProvider: accessTokenProvider,
            transport: transport,
        )
        let externalRepository = ExternalRepositoryAssembly(
            baseURL: environment.externalRepositoryBaseURL,
            transport: transport,
        )

        return AppComposition(
            authentication: authentication,
            learningProject: learningProject,
            member: member,
            externalRepository: externalRepository,
            keychainStore: keychainStore,
        )
    }

    // MARK: Private

    private static let deviceKeychainNamespace = KeychainNamespace("com.nexters.hytime.gitit.device")
    private static let deviceKeychainKey = "deviceID"

    private static func deviceID(keychainStore: KeychainStore) -> String {
        if
            let data = try? keychainStore.load(for: deviceKeychainKey, in: deviceKeychainNamespace),
            let existing = String(data: data, encoding: .utf8)
        {
            return existing
        }
        let newDeviceID = UUID().uuidString
        if let data = newDeviceID.data(using: .utf8) {
            try? keychainStore.save(data, for: deviceKeychainKey, in: deviceKeychainNamespace)
        }
        return newDeviceID
    }

}
