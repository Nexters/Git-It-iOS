import DataExternalRepository
import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation
import InfrastructureAuthentication
import InfrastructureNetworkClient

// MARK: - AppComposition

public struct AppComposition: Sendable {

    // MARK: Lifecycle

    private init(
        authentication: AuthenticationAssembly,
        learningProject: LearningProjectAssembly,
        member: MemberAssembly,
        externalRepository: ExternalRepositoryAssembly,
    ) {
        signIn = authentication.signIn
        signOut = authentication.signOut
        restoreSession = authentication.restoreSession
        observeAuthenticationOutcomes = authentication.observeAuthenticationOutcomes
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

        fetchMemberProfile = member.fetchMemberProfile
        updateMemberPosition = member.updateMemberPosition
        updateMemberCareerLevel = member.updateMemberCareerLevel
        registerMemberDevice = member.registerMemberDevice
        deleteMemberAccount = member.deleteMemberAccount

        fetchExternalRepository = externalRepository.fetchExternalRepository
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
    public let observeAuthenticationOutcomes: any ObserveAuthenticationOutcomesUseCase
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
        )
    }

}
