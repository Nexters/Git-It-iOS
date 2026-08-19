# 기능 명세: 학습 프로젝트 생명주기 UseCase 구현

**Git-flow 유형**: `feature`

**기능 브랜치**: `미생성 (예정: feature/learning-project-lifecycle)`

**생성일**: 2026-08-19

**상태**: 초안

**입력**: 사용자 설명: "spec 006에 정의된 유즈케이스 중 구현되지 않은 요구사항을 구현합니다" — 범위는 spec 006의 시나리오 1(P1, 학습 프로젝트 생명주기) 5개 UseCase로 한정: `FetchExternalRepository`, `CreateLearningProject`, `FetchLearningProjects`, `FetchLearningProjectDetail`, `DeleteLearningProject`.

## 명확화

### 세션 2026-08-19

- 질문: `FetchExternalRepository`의 FR-004는 "Private Repository이거나 조회에 실패한 Repository"를 하나로 묶어 등록 불가로만 처리한다. GitHub 공개 API는 저장소 없음(404), 접근 불가/rate limit(403), 네트워크 오류를 서로 다른 상황으로 반환하는데, Domain 오류를 몇 가지로 구분해야 하는가? → 답변: 세 가지로 구분한다 — URL 형식 오류(입력 URL 자체를 파싱할 수 없음), 오프라인(네트워크에 연결할 수 없어 GitHub API를 호출하지 못함), 그 밖의 오류(Private Repository, 저장소 없음, GitHub API rate limit, 5xx 등 나머지 모든 실패를 하나의 케이스로 처리).

## 변경 시나리오와 테스트 *(필수)*

이 기능의 실제 이해관계자는 이 5개 UseCase 위에 화면(Feature)을 구현할 후속 개발자입니다. [006-domain-usecase-requirements](../006-domain-usecase-requirements/spec.md)가 요구사항과 서버 API 계약을 이미 확정했으므로, 이 기능은 그 요구사항을 `DomainAuthentication`/`DataAuthentication`과 동일한 레이어 경계(Domain: Contracts·Models·UseCases / Data: Contracts·DTOs·Models·Errors·Repository Adapter)로 실제 동작하는 Swift 코드로 옮기는 것을 목표로 합니다. 최종 앱 사용자는 이 코드를 직접 인지하지 않으며, 이 기능이 완료되어야 후속 Feature 스펙이 API를 재조사하거나 재설계하지 않고 화면을 구현할 수 있다는 점에서 간접적인 혜택을 받습니다. 이 기능은 화면(Feature/UI)과 Composition 계층의 DI 배선을 만들지 않습니다.

### 시나리오 1 - 외부 Repository 확인과 학습 프로젝트 등록이 실제로 동작한다 (우선순위: P1)

개발자가 `FetchExternalRepository`와 `CreateLearningProject` UseCase를 호출하면, GitHub 공개 API로 확인한 Repository 정보를 바탕으로 Git-It 서버에 학습 프로젝트를 등록하고 `projectId`와 생성 상태를 돌려받는다. 같은 Repository를 다시 등록하거나 삭제했던 Repository를 재등록해도 spec 006이 정의한 멱등성·복원 규칙대로 동작한다.

**주요 행위자**: 후속 Feature 스펙을 구현할 개발자

**우선순위 이유**: 등록은 학습 프로젝트 생명주기의 진입점이며, 이 흐름이 없으면 조회·삭제를 검증할 대상 프로젝트 자체가 존재할 수 없다.

**독립 테스트**: 유효한 GitHub Repository URL로 `FetchExternalRepository`를 호출해 `ExternalRepository`를 얻고, 그 결과로 `CreateLearningProject`를 호출해 `projectId`를 받는 계약 테스트로 전체를 독립 검증할 수 있으며, 이것만으로 학습 프로젝트를 최초로 만들 수 있다는 가치를 제공한다.

**수용 시나리오**:

1. **전제** 조회 가능한 Public GitHub Repository의 URL이 주어졌을 때, **실행** `FetchExternalRepository`를 호출하면, **결과** GitHub 공개 API로 확인된 canonical Repository URL과 메타데이터를 담은 `ExternalRepository`가 반환된다.
2. **전제** GitHub Repository URL로 파싱할 수 없는 형식의 문자열이 주어졌을 때, **실행** `FetchExternalRepository`를 호출하면, **결과** GitHub API를 호출하지 않고 URL 형식 오류로 실패가 식별된다.
3. **전제** 네트워크에 연결할 수 없는 상태일 때, **실행** `FetchExternalRepository`를 호출하면, **결과** 오프라인 오류로 실패가 식별된다.
4. **전제** Private Repository이거나 존재하지 않는 Repository의 URL이 주어졌을 때, **실행** `FetchExternalRepository`를 호출하면, **결과** 등록 가능한 `ExternalRepository`가 반환되지 않고 그 밖의 오류로 실패가 식별된다.
5. **전제** canonical Repository URL과 `quizLevel`이 준비되었을 때, **실행** `CreateLearningProject`를 호출하면, **결과** `POST /api/v1/projects`가 호출되고 응답의 `projectId`와 `status`가 그대로 반환된다.
6. **전제** 같은 사용자가 이미 등록한 Repository를 다른 `quizLevel`로 다시 등록 요청했을 때, **실행** `CreateLearningProject`를 호출하면, **결과** 새 프로젝트가 생성되지 않고 기존 `projectId`·`quizLevel`·`status`가 그대로 반환된다.
7. **전제** 사용자가 삭제했던 프로젝트의 Repository를 같은 사용자가 다시 등록했을 때, **실행** `CreateLearningProject`를 호출하면, **결과** 새 프로젝트 대신 삭제 이전 `projectId`와 진행 상태가 복원되어 반환된다.
8. **전제** `githubRepoUrl`이 비어 있거나 GitHub에 없는 저장소일 때, **실행** `CreateLearningProject`를 호출하면, **결과** 서버의 400 오류(`COMMON-001`)가 Domain 오류로 매핑되어 전달된다.

---

### 시나리오 2 - 학습 프로젝트 목록·상세 조회가 실제로 동작한다 (우선순위: P2)

개발자가 `FetchLearningProjects`와 `FetchLearningProjectDetail` UseCase를 호출하면, 문제 생성이 완료된 프로젝트만 페이지네이션 목록으로, 또는 단일 프로젝트의 Repository 정보·진행률·세트별 진행 정보를 상세로 돌려받는다.

**주요 행위자**: 후속 Feature 스펙을 구현할 개발자

**우선순위 이유**: 등록된 프로젝트를 확인할 수 있어야 등록이 성공했는지 검증할 수 있으며, 삭제 이전에 대상 프로젝트가 존재함을 확인하는 전제 조건이기도 하다.

**독립 테스트**: 문제 생성이 완료된 프로젝트가 있는 계정으로 `FetchLearningProjects`를 호출해 목록에서 해당 프로젝트를 확인하고, 그 `projectId`로 `FetchLearningProjectDetail`을 호출해 세트별 진행 정보를 확인하는 계약 테스트로 독립 검증할 수 있다.

**수용 시나리오**:

1. **전제** 문제 생성이 완료된 프로젝트가 있을 때, **실행** `FetchLearningProjects`를 `page`·`size`로 호출하면, **결과** 진행률과 다음 학습 정보(`nextSetId`, `nextQuestionId` 포함)를 담은 목록과 `hasNext`가 반환된다.
2. **전제** 문제 생성이 `COMPLETED`가 아닌 프로젝트가 있을 때, **실행** `FetchLearningProjects`를 호출하면, **결과** 해당 프로젝트는 목록에 포함되지 않는다.
3. **전제** 유효한 `projectId`가 주어졌을 때, **실행** `FetchLearningProjectDetail`을 호출하면, **결과** Repository 정보, 전체 진행률, `sets[].completedCount`/`problemCount`를 포함한 세트별 진행 정보가 반환되고, 다음에 풀 세트가 `completedCount < problemCount`인 첫 세트로 판단된다.
4. **전제** 존재하지 않거나 본인 소유가 아니거나 삭제된 `projectId`가 주어졌을 때, **실행** `FetchLearningProjectDetail`을 호출하면, **결과** 소유권 정보를 노출하지 않는 동일한 404 오류(`PROJECT-001`)가 Domain 오류로 매핑되어 전달된다.

---

### 시나리오 3 - 학습 프로젝트 삭제가 실제로 동작한다 (우선순위: P3)

개발자가 `DeleteLearningProject` UseCase를 호출하면, 프로젝트가 소프트 삭제되어 이후 목록·상세 조회에서 사라진다.

**주요 행위자**: 후속 Feature 스펙을 구현할 개발자

**우선순위 이유**: 삭제는 등록·조회가 이미 동작해야 검증 가능한 생명주기의 마지막 동작이며, 다른 UseCase의 구현을 막지 않는 독립 기능이다.

**독립 테스트**: 이미 존재하는 `projectId`로 `DeleteLearningProject`를 호출한 뒤, 같은 `projectId`로 `FetchLearningProjectDetail`을 호출하면 404가 반환되는 것으로 독립 검증할 수 있다.

**수용 시나리오**:

1. **전제** 본인 소유의 유효한 `projectId`가 주어졌을 때, **실행** `DeleteLearningProject`를 호출하면, **결과** `DELETE /api/v1/projects/{projectId}`가 호출되고 성공 이후 해당 프로젝트는 목록·상세 조회에서 더 이상 확인되지 않는다.
2. **전제** 존재하지 않거나 본인 소유가 아니거나 이미 삭제된 `projectId`가 주어졌을 때, **실행** `DeleteLearningProject`를 호출하면, **결과** 소유권 정보를 노출하지 않는 동일한 404 오류(`PROJECT-001`)가 Domain 오류로 매핑되어 전달된다.

---

### 예외·경계 사례

- `FetchExternalRepository`는 Git-It 서버가 아닌 GitHub 공개 API(`https://api.github.com`)를 직접 호출한다 — Git-It 서버 API에는 검증 전용 엔드포인트가 없다.
- 사용자당 Repository 하나에는 프로젝트가 하나만 존재한다. 동일 사용자의 재등록은 `quizLevel`이 다르더라도 새 프로젝트를 만들지 않고 기존 프로젝트를 그대로 반환한다. 다른 사용자가 같은 (Repository, `quizLevel`) 조합을 처음 등록하면 문제 콘텐츠는 재사용하되 자신만의 새 `projectId`를 받는다.
- 삭제된 프로젝트의 Repository를 동일 사용자가 다시 등록하면 소프트 삭제 상태가 해제되고 삭제 이전 `projectId`와 진행 상태가 그대로 복원된다.
- 문제 생성 상태가 `COMPLETED`가 아닌 프로젝트는 목록에 노출되지 않고, 상세 조회는 존재하지 않는 프로젝트와 동일하게 404(`PROJECT-001`)로 처리된다. 생성 완료 대기·Polling·FCM 알림·재시도는 이 기능의 책임 밖이다.
- 상세 조회 응답에는 `nextSetId`가 없으므로 `sets` 배열에서 `completedCount < problemCount`인 첫 세트로 다음에 풀 세트를 판단해야 한다.
- 서버 스키마상 `quizLevel`은 `required`가 아니지만 도메인 문서는 필수 입력으로 정의하므로, `CreateLearningProject`는 항상 값이 채워진 `quizLevel`을 요구한다. 값을 비운 호출의 서버 동작은 범위 밖이다.
- 목록·상세·삭제 모두 인증되지 않은 요청은 서버의 401 오류(`COMMON-002`)를 그대로 Domain 오류로 전달한다.

## 요구사항 *(필수)*

### 기능 요구사항

**FetchExternalRepository — 외부 Repository 확인**

- **FR-001**: 시스템은 사용자가 입력한 GitHub Repository URL에서 조회에 필요한 소유자·저장소 식별 정보를 실제로 파싱해야 한다(`MUST`). 파싱할 수 없는 형식이면 GitHub API를 호출하지 않고 URL 형식 오류로 실패해야 한다(`MUST`).
- **FR-002**: 시스템은 Git-It 서버가 아닌 GitHub 공개 API를 실제로 호출해 해당 Repository의 존재 및 조회 가능 여부를 확인해야 한다(`MUST`).
- **FR-003**: 시스템은 확인된 Repository 메타데이터와 canonical Repository URL을 `ExternalRepository` 값으로 구성해 반환해야 한다(`MUST`).
- **FR-004**: 시스템은 `FetchExternalRepository` 실패를 다음 세 가지 Domain 오류로 구분해 반환해야 하며(`MUST`), 어떤 경우에도 등록 가능한 `ExternalRepository`는 반환하지 않아야 한다(`MUST NOT`):
  - **URL 형식 오류**: 입력된 문자열에서 소유자·저장소 식별 정보를 파싱할 수 없는 경우(FR-001).
  - **오프라인**: 네트워크에 연결할 수 없어 GitHub API 호출 자체가 이루어지지 못한 경우.
  - **그 밖의 오류**: 위 두 경우를 제외한 모든 실패를 하나의 케이스로 처리한다 — Private Repository, 존재하지 않는 Repository, GitHub API rate limit, 5xx 등을 서로 구분하지 않는다.

**CreateLearningProject — 학습 프로젝트 등록**

- **FR-005**: 시스템은 canonical Repository URL(`githubRepoUrl`)과 `quizLevel`(`L1`|`L2`|`L3`)을 실제로 `POST /api/v1/projects` 요청 본문에 담아 전송해야 한다(`MUST`).
- **FR-006**: 시스템은 서버 응답의 `projectId`와 `status`(`READY`|`ANALYZED`|`ANCHORED`|`REJECTED`|`FAILED`|`COMPLETED`)를 Domain 모델로 그대로 반환해야 한다(`MUST`).
- **FR-007**: 동일 사용자가 이미 등록한 Repository를 다른 `quizLevel`로 다시 등록 요청하면, 시스템은 새 프로젝트를 생성하지 않고 서버가 반환한 기존 `projectId`·`status`와, 서버가 재등록 시 값이 바뀌지 않음을 보장하는 기존 `quizLevel`을 그대로 반환해야 한다(`MUST`, 클라이언트는 이 멱등 응답을 별도로 재해석하거나 거부하지 않는다). `quizLevel`은 서버 응답 필드가 아니라 이 보장을 근거로 클라이언트가 보존한 값이다.
- **FR-008**: 사용자가 삭제했던 프로젝트의 Repository를 동일 사용자가 다시 등록하면, 시스템은 서버가 반환한 복원된 `projectId`·`quizLevel`과 진행 상태를 그대로 반환해야 한다(`MUST`).
- **FR-009**: `githubRepoUrl`이 비어 있거나 GitHub에 없는 저장소이거나 문제를 낼 수 없다고 판정된 저장소인 경우, 시스템은 서버의 400 오류(`COMMON-001`)를 Domain 오류 타입으로 매핑해 전달해야 한다(`MUST`).
- **FR-010**: 시스템은 생성 완료 대기, FCM 이벤트 수신, Polling/Timer 관리, Timeout 감시, 재시도, 생성 요청 정보의 로컬 영속화를 구현하지 않아야 한다(`MUST NOT`).

**FetchLearningProjects — 학습 프로젝트 목록 조회**

- **FR-011**: 시스템은 `page`(기본값 0)와 `size`(기본값 10)를 실제로 `GET /api/v1/projects` 쿼리 파라미터로 전송해야 한다(`MUST`).
- **FR-012**: 시스템은 프로젝트별 진행 정보(`overallProgressPercent`)와 다음 학습 정보(`currentSetLabel`, `currentSetTitle`, `nextSetId`, `nextQuestionId`)를 Domain 모델로 그대로 반환해야 한다(`MUST`).
- **FR-013**: 시스템은 `hasNext`를 Domain 모델로 반환해야 한다(`MUST`).
- **FR-014**: 문제 생성 상태가 `COMPLETED`가 아닌 프로젝트는 서버 응답에 포함되지 않으며, 시스템은 이 서버 동작을 그대로 신뢰하고 별도의 클라이언트 필터링을 추가하지 않는다(`MUST NOT` 중복 필터링).
- **FR-015**: 인증되지 않은 요청에 대한 서버의 401 오류(`COMMON-002`)를 시스템은 Domain 오류 타입으로 매핑해 전달해야 한다(`MUST`).

**FetchLearningProjectDetail — 학습 프로젝트 상세 조회**

- **FR-016**: 시스템은 `projectId`를 경로 파라미터로 실제 `GET /api/v1/projects/{projectId}`를 호출해야 한다(`MUST`).
- **FR-017**: 시스템은 Repository 기본 정보(`repositoryUrl`, `repositoryName`, `repositoryImageUrl`, `starCount`, `techStack`), 전체 진행률, `nextQuestionId`(있는 경우), 세트별 진행 정보(`sets[].label`, `sets[].title`, `sets[].problemCount`, `sets[].completedCount`)를 Domain 모델로 그대로 반환해야 한다(`MUST`).
- **FR-018**: 존재하지 않거나 본인 소유가 아니거나 삭제된 프로젝트, 또는 문제 생성이 `COMPLETED`가 아닌 프로젝트에 대해, 시스템은 서버의 404 오류(`PROJECT-001`)를 소유권·생성 상태 구분 없이 동일한 Domain 오류 타입으로 매핑해야 한다(`MUST`).
- **FR-019**: 시스템은 `sets` 배열에서 `completedCount`가 `problemCount`보다 작은 첫 세트를 다음에 풀 세트로 실제로 계산해야 한다(`MUST`) — 서버 상세 응답에는 `nextSetId`가 없으므로 이 계산은 클라이언트 책임이다.

**DeleteLearningProject — 학습 프로젝트 삭제**

- **FR-020**: 시스템은 `projectId`를 경로 파라미터로 실제 `DELETE /api/v1/projects/{projectId}`를 호출해야 한다(`MUST`).
- **FR-021**: 삭제 성공 응답 이후, 시스템은 별도의 로컬 캐시나 상태를 유지해 삭제된 프로젝트를 계속 유효한 것으로 취급하지 않아야 한다(`MUST NOT`).
- **FR-022**: 존재하지 않거나 본인 소유가 아니거나 이미 삭제된 프로젝트에 대한 삭제 요청에 대해, 시스템은 서버의 404 오류(`PROJECT-001`)를 동일한 Domain 오류 타입으로 매핑해야 한다(`MUST`).

**공통**

- **FR-023**: 5개 UseCase는 각각 `DomainAuthentication`의 `UseCases` 폴더 관례를 따라 단일 책임의 실행 가능한 타입(프로토콜 또는 구조체/클래스)으로 Domain 패키지에 구현되어야 한다(`MUST`).
- **FR-024**: 5개 UseCase가 의존하는 Repository 계약은 Domain 패키지의 `Contracts`에 정의되고, 그 구현은 Data 패키지에서 서버 API 호출과 DTO↔Domain 모델 변환을 담당해야 한다(`MUST`) — `DomainAuthentication`/`DataAuthentication`과 동일한 레이어 경계를 유지한다.
- **FR-025**: 각 UseCase는 성공 경로 1개 이상과 문서화된 모든 오류 경로를 검증하는 자동화된 테스트를 가져야 한다(`MUST`) — `FetchExternalRepository`는 URL 형식 오류·오프라인·그 밖의 오류 3가지, 나머지 4개 UseCase는 각자 정의된 서버 오류 코드(400/401/404)를 대상으로 한다.

### 핵심 엔터티

- **ExternalRepository**: 등록 전, GitHub 공개 API로 확인한 외부 Repository 정보. canonical Repository URL과 등록에 필요한 메타데이터를 담는다.
- **ExternalRepositoryError**: `FetchExternalRepository` 실패를 나타내는 Domain 오류. `invalidURLFormat`(URL 형식 오류), `offline`(오프라인), `other`(그 밖의 모든 실패: Private Repository, 저장소 없음, GitHub API rate limit, 5xx 등)로 구분된다.
- **LearningProject**: 사용자가 학습 중인 프로젝트. `projectId`는 사용자별로 소유되며, 사용자당 Repository 하나에는 프로젝트가 하나만 존재한다. 목록 조회에서는 요약 정보(진행률, 다음 학습 위치)를, 상세 조회에서는 Repository 정보와 세트별 진행 정보를 포함한다.
- **QuizGenerationStatus**: 프로젝트 등록 후 문제 생성이 진행되는 단계(`READY`, `ANALYZED`, `ANCHORED`, `REJECTED`, `FAILED`, `COMPLETED`). `COMPLETED`여야 목록·상세에서 프로젝트가 노출된다.
- **QuizLevel**: 사용자가 선택하는 문제 난이도(`L1`, `L2`, `L3`). 같은 Repository라도 `QuizLevel`이 다르면 별도의 문제 콘텐츠 공유 단위가 된다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: 개발자가 유효한 GitHub Repository URL만으로 `FetchExternalRepository` → `CreateLearningProject` → `FetchLearningProjects`/`FetchLearningProjectDetail` → `DeleteLearningProject`로 이어지는 전체 생명주기를 계약 테스트로 실행해 각 단계의 반환 값과 부작용(삭제 후 미노출 등)을 확인할 수 있다.
- **SC-002**: 5개 UseCase 각각에 대해 성공 응답 필드가 자동화된 테스트로 100% 커버된다. `CreateLearningProject`/`FetchLearningProjects`/`FetchLearningProjectDetail`/`DeleteLearningProject`는 spec 006이 정의한 Git-It 서버 오류 코드(400/401/404) 경로를, `FetchExternalRepository`는 URL 형식 오류·오프라인·그 밖의 오류 3가지 경로를 각각 100% 커버한다.
- **SC-003**: 재등록 멱등성(FR-007), 삭제 후 재등록 복원(FR-008), 존재하지 않음/소유권 아님 동일 404 처리(FR-018, FR-022)를 포함해 spec 006이 식별한 서버-도메인 불일치 규칙이 회귀 테스트로 고정되어, 이후 리팩터링에서도 깨지면 즉시 실패로 드러난다.
- **SC-004**: 새로 추가된 Domain/Data 코드는 `DomainAuthentication`/`DataAuthentication`과 동일한 폴더 관례(`Contracts/`, `Models/`, `DTOs/`, `Errors/`, `UseCases/`)를 따르며, plan.md `프로젝트 구조`에 명시된 파일 경로와 실제 생성된 파일 경로가 100% 일치한다.

## 가정

- 이 기능은 spec 006이 이미 확정한 요구사항과 오류 코드를 재해석 없이 그대로 구현 대상으로 삼는다. 요구사항 자체가 다시 바뀌면 spec 006을 먼저 갱신한다.
- `001-apple-social-login`에서 확립된 인증(로그인된 사용자, 액세스 토큰 자동 첨부·갱신)과 `003-http-client`에서 확립된 HTTP 클라이언트를 그대로 재사용할 수 있다고 가정하며, 이 기능은 새로운 인증·통신 인프라를 만들지 않는다.
- 이 기능은 Domain·Data 패키지 구현까지만 다루며, 실제 GitHub·Git-It 서버 호출을 수행하는 Composition Adapter(Domain↔Data, Data↔Infrastructure)와 그 DI 배선, Feature/UI 화면 구현은 이 5개 UseCase를 소비할 후속 스펙([008-network-composition-adapters](../008-network-composition-adapters/spec.md) 등)에서 다룬다고 가정한다 — spec 006의 "범위 밖" 절과 동일한 경계다. FR-001~FR-025의 "실제로 호출해야 한다"는 이 기능(Domain·Data 계약과 계약 테스트)과 008(실제 호출을 수행하는 Composition Adapter)이 함께 충족하는 요구사항이며, 007 단독으로는 계약 수준까지만 충족한다.
- `git-it-domain-usecases`의 나머지 5개 UseCase(`FetchLearningSet`, `SubmitChoiceAnswer`, `SubmitEssayAnswer`, `SetQuestionBookmark`, `FetchBookmarkedQuestions`)는 이 기능의 범위 밖이며, 별도의 후속 스펙에서 다룬다고 가정한다.
- `Git-It-server-scheme.json`에 반영된 서버 API 계약(엔드포인트, 요청/응답 필드, 오류 코드)이 구현 시점까지 변경되지 않는다고 가정한다.

## 범위 밖

- `FetchLearningSet`, `SubmitChoiceAnswer`, `SubmitEssayAnswer`, `SetQuestionBookmark`, `FetchBookmarkedQuestions` — spec 006 시나리오 2·3에 속하며 별도의 후속 스펙에서 다룬다.
- Feature(화면)·Navigation 구현과 Composition 계층의 DI 배선 — 이 5개 UseCase를 소비할 후속 스펙에서 다룬다.
- 실제 GitHub 공개 API·Git-It 서버 호출을 수행하는 Composition Adapter 구현 — `ExternalRepositoryLookup`/`LearningProjectRepository`의 Domain↔Data Adapter와 `ExternalRepositoryRemote`/`LearningProjectRemote`의 Data↔Infrastructure Adapter(`HTTPClient` 연동, Bearer 토큰 첨부 포함)는 [008-network-composition-adapters](../008-network-composition-adapters/spec.md)에서 다룬다.
- 로컬 캐싱·영속화, Polling/Timer, Timeout 감시, 문제 생성 상태 재시도 전략 — spec 006이 이미 각 UseCase의 책임 밖으로 명시했다.
- Apple/Google 로그인, 회원 프로필, 문제 생성 재시도(`retryQuizGeneration`) 등 spec 006 범위 밖으로 이미 명시된 API.
