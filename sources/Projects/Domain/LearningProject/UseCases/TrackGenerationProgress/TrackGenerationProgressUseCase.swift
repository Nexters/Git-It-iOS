import Foundation

public protocol TrackGenerationProgressUseCase: Sendable {
    /// 진행 중인 생성 1건을 기록한다. 이미 기록된 건이 있으면 마지막 요청으로 대체한다.
    func begin(
        projectID: String,
        requestedAt: Date,
    ) async

    /// 현재 보관 중인 진행 상태를 반환한다. 없으면 `nil`이다.
    func current() async -> GenerationProgress?

    /// 보관 중인 진행 상태를 해제한다.
    func end() async
}
