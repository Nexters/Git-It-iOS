# 계약: 생성 진행 상태 (Domain)

**대상 요구사항**: FR-005, FR-007, FR-008, FR-010~013

Domain이 소유하는 공개 계약이다. Feature와 Composition이 모두 참조하며, Domain은 프로젝트
내부 패키지에 의존하지 않는다.

## 저장 계약

```swift
public protocol GenerationProgressRepository: Sendable {
    func load() async -> GenerationProgress?
    func save(_ progress: GenerationProgress) async
    func clear() async
}
```

- `save`는 기존 값을 덮어쓴다. 동시에 1건만 존재한다(FR-007).
- `load`는 저장된 값이 없으면 `nil`을 반환한다.
- 구현체는 Composition의 어댑터가 Data의 로컬 저장소로 연결한다.

## 대기 정책

```swift
public struct GenerationWaitPolicy: Sendable, Equatable {
    public static let standard: GenerationWaitPolicy

    public let minimumWait: TimeInterval       // 300
    public let retentionLimit: TimeInterval

    public func readyDate(for progress: GenerationProgress) -> Date
    public func isExpired(_ progress: GenerationProgress, now: Date) -> Bool
}
```

- `readyDate(for:)`는 `progress.requestedAt.addingTimeInterval(minimumWait)`을 반환한다.
- 진행 화면 전이(FR-013), 완료 알림 발송(FR-010), 홈 표시 해제(FR-008)는 모두
  `max(readyDate(for:), 결과 도착 시각)`을 기준으로 한다. 세 시점의 차이는 1초 이내여야
  한다(SC-009).
- 값 타입으로 두어 테스트가 짧은 대기 시간으로 대체할 수 있게 한다.

## 사용 사례

```swift
public protocol TrackGenerationProgressUseCase: Sendable {
    func begin(projectID: String, requestedAt: Date) async
    func current() async -> GenerationProgress?
    func end() async
}
```

- `begin`은 생성 요청 제출 성공 직후 호출한다(FR-005).
- `current`는 앱 시작 시 복원에 사용한다.
- `end`는 진행 상태 해제 시점에 호출한다(FR-008).
- 기존 `RequestGenerationReminderUseCase`와 같은 `UseCases/<이름>/` 폴더 구조를 따른다.

## 계약 위반 판정

| 조건 | 기대 |
| --- | --- |
| `begin` 후 `current`가 `nil` | 위반 |
| `begin`을 두 번 호출 | 마지막 값만 남는다. 두 건이 동시에 존재하면 위반 |
| `end` 후 `current`가 값 반환 | 위반 |
| `readyDate`가 `requestedAt + 300초`가 아님 | 위반 |
