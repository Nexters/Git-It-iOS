# 기능 명세: GitHub·Git-It 프로젝트 API Composition Adapter 구축

**Git-flow 유형**: `feature`

**기능 브랜치**: `미생성 (예정: feature/network-composition-adapters)`

**생성일**: 2026-08-20

**상태**: 초안

**입력**: 사용자 설명: "007-learning-project-lifecycle에 대한 `/speckit-analyze` 논의 중 확인된 문제를 해소합니다 — FR-002/FR-005/FR-011/FR-016/FR-020의 '실제로 호출해야 한다'는 007의 Domain·Data 계약만으로는 충족되지 않으며, 이 저장소의 모든 이전 스펙(001-apple-social-login, 003-http-client)도 동일하게 실제 Composition Adapter 구현을 후속 작업으로 미뤄왔다. 이 기능은 007이 정의한 `ExternalRepositoryLookup`(GitHub)과 `LearningProjectRepository`(Git-It 서버)에 대해 이 저장소 최초의 프로덕션 Composition Adapter를 구현해 실제 네트워크 호출이 동작하게 한다. 인증 로그인·세션·토큰 갱신 Adapter는 `refreshSession`/`revokeRefreshToken`에 대응하는 서버 엔드포인트가 `Git-It-server-scheme.json`에서 확인되지 않아 이 기능의 범위에서 제외한다."

## 명확화

### 세션 2026-08-20

- 질문: 일시적 장애(타임아웃·연결 실패)가 발생하면 Composition Adapter가 자동 재시도를 수행해야 하나요? → 답변: 재시도하지 않는다. 즉시 대응하는 Domain 오류로 매핑해 UseCase·후속 Feature가 재시도 여부를 결정하게 한다.
- 질문: Composition Adapter가 실패를 진단 목적으로 기록(로깅)해야 하나요? → 답변: 기록하지 않는다. `003-http-client`가 이미 정한 "자체 기록·관찰 수단 미제공" 경계를 그대로 유지하며, 운영자는 후속 Feature를 통해 노출되는 타입화된 Domain 오류로 실패를 관찰한다.

## 변경 시나리오와 테스트 *(필수)*

이 기능의 실제 이해관계자는 007이 정의한 5개 UseCase 위에 화면(Feature)을 구현할 후속 개발자와, 이 기능이 배포된 뒤 실제 트래픽을 관찰할 운영자다. 007은 Domain·Data 패키지의 계약과 Test Double 기반 계약 테스트까지만 다루기로 스스로 범위를 한정했고([spec.md](../007-learning-project-lifecycle/spec.md) "범위 밖"), 그 결과 007이 끝나도 GitHub 공개 API·Git-It 서버로 나가는 실제 HTTP 요청은 이 저장소 어디에도 존재하지 않았다. 이 기능은 `sources/docs/package-rules/composition.md`가 정의한 Domain↔Data Adapter와 Data↔Infrastructure Adapter를 실제로 구현해 그 공백을 메운다.

### 시나리오 1 - GitHub 공개 API 확인이 실제 네트워크 호출로 동작한다 (우선순위: P1)

개발자가 007의 `FetchExternalRepository` UseCase에 이 기능이 제공하는 Composition Adapter를 주입해 호출하면, Test Double이 아니라 실제 `HTTPClient`(003-http-client)가 `https://api.github.com`으로 요청을 보내고, 그 응답이 007이 정의한 `ExternalRepository`/`ExternalRepositoryError`로 정확히 변환되어 돌아온다.

**주요 행위자**: 007의 UseCase를 소비할 후속 Feature 개발자

**우선순위 이유**: GitHub 확인은 학습 프로젝트 등록의 진입점이므로, 이 Adapter가 없으면 등록 자체가 실제 환경에서 동작할 수 없다. 인증이 필요 없어 시나리오 2보다 독립적으로 먼저 검증할 수 있다.

**독립 테스트**: 실제 GitHub 저장소 응답을 흉내 낸 `HTTPTransport` 테스트 대역을 주입한 `HTTPClient`로 Adapter를 구성하고, `owner`/`name`을 넘겨 `ExternalRepository`가 정확히 반환되는지 확인하는 것만으로 전체를 독립 검증할 수 있다.

**수용 시나리오**:

1. **전제** 존재하는 GitHub 저장소의 `owner`/`name`이 주어졌을 때, **실행** Adapter가 GitHub API 응답(200)을 받으면, **결과** `GitHubRepositoryResponseDTO`가 007의 `ExternalRepository`로 변환되어 반환된다.
2. **전제** GitHub API가 저장소를 찾을 수 없거나(404) Private이거나 rate limit(403)이거나 5xx를 반환했을 때, **실행** Adapter를 호출하면, **결과** 007의 `ExternalRepositoryError.other`가 던져진다.
3. **전제** `HTTPClient`가 연결 실패(`HTTPClientError.connectionFailed`)를 반환했을 때, **실행** Adapter를 호출하면, **결과** 007의 `ExternalRepositoryError.offline`이 던져진다.

---

### 시나리오 2 - Git-It 서버 학습 프로젝트 CRUD가 실제 네트워크 호출로 동작한다 (우선순위: P2)

개발자가 007의 `CreateLearningProject`/`FetchLearningProjects`/`FetchLearningProjectDetail`/`DeleteLearningProject` UseCase에 이 기능이 제공하는 Composition Adapter를 주입해 호출하면, 실제 `HTTPClient`가 유효한 액세스 토�큰을 Bearer 헤더로 첨부해 Git-It 서버의 `/api/v1/projects` 엔드포인트를 호출하고, 그 응답이 007이 정의한 Domain 모델·오류로 정확히 변환되어 돌아온다.

**주요 행위자**: 007의 UseCase를 소비할 후속 Feature 개발자, 배포 환경을 운영하는 운영자

**우선순위 이유**: 목록·상세·삭제는 등록이 이미 동작해야 의미가 있으므로 시나리오 1 다음 순위다. 유효한 액세스 토큰이 이미 주어진다고 가정하는 조건부 시나리오다(가정 참고).

**독립 테스트**: 실제 Git-It 서버 응답(성공·400·401·404·500)을 흉내 낸 `HTTPTransport` 테스트 대역을 주입한 `HTTPClient`로 Adapter를 구성하고, 4개 메서드 각각의 성공·오류 매핑을 확인하는 것으로 독립 검증할 수 있다.

**수용 시나리오**:

1. **전제** 유효한 액세스 토큰과 `githubRepoUrl`·`quizLevel`이 주어졌을 때, **실행** Adapter가 `POST /api/v1/projects`에 200 응답을 받으면, **결과** `RegisterProjectResponseDTO`가 007의 `LearningProjectRegistration`으로 변환되어 반환된다.
2. **전제** 유효한 액세스 토큰과 `page`·`size`가 주어졌을 때, **실행** Adapter가 `GET /api/v1/projects`에 200 응답을 받으면, **결과** `ProjectListResponseDTO`가 007의 `LearningProjectPage`로 변환되어 반환된다.
3. **전제** 유효한 액세스 토큰과 `projectId`가 주어졌을 때, **실행** Adapter가 `GET /api/v1/projects/{projectId}`에 200 응답을 받으면, **결과** `ProjectDetailResponseDTO`가 007의 `LearningProjectDetail`로 변환되어 반환된다.
4. **전제** 유효한 액세스 토큰과 `projectId`가 주어졌을 때, **실행** Adapter가 `DELETE /api/v1/projects/{projectId}`에 200 응답을 받으면, **결과** 오류 없이 완료된다.
5. **전제** 서버가 400(`COMMON-001`)·401(`COMMON-002`)·404(`PROJECT-001`)·500(`COMMON-005`) 중 하나를 반환했을 때, **실행** 4개 메서드 중 하나를 호출하면, **결과** 007의 `LearningProjectError`(`invalidRequest`/`unauthorized`/`notFound`/`unexpected`) 중 대응하는 케이스가 던져진다.
6. **전제** 액세스 토큰이 없거나 만료되어 서버가 401을 반환했을 때, **실행** 4개 메서드 중 하나를 호출하면, **결과** 별도 재시도나 재해석 없이 `LearningProjectError.unauthorized`가 그대로 던져진다.

---

### 예외·경계 사례

- `HTTPClient`가 타임아웃(`timedOut`)이나 취소(`cancelled`)를 반환하면 두 Adapter 모두 이를 GitHub 쪽은 `other`, Git-It 서버 쪽은 `unexpected`로 매핑한다 — 007이 이 두 케이스를 위한 전용 Domain 오류 케이스를 정의하지 않았으므로 재해석하지 않는다.
- 응답 디코딩이 실패하면(`HTTPClientError.responseDecodingFailed`, 또는 성공 상태 코드인데 007의 DTO 구조와 다른 응답) 두 Adapter 모두 이를 서버 내부 오류와 구분하지 않고 GitHub 쪽은 `other`, Git-It 서버 쪽은 `unexpected`로 매핑한다.
- GitHub API와 Git-It 서버는 서로 다른 base URL을 가지므로 두 Adapter는 서로 다른 `HTTPClient` 인스턴스(또는 구성)를 사용한다.
- 액세스 토큰을 얻는 지점 자체가 아직 없는 상태(범위 밖)에서 Adapter가 호출되면, 시스템은 토큰 부재를 별도로 처리하지 않고 서버의 401 응답으로 자연스럽게 이어지도록 둔다(수용 시나리오 2-6).

## 요구사항 *(필수)*

### 기능 요구사항

**GitHub Composition Adapter**

- **FR-001**: 시스템은 007의 `ExternalRepositoryLookup`(Domain)을 구현하는 Composition Adapter를 제공해 `FetchExternalRepository`가 실제 GitHub 공개 API 응답을 근거로 동작하게 해야 한다(`MUST`).
- **FR-002**: 이 Adapter는 `owner`·`name`으로 실제 `GET https://api.github.com/repos/{owner}/{name}` 요청을 `HTTPClient`로 전송해야 한다(`MUST`).
- **FR-003**: 이 Adapter는 성공 응답을 007의 `GitHubRepositoryResponseDTO`로 디코딩한 뒤 `ExternalRepository` Domain 모델로 변환해 반환해야 한다(`MUST`).
- **FR-004**: 이 Adapter는 `HTTPClientError`와 GitHub 응답 상태 코드를 007의 `ExternalRepositoryError`(`offline`/`other`) 케이스로 매핑해야 한다(`MUST`) — `invalidURLFormat`은 Domain UseCase가 Adapter 호출 전에 이미 처리하므로 이 Adapter의 매핑 대상이 아니다.

**Git-It 서버 Composition Adapter**

- **FR-005**: 시스템은 007의 `LearningProjectRepository`(Domain)를 구현하는 Composition Adapter를 제공해 `CreateLearningProject`·`FetchLearningProjects`·`FetchLearningProjectDetail`·`DeleteLearningProject` 4개 UseCase가 실제 Git-It 서버 응답을 근거로 동작하게 해야 한다(`MUST`).
- **FR-006**: 이 Adapter는 `POST /api/v1/projects`·`GET /api/v1/projects`·`GET /api/v1/projects/{projectId}`·`DELETE /api/v1/projects/{projectId}`를 각각 대응하는 UseCase 호출에서 실제로 `HTTPClient`로 전송해야 한다(`MUST`).
- **FR-007**: 이 Adapter는 Git-It 서버로 보내는 모든 요청에 호출 시점에 유효한 액세스 토큰을 `Authorization: Bearer` 헤더로 첨부해야 한다(`MUST`). 토큰 자체의 발급·저장·조회·갱신은 이 기능의 책임이 아니다(가정 참고).
- **FR-008**: 이 Adapter는 성공 응답 DTO(`RegisterProjectResponseDTO`/`ProjectListResponseDTO`/`ProjectDetailResponseDTO`)를 007의 Domain 모델(`LearningProjectRegistration`/`LearningProjectPage`/`LearningProjectDetail`)로 변환해 반환해야 한다(`MUST`).
- **FR-009**: 이 Adapter는 서버 응답의 상태 코드와 `code` 필드(`COMMON-001`/`COMMON-002`/`PROJECT-001`/`COMMON-005`)를 007의 `LearningProjectError`(`invalidRequest`/`unauthorized`/`notFound`/`unexpected`) 케이스로 매핑해야 한다(`MUST`).

**공통**

- **FR-010**: `HTTPClientError`(연결 실패·타임아웃·취소·요청 인코딩 실패·응답 디코딩 실패)는 두 Adapter 모두 대응하는 Domain 오류의 미분류 케이스로 매핑해야 한다(`MUST`) — GitHub Adapter는 연결 실패를 `offline`으로, 그 밖의 `HTTPClientError`는 `other`로 구분한다. Git-It 서버 Adapter는 모든 `HTTPClientError`를 `unexpected`로 매핑한다.
- **FR-011**: 시스템은 GitHub API·Git-It 서버 각각에 대해 서로 다른 base URL로 `HTTPClient`를 구성할 수 있어야 한다(`MUST`).
- **FR-012**: 두 Adapter 모두 재등록 판단·다음 세트 계산 등 007이 이미 UseCase나 Domain 모델에 배치한 비즈니스 규칙을 다시 구현하지 않아야 한다(`MUST NOT`) — 요청·응답 변환과 오류 매핑만 수행한다(`sources/docs/package-rules/composition.md` 제약조건).
- **FR-013**: 시스템은 로그인 시작·세션 복원·액세스 토큰 갱신·폐기를 수행하는 Composition Adapter를 구현하지 않아야 한다(`MUST NOT`) — `refreshSession`/`revokeRefreshToken`에 대응하는 서버 엔드포인트가 `Git-It-server-scheme.json`에서 확인되지 않아 범위 밖이다.
- **FR-014**: 두 Adapter는 각각 성공 경로 1개 이상과 예외·경계 사례 절이 식별한 모든 오류 경로를 검증하는 자동화된 테스트를 가져야 한다(`MUST`) — 실제 네트워크 호출 대신 `HTTPTransport`를 대체한 테스트 대역을 주입해 `HTTPClient`의 실제 요청 구성·응답 해석·오류 전파 경로를 그대로 실행하는 방식으로 검증한다.
- **FR-015**: 두 Adapter 모두 일시적 네트워크 장애(타임아웃·연결 실패 등)에서 자동 재시도를 수행하지 않고 즉시 대응하는 Domain 오류로 매핑해야 한다(`MUST NOT` 자동 재시도) — 재시도 여부 결정은 UseCase를 소비하는 후속 Feature의 책임이다.
- **FR-016**: 두 Adapter 모두 요청·응답·오류를 별도로 기록(로깅)하지 않아야 한다(`MUST NOT`) — `003-http-client`가 이미 정한 "자체 기록·관찰 수단 미제공" 경계를 유지하며, 운영자는 후속 Feature를 통해 노출되는 타입화된 Domain 오류(FR-004, FR-009)로 실패를 관찰한다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: `owner`/`name`이 주어지면, GitHub 응답을 흉내 낸 `HTTPTransport` 테스트 대역을 통과하는 통합 테스트가 실제 `HTTPClient` 요청 구성부터 `ExternalRepository` 반환까지 전 구간을 한 번에 검증한다.
- **SC-002**: Git-It 서버 4개 엔드포인트 각각에 대해 성공·오류(400/401/404/500) 응답을 흉내 낸 통합 테스트가 대응하는 Domain 모델 또는 `LearningProjectError` 케이스로 정확히 도달함을 100% 커버한다.
- **SC-003**: 두 Adapter의 요청 구성(URL·메서드·헤더·바디)과 응답 매핑이 회귀 테스트로 고정되어, 이후 리팩터링이나 007 계약 변경으로 매핑이 깨지면 즉시 실패로 드러난다.
- **SC-004**: 액세스 토큰이 없거나 만료된 상태로 Git-It 서버 요청을 보내는 테스트가, 실제 토큰 발급 로직 없이도 서버의 401 응답이 `LearningProjectError.unauthorized`로 예외 없이 도달함을 확인한다.

## 가정

- 007이 정의한 Domain·Data 계약(`ExternalRepositoryLookup`, `LearningProjectRepository`, `ExternalRepositoryRemote`, `LearningProjectRemote`, DTO, 오류 타입)을 이 기능이 그대로 재사용하며 재정의하지 않는다.
- `003-http-client`의 `HTTPClient`/`HTTPTransport`를 그대로 재사용하며 새로운 통신 인프라를 만들지 않는다.
- 호출 시점에 유효한 액세스 토큰을 얻을 수 있는 지점이 존재한다고 가정한다. 그 지점을 실제로 채우는 로그인·세션·토큰 갱신 Adapter는 이 기능의 범위 밖이며, `LoginSessionRemote.refreshSession`/`revokeRefreshToken`에 대응하는 서버 엔드포인트가 `Git-It-server-scheme.json`(Auth 태그: `POST /api/v1/auth/login/google`, `POST /api/v1/auth/login/apple`, `GET /api/v1/auth/token`뿐)에서 확인되지 않아 별도로 다뤄야 한다는 사실이 이번 조사에서 새로 드러났다.
- GitHub 공개 API 호출은 인증이 필요하지 않다고 가정한다(007 FR-002와 동일 전제).
- `Git-It-server-scheme.json`·GitHub API 응답 형식이 구현 시점까지 변경되지 않는다고 가정한다. 이 파일은 아직 커밋되지 않은 작업본이므로, 구현 시작 전 최신 상태인지 재확인이 필요하다.

## 범위 밖

- 로그인 시작·세션 복원·액세스 토큰 갱신·폐기를 수행하는 Composition Adapter(`AuthenticationProvider`/`LoginSessionRemote` 관련) — 대응하는 서버 엔드포인트(refresh/revoke)가 확인되지 않아 별도 스펙에서 다룬다. `001-apple-social-login`·`003-http-client`의 spec.md는 이 기능이 소급 수정하지 않는다.
- Feature(화면)·Navigation 구현과 App 수준 DI Container에 이 Adapter를 등록해 Feature에 전달하는 작업 — 아직 이 5개 UseCase를 소비하는 Feature가 없다.
- 007이 이미 범위 밖으로 명시한 항목: `FetchLearningSet` 등 나머지 5개 UseCase, 로컬 캐싱·영속화, Polling/Timer, Timeout 감시, 문제 생성 상태 재시도 전략.
- GitHub API·Git-It 서버 요청/응답 스키마 자체의 변경이나 재설계.
