# 계약: Git-It 서버 Composition Adapter

**명세**: [spec.md](../spec.md) 시나리오 2, FR-005~009, FR-010~016 | **데이터 모델**:
[data-model.md](../data-model.md) §2

## Data↔Infrastructure Adapter

```swift
// sources/Projects/Composition/Composition/LearningProjectLifecycle/LearningProjectRemoteAdapter.swift
public struct LearningProjectRemoteAdapter: LearningProjectRemote {
    public init(httpClient: HTTPClient, sessionStorage: LoginSessionStorage)

    public func registerProject(_ request: RegisterProjectRequestDTO) async throws -> RegisterProjectResponseDTO
    public func fetchProjects(page: Int, size: Int) async throws -> ProjectListResponseDTO
    public func fetchProjectDetail(projectId: String) async throws -> ProjectDetailResponseDTO
    public func deleteProject(projectId: String) async throws
}
```

4개 메서드 모두 호출 직전 `sessionStorage.load()?.accessToken`을 읽어
`Authorization: Bearer {accessToken}` 헤더를 구성한 뒤(FR-007, 토큰이 없으면 헤더 없이 그대로
요청해 서버의 401로 자연 귀결— spec.md 예외·경계 사례) `httpClient.send(...)`로 대응하는
`/api/v1/projects` 엔드포인트를 호출한다(FR-006). 200~299 응답은 대응 DTO로 디코딩해
반환하고, 그 밖의 모든 실패는 `DataLearningProjectError`로 던진다(data-model.md §2 오류 매핑
표, FR-009·FR-010). 재시도하지 않으며(FR-015) 요청·응답·토큰을 기록하지 않는다(FR-016).

## Domain↔Data Adapter

```swift
// sources/Projects/Composition/Composition/LearningProjectLifecycle/LearningProjectRepositoryAdapter.swift
public struct LearningProjectRepositoryAdapter: LearningProjectRepository {
    public init(remote: LearningProjectRemote)

    public func register(githubRepoUrl: String, quizLevel: QuizLevel) async throws -> LearningProjectRegistration
    public func fetchProjects(page: Int, size: Int) async throws -> LearningProjectPage
    public func fetchProjectDetail(projectId: String) async throws -> LearningProjectDetail
    public func deleteProject(projectId: String) async throws
}
```

4개 메서드 모두 `remote`의 대응 메서드를 호출해 DTO를 받으면 007의 Domain 모델로 변환해
반환한다(FR-008, `register`의 `quizLevel`은 007 research.md 결정 7에 따라 호출 시 전달받은
값을 보존해 `LearningProjectRegistration.quizLevel`을 구성한다 — 서버 응답에서 읽지 않는다).
`remote`가 `DataLearningProjectError`를 던지면 대응하는 `LearningProjectError`로 변환해 다시
던진다.

## FR-014 테스트 매트릭스

**`LearningProjectRemoteAdapter`** — Fake `HTTPTransport` + Fake `LoginSessionStorage`를
주입한 실제 `HTTPClient`로 검증:

- 성공 4건: `registerProject`/`fetchProjects`/`fetchProjectDetail`/`deleteProject` 각각
  Fake transport가 200 + 서버 예시 JSON 반환 → 대응 DTO로 정확히 디코딩됨을 확인.
- 오류 4건: Fake transport가 400(`COMMON-001`)/401(`COMMON-002`)/404(`PROJECT-001`)/
  500(`COMMON-005`) 반환 → 각각 `DataLearningProjectError.invalidRequest`/`.unauthorized`/
  `.notFound`/`.serverError`.
- 오류 1건: Fake transport가 `HTTPClientError`(연결 실패·타임아웃·취소·디코딩 실패 등) 던짐
  → `DataLearningProjectError.unexpected`.
- 토큰 첨부 검증: Fake `sessionStorage`가 `StoredLoginSession`을 반환할 때 실제로 구성된
  `HTTPTransportRequest`의 `Authorization` 헤더가 `Bearer {accessToken}`과 일치하는지
  확인(FR-007, SC-004 관련).
- 토큰 부재 검증: Fake `sessionStorage`가 `nil`을 반환할 때 `Authorization` 헤더 없이
  요청이 전송되고, Fake transport가 401을 반환하면 `.unauthorized`로 도달하는지 확인
  (SC-004, spec.md 수용 시나리오 2-6).
- 요청 검증: 4개 메서드 각각 실제로 구성된 `HTTPTransportRequest`의 메서드·경로·쿼리
  파라미터·바디가 대응 엔드포인트와 일치하는지 확인(SC-003 회귀 고정).

**`LearningProjectRepositoryAdapter`** — Fake `LearningProjectRemote`로 검증:

- 성공 4건: Fake가 각 DTO 반환 → 대응 Domain 모델로 정확히 변환.
- 오류 4건: Fake가 `DataLearningProjectError`의 각 케이스를 던짐 → 대응하는
  `LearningProjectError` 케이스로 변환.

## 제외 책임(spec.md와 동일)

로그인 시작·세션 복원·토큰 갱신·폐기(`LoginSessionStorage`의 프로덕션 구현 포함, 범위
밖), 재등록·삭제 후 복원 판단(서버 책임, 007 research.md 결정과 동일), Feature/UI 소비,
App 수준 DI Container 등록.
