# 데이터 모델: 온보딩·로그인·튜토리얼 App 통합

## AppRootState

| 필드 | 타입 | 규칙 |
|---|---|---|
| route | `restoring | onboarding | mainShell` | 항상 정확히 하나 |
| onboarding | `OnboardingState?` | route가 onboarding일 때만 존재 |
| restoreAttempt | request identity | launch 자동 요청 1회 및 retry 중복 방지 |

전이: launch → restoring → (onboarding | mainShell). 복구 오류는 onboarding 내부 `restoreError` phase로
전환하고 retry는 onboarding의 splash를 거쳐 restoring 요청만 다시 실행하며 session 정리나 sign-in을
호출하지 않는다. Feature delegate의 완료는 mainShell, logout 또는 session invalidation은 tutorial
3페이지 onboarding으로 전환한다.

## OnboardingState

| 필드 | 타입 | 규칙 |
|---|---|---|
| phase | `splash | restoreError | tutorial(page) | legalAgreement | position | career | completing` | 항상 정확히 하나 |
| authentication | `idle | restoring | signingIn | success | cancelled | retryableFailure` | 진행 중 중복 입력 금지 |
| curation | `CurationSelection` | 부분 profile이어도 두 선택 nil로 초기화 |
| activeRequest | request identity? | restore·sign-in을 포함해 현재 phase/request를 떠난 응답은 무시 |
| legal | `LegalAgreementState` | 설치 단위 기록과 현재 sheet 선택을 구분 |

`authentication` 값은 Domain의 `SignInResult`·`RestoreSessionResult`를 Feature가 해석한 결과다.
Domain 타입과 Feature 상태 값의 대응은 아래 "인증 액션 결과 타입" 절을 따른다.

## 인증 액션 결과 타입

Domain은 상태 조회와 액션 결과를 분리한다. `AuthenticationOutcome`은
`ObserveAuthenticationOutcomesUseCase` 전용 상태 조회 타입이며, `SignInUseCase`·
`SignOutUseCase`·`RestoreSessionUseCase`는 이를 재사용하지 않고 각자 전용 액션 결과 타입을
반환한다.

| Domain UseCase | 결과 타입 | 케이스 |
|---|---|---|
| `ObserveAuthenticationOutcomesUseCase` | `AuthenticationOutcome` (상태 조회, 기존 유지) | `authenticated(AuthenticatedUser)` \| `unauthenticated` \| `recoverableFailure` |
| `SignInUseCase` | `SignInResult` (신규) | `success(AuthenticatedUser)` \| `cancelled` \| `retryableFailure` |
| `SignOutUseCase` | `SignOutResult` (신규) | `success` \| `retryableFailure` |
| `RestoreSessionUseCase` | `RestoreSessionResult` (신규) | `authenticated(AuthenticatedUser)` \| `unauthenticated` \| `recoverableFailure` |

`SignInResult.cancelled`은 Apple 인증 취소(`AuthenticationError.cancelled`)에서만 발생하며
`retryableFailure`(일시적 실패)와 구분된다. `SignOutResult.retryableFailure`는 로컬 인증 정리
실패를 성공과 구분해 FR-033을 충족하며, 실패 시 인증 상태를 불명확하게 바꾸지 않는다.
`RestoreSessionResult`는 상태 조회와 같은 3케이스를 갖지만 launch 자동 복구·명시적 retry라는
액션의 결과이므로 별도 타입으로 분리한다.

## TutorialPage

세 개의 순서가 고정된 presentation 값이다. page 3은 Apple 시작 CTA, 가입 tooltip, 실제 bundle
version을 표시한다. illustration/mini screen은 Domain 동작이 없는 교체 가능한 presentation 요소다.

## PolicyDocument

| 필드 | 타입 | 검증 |
|---|---|---|
| identifier | non-empty String | `privacy-policy` 또는 `terms-of-service` |
| displayName | non-empty String | 승인 문안 표시 이름 |
| version | non-empty String | 최초 값 `1`, 외부 수정 시각에서 추론하지 않음 |
| approvedURL | URL | `https` 승인 링크 |
| isRequired | Bool | privacy와 terms는 true |

manifest는 개인정보 처리방침을 `privacy-policy`/`1`, 서비스 이용 약관을
`terms-of-service`/`1`로 고정한다.

## PolicyConsentRecord

| 필드 | 타입 | 검증 |
|---|---|---|
| documentIdentifier | String | manifest 문서 ID와 대응 |
| version | String | 동의 당시 명시 버전 |
| acceptedAt | Date | 문서별 시각 |

회원 ID, Apple 계정 ID, email을 포함하지 않는다. 현재 필수 문서마다 ID와 version이 모두 일치할
때만 전체 동의가 유효하다. 한 문서 버전 변경은 그 문서 기록만 무효화한다. 로그아웃과 session
invalidation에는 유지되고 앱 데이터 삭제 시 사라진다.

## LegalAgreementState

| 필드 | 타입 | 규칙 |
|---|---|---|
| selectedDocumentIDs | Set<String> | 현재 sheet의 선택, 저장 기록과 별개 |
| linkStatus | documentID별 `idle | opening | openFailed` | 동의 유효성에 영향 없음 |
| canContinue | Bool | 현재 필수 문서 선택이 모두 존재 |

sheet 취소는 저장과 sign-in을 수행하지 않는다. link 미열람/열기 요청 실패도 canContinue를 바꾸지
않는다. 외부 브라우저가 열린 뒤의 page load 상태는 모델링하지 않는다.

## MemberProfile

| 필드 | 타입 | 규칙 |
|---|---|---|
| position | `MemberPosition?` | 서버 null을 그대로 보존; DTO는 `String?` |
| careerLevel | `CareerLevel?` | 서버 null을 그대로 보존; DTO는 `String?` |
| 나머지 기존 필드 | 기존 타입 | 기존 계약 유지 |

둘 다 non-null이면 curation 완료, 하나라도 null이면 두 UI 선택을 nil로 초기화하고 전체 curation을
다시 제출한다. 지원하지 않는 non-null raw value는 nil이 아니라 계약/decoding 오류다.

`GET /api/v1/members/me` 응답에 공식 schema 선언이 없어 null 허용 여부가 명시되지 않았으나
명세(FR-002, FR-030)와 세션 2026-08-25 답변을 우선 계약으로 유지한다.

## CurationSelection

| 필드 | 타입 | 규칙 |
|---|---|---|
| position | `MemberPosition?` | frontend/backend/iOS/android만 노출; 서버 raw value `BACKEND`/`FRONTEND`/`IOS`/`ANDROID` |
| careerLevel | `CareerLevel?` | `entry`/`junior`/`middle`/`senior`만 지원·노출하며 `.unknown`은 정의하지 않음; 서버 raw value `ENTRY`/`JUNIOR`/`MIDDLE`/`SENIOR` |
| submission | `idle \| submitting \| failed` | submitting 중 중복 요청 금지 |

position → career 순서로 이동한다. career에서 뒤로 가면 두 값을 보존한다. position에서 뒤로 가면
명시적 sign-out 성공 후 tutorial 3페이지로 이동하고 실패 시 현재 인증 상태와 재시도 오류를 유지한다.

## MemberRegistrationStatus

`registered(profile) | unregistered | retryableFailure`로 구분한다. 오직 Member API의 계약된 404
(`code: "MEMBER-001"`)가 unregistered이며 transport·5xx·decoding·unexpected raw value는
retryableFailure다.

## API 원문 raw value 변환 책임 (Data 레이어)

| Domain 이름 | 서버 raw value | 변환 위치 |
|---|---|---|
| `MemberPosition.backend` | `BACKEND` | Data DTO |
| `MemberPosition.frontend` | `FRONTEND` | Data DTO |
| `MemberPosition.ios` | `IOS` | Data DTO |
| `MemberPosition.android` | `ANDROID` | Data DTO |
| `CareerLevel.entry` | `ENTRY` | Data DTO |
| `CareerLevel.junior` | `JUNIOR` | Data DTO |
| `CareerLevel.midLevel` | `MIDDLE` | Data DTO |
| `CareerLevel.senior` | `SENIOR` | Data DTO |

위 목록에 없는 non-null raw value는 decoding 오류(retryableFailure)로 처리한다.
`MemberPosition.web`·`MemberPosition.unknown`은 서버 API에 없으며 Domain에서도 선택 항목에
노출하지 않는다.

## LoginResponse (로그인 응답)

`POST /api/v1/auth/login/apple` 200 응답에 포함되는 서버 계약.

| 필드 | 타입 | 활용 |
|---|---|---|
| accessToken | String | Bearer 인증 헤더 |
| refreshToken | String | 토큰 재발급 |
| needsCuration | Boolean | `true`이면 curation 화면으로 이동; `false`이면 MainShell으로 이동 |

로그인 직후 경로에서 `needsCuration`으로 curation 필요 여부를 판정한다. 세션 복구(앱 재시작)
경로에는 login 응답이 없으므로 `FetchMemberProfileUseCase`를 통한 null 여부 판정을 유지한다.
