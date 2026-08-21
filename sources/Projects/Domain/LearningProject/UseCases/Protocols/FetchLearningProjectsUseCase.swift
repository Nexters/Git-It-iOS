/// UC03 — 전체 학습 프로젝트 snapshot 조회. page cursor·append 상태를 만들지 않는다.
public protocol FetchLearningProjectsUseCase: Sendable {
    func callAsFunction() async throws -> LearningProjectPage
}
