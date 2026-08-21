# 1단계 데이터 모델: UC01~UC20 전체 UseCase end-to-end 구현

**출처**: `private/spec.md`(Spec-Kit ID `014-all-usecases-implementation`) 8장·9장의 커밋 사본이다. 필드 단위 세부 스펙은 이 문서가 정본이며, UC별 입출력 시그니처는 [contracts/usecase-catalog.md](./contracts/usecase-catalog.md)를 참고한다.

## 1. LearningProject bounded context (`DomainLearningProject`)

| 엔터티 | 표현 대상 | 핵심 속성·관계 |
|---|---|---|
| `ExternalRepository` | GitHub 공개 저장소의 canonical 정보 | owner/repository canonical URL, 표시 metadata; UC01 출력 |
| `QuizLevel` | 학습 난이도 선택지 | `L1`\|`L2`\|`L3`; UC02 입력 |
| `ProjectRegistrationReceipt` | 프로젝트 생성 요청의 raw 접수 결과(상태 머신 아님) | `projectID`, raw `requestStatus: String`, 선택한 `QuizLevel` |
| `LearningProjectPage` | 전체 학습 프로젝트 snapshot | 서버 배열 순서 보존, pagination cursor 없음(compatibility 값은 Data 내부로 격리) |
| `LearningProjectSummary` | 프로젝트 목록 항목 | `projectID`, `nextSetID?`(optional 보존), `nextQuestionID?`(optional 보존) |
| `LearningProjectDetail` | 프로젝트 상세 | Repository 정보, 전체 진행률, `nextQuestionID?`, ordered `sets`(`LearningProjectSetProgress`) |
| `LearningProjectSetProgress` | 세트별 진행률 | 서버 검증 필드 매핑(하드코딩 0 금지) |
| `LearningSet` | 학습 세트 | ordered `Question` 목록, `myAnswer?` |
| `Question` | 문제 | `QuestionFormat`, `QuestionSource`, choices/rubric 공개 시점 제약(제출 전 비공개) |
| `QuestionFormat` | 문제 형식(객관식/서술형 등) | 서버 값 보존 |
| `QuestionSource` | 문제 출처 metadata | — |
| `ChoiceAnswerResult` | 객관식 제출 결과 | 서버의 `correct`, `answerIndex`, `explanation` 보존 |
| `EssayAnswerResult` | 서술형 제출 결과 | 서버 `explanation`, `Rubric` 보존; 클라이언트가 `correct` 생성 금지 |
| `Rubric` | 서술형 평가 기준 | — |
| `BookmarkState` | 문제 북마크 최종 상태 | desired final bool과 서버 응답 bool 분리 |
| `BookmarkedQuestion` | 북마크된 문제 항목 | `projectID + setID + questionID` 보존 |
| `BookmarkedQuestionCollection` | 북마크 목록 | `totalCount`, 전체 `availableProjects`(filter 무관 불변), filtered `bookmarks` |

## 2. Authentication bounded context (`DomainAuthentication`)

| 엔터티 | 표현 대상 | 핵심 속성·관계 |
|---|---|---|
| `AuthenticationMethod` | 인증 수단 | `.apple` |
| `AuthenticationOutcome` | 로그인 결과 | session/onboarding phase 포함 |
| `AuthenticatedSession`(또는 동일 의미 모델) | 인증된 세션 표현 | — |
| `SessionRecord` | 로컬 세션 정본 | `tokens: SessionTokens`, `onboarding: LocalOnboardingState` |
| `SessionTokens` | token pair | `accessToken`, `refreshToken`, `accessTokenExpiresAt`, `refreshTokenExpiresAt`(서버 미제공 시 임의 생성 금지) |
| `LocalOnboardingState` | 온보딩 로컬 상태 | `needsCuration`, `acceptedLegalVersions`, `acceptedAt` |
| `SessionRefreshOutcome` | refresh 결과 | 거부/temporary failure 구분 |
| `LegalDocument` | 약관·개인정보 문서 | 승인된 버전만 사용 |
| `LegalAcceptanceRecord` | 약관 수락 기록 | — |

`AuthenticatedUser.id`에 idToken을 저장하는 현재 임시 경로는 제거 대상이다. 사용자 표시 정보는 Member context가 소유한다.

## 3. Member bounded context (신규 `DomainMember`)

| 엔터티 | 표현 대상 | 핵심 속성·관계 |
|---|---|---|
| `MemberProfile` | 회원 프로필과 학습 통계 | name/email/position/career/`LearningStatistics` |
| `MemberPosition` | 개발 분야 | wire raw value는 Data DTO 소유, unknown을 임의 기본값으로 치환 금지 |
| `CareerLevel` | 개발 수준 | 상동 |
| `LearningStatistics` | 학습 통계 | 서버 값 그대로, 클라이언트 재계산 금지 |
| `WeeklyLearningCount` | 주간 학습 횟수 차트 항목 | 배열 순서 보존(KST·월요일 시작 등 재계산 금지) |
| `MemberDeviceInfo` | 기기 등록 정보 | `deviceID`, `deviceType=iOS`, `appVersion`, `osVersion`, optional `deviceToken` |
| `MemberError` | Member 관련 오류 | 섹션 4 오류 정본과 연결 |

## 4. Domain 오류 정본

| Domain 오류 | 의미 | Feature/App 처리 |
|---|---|---|
| `invalidRequest` | 입력·형식 문제 | 입력 보존·수정 가능 |
| `unauthorized` | access token 401 | Root refresh/session flow |
| `sessionExpired` | refresh 거부·만료 | local clear 후 U01 |
| `projectUnavailable` | project 404 | 원인 추론 없이 이전/refresh |
| `learningSetUnavailable` | set 404 | U07/목록 재조회 |
| `questionUnavailable` | question 404 | set 재조회/이전 |
| `memberUnavailable` | member 404 | session/member 정합성 재평가 |
| `externalRepositoryUnavailable` | GitHub 없음/private/불가 | 등록 값 생성 금지 |
| `externalRateLimited` | GitHub rate limit | DEC-011 safe default |
| `authenticationCancelled` | Apple 사용자 취소 | 경고 없이 unauthenticated |
| `invalidAuthenticationCallback` | state/replay/expiry | grant/session 생성 금지 |
| `temporarilyUnavailable` | 5xx/transport | 현재 입력·데이터 보존 + retry |

- Data의 진단 metadata는 로그 redaction 정책 안에서 유지할 수 있다.
- Feature에는 안전한 Domain 오류만 전달한다.
- `@unknown default`에서 유효 Domain 값으로 조용히 대체하지 않는다. temporary/unexpected 실패로 명시한다.

## 5. 상태 전이 요약

- **세션**: `restoring → unauthenticated | authenticated`; `authenticated`는 `authenticating → refreshing`을 거칠 수 있고 refresh 거부 시 `unauthenticated`로 복귀한다(회귀 없음).
- **온보딩**: `unknown → terms → curation → submitting → completed`; legal 필수 수락과 curation 성공이 모두 있어야 `completed`.
- **프로젝트 등록**: `validating → registering → requestAccepted`(raw `requestStatus` 보존, generation 완료 아님) 또는 `failed`.
- **삭제(UC05, UC20)**: `idle → committing → (성공: 로컬 제거/purge) | (404: full refresh) | (5xx/transport: 이전 상태 보존 + retry)`.
- **북마크(UC09)**: 낙관적 갱신 없이 `요청 전 상태 → 서버 응답 bool이 최종 정본`; 실패 시 이전 서버 상태 유지.

## 6. Data DTO 정합 메모(참고, 정본은 Data 패키지 구현에서 확정)

- project list의 optional ID는 DTO 단계부터 optional로 선언한다.
- `registration status`는 String으로 디코딩하고 enum 매핑을 시도하지 않는다.
- `bookmark.setID`는 필수 필드로 디코딩한다.
- choice/essay 응답은 서로 다른 DTO 타입을 유지한다(공용 union DTO 금지).
- 모든 wire key는 `CodingKeys`로 서버 원문(`projectId`, `repositoryUrl` 등)과 연결한다.
