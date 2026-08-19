# 기능 명세: Git-It 학습 도메인 UseCase 요구사항

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/domain-usecase-requirements`

**생성일**: 2026-08-19

**상태**: 초안

**입력**: 사용자 설명: "@git-it-domain-usecases @Git-It-server-scheme.json 를 통해서 UseCase 요구사항 명세서를 작성해주세요. 이후에 구현 작업들은 후행 스팩들을 통해 진행될 예정입니다. 요구사항 명세서를 작성하는 것을 목표로 직행해주세요"

## 명확화

### 세션 2026-08-19

- 질문: 학습 프로젝트 목록/상세 조회 응답에는 문제 생성 상태(`quizGenerationStatus` 등) 필드가 없다(등록 응답의 `status`만 존재). 생성이 아직 끝나지 않은 프로젝트를 목록·상세 조회에서 어떻게 판단해야 하는가? → 답변: 문제 생성이 `COMPLETED` 상태가 되기 전에는 프로젝트가 목록·상세 조회 결과에 전혀 노출되지 않는다(상세 조회는 존재하지 않는 프로젝트와 동일하게 404로 처리됨). 생성 중 상태를 앱에서 확인하는 흐름은 이 10개 UseCase의 범위 밖이며, 별도의 생성 상태 조회/알림 UseCase(예: 문제 생성 재시도 `retryQuizGeneration`과 함께)가 필요하다.
- 질문: 프로젝트 상세 조회 응답에는 `nextQuestionId`만 있고 `nextSetId`가 없다(목록 조회에는 `nextSetId`가 있음). 상세 화면에서 "다음에 풀 세트"는 무엇을 기준으로 정해 `FetchLearningSet`을 호출해야 하는가? → 답변: BE·Android 간 API 설계 합의(Slack 스레드, 이정원·류호성)에 따라 목록 조회(`FetchLearningProjects`)는 서버가 `nextSetId`와 `nextQuestionId`를 함께 반환하며, 이어 풀기는 이 두 값을 그대로 사용한다. 상세 조회(`FetchLearningProjectDetail`)에서는 `sets` 배열의 세트별 진행 정보(`completedCount` < `problemCount`)로 다음에 풀 세트를 판단한다. 모든 세트를 완료한 경우 서버는 다음 세트를 첫 번째 세트로 고정해 반환하며, 이 경우 학습 세트를 다시 조회하면 모든 문제가 이미 답변된 상태로 확인되므로 첫 문제부터 다시 푸는 재풀이로 처리한다.
- 질문: 객관식/서술형 답변 제출 응답에는 진행률(`overallProgressPercent` 등) 필드가 없다. 제출 이후 최신 진행률은 어떻게 반영되어야 하는가? → 답변: 제출 UseCase는 진행률을 반환하지 않는다. 최신 진행률이 필요한 화면은 제출 이후 `FetchLearningProjectDetail` 또는 `FetchLearningProjects`를 다시 호출해 진행률을 갱신해야 한다.
- 질문: `POST /api/v1/projects`의 서버 설명에 "다른 회원이 이미 등록한 저장소라면 그 문제 세트를 함께 씁니다"라는 문구가 있다. 재등록한 사용자는 원래 등록자와 같은 `projectId`를 공유하는가, 아니면 문제 콘텐츠만 재사용하고 본인만의 새 `projectId`를 받는가? → 답변: 사용자별로 별도의 `projectId`를 받는다. 문제 콘텐츠(문제 세트)는 여러 사용자 사이에 재사용되지만, 각 사용자의 프로젝트 레코드(진행률·삭제 권한)는 서로 공유되지 않는다.
- 질문: 사용자가 삭제한 프로젝트의 Repository를 동일 사용자가 다시 등록하면, 삭제된 기존 프로젝트가 복원되는가 아니면 새 프로젝트가 생성되는가? → 답변: 삭제됐던 기존 프로젝트가 복원된다. 재등록 요청은 삭제 여부와 무관하게 항상 동일 `projectId`를 반환하며, 이전 진행 상태(진행률, `myAnswer` 등)도 그대로 유지된다.
- 질문: 서로 다른 사용자가 같은 Repository를 서로 다른 `quizLevel`로 등록하면 어떻게 되는가? → 답변: 문제 콘텐츠는 (Repository, `quizLevel`) 조합 단위로 공유된다. 같은 Repository라도 같은 `quizLevel`을 고른 사용자끼리만 문제 세트를 공유하며, 다른 `quizLevel`을 고른 사용자가 등록하면 그 레벨에 맞는 문제 생성이 새로 트리거된다.
- 질문: 동일 사용자가 이미 등록한 Repository를 다른 `quizLevel`로 또 등록하면 어떻게 되는가? → 답변: 사용자당 Repository 하나에는 프로젝트가 하나만 존재한다. 이미 등록한 Repository를 다른 `quizLevel`로 다시 등록해도 새 프로젝트를 만들지 않고 기존 프로젝트를 그대로 반환하며, `quizLevel`도 바뀌지 않는다. (참고: 앞선 "다른 사용자가 같은 Repository를 서로 다른 `quizLevel`로 등록"하는 경우와는 다른 규칙이다 — 그 규칙은 사용자가 다를 때만 적용되며, 동일 사용자에게는 이 "저장소당 프로젝트 1개" 규칙이 우선한다.)

## 변경 시나리오와 테스트 *(필수)*

이 기능의 실제 이해관계자는 `sources/docs/git-it-domain-usecases/`에 정의된 10개 도메인 UseCase를 이후 별도의 `/speckit-specify` · `/speckit-plan` 호출로 하나씩 구현할 iOS 개발자입니다. 이 명세 자체는 화면이나 Swift 코드를 만들지 않으며, 각 UseCase의 책임(도메인 문서 기준)과 Git-It 서버 API 계약(`Git-It-server-scheme.json` 기준)을 하나로 대조·통합한 요구사항 문서를 산출물로 합니다. 최종 앱 사용자는 이 문서를 직접 인지하지 않으며, 후속 구현 스펙이 API를 재조사하지 않고 정확하게 진행되는 방식으로 간접적인 혜택을 받습니다.

### 시나리오 1 - 학습 프로젝트 생명주기 요구사항 확인 (우선순위: P1)

개발자는 외부 Repository 확인, 학습 프로젝트 등록, 목록·상세 조회, 삭제까지 학습 프로젝트 생명주기 전체의 요구사항과 그에 대응하는 Git-It 서버 API 계약(엔드포인트, 요청/응답 필드, 오류 코드)을 이 문서 하나에서 확인하고, 각 UseCase의 후속 구현 스펙을 API 재조사 없이 시작한다.

**주요 행위자**: 후속 UseCase 구현 스펙을 작성하는 iOS 개발자

**우선순위 이유**: 프로젝트 확인·등록·조회·삭제는 학습 앱의 진입점이며 다른 모든 학습 흐름(세트 조회, 답변 제출, 북마크)의 전제 조건이므로 가장 먼저 정확하게 문서화되어야 한다.

**독립 테스트**: 이 문서만 읽고 FetchExternalRepository, CreateLearningProject, FetchLearningProjects, FetchLearningProjectDetail, DeleteLearningProject 각각의 입력·출력·성공 응답·오류 응답(코드 포함)을 빠짐없이 재구성할 수 있는지 검토로 확인한다.

**수용 시나리오**:

1. **전제** 개발자가 GitHub Repository URL로 학습 프로젝트를 등록하는 흐름의 요구사항을 확인해야 할 때, **실행** 문서의 프로젝트 생명주기 절을 읽으면, **결과** GitHub API를 통한 사전 확인 책임, `POST /api/v1/projects` 요청 필드(`githubRepoUrl`, `quizLevel`)와 응답 필드(`projectId`, `status`), 재등록 시 멱등 동작, 400/401/500 오류 코드가 모두 확인된다.
2. **전제** 개발자가 목록·상세 조회 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** 페이지네이션 파라미터(`page`, `size`, `hasNext`)와 상세 응답 필드(진행률, 다음 문제, 세트별 진행), 404/401/500 오류 코드까지 확인된다.
3. **전제** 개발자가 삭제 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** 소프트 삭제 방식과, 소유권을 노출하지 않기 위해 "존재하지 않음"과 "본인 소유 아님"을 동일한 404로 응답한다는 사실이 확인된다.

---

### 시나리오 2 - 학습 세트 풀이 요구사항 확인 (우선순위: P2)

개발자는 학습 세트 조회부터 객관식·서술형 답변 제출까지, 문제 풀이 흐름의 요구사항과 문제 형식(`MULTIPLE_CHOICE`/`ESSAY`)별로 갈라지는 제출 계약을 이 문서에서 확인한다.

**주요 행위자**: 후속 UseCase 구현 스펙을 작성하는 iOS 개발자

**우선순위 이유**: 문제 풀이는 학습 프로젝트가 존재해야 의미가 있으므로 시나리오 1 다음 우선순위이며, 두 제출 UseCase(객관식/서술형)는 서로 다른 오류 조건과 응답 구조를 가져 혼동 없이 문서화해야 한다.

**독립 테스트**: 이 문서만 읽고 FetchLearningSet, SubmitChoiceAnswer, SubmitEssayAnswer 각각의 입력·출력과, 문제 형식이 요청과 맞지 않을 때의 오류 처리를 재구성할 수 있는지 검토로 확인한다.

**수용 시나리오**:

1. **전제** 개발자가 세트 조회 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** 문제 목록이 필터링 없이 생성 순서 그대로 반환되고, 기존 답변(`myAnswer`)이 있는 문제와 없는 문제를 구분해 이어 풀 지점을 판단할 수 있다는 요구사항이 확인된다.
2. **전제** 개발자가 객관식 답변 제출 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** `selectedIndex` 제출과 정답 여부·정답 index·해설 응답, 재제출 시 덮어쓰기 동작, 선택지 범위 초과나 형식 불일치 시 400 오류가 확인된다.
3. **전제** 개발자가 서술형 답변 제출 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** 서버가 채점하지 않고 rubric(배점 기준, 핵심 포인트, 예시 답안)을 반환해 학습자가 자가채점한다는 요구사항이 확인된다.

---

### 시나리오 3 - 북마크 관리 요구사항 확인 (우선순위: P3)

개발자는 문제 북마크 상태 설정과 북마크 목록 조회 요구사항을 이 문서에서 확인하고, toggle이 아닌 명시적 최종 상태 전달 방식과 프로젝트 필터링 동작을 정확히 파악한다.

**주요 행위자**: 후속 UseCase 구현 스펙을 작성하는 iOS 개발자

**우선순위 이유**: 북마크는 학습 프로젝트와 문제가 이미 존재해야 의미가 있는 보조 기능이며, 다른 UseCase의 구현을 막지 않으므로 가장 낮은 우선순위로 문서화한다.

**독립 테스트**: 이 문서만 읽고 SetQuestionBookmark, FetchBookmarkedQuestions 각각의 입력·출력과, 북마크 상태 전달이 toggle 추론이 아닌 명시적 지정이라는 요구사항을 재구성할 수 있는지 검토로 확인한다.

**수용 시나리오**:

1. **전제** 개발자가 북마크 설정 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** 현재 UI 상태로부터 toggle 여부를 추론하지 않고 사용자가 원하는 최종 `bookmarked` 값을 그대로 전달해야 한다는 요구사항이 확인된다.
2. **전제** 개발자가 북마크 목록 조회 요구사항을 확인해야 할 때, **실행** 문서를 읽으면, **결과** `projectId` 필터의 선택적 동작과, 필터와 무관하게 항상 전체를 반환하는 `availableProjects`의 용도가 확인된다.

---

### 예외·경계 사례

- Git-It 서버 API 스키마에는 저장소 검증 전용 엔드포인트가 없다. `FetchExternalRepository`는 Git-It 서버가 아닌 GitHub 공개 API를 직접 호출해 조회 가능 여부를 확인하며, 이 문서는 이 경계를 명시적으로 구분한다.
- 사용자당 Repository 하나에는 프로젝트가 하나만 존재한다. 동일 사용자가 이미 등록한 Repository를 다시 등록 요청하면 요청한 `quizLevel`이 기존과 다르더라도 새 프로젝트가 생기지 않고 기존 프로젝트가 그대로 반환되며 `quizLevel`도 바뀌지 않는다 — 도메인 문서에는 없는, 서버 스키마에서만 확인되는 멱등성 요구사항이다. 반면 다른 사용자가 같은 Repository를 처음 등록하면(그 사용자가 고른 `quizLevel`로) 문제 콘텐츠는 재사용하되 자신만의 새 `projectId`를 받는다 — `projectId`는 프로젝트를 공유하지 않는 사용자별 소유 자원이다.
- 문제 콘텐츠(문제 세트) 공유 단위는 Repository 하나가 아니라 (Repository, `quizLevel`) 조합이다 — 이는 서로 다른 사용자 사이의 콘텐츠 재사용 범위를 결정할 뿐, 동일 사용자가 한 Repository에 여러 `quizLevel` 프로젝트를 가질 수 있다는 뜻은 아니다(위 "저장소당 프로젝트 1개" 규칙이 사용자 단위로 우선한다). 같은 Repository라도 아직 아무도 요청하지 않은 `quizLevel`로 다른 사용자가 처음 등록하면 그 레벨의 문제 세트 생성이 새로 트리거된다.
- 삭제한 프로젝트의 Repository를 동일 사용자가 다시 등록하면 소프트 삭제 상태가 해제되고, 새 `projectId`가 아니라 삭제 이전의 `projectId`와 진행 상태(진행률, `myAnswer` 등)가 그대로 복원된다. 삭제는 재등록으로 다시 되돌릴 수 있는 상태 전환이며, 데이터를 영구히 소거하는 동작이 아니다.
- 프로젝트 등록 직후 `status`가 `COMPLETED`가 아니면 해당 프로젝트는 목록·상세 조회에서 노출되지 않으며(상세 조회는 404 `PROJECT-001`), 학습 세트 조회(`FetchLearningSet`)도 404(`QUIZ-006`, 문제 생성 미완료로 세트를 찾을 수 없음)를 반환한다. 생성 완료 대기·Polling·상태 확인은 이 10개 UseCase의 책임 밖이므로, 이 경계에서 무엇을 다루고 무엇을 다루지 않는지 이 문서에 명시한다.
- 사용자가 프로젝트의 모든 세트, 모든 문제를 이미 완료한 경우 서버는 다음에 풀 세트를 첫 번째 세트로 고정해 반환한다. 이때 학습 세트를 조회하면 모든 문제에 `myAnswer`가 채워져 있으므로, 시스템은 이를 오류로 취급하지 않고 처음 문제부터 다시 풀 수 있는 재풀이로 처리해야 한다.
- 답변 제출(`SubmitChoiceAnswer`, `SubmitEssayAnswer`) 응답은 갱신된 진행률을 포함하지 않는다. 제출 직후의 진행률 표시가 필요한 흐름은 `FetchLearningProjectDetail` 또는 `FetchLearningProjects`를 별도로 재호출해 최신 진행률을 얻어야 한다.
- 프로젝트 삭제와 상세 조회 모두, 존재하지 않는 프로젝트와 본인 소유가 아닌 프로젝트를 구분하지 않고 동일한 404(`PROJECT-001`)로 응답해 소유권 정보를 노출하지 않는다.
- 서버 스키마상 `RegisterProjectRequest.quizLevel`과 `SubmitChoiceAnswerRequest.selectedIndex`는 `required` 목록에 없어 값 없이도 호출 가능하지만, 두 도메인 문서 모두 이를 필수 입력으로 정의한다. 이 문서는 도메인 문서를 따라 클라이언트가 항상 값을 채워 전달한다고 명시하고, 값을 비웠을 때의 서버 동작은 범위 밖으로 남긴다.
- 같은 문제에 답을 다시 제출하면(객관식·서술형 모두) 이전 답이 누적되지 않고 최신 제출로 덮어써지며, 세트를 다시 조회하면 최신 답변 상태가 사용된다.
- 객관식 문제 id로 서술형 제출 엔드포인트를 호출하거나 그 반대인 경우, 두 엔드포인트 모두 400(`COMMON-001`, "문제 형식과 맞지 않는 답변입니다")으로 응답한다.

## 요구사항 *(필수)*

### 기능 요구사항

**FetchExternalRepository — 외부 Repository 확인**

- **FR-001**: 시스템은 사용자가 입력한 GitHub Repository URL에서 조회에 필요한 소유자·저장소 식별 정보를 식별해야 한다(`MUST`).
- **FR-002**: 시스템은 Git-It 서버가 아닌 GitHub 공개 API를 통해 해당 Repository의 존재 및 조회 가능 여부를 확인해야 한다(`MUST`). Git-It 서버 API에는 이 목적의 별도 엔드포인트가 없다.
- **FR-003**: 시스템은 확인된 Repository 메타데이터와 canonical Repository URL을 `ExternalRepository`로 구성해 반환해야 한다(`MUST`).
- **FR-004**: Private Repository이거나 조회에 실패한 Repository에 대해서는 등록 가능한 `ExternalRepository`를 반환하지 않아야 한다(`MUST NOT`).

**CreateLearningProject — 학습 프로젝트 등록**

- **FR-005**: 시스템은 canonical Repository URL(`githubRepoUrl`)과 사용자가 선택한 `quizLevel`(`L1`|`L2`|`L3`)을 `POST /api/v1/projects` 요청으로 서버에 전달해야 한다(`MUST`).
- **FR-006**: 시스템은 서버 응답의 `projectId`와 생성 진행 상태 `status`(`READY`|`ANALYZED`|`ANCHORED`|`REJECTED`|`FAILED`|`COMPLETED`)를 그대로 반환해야 한다(`MUST`). `status`가 `COMPLETED`가 아니면 아직 풀 수 있는 문제가 없음을 호출자가 판단할 수 있어야 한다(`MUST`).
- **FR-007**: 사용자당 Repository 하나에는 프로젝트가 하나만 존재해야 한다(`MUST NOT` 동일 사용자가 동일 Repository에 대해 두 개 이상의 프로젝트를 가짐). 동일 사용자가 이미 등록한 Repository를 다시 등록 요청하면 — 요청에 담긴 `quizLevel`이 기존 프로젝트의 `quizLevel`과 다르더라도 — 시스템은 새 프로젝트를 생성하지 않고 기존 `projectId`·`quizLevel`·`status`를 그대로 반환해야 한다(`MUST NOT` 새 프로젝트 생성, `MUST NOT` 기존 `quizLevel` 변경). 다른 사용자가 먼저 등록한 (Repository, `quizLevel`) 조합을 처음 등록하는 사용자는, 문제 콘텐츠(문제 세트)는 재사용하되 자신만의 새로운 `projectId`를 받아야 한다(`MUST`) — `projectId`는 사용자별로 소유되며 여러 사용자 사이에 공유되지 않는다(`MUST NOT`). 문제 콘텐츠 공유 단위는 Repository 하나가 아니라 (Repository, `quizLevel`) 조합이며(`MUST`), 다른 사용자가 아직 생성되지 않은 `quizLevel`로 처음 등록하면 그 레벨에 맞는 문제 생성이 새로 트리거되어야 한다(`MUST`).
- **FR-008**: 사용자가 삭제(`DeleteLearningProject`)했던 프로젝트의 Repository를 동일 사용자가 다시 등록하면(요청한 `quizLevel`과 무관하게), 시스템은 새 프로젝트를 생성하지 않고 삭제됐던 기존 프로젝트를 복원해 이전 `projectId`·`quizLevel`과 진행 상태(진행률, `myAnswer` 등)를 그대로 반환해야 한다(`MUST`).
- **FR-009**: `githubRepoUrl`이 비어 있거나 GitHub에 없는 저장소이거나 문제를 낼 수 없다고 판정된 저장소인 경우, 시스템은 서버의 400 오류(코드 `COMMON-001`)를 그대로 전달해야 한다(`MUST`).
- **FR-010**: 시스템은 생성 완료 대기, FCM 이벤트 수신, Polling/Timer 관리, Timeout 감시, 재시도, 생성 요청 정보의 로컬 영속화를 수행하지 않아야 한다(`MUST NOT`) — 이는 이 UseCase의 책임 밖이다.

**FetchLearningProjects — 학습 프로젝트 목록 조회**

- **FR-011**: 시스템은 `page`(0부터 시작, 기본값 0)와 `size`(기본값 10)를 조회 조건으로 `GET /api/v1/projects`에 전달해야 한다(`MUST`).
- **FR-012**: 시스템은 프로젝트별 진행 정보(`overallProgressPercent`)와 다음 학습 정보(`currentSetLabel`, `currentSetTitle`, `nextSetId`, `nextQuestionId`)를 응답에서 그대로 반환해야 한다(`MUST`). `nextSetId`와 `nextQuestionId`는 서버가 직접 계산해 반환하는 값이며, 시스템은 이어 풀기 진입점으로 이 두 값을 그대로 사용해야 한다(`MUST`).
- **FR-013**: 시스템은 다음 페이지 존재 여부(`hasNext`)를 반환해야 한다(`MUST`).
- **FR-014**: 문제 생성 상태가 `COMPLETED`가 아닌 프로젝트는 목록 조회 결과에 포함되지 않아야 한다(`MUST NOT`).
- **FR-015**: 인증되지 않은 요청에 대한 서버의 401 오류(코드 `COMMON-002`)를 시스템은 그대로 전달해야 한다(`MUST`).

**FetchLearningProjectDetail — 학습 프로젝트 상세 조회**

- **FR-016**: 시스템은 `projectId`를 기준으로 `GET /api/v1/projects/{projectId}`를 호출해야 한다(`MUST`).
- **FR-017**: 시스템은 Repository 기본 정보(`repositoryUrl`, `repositoryName`, `repositoryImageUrl`, `starCount`, `techStack`), 전체 진행률(`overallProgressPercent`), 다음 문제 id(`nextQuestionId`, 있는 경우), 세트별 진행 정보(`sets[].label`, `sets[].title`, `sets[].problemCount`, `sets[].completedCount`)를 반환해야 한다(`MUST`).
- **FR-018**: 존재하지 않거나 본인 소유가 아니거나 삭제된 프로젝트, 또는 문제 생성 상태가 `COMPLETED`가 아닌 프로젝트에 대해, 시스템은 소유권·생성 상태 정보를 노출하지 않는 서버의 404 오류(코드 `PROJECT-001`)를 그대로 전달해야 한다(`MUST`).
- **FR-019**: 상세 조회 응답에는 `nextSetId`가 없으므로, 시스템은 `sets` 배열에서 `completedCount`가 `problemCount`보다 작은 첫 세트를 다음에 풀 세트로 판단해야 한다(`MUST`). 모든 세트를 완료한 경우 서버가 반환하는 `nextQuestionId`는 재풀이 대상 세트의 첫 문제를 가리키는 것으로 처리해야 한다(`MUST`).

**DeleteLearningProject — 학습 프로젝트 삭제**

- **FR-020**: 시스템은 `projectId`를 기준으로 `DELETE /api/v1/projects/{projectId}`를 호출해야 한다(`MUST`).
- **FR-021**: 삭제 성공 후 시스템은 해당 프로젝트를 더 이상 유효한 학습 프로젝트로 취급하지 않아야 한다(`MUST NOT` 이후 목록·상세 결과에 포함). 단, 동일 사용자가 같은 Repository를 다시 등록하면 이 삭제 상태는 해제되고 프로젝트가 이전 진행 상태 그대로 복원된다(`CreateLearningProject` FR-008 참고) — 삭제는 이 재등록 경로를 막지 않는다(`MUST NOT`).
- **FR-022**: 존재하지 않거나 본인 소유가 아니거나 이미 삭제된 프로젝트에 대한 삭제 요청은 소유권 정보를 노출하지 않기 위해 동일한 404 오류(코드 `PROJECT-001`)로 처리되어야 한다(`MUST`).

**FetchLearningSet — 학습 세트 조회**

- **FR-023**: 시스템은 `projectId`와 `setId`를 기준으로 `GET /api/v1/projects/{projectId}/sets/{setId}`를 호출해야 한다(`MUST`).
- **FR-024**: 시스템은 세트에 포함된 모든 문제를 생성된 순서 그대로 반환해야 하며, 이미 푼 문제를 걸러내서는 안 된다(`MUST NOT` 필터링).
- **FR-025**: 이미 답변한 문제는 응답에 기존 답변 상태(`myAnswer`: 객관식은 `selectedIndex`, 서술형은 `text`, `correct`는 서술형에서 항상 null)를 포함해야 하며, 호출자는 `myAnswer`가 없는 첫 문제를 이어 풀 지점으로 식별할 수 있어야 한다(`MUST`). 세트의 모든 문제에 `myAnswer`가 있으면 시스템은 이를 재풀이 가능한 상태로 처리해야 한다(`MUST`).
- **FR-026**: 세트 조회 응답에는 정답, 해설, 채점 기준이 포함되지 않아야 한다(`MUST NOT`) — 이는 답변 제출 응답에서만 제공된다.
- **FR-027**: 내 프로젝트가 아니거나 그 프로젝트의 저장소에 없는 세트, 또는 문제 생성이 아직 끝나지 않은 프로젝트에 대한 요청은 서버의 404 오류(코드 `PROJECT-001` 또는 `QUIZ-006`)로 처리되어야 한다(`MUST`).

**SubmitChoiceAnswer — 객관식 답변 제출**

- **FR-028**: 시스템은 `projectId`, `questionId`와 사용자가 선택한 0부터 시작하는 `selectedIndex`를 `POST /api/v1/projects/{projectId}/questions/{questionId}/answers/choice`로 제출해야 한다(`MUST`).
- **FR-029**: 시스템은 정답 여부(`correct`), 정답 index(`answerIndex`), 해설(`explanation`)을 응답에서 반환해야 한다(`MUST`).
- **FR-030**: 같은 문제에 다시 제출한 답변은 누적되지 않고 최신 제출로 덮어써져야 하며(`MUST`), 이후 세트 재조회 시 최신 답변 상태가 사용되어야 한다(`MUST`).
- **FR-031**: 선택지 범위를 벗어난 index이거나 서술형 문제 id로 이 엔드포인트를 호출한 경우, 시스템은 서버의 400 오류(코드 `COMMON-001`)를 그대로 전달해야 한다(`MUST`).

**SubmitEssayAnswer — 서술형 답변 제출**

- **FR-032**: 시스템은 `projectId`, `questionId`와 사용자가 작성한 답변 텍스트(최대 2000자)를 `POST /api/v1/projects/{projectId}/questions/{questionId}/answers/essay`로 제출해야 한다(`MUST`).
- **FR-033**: 시스템은 해설(`explanation`)과 자가채점용 `rubric`(기준별 배점, 핵심 포인트, 만점·부분점수·0점 답안 예시)을 반환해야 한다(`MUST`).
- **FR-034**: 시스템은 사용자의 서술형 답안을 자체적으로 채점하지 않아야 한다(`MUST NOT`) — 채점은 학습자가 `rubric`을 보고 스스로 수행한다.
- **FR-035**: 같은 문제에 다시 제출한 답변은 누적되지 않고 최신 제출로 덮어써져야 한다(`MUST`). 답변이 비어 있거나 객관식 문제 id로 이 엔드포인트를 호출한 경우 서버의 400 오류(코드 `COMMON-001`)로 처리되어야 한다(`MUST`).
- **FR-036**: `SubmitChoiceAnswer`와 `SubmitEssayAnswer` 모두 제출 응답에 진행률을 포함하지 않는다(`MUST NOT`). 제출 직후 최신 진행률 표시가 필요한 흐름은 `FetchLearningProjectDetail` 또는 `FetchLearningProjects`를 별도로 재호출해야 한다(`MUST`).

**SetQuestionBookmark — 문제 북마크 상태 설정**

- **FR-037**: 시스템은 `projectId`, `questionId`와 사용자가 원하는 최종 `bookmarked`(`true`/`false`) 값을 `POST /api/v1/projects/{projectId}/questions/{questionId}/bookmark`로 전달해야 한다(`MUST`).
- **FR-038**: 시스템은 현재 UI 상태로부터 toggle 여부를 추론하지 않아야 하며(`MUST NOT`), 항상 명시적인 최종 상태를 전송해야 한다(`MUST`).
- **FR-039**: `bookmarked` 값이 없으면 400(코드 `COMMON-001`), 프로젝트 또는 문제를 찾을 수 없으면 404(코드 `PROJECT-001` 또는 `QUIZ-005`)로 처리되어야 한다(`MUST`).

**FetchBookmarkedQuestions — 북마크한 문제 목록 조회**

- **FR-040**: 시스템은 `projectId`를 선택적 필터로 `GET /api/v1/projects/bookmarks`에 전달해야 하며, 생략 시 전체 프로젝트의 북마크를 반환해야 한다(`MUST`).
- **FR-041**: 시스템은 북마크된 문제 목록(각 항목의 프로젝트 식별자·이름, 세트 식별자(`setId`), 세트 라벨, 세트 내 문제 번호, 문제 식별자·본문 포함)과 총 개수(`totalCount`)를 반환해야 한다(`MUST`). `setId`는 문제 풀이가 오직 `GET /api/v1/projects/{projectId}/sets/{setId}`를 통해서만 가능하므로, 북마크한 문제를 바로 풀이로 이어가는 데 필수적인 값이다.
- **FR-042**: 시스템은 `projectId` 필터 적용 여부와 무관하게 북마크가 하나라도 있는 프로젝트 전체 목록(`availableProjects`)을 함께 반환해야 한다(`MUST`) — 필터 UI 구성에 사용된다.

### 핵심 엔터티

- **ExternalRepository**: 등록 전, GitHub 공개 API로 확인한 외부 Repository 정보. canonical Repository URL과 등록에 필요한 메타데이터를 담는다.
- **LearningProject**: 사용자가 학습 중인 프로젝트. `projectId`는 사용자별로 소유되는 자원이며, 사용자당 Repository 하나에는 프로젝트가 하나만 존재한다(`quizLevel`은 그 사용자에 한해 최초 등록 시점에 고정됨). 여러 사용자가 같은 Repository를 등록해도 프로젝트 자체는 공유되지 않으며, 각자 고른 `quizLevel`에 해당하는 문제 콘텐츠만 (Repository, `quizLevel`) 단위로 재사용된다. 목록 조회에서는 요약 정보(진행률, 다음 학습 위치)를, 상세 조회에서는 Repository 정보와 세트별 진행 정보를 포함한다. `QuizGenerationStatus`가 `COMPLETED`가 아닌 동안에는 목록·상세 조회 어디에도 노출되지 않는다. 삭제는 소프트 삭제이며, 동일 사용자가 같은 Repository를 재등록하면(요청한 `quizLevel`과 무관하게) 진행 상태를 유지한 채 복원된다.
- **QuizGenerationStatus**: 프로젝트 등록 후 문제 생성이 진행되는 단계(`READY`, `ANALYZED`, `ANCHORED`, `REJECTED`, `FAILED`, `COMPLETED`). `COMPLETED`여야 학습 세트를 조회하거나 목록·상세에서 프로젝트를 확인할 수 있다. `COMPLETED` 이전 단계의 진행 상황을 사용자에게 보여주는 흐름은 이 문서가 다루는 10개 UseCase의 범위 밖이다.
- **QuizLevel**: 사용자가 선택하는 문제 난이도(`L1`, `L2`, `L3`). 직급과 무관하게 문제의 깊이만 구분한다. 같은 Repository라도 `QuizLevel`이 다르면 별도의 문제 세트(콘텐츠)가 생성·공유되는 단위 경계가 된다.
- **LearningSet**: 프로젝트에 걸린 문제 묶음. 라벨, 제목, 안내문(orientation), 난이도, 소속 문제 목록을 가진다.
- **Question**: 세트에 속한 개별 문제. 형식(`MULTIPLE_CHOICE`|`ESSAY`)에 따라 선택지 유무와 제출 대상 UseCase가 갈린다. 인용한 코드 위치(Source)를 근거로 가진다.
- **MyAnswer**: 사용자가 이미 제출한 답변 상태. 객관식은 선택 index, 서술형은 답변 텍스트를 가지며, 정답 여부는 서술형에서 항상 비어 있다.
- **Rubric**: 서술형 답변 자가채점 기준. 기준별 배점, 핵심 포인트, 만점·부분점수·0점 예시 답안으로 구성된다.
- **BookmarkedQuestion**: 사용자가 북마크한 문제를 나타내며, 소속 프로젝트·세트·문제 번호와 본문을 포함한다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: `git-it-domain-usecases` 폴더의 10개 UseCase 문서 전원이 대응하는 Git-It 서버 API 엔드포인트(메서드, 경로)와 1:1로 매핑되어 이 문서에 기록된다.
- **SC-002**: 문서화된 10개 UseCase 각각이 성공 응답 필드와 발생 가능한 오류 응답(HTTP 상태 코드와 서버 오류 코드 포함)을 빠짐없이 포함해, 후속 계획 단계에서 `Git-It-server-scheme.json`을 다시 열어보지 않고도 진행할 수 있다.
- **SC-003**: 도메인 문서와 서버 API 스키마 사이에서 발견된 불일치·격차(멱등성, 선택적/필수 필드 차이, 검증 엔드포인트 부재, 문서화되지 않은 API 등)가 예외·경계 사례 또는 가정 섹션에 100% 기록된다.
- **SC-004**: 이 문서만으로 10개 UseCase 각각의 후속 `/speckit-specify` 또는 `/speckit-plan` 실행을 시작할 수 있는 커버리지가 100%이다(추가 API 조사 없이 입력·출력·오류 처리를 확정할 수 있음).

## 가정

- `FetchExternalRepository`의 GitHub Repository 확인은 Git-It 서버가 아닌 GitHub 공개 API(`https://api.github.com`)를 직접 호출한다고 가정한다. 도메인 문서가 "GitHub API를 통해"라고 명시하며, `Git-It-server-scheme.json`에도 별도의 저장소 검증 엔드포인트가 없음을 확인했다.
- `quizLevel`(`RegisterProjectRequest`)과 `selectedIndex`(`SubmitChoiceAnswerRequest`)는 서버 스키마상 `required`로 명시되어 있지 않지만, 두 도메인 문서 모두 이를 필수 입력으로 정의하므로 클라이언트는 항상 명시적인 값을 채워 전달한다고 가정한다. 값을 비운 채 호출했을 때의 서버 동작은 이 문서의 범위 밖이다.
- `001-apple-social-login` 스펙이 이미 인증·로그인 흐름(`POST /api/v1/auth/login/apple` 포함)과 토큰 저장·갱신·로그아웃을 다루고 있으므로, 이 문서는 로그인 이후 인증된 사용자를 전제로 하는 학습 도메인 UseCase만 다룬다고 가정한다.
- `Git-It-server-scheme.json`에는 존재하지만 대응하는 도메인 UseCase 문서가 `git-it-domain-usecases` 폴더에 없는 API(문제 생성 재시도 `retryQuizGeneration`, 구글 로그인, 회원 프로필/개발 분야/개발 수준/기기 정보/큐레이션 등록, 회원 탈퇴, 액세스 토큰 검증)는 이번 명세의 범위에 포함하지 않는다고 가정한다. 이들은 대응하는 도메인 문서가 추가된 뒤 별도 명세로 다룬다.
- 각 UseCase 응답의 공통 래퍼(`success`, `data`, `code`, `message`, `errors`)와 오류 코드 체계는 서버가 제공하는 그대로 유지된다고 가정하며, 이를 Domain 오류로 변환하는 구체적인 Swift 타입 설계는 후속 구현 스펙(Data 레이어)에서 결정한다.
- 목록 조회의 `nextSetId`/`nextQuestionId`, 북마크 목록의 `setId` 필드는 `Git-It-server-scheme.json`에 반영되어 있지만, 그렇게 설계된 이유("문제 풀이는 `GET /api/v1/projects/{projectId}/sets/{setId}`로만 가능하다")는 어떤 문서에도 없고 BE·Android 간 사전 논의(2026-08-19 명확화 세션에서 확인)에만 남아 있었다. 이 문서는 그 논의 결과를 반영해 FR-012, FR-019, FR-041에 명시했다.

## 범위 밖

- Apple/Google 로그인, 회원 프로필 조회·수정(개발 분야, 개발 수준, 기기 등록, 큐레이션), 회원 탈퇴, 액세스 토큰 검증 — 대응하는 도메인 UseCase 문서가 없어 이번 명세에서 제외하며, 별도 명세 대상이다.
- 문제 생성 재시도(`retryQuizGeneration`) — 서버 API에는 존재하나 대응하는 도메인 UseCase 문서가 아직 없어 제외한다.
- 각 UseCase의 실제 Swift `protocol`/DTO/Repository Adapter 구현, 화면(Feature) 구성과 Navigation — 후속 구현 스펙(`/speckit-specify`, `/speckit-plan`, `/speckit-tasks`)에서 다룬다.
- 로컬 캐싱·영속화, Polling/Timer, Timeout 감시, 생성 상태 재시도 전략 — 각 도메인 문서가 명시적으로 제외한 책임이며 이 문서도 동일하게 범위 밖으로 둔다.
