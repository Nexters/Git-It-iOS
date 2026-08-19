# 006-domain-usecase-requirements 암묵지 기록

**대상 기능**: `006-domain-usecase-requirements`

**기록 원칙**: 복수 근거에서 해석한 지식을 상태와 범위와 함께 append-only로 보존한다.

## TK-20260819-001: 북마크 목록 응답의 setId는 "문제 풀이는 세트 단위로만 가능하다"는 제약에서 파생된 값이다

**기록일**: 2026-08-19
**상태**: 검증됨
**확신도**: 높음
**적용 범위**: `FetchBookmarkedQuestions` (및 이를 소비해 문제 풀이로 이어가는 후속 화면)
**관련 항목**: spec.md FR-040

### 해석

`BookmarkedQuestionResponse`에 `setId`가 포함된 이유는 단순한 부가 정보가 아니라, Git-It 서버에 "문제 하나만 단독으로 조회·풀이하는 API가 없고 오직 `GET /api/v1/projects/{projectId}/sets/{setId}`로 세트 전체를 통해서만 문제를 풀 수 있다"는 서버 구조상 제약이 있기 때문이며, 이 제약은 `git-it-domain-usecases`의 어떤 문서에도 명시되어 있지 않다.

### 근거

- `sources/docs/Git-It-server-scheme.json`의 `BookmarkedQuestionResponse` 스키마: `projectId`, `projectName`, `setId`, `setLabel`, `problemNumber`, `questionId`, `question` 필드를 가지며 `setId`가 포함되어 있다(2026-08-19 확인, 재확인 가능).
- 사용자가 `/speckit-clarify` 세션에서 확인해 준 결정: Git-It BE(이정원)·Android(류호성) 간 Slack 논의 원문에서, Android 개발자가 "문제를 풀려면 `GET /api/v1/projects/{projectId}/sets/{setId}`를 통해서만 풀 수 있는 걸로 파악했다"며 북마크 목록에 `setId` 추가를 요청했고 BE가 이를 수락해 반영했다(사용자가 확인한 결정, 이 세션의 명확화 답변으로 재확인 가능).

### 적용과 제외

- 적용: 북마크된 문제를 눌러 풀이 화면으로 바로 진입시키는 흐름을 설계할 때, `questionId`만으로는 진입이 불가능하며 반드시 `setId`를 함께 사용해야 한다고 판단하는 근거로 적용한다.
- 제외: 서버에 향후 문제 단독 조회 API가 추가되는 경우 이 제약은 더 이상 유효하지 않으므로, 그 시점의 스키마로 재확인해야 한다.

### 반례와 불확실성

Slack 대화는 캡처된 시점의 논의이며 이후 서버 설계가 바뀌었을 가능성을 배제할 수 없다. 다만 현재(2026-08-19) `Git-It-server-scheme.json`에 문제 단독 조회 엔드포인트가 없다는 점은 별도로 확인했다(`paths`에 `GET /api/v1/projects/{projectId}/questions/{questionId}` 형태의 엔드포인트가 존재하지 않음).

### 검증 또는 승격 조건

`Git-It-server-scheme.json`이 갱신되어 문제 단독 조회 API가 추가되거나 `setId` 없이 풀이 진입이 가능해지면 이 해석은 폐기 대상이다. 후속 UseCase 구현 스펙(`FetchBookmarkedQuestions` 관련)에서 이 제약을 요구사항으로 재확인하면 명시 문서로 승격한다.

### 연결

없음

## TK-20260819-002: 학습 세트 "다음에 풀 위치" 필드는 목록·상세 조회에서 서로 다른 방식으로 노출되며, 완료 시 서버는 첫 세트로 고정 응답한다

**기록일**: 2026-08-19
**상태**: 검증됨
**확신도**: 높음
**적용 범위**: `FetchLearningProjects`, `FetchLearningProjectDetail`, `FetchLearningSet`의 "이어 풀기/재풀이" 진입점 판단
**관련 항목**: spec.md FR-011, FR-018, FR-024

### 해석

프로젝트 목록 조회(`FetchLearningProjects`)는 서버가 `nextSetId`와 `nextQuestionId`를 함께 계산해 반환하지만, 프로젝트 상세 조회(`FetchLearningProjectDetail`)는 `nextQuestionId`만 반환하고 `nextSetId`는 반환하지 않는다 — 이는 실수나 결함이 아니라 목록 API 설계 시점의 의도적 결정이며, 상세 조회에서는 `sets` 배열의 세트별 진행 정보로 클라이언트가 직접 "다음 세트"를 계산하는 것이 전제된 구조다. 또한 프로젝트의 모든 세트·문제를 이미 완료한 경우, 서버는 "안 푼 문제가 있는 세트"를 찾는 대신 편의상 `nextSetId`를 고정적으로 첫 번째 세트로 반환하기로 결정했으며, 이 경우 클라이언트는 해당 세트를 다시 조회했을 때 모든 문제에 `myAnswer`가 이미 채워져 있는 상태를 오류가 아니라 "처음부터 다시 풀기(재풀이)"로 처리해야 한다.

### 근거

- `sources/docs/Git-It-server-scheme.json`: `GET /api/v1/projects` 응답 예시 항목에는 `nextSetId`와 `nextQuestionId`가 모두 있고, `GET /api/v1/projects/{projectId}` 응답 예시에는 `nextQuestionId`만 있고 `nextSetId`가 없다(2026-08-19 확인, 재확인 가능).
- 사용자가 `/speckit-clarify` 세션에서 확인해 준 결정: Git-It BE(이정원)·Android(류호성) 간 Slack 논의 원문에서 "마지막 세트의 마지막 문제를 풀었을 경우"에 대해 BE가 "일단 setId 1로 고정해서 보내줄게"라고 결정했고, Android가 "여러 번 문제를 푸는 경우에는 모든 리스트가 푼 문제로 확인될 거니까 그때는 q1부터 문제 풀게끔 예외처리하면 될 것 같다"고 답했으며, 최종적으로 BE가 "nextSetId, nextQuestionId 둘 다 응답할게"라고 확정했다(사용자가 확인한 결정, 이 세션의 명확화 답변으로 재확인 가능).

### 적용과 제외

- 적용: 목록 화면에서 "이어 풀기" 버튼은 서버가 반환한 `nextSetId`/`nextQuestionId`를 그대로 사용한다고 판단하는 근거로, 상세 화면에서는 `sets` 배열의 `completedCount`/`problemCount` 비교로 다음 세트를 계산해야 한다고 판단하는 근거로 적용한다. 완료 후 재조회 시 전 문항 `myAnswer` 존재를 오류로 처리하지 않는다는 판단의 근거로도 적용한다.
- 제외: 상세 조회 응답 스키마에 향후 `nextSetId`가 추가되면 이 해석(클라이언트 계산 필요)은 더 이상 유효하지 않으므로 그 시점의 스키마로 재확인해야 한다. 세트가 하나도 없는(문제 생성 자체가 안 된) 프로젝트의 동작에는 이 해석을 적용하지 않는다 — 그 경우는 [[TK-20260819-001]]과 별개로 `QuizGenerationStatus`에 의해 애초에 목록·상세 조회 결과에서 제외된다(spec.md FR-013, FR-017).

### 반례와 불확실성

Slack 대화 속 "setId 1로 고정"이라는 표현이 실제 서버 구현에서 세트 목록의 첫 번째 항목(배열 인덱스 0)을 의미하는지, 아니면 라벨상 "Set 1"에 대응하는 특정 `setId` 값을 의미하는지는 대화만으로 확정할 수 없다. 두 경우 모두 실무적으로는 "완료 후 다시 조회하면 배열의 첫 세트가 오는 것"으로 동일하게 처리되지만, 정확한 서버 로직은 재확인이 필요하다.

### 검증 또는 승격 조건

후속 `FetchLearningProjectDetail`/`FetchLearningSet` 구현 스펙에서 실제 서버 응답으로 "전체 완료 후 상세 재조회" 시나리오를 검증하면 명시 문서로 승격한다. `Git-It-server-scheme.json`이 상세 응답에 `nextSetId`를 추가하도록 갱신되면 이 해석은 재검토 대상이다.

### 연결

[[TK-20260819-001]]
