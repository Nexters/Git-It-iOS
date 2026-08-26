import DomainAuthentication
import DomainMember
import Foundation

// MARK: - RestoreSessionUseCaseMock

actor RestoreSessionUseCaseMock: RestoreSessionUseCase {
    init(results: [RestoreSessionResult] = [.unauthenticated]) {
        self.results = results
    }

    func callAsFunction() async -> RestoreSessionResult {
        callCount += 1
        return nextResult()
    }

    func snapshot() -> Int {
        callCount
    }

    private var results: [RestoreSessionResult]
    private var callCount = 0

    private func nextResult() -> RestoreSessionResult {
        guard !results.isEmpty else { return .recoverableFailure }
        return results.count > 1 ? results.removeFirst() : results[0]
    }
}

// MARK: - SignInUseCaseMock

actor SignInUseCaseMock: SignInUseCase {
    init(results: [SignInResult] = [.retryableFailure]) {
        self.results = results
    }

    func callAsFunction(_ method: AuthenticationMethod) async -> SignInResult {
        calls.append(method)
        return nextResult()
    }

    func snapshot() -> [AuthenticationMethod] {
        calls
    }

    private var results: [SignInResult]
    private var calls: [AuthenticationMethod] = []

    private func nextResult() -> SignInResult {
        guard !results.isEmpty else { return .retryableFailure }
        return results.count > 1 ? results.removeFirst() : results[0]
    }
}

// MARK: - SignOutUseCaseMock

actor SignOutUseCaseMock: SignOutUseCase {
    init(results: [SignOutResult] = [.success]) {
        self.results = results
    }

    func callAsFunction() async -> SignOutResult {
        callCount += 1
        return nextResult()
    }

    func snapshot() -> Int {
        callCount
    }

    private var results: [SignOutResult]
    private var callCount = 0

    private func nextResult() -> SignOutResult {
        guard !results.isEmpty else { return .success }
        return results.count > 1 ? results.removeFirst() : results[0]
    }
}

// MARK: - FetchMemberProfileUseCaseMock

actor FetchMemberProfileUseCaseMock: FetchMemberProfileUseCase {
    init(results: [Result<MemberProfile, MemberError>] = [.failure(.temporarilyUnavailable)]) {
        self.results = results
    }

    func callAsFunction() async throws -> MemberProfile {
        callCount += 1
        return try nextResult().get()
    }

    func snapshot() -> Int {
        callCount
    }

    private var results: [Result<MemberProfile, MemberError>]
    private var callCount = 0

    private func nextResult() -> Result<MemberProfile, MemberError> {
        guard !results.isEmpty else { return .failure(.temporarilyUnavailable) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }
}

// MARK: - CompleteCurationUseCaseMock

actor CompleteCurationUseCaseMock: CompleteCurationUseCase {
    struct Call: Equatable {
        let position: MemberPosition
        let careerLevel: CareerLevel
    }

    init(results: [Result<Void, MemberError>] = [.success(())]) {
        self.results = results
    }

    func callAsFunction(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        calls.append(Call(position: position, careerLevel: careerLevel))
        try nextResult().get()
    }

    func snapshot() -> [Call] {
        calls
    }

    private var results: [Result<Void, MemberError>]
    private var calls: [Call] = []

    private func nextResult() -> Result<Void, MemberError> {
        guard !results.isEmpty else { return .success(()) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }
}

// MARK: - PolicyConsentUseCaseMock

actor PolicyConsentUseCaseMock: PolicyConsentUseCase {
    init(
        requiredDocuments: [PolicyDocument] = [],
        storedConsentRecords: [PolicyConsentRecord] = [],
    ) {
        requiredDocumentsResult = requiredDocuments
        storedConsentRecordsResult = storedConsentRecords
    }

    func requiredDocuments() async throws -> [PolicyDocument] {
        requiredDocumentsCallCount += 1
        return requiredDocumentsResult
    }

    func storedConsentRecords() async throws -> [PolicyConsentRecord] {
        storedConsentRecordsResult
    }

    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws {
        savedRecords.append(records)
        storedConsentRecordsResult = records
    }

    nonisolated func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        PolicyConsentRecord.isConsentValid(storedRecords: storedRecords, for: requiredDocuments)
    }

    func snapshot() -> (requiredDocumentsCallCount: Int, savedRecords: [[PolicyConsentRecord]]) {
        (requiredDocumentsCallCount, savedRecords)
    }

    private let requiredDocumentsResult: [PolicyDocument]
    private var storedConsentRecordsResult: [PolicyConsentRecord]
    private var requiredDocumentsCallCount = 0
    private var savedRecords: [[PolicyConsentRecord]] = []
}

// MARK: - Test Fixtures

enum OnboardingTestFixture {
    static let privacyPolicy = PolicyDocument(
        identifier: "privacy-policy",
        displayName: "개인정보 처리방침",
        version: "1",
        approvedURL: URL(string: "https://example.com/privacy-policy")!,
        isRequired: true,
    )

    static let termsOfService = PolicyDocument(
        identifier: "terms-of-service",
        displayName: "서비스 이용 약관",
        version: "1",
        approvedURL: URL(string: "https://example.com/terms-of-service")!,
        isRequired: true,
    )

    static let requiredDocuments = [privacyPolicy, termsOfService]

    static let validConsentRecords = [
        PolicyConsentRecord(documentIdentifier: privacyPolicy.identifier, version: privacyPolicy.version, acceptedAt: Date()),
        PolicyConsentRecord(documentIdentifier: termsOfService.identifier, version: termsOfService.version, acceptedAt: Date()),
    ]

    static let authenticatedUser = AuthenticatedUser(id: "member-1", availability: .available, displayName: "테스터")

    static func profile(position: MemberPosition?, careerLevel: CareerLevel?) -> MemberProfile {
        MemberProfile(
            name: "테스터",
            email: "tester@example.com",
            position: position,
            careerLevel: careerLevel,
            statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
        )
    }
}
