# UC01~UC20 정본 카탈로그

**출처**: `private/spec.md`(Spec-Kit ID `014-all-usecases-implementation`) 7장의 커밋 사본이다. `private/**`는 `.gitignore`로 커밋되지 않으므로([명확화 세션 2026-08-22](../spec.md#명확화) 참고) 이 문서를 UC01~UC20의 Protocol·입출력·요구사항·검증 계약 정본으로 사용한다. 패키지 컨벤션·오류 정본은 [research.md](../research.md), [data-model.md](../data-model.md)를 참고한다.

---

### UC01 — Public GitHub Repository 조회

**Domain Protocol**: `FetchExternalRepositoryUseCase`
**Concrete**: `FetchExternalRepository`
**입력**: raw GitHub URL string
**출력**: canonical `ExternalRepository`
**외부 경계**: GitHub public repository API
**소비 Feature**: U02

요구사항:

- URL parse 실패 시 외부 request 0회다.
- canonical owner/repository URL과 표시 metadata를 보존한다.
- Git-It Bearer token을 전송하지 않는다.
- private/not-found/조회 불가를 등록 가능한 값으로 만들지 않는다.
- rate limit은 `externalRateLimited`로 구분하고 DEC-011 safe default를 사용한다.
- 이전 URL request의 늦은 response를 무시한다.

검증:

- valid canonicalization
- malformed URL no-call
- not-found/private/rate-limit/offline mapping
- no Authorization header
- request identity

### UC02 — 학습 프로젝트 생성 요청 접수

**Domain Protocol**: `CreateLearningProjectUseCase`
**Concrete**: `CreateLearningProject`
**입력**: `githubRepoURL`, `QuizLevel`
**출력**: `ProjectRegistrationReceipt`
**서버 operation**: `POST /api/v1/projects`
**소비 Feature**: U02

요구사항:

- canonical URL과 `L1|L2|L3`를 항상 전송한다.
- 중복 submit은 서버 request 최대 1건이다.
- 성공은 generation 완료가 아니라 request receipt다.
- `requestStatus` raw value를 보존하고 polling cursor로 사용하지 않는다.
- in-flight 동안만 loading을 표시한다.
- 성공 후 explicit CTA로 U03에 이동한다.
- status/retry endpoint를 U02/U03에 주입하지 않는다.

검증:

- quizLevel 100% 포함
- raw status 대소문자 무손실
- no generation polling
- duplicate tap single-flight
- 400/401/500 input preservation

### UC03 — 전체 학습 프로젝트 snapshot 조회

**Domain Protocol**: `FetchLearningProjectsUseCase`
**Concrete**: `FetchLearningProjects`
**입력**: 없음
**출력**: `LearningProjectPage` 또는 동일 의미의 snapshot
**서버 operation**: `GET /api/v1/projects?page=0&size=20` compatibility call
**소비 Feature**: U03, U04

요구사항:

- Domain/Feature에 page cursor·append·next-page retry 상태를 만들지 않는다.
- 서버 배열 순서를 유지한다.
- full snapshot 성공 시 전체 교체한다.
- refresh 실패 시 기존 snapshot을 유지한다.
- `nextSetID?`, `nextQuestionID?`를 보존한다.
- `hasNext=false`를 compatibility field로만 취급한다.

검증:

- 21개 이상 단일 response 접근
- next page request 0회
- optional route ID
- late refresh response 무시
- existing snapshot preservation

### UC04 — 학습 프로젝트 상세 조회

**Domain Protocol**: `FetchLearningProjectDetailUseCase`
**Concrete**: `FetchLearningProjectDetail`
**입력**: `projectID`
**출력**: `LearningProjectDetail`
**서버 operation**: `GET /api/v1/projects/{projectID}`
**소비 Feature**: U07

요구사항:

- Repository 정보, 전체 진행률, `nextQuestionID?`, ordered `sets`를 보존한다.
- set progress count를 하드코딩하지 않는다.
- target set은 first incomplete, 없으면 first set이다.
- detail `nextQuestionID?`는 selected set의 soft preference다.
- sets empty이면 CTA disabled + 확정 copy, polling 없음이다.
- project unavailable의 세부 원인을 추론하지 않는다.

검증:

- projectID exact pass-through
- first incomplete/replay/empty fallback
- set order preservation
- preferred question fallback handoff

### UC05 — 학습 프로젝트 삭제

**Domain Protocol**: `DeleteLearningProjectUseCase`
**Concrete**: `DeleteLearningProject`
**입력**: `projectID`
**출력**: Void
**서버 operation**: `DELETE /api/v1/projects/{projectID}`
**소비 Feature**: U04

요구사항:

- confirmation 전 request 0회다.
- committing 중 dismiss·중복·다른 target mutation을 차단한다.
- success 전 row를 제거하지 않는다.
- 404는 임의 성공 제거가 아니라 full snapshot refresh다.
- 500/transport는 row와 snapshot 보존 + retry feedback이다.
- 삭제는 soft delete 의미이며 복원 가능성을 단정하지 않는다.

검증:

- cancel 0 call, confirm exactly 1 call
- committing lock
- 404 reconciliation
- temporary failure state preservation
- result-lost re-entry refresh

### UC06 — 학습 세트 조회

**Domain Protocol**: `FetchLearningSetUseCase`
**Concrete**: `FetchLearningSet`
**입력**: `projectID`, `setID`
**출력**: `LearningSet`
**서버 operation**: `GET /api/v1/projects/{projectID}/sets/{setID}`
**소비 Feature**: U08

요구사항:

- 문제를 서버 순서대로 모두 반환한다.
- `myAnswer?`, question format, choices/source/rubric 공개 시점을 보존한다.
- 시작 index는 preferred question → first unanswered → index 0이다.
- 정답·해설·rubric을 제출 전에 노출하지 않는다.
- route identity를 `projectID + setID`로 묶는다.

검증:

- all question formats mapping
- server order
- resume fallback 3단계
- hidden solution before submission
- project/set unavailable distinction

### UC07 — 객관식 답변 제출

**Domain Protocol**: `SubmitChoiceAnswerUseCase`
**Concrete**: `SubmitChoiceAnswer`
**입력**: `projectID`, `questionID`, zero-based `selectedIndex`
**출력**: `ChoiceAnswerResult`
**서버 operation**: `POST .../answers/choice`
**소비 Feature**: U08

요구사항:

- selection 전 제출하지 않는다.
- index 범위를 검증한다.
- 서버의 `correct`, `answerIndex`, `explanation`을 보존한다.
- 결과 전 correct/incorrect UI를 표시하지 않는다.
- 재제출은 최신 값을 덮어쓴다.
- progress를 결과에서 추정하지 않는다.

검증:

- invalid index no-call
- exact request index
- correct/incorrect result mapping
- duplicate submit single-flight
- latest answer overwrite

### UC08 — 서술형 답변 제출

**Domain Protocol**: `SubmitEssayAnswerUseCase`
**Concrete**: `SubmitEssayAnswer`
**입력**: `projectID`, `questionID`, text
**출력**: `EssayAnswerResult`
**서버 operation**: `POST .../answers/essay`
**소비 Feature**: U08

요구사항:

- trim 후 empty 제출을 차단한다.
- 최대 2000자를 적용한다.
- explanation과 rubric 전체를 보존한다.
- 앱이 `correct`를 생성하지 않는다.
- 재제출은 최신 text를 덮어쓴다.
- progress를 추정하지 않는다.

검증:

- whitespace no-call
- length boundary
- rubric mapping
- generated correct 0건
- latest text overwrite

### UC09 — 문제 북마크 최종 상태 설정

**Domain Protocol**: `SetQuestionBookmarkUseCase`
**Concrete**: `SetQuestionBookmark`
**입력**: `projectID`, `questionID`, desired `bookmarked`
**출력**: final `BookmarkState` 또는 Bool
**서버 operation**: `POST .../bookmark`
**소비 Feature**: U08

요구사항:

- toggle event가 아니라 desired final bool을 전송한다.
- 성공 response의 bool을 정본으로 반영한다.
- 실패 시 previous server state를 유지/복원한다.
- 같은 question mutation을 직렬화한다.
- U05 목록에서 직접 해제 control을 제공하지 않는다.

검증:

- exact desired bool
- final response authority
- duplicate tap serialization
- rollback/previous state retention

### UC10 — 북마크 목록 조회

**Domain Protocol**: `FetchBookmarkedQuestionsUseCase`
**Concrete**: `FetchBookmarkedQuestions`
**입력**: optional `projectID`
**출력**: `BookmarkedQuestionCollection`
**서버 operation**: `GET /api/v1/projects/bookmarks`
**소비 Feature**: U05, U08

요구사항:

- `totalCount`, 전체 `availableProjects`, filtered `bookmarks`를 보존한다.
- bookmark item의 `projectID + setID + questionID`를 보존한다.
- filter 변경 시 availableProjects를 filtered 결과로 재계산하지 않는다.
- U08에서는 current project/set/question으로 초기 bookmark를 결합한다.
- response 전 false를 정본으로 표시하지 않는다.
- bookmark load 실패가 성공한 set load를 무효화하지 않는다.

검증:

- unfiltered/filtered semantics
- route ID completeness
- availableProjects invariance
- unknown-before-loaded state
- stale filter response ignore

### UC11 — Apple 로그인과 Git-It session 시작

**Domain Protocol**: `SignInUseCase`
**Concrete**: `SignIn`
**입력**: `AuthenticationMethod.apple`
**출력**: `AuthenticationOutcome` with session/onboarding phase
**서버 operation**: `POST /api/v1/auth/login/apple`
**소비 Feature**: U01

요구사항:

- 하나의 명시적 tap당 Apple attempt 최대 1개다.
- attemptID/nonce/state/expiry/replay를 검증한다.
- user cancellation은 일반 오류 경고가 아니다.
- valid idToken만 server exchange에 전달한다.
- token pair와 `needsCuration` 보호 저장 성공 후에만 authenticated다.
- idToken을 user identity로 저장하지 않는다.
- token 원문을 Feature에 반환하지 않는다.

검증:

- state match/nil/mismatch/expiry/replay/missing token/cancel
- server exchange exactly once
- storage failure rollback
- needsCuration preservation
- token redaction

### UC12 — Session refresh

**Domain Protocol**: `RefreshSessionUseCase`
**Concrete**: `RefreshSession`
**입력**: 없음
**출력**: `SessionRefreshOutcome`
**서버 operation**: **미제공 / INT-API-001**
**소비 Feature**: Root session coordinator

구현 가능 범위:

- Domain Protocol·outcome·single-flight 규칙
- Session repository의 atomic replacement 계약
- Root 보호 화면 비노출·waiter join·거부/temporary 분기
- Data capability boundary와 release blocker

금지:

- 임의 refresh path·request/response DTO
- local token 연장 또는 fake success
- temporary failure에서 credential 삭제

완료 판정:

- 코드 구조 완료와 production capability 완료를 분리한다.
- 서버 또는 승인 adapter 계약·E2E 없이는 UC12 production 완료로 표시하지 않는다.

### UC13 — Access token 유효성 확인

**Domain Protocol**: `VerifyAccessTokenUseCase`
**Concrete**: `VerifyAccessToken`
**입력**: 없음
**출력**: Void 또는 검증 outcome
**서버 operation**: `GET /api/v1/auth/token`
**소비 Feature**: Root restore/U03 bootstrap

요구사항:

- current access token을 Bearer로 보낸다.
- 200 `data=null`을 curation 완료로 해석하지 않는다.
- local onboarding state를 변경하지 않는다.
- 401은 refresh/session flow로 전달한다.
- temporary failure에서 protected UI를 노출하지 않는다.

검증:

- valid/401/transport
- Authorization header
- onboarding state unchanged
- no fabricated `needsCuration=false`

### UC14 — 로그아웃과 best-effort revoke

**Domain Protocol**: `SignOutUseCase`
**Concrete**: `SignOut`
**입력**: 없음
**출력**: unauthenticated outcome
**서버 revoke**: **미제공 / INT-API-001**
**소비 Feature**: U06, Root

요구사항:

- refresh token snapshot을 확보한다.
- local token/onboarding/legal protected record와 child effects를 먼저 제거한다.
- Apple authorization reference를 정리한다.
- revoke는 best-effort이며 실패가 local logout을 되돌리지 않는다.
- revoke path·DTO를 임의 생성하지 않는다.

검증:

- local clear always completes
- child effect cancellation
- revoke 최대 1회
- revoke failure no rollback
- protected screen re-exposure 0건

### UC15 — 초기 curation 완료

**Domain Protocol**: `CompleteCurationUseCase`
**Concrete**: `CompleteCuration`
**입력**: `MemberPosition`, `CareerLevel`
**출력**: Void
**서버 operation**: `POST /api/v1/members/me/curation`
**소비 Feature**: U01

요구사항:

- server mutation 성공 전 local `needsCuration=false`를 확정하지 않는다.
- 성공 시 local onboarding state를 원자적으로 완료 방향으로 갱신한다.
- legal required acceptance와 모두 충족돼야 onboarding completed다.
- position/career raw wire value는 Data에서 매핑한다.

검증:

- exact request fields
- server failure local state unchanged
- success local state update
- legal+curation combined completion

### UC16 — Member profile·학습 통계 조회

**Domain Protocol**: `FetchMemberProfileUseCase`
**Concrete**: `FetchMemberProfile`
**입력**: 없음
**출력**: `MemberProfile`
**서버 operation**: `GET /api/v1/members/me`
**소비 Feature**: U06

요구사항:

- name/email/position/career/statistics를 보존한다.
- weekly chart 배열 순서를 유지한다.
- KST·월요일 시작·월 1일 시작 값을 재계산하지 않는다.
- 서버에 없는 profile image/nickname을 생성하지 않는다.
- member unavailable을 session/member 정합성 오류로 구분한다.

검증:

- full profile mapping
- stats/order preservation
- no client recomputation
- member unavailable/temporary failure

### UC17 — 개발 분야 변경

**Domain Protocol**: `UpdateMemberPositionUseCase`
**Concrete**: `UpdateMemberPosition`
**입력**: `MemberPosition`
**출력**: Void
**서버 operation**: `POST /api/v1/members/me/position`
**소비 Feature**: U06

요구사항:

- career level을 함께 변경하지 않는다.
- 성공 전 server-canonical profile을 영구 교체하지 않는다.
- 동일 mutation을 single-flight로 처리한다.
- 실패 시 이전 profile을 유지한다.

검증:

- position-only request
- career unchanged
- success/failure state
- duplicate submit prevention

### UC18 — 개발 수준 변경

**Domain Protocol**: `UpdateMemberCareerLevelUseCase`
**Concrete**: `UpdateMemberCareerLevel`
**입력**: `CareerLevel`
**출력**: Void
**서버 operation**: `POST /api/v1/members/me/career-level`
**소비 Feature**: U06

요구사항:

- position을 함께 변경하지 않는다.
- 성공 전 server-canonical profile을 영구 교체하지 않는다.
- 실패 시 이전 profile을 유지한다.

검증:

- career-only request
- position unchanged
- mutation isolation

### UC19 — Member device info 등록

**Domain Protocol**: `RegisterMemberDeviceUseCase`
**Concrete**: `RegisterMemberDevice`
**입력**: `MemberDeviceInfo`
**출력**: Void
**서버 operation**: `POST /api/v1/members/me/device`
**소비 주체**: App lifecycle, U06 상태 표시 보조

요구사항:

- `deviceID`, `deviceType=iOS`, appVersion, osVersion, optional deviceToken을 전송한다.
- login 완료, APNs token 변경, app/OS version 변경 시 최신 값을 등록한다.
- 권한이 없으면 `deviceToken=nil`을 허용한다.
- v1 single-device last-write-wins를 수용한다.
- unregister UI/API를 만들지 않는다.

검증:

- exact device fields
- nil token allowed
- lifecycle trigger deduplication
- token change re-registration

### UC20 — 회원 계정 삭제

**Domain Protocol**: `DeleteMemberAccountUseCase`
**Concrete**: `DeleteMemberAccount`
**입력**: 없음
**출력**: Void
**서버 operation**: `DELETE /api/v1/members/me`
**소비 Feature**: U06

요구사항:

- confirmation 전 request 0회다.
- committing 중 cancel·duplicate·다른 account mutation을 차단한다.
- success 후 local session/cache/protected effects를 삭제하고 U01로 이동한다.
- hard delete·복구 불가 확정 문구를 사용한다.
- 30일 복구·문의 복원 문구를 사용하지 않는다.
- 실패 시 삭제 완료로 표시하지 않는다.

검증:

- confirmation contract
- exact 1 request
- committing lock
- success local purge/root route
- failure retry/session flow

---

## Integration blocker

| ID | 범위 | 처리 |
|---|---|---|
| INT-API-001 | UC12/UC14 | refresh/revoke server 또는 승인 adapter 필요 |
| INT-API-002 | 전역 | deployed OpenAPI raw artifact 필요 |
| INT-LEGAL-001 | U01/U06 | approved legal content/version/required flags 필요 |
| INT-ENV-001 | 전역 | production/staging base URL·E2E 대상 필요 |
| INT-LEGAL-002 | U06 | open-source notice 생성·bundle 방식 필요 |

Blocker가 있어도 Domain/Feature 구조와 테스트 가능한 계약 구현을 중단하지 않는다. 단, blocker가 열린 상태를 production 완료로 표시하지 않는다.

## 제품 결정 safe default

- DEC-011: canonical GitHub URL만 허용, 입력 보존, private/not-found 세부 원인 노출 금지
- DEC-018: delete 404 full refresh, 500 retry banner, row 보존
- DEC-024: U08 이탈 또는 명시적 refresh 시 progress 1회 invalidation

새 결정이 승인되면 요구사항 ID와 테스트를 함께 갱신한다.
