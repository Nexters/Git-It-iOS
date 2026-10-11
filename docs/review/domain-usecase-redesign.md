# Domain UseCase 재설계

**작성** 개발자 초안(관심사별 섹션) + 기존 기능 배치·모델 정의 보완 · **작성일** 2026-09-17
**기준 코드** branch `feature/pending-repository-legacy-cleanup` @ `760e1e3` (UseCase 프로토콜 20개)
**관련 문서** [의도 점검표](domain-usecase-review.md) · [Domain 패키지 규칙](../package-rules/domain.md) · [D-ARCH-004](../architecture.md#d-arch-004--domaindatainfrastructure-관심사-경계)

섹션 하나는 **관심사 하나**이고, 관심사마다 UseCase 객체 하나와 그 관심사의 모델을 정의합니다. 모든 섹션은 아래 [공통 API 규칙](#공통-api-규칙)을 따르며, 현재 기능은 [기존 기능 대응표](#기존-기능-대응표)에서 빠짐없이 새 API로 이어집니다.

---

## 결정 기록

| # | 일자 | 결정 | 반영 |
| --- | --- | --- | --- |
| 1 | 2026-09-17 | 섹션은 개발자가 나눈 관심사 기준을 유지한다. 초안의 모델은 이름을 그대로 쓰지 않고 적합한 형태로 정의한다 | 전체 |
| 2 | 2026-09-17 | `Authentication` → **`Account`**. 세션이라는 명칭을 외부에 노출하지 않는다 | [Account](#account), R10 |
| 3 | 2026-09-17 | `Project` 목록은 **Generation 상태로 필터링**한 값을 **`AsyncStream`으로 공유**해 모든 화면이 같은 상태를 보여준다 | [Project](#project), R9 |
| 4 | 2026-09-17 | "생성 중" 기준은 **사용자에게 보이는 준비 기준 하나**다. 서버 완료 후에도 `readyAt`까지는 준비 중이며, 목록 필터와 Home 배너가 같은 기준을 쓴다 | [ProjectGeneration](#projectgeneration) |
| 5 | 2026-09-17 | 로그아웃·탈퇴 정리는 **각 관심사가 로그인 상태를 구독해 스스로 정리**한다. 공개 `clear` 동작은 두지 않는다 | [Account](#account), [Project](#project), [ProjectGeneration](#projectgeneration) |
| 6 | 2026-09-17 | **UseCase는 다른 UseCase에 의존하지 않는다.** 다른 관심사의 상태가 필요하면 **상태 스트림을 여는 클로저**를 생성자로 주입받는다 | R11 |
| 7 | 2026-09-17 | **`ServicePolicy`를 제거하고 `Account`에 편입**한다 | [Account](#account) |
| 8 | 2026-09-17 | 채점 후 목록 진행률은 **화면(Router)이 퀴즈를 닫을 때 `Project.refresh()`를 호출**한다 (결정 21) | [Project](#project) |
| 9 | 2026-09-17 | **요청 인증 정보는 Data가 소유**한다. 읽기·만료 판정을 Data가 맡고, Account는 로그인 상태만 판단한다. 토큰 값은 Domain을 통과하지 않는다 | [요청 인증 정보](#요청-인증-정보) |
| 10 | 2026-09-17 | ~~**토큰 갱신을 이번 재설계에 포함**한다 (401 → 갱신 → 재요청, 갱신 실패 시 로그아웃). 현재는 미구현~~ — **결정 22로 대체** | [요청 인증 정보](#요청-인증-정보) |
| 11 | 2026-09-17 | 큐레이션 = 포지션 + 경력 한 쌍 | [UserInfo](#userinfo) |
| 12 | 2026-09-17 | 알림 권한은 **`LocalSetting`**(→ 결정 24 `AppSetting`), 계정 탈퇴는 **`Account`** 가 소유한다 | [AppSetting](#appsetting), [Account](#account) |
| 13 | 2026-09-17 | 생성 실패는 `readyAt`을 기다리지 않고 **즉시 `failed`로 전환**하고 **실패 알림**을 보낸다. 실패한 프로젝트는 목록에 포함되지 않는다 (현재 동작 변경) | [ProjectGeneration](#projectgeneration) |
| 14 | 2026-09-17 | `SignInState`에 **`.unknown`** 을 둔다. 로그인 복원이 끝나기 전에는 `.unknown`이며, 로그아웃 신호로 취급하지 않는다 | [Account](#account), R11 |
| 15 | 2026-09-17 | 확장 앱은 **로그인 상태를 확인해 생성 요청만** 한다. 상태 추적·로그아웃 정리·준비 타이머는 메인 앱이 맡는다 | [ProjectGeneration](#projectgeneration), [요청 인증 정보](#요청-인증-정보) |
| 16 | 2026-09-17 | ~~갱신이 **네트워크 오류로 실패하면 로그인 정보를 지우지 않는다.** 서버가 갱신을 거부했을 때만 지우고 로그아웃한다~~ — **결정 22로 대체** | [요청 인증 정보](#요청-인증-정보) |
| 17 | 2026-09-17 | ~~**확장 앱은 토큰을 갱신하지 않는다.** 인증 정보가 유효할 때만 동작한다~~ — **결정 22로 대체 — 앱·확장 앱 모두 갱신 없음** | [요청 인증 정보](#요청-인증-정보) |
| 18 | 2026-09-17 | ~~`signInAvailability()`는 갱신 가능 여부로 판정한다. 접근 토큰 만료 + 갱신 가능 → `appLaunchRequired`, 갱신 불가 → `signInRequired`~~ — **결정 22로 대체** | [Account](#account) |
| 19 | 2026-09-17 | `needsCuration`은 **로그인·복원 결과에만** 담고 `signInStates()` 스트림 상태에서 제외한다 | [Account](#account) |
| 20 | 2026-09-18 | 로그인 무효 신호(`signInInvalidations`)를 받으면 Account가 **공유 로그인 표시를 지운다.** 서버 로그아웃은 요청하지 않는다 | [Account](#account) |
| 21 | 2026-09-18 | 퀴즈 후 진행률: **퀴즈를 닫을 때 한 번** Router가 `Project.refresh()`를 호출하고, 상세 화면은 갱신 요청을 받아 `detail(of:)`를 다시 호출한다. `refresh()`는 **첫 페이지로 교체**한다. 답안마다 보내던 `progressInvalidated`는 제거한다 | [Project](#project) |
| 22 | 2026-09-18 | **서버에 토큰 갱신 API가 없어 갱신을 하지 않는다.** 접근 토큰이 만료되었거나 서버가 401을 돌려주면 로그인 정보를 지우고 로그아웃한다. 앱·확장 앱 동일 | [요청 인증 정보](#요청-인증-정보), [Account](#account) |
| 23 | 2026-09-18 | **실패한 프로젝트는 서버 목록 응답에서 자동으로 제외**된다. 클라이언트는 `failed`를 필터링하지 않는다 | [Project](#project), [ProjectGeneration](#projectgeneration) |
| 24 | 2026-09-18 | `LocalSetting`·`ServerSetting`을 **`AppSetting`으로 통합**한다. 알림 권한과 기기 등록을 한 관심사로 다룬다 | [AppSetting](#appsetting) |
| 25 | 2026-09-18 | 이름 **`ProjectGeneration`이 점검표 D1(`QuizGenerationUseCase`)·D7(`QuizGenerationReceipt`)을 대체**한다 | [ProjectGeneration](#projectgeneration) |
| 26 | 2026-09-18 | **관심사 하나 = Domain 타깃 하나.** 현재 `DomainAuthentication`·`DomainLearningProject`·`DomainMember` 세 타깃을 관심사별 일곱 타깃으로 나눈다 | [Domain 타깃 구성](#domain-타깃-구성), R11 |
| 27 | 2026-09-18 | 여러 관심사가 공개 API에 쓰는 식별자는 **기반 타깃 `DomainIdentifier`** 에 둔다. 이 타깃은 **식별자 `typealias`만** 가지며, 관심사 타깃이 import할 수 있는 유일한 Domain 타깃이다 | [Domain 타깃 구성](#domain-타깃-구성), R2 |

---

## 공통 API 규칙

| ID | 규칙 | 예 |
| --- | --- | --- |
| R1 | 관심사 하나 = 공개 프로토콜 `<관심사>UseCase` 하나 + 구현 하나 | `ProjectUseCase` |
| R2 | 식별자는 관심사 ID 타입으로 표현한다 (`typealias <대상>ID = String`). 둘 이상의 관심사가 쓰는 식별자는 `DomainIdentifier`에, 한 관심사만 쓰는 식별자는 그 관심사 타깃에 둔다 (결정 27) | `ProjectID`, `QuizID`, `QuizSetID` |
| R3 | 식별자만 받는 동작은 ID를 인자로 받는다. **사용자가 입력·선택한 값**이 들어가면 관심사 입력 모델 하나로 받는다 | `detail(of: ProjectID)` / `grade(_: ChoiceAnswer)` |
| R4 | 반환은 관심사 모델이다. `Bool`·`String`·튜플을 직접 반환하지 않는다. 대상이 없을 수 있으면 `Model?` | `NotificationAuthorizationStatus` (Bool 대신) |
| R5 | 오류는 관심사별 `<관심사>Error` 하나로 던진다. **사용자 흐름이 갈리는 결과**(취소, 재시도 가능 등)만 결과 enum으로 반환한다 | `SignInResult` |
| R6 | 상태 관찰은 `AsyncStream<Model>` 하나로 제공하고, 구독 즉시 현재 상태를 첫 값으로 보낸다. 별도 현재값 조회를 두지 않는다 | `states()`, `projects()` |
| R7 | 조회는 대상 명사, 변경은 동사로 짓는다. `load`·`save`·`fetch`처럼 저장소 연산을 드러내는 이름은 쓰지 않는다 (D-ARCH-004) | `curation()` / `updateCuration(_:)` |
| R8 | 직렬화·단일 비행·관찰 시작·만료 정리·타이머 같은 실행 보장은 구현 내부 상태이며 공개하지 않는다 | 준비 완료 타이머 |
| R9 | **여러 화면이 같은 상태를 보여줘야 하는 데이터는 UseCase 인스턴스 하나가 보관하고 스트림으로 공유한다.** 변경 동작은 결과를 반환하는 대신 스트림에 반영한다. Composition은 이 UseCase를 앱에서 한 번만 생성한다 | `ProjectUseCase.projects()` |
| R10 | **구현 수단의 명칭(세션, 토큰, 캐시, 대기열 등)은 공개 이름·모델에 드러내지 않는다.** 사용자가 인지하는 개념(로그인, 계정, 알림)으로 표현한다 | `restoreSignIn()` (세션 복원 대신) |
| R11 | **UseCase는 다른 UseCase를 생성자로 받지 않는다.** 다른 관심사의 상태가 필요하면 `@Sendable () async -> AsyncStream<상태>` 클로저를 받는다. 다른 관심사의 **변경 동작**은 클로저로도 받지 않는다. Composition이 클로저를 연결한다 | `Project(preparingProjectIDs: ...)` — Composition이 `ProjectGeneration.states()`에서 값을 골라 연결 |

**R11 보충 — Domain 타깃 경계**

관심사마다 Domain 타깃이 따로 있고(결정 26) 서로 import하지 않습니다. 예외는 식별자만 담는 `DomainIdentifier`입니다(결정 27). 따라서 주입 클로저의 스트림 원소 타입은 **받는 쪽 타깃이 알 수 있는 타입**이어야 합니다. 다른 관심사의 모델은 받지 않고, 받는 쪽이 필요한 값만 받습니다.

| 상태 출처 | 받는 쪽 | 클로저 타입 |
| --- | --- | --- |
| `ProjectGeneration` | `Project` | `@Sendable () async -> AsyncStream<Set<ProjectID>>` — 목록에서 제외할 projectID. Composition이 `ProjectGeneration.states()`의 `preparingProjectIDs`를 연결한다 |
| `Account` | `Project`, `ProjectGeneration` | `@Sendable () async -> AsyncStream<Void>` — **로그아웃 신호만** 전달. Composition이 `Account.signInStates()`에서 `.signedOut`만 걸러 연결한다. `.unknown`은 전달하지 않는다 (결정 14) |
| Data `RequestCredentialProvider` | `Account` | `@Sendable () async -> AsyncStream<Void>` — 접근 토큰 만료·401로 로그인 정보가 지워졌다는 신호 (결정 9·22) |

확장 앱은 로그아웃 정리를 하지 않으므로 `signedOutEvents`·`signInInvalidations`에 **빈 스트림**을 연결한다 (결정 15·17).

---

## Account

**책임** 사용자의 로그인 상태를 시작·유지·확인·종료하고, 서비스 약관 동의를 관리하며, 계정을 탈퇴한다. 로그인 정보의 저장은 외부에 드러내지 않는다.

| 기능 | API | 기존 기능 |
| --- | --- | --- |
| 로그인 | `signIn(with: SignInMethod) async -> SignInResult` | `SignIn` |
| 로그아웃 | `signOut() async -> SignOutResult` | `SignOut` |
| 로그인 상태 구독 | `signInStates() async -> AsyncStream<SignInState>` | 신규 — 결정 5의 정리 신호원 |
| 로그인 복원 (앱 실행) | `restoreSignIn() async -> SignInRestoration` | `RestoreSession` |
| 로그인 유효성 확인 (재진입) | `verifySignIn() async -> SignInVerification` | `VerifyAuthorization` |
| 로그인 사용 가능 여부 (확장 앱) | `signInAvailability() async -> SignInAvailability` | `ResolveSessionAvailability` |
| 약관 동의 상태 조회 | `policyConsentStatus() async throws -> PolicyConsentStatus` | `PolicyConsent.requiredDocuments` + `storedConsentRecords` + Feature의 `isConsentValid` |
| 약관 동의 | `consent(to: [PolicyDocumentID]) async throws` | `PolicyConsent.saveConsentRecords` |
| 계정 탈퇴 | `withdraw() async throws` | `DeleteMemberAccount` |
| 로그인 정보 갱신 | 없음 — 서버 갱신 API 없음. 만료·401은 로그아웃 (결정 22) | `RefreshSession` (소비처 없음, 어댑터가 항상 실패를 던지는 미구현 상태) → 제거 |

```swift
public protocol AccountUseCase: Sendable {
    func signIn(with method: SignInMethod) async -> SignInResult
    func signOut() async -> SignOutResult
    func signInStates() async -> AsyncStream<SignInState>
    func restoreSignIn() async -> SignInRestoration
    func verifySignIn() async -> SignInVerification
    func signInAvailability() async -> SignInAvailability
    func policyConsentStatus() async throws -> PolicyConsentStatus
    func consent(to documentIDs: [PolicyDocumentID]) async throws
    func withdraw() async throws
}
```

**모델 — 로그인**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `SignInMethod` | `enum { apple }` | `AuthenticationMethod` |
| `AccountID` | `typealias = String` | 신규 |
| `SignedInAccount` | `id: AccountID`, `displayName: String?`, `needsCuration: Bool` — 로그인·복원 **결과**에만 쓴다 | `AuthenticatedUser` + `SignInResult.success`의 `needsCuration` |
| `SignInState` | `enum { unknown, signedIn(AccountID), signedOut }` — `needsCuration` 제외 (결정 14·19) | 신규 |
| `SignInResult` | `enum { signedIn(SignedInAccount), cancelled, retryableFailure }` | `SignInResult` |
| `SignOutResult` | `enum { signedOut, retryableFailure }` | `SignOutResult` |
| `SignInRestoration` | `enum { signedIn(SignedInAccount), signedOut, temporarilyUnavailable }` | `RestoreSessionResult` |
| `SignInVerification` | `enum { valid, reauthenticationRequired, temporarilyUnavailable }` | `AuthorizationStatus` |
| `SignInAvailability` | `enum { signedIn, signInRequired, appLaunchRequired }` | `SessionAvailability` — 토큰 값 제거 |

**모델 — 약관 동의** (구 `ServicePolicy`)

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `PolicyDocumentID` | `typealias = String` | 신규 |
| `PolicyDocument` | `id`, `displayName`, `version`, `approvedURL`, `isRequired` | `PolicyDocument` (`identifier` → `id`) |
| `PolicyConsent` | `documentID`, `version`, `consentedAt` | `PolicyConsentRecord` |
| `PolicyConsentStatus` | `documents: [PolicyDocument]`, `consents: [PolicyConsent]`, `isSatisfied: Bool` | 신규 — 조회 둘과 판정 하나를 묶음 |

**모델 — 오류**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `AccountError` | `policyUnavailable`, `withdrawalUnavailable`, `unauthorized`, `temporarilyUnavailable` | `AuthenticationError` + `LoginSessionError` + `MemberError` 일부. 로그인 흐름의 취소·실패는 결과 enum이 담는다 (R5) |

**공개하지 않는 타입** — `SessionTokens`, `SessionRecord`, `AuthenticationGrant`, `LocalOnboardingState` (R10)

**생성자 (R11)**

```swift
public init(
    authenticationRepository: any AuthenticationRepository,
    signInRepository: any SignInRepository,
    withdrawalRepository: any WithdrawalRepository,
    policyConsentRepository: any PolicyConsentRepository,
    policyDocuments: [PolicyDocument],
    signInInvalidations: @escaping @Sendable () async -> AsyncStream<Void>,
)
```

- `signInInvalidations` — 접근 토큰 만료·401로 Data가 로그인 정보를 지웠을 때의 신호. Composition이 `RequestCredentialProvider.invalidations()`를 연결한다 (결정 9·22)
- `withdrawalRepository` *(이름 제안)* — 현재 `DomainMember`의 `MemberRepository.deleteAccount()`를 `DomainAccount`의 탈퇴 계약으로 옮긴 것 (결정 12·26)
- `signInRepository` *(이름 제안)* — 현재 `LoginSessionRepository`·`CurrentSessionRepository`·`SharedSignInStateRepository`를 R10 기준으로 정리한 계약. 토큰을 반환하지 않고 로그인 기록의 유효 여부만 돌려준다

**내부 책임**
- `signInStates()`는 `restoreSignIn()`이 끝나기 전까지 `.unknown`을 보낸다. 이후 로그인·로그아웃·복원·확인·탈퇴의 결과로 상태를 방출한다. 재인증 필요·계정 사용 불가·**`signInInvalidations` 수신**으로 로그인이 무효가 되어도 `.signedOut`을 방출한다 (결정 14)
- `signInAvailability()` 판정 (결정 22) — 현재 `ResolveSessionAvailability`와 같은 기준

  | 공유 로그인 표시 | 로그인 기록 | 결과 |
  | --- | --- | --- |
  | 없음 | — | `appLaunchRequired` |
  | 로그아웃 | — | `signInRequired` |
  | 로그인 | 없음, 또는 접근 토큰 만료 | `signInRequired` |
  | 로그인 | 접근 토큰 유효 | `signedIn` |

  만료 시각 비교는 `signInRepository`의 Data 구현이 수행하고, Domain은 판정 결과만 받는다 (결정 9)
- 무효 로그인 정리(서버 로그아웃 → 인증 참조 제거)를 한 곳에서 수행한다. 현재 `SignIn`·`RestoreSession`·`VerifyAuthorization`에 각각 구현되어 있다
- `signInInvalidations`를 받으면 **공유 로그인 표시를 로그아웃으로 바꾸고** `.signedOut`을 방출한다. 로그인 정보는 Data가 이미 지웠고 토큰이 무효한 상태이므로 서버 로그아웃은 요청하지 않는다 (결정 20)
- 약관 동의 유효성 판정(필수 문서의 ID·version 일치)과 동의 시각 기록을 수행한다. 현재 판정은 `LegalAgreementFeature`에 있다
- 탈퇴 성공 시 약관 동의 기록을 삭제하고 `.signedOut`을 방출한다. 다른 관심사의 정리는 각자 구독으로 수행된다 (결정 5)

**정리 대상** `LegalDocument`·`LegalAcceptanceRecord`는 `PolicyDocument`·`PolicyConsentRecord`와 필드가 같고 참조처가 없다 → 제거

---

## UserInfo

**책임** 회원의 상세 정보와 학습 목표(큐레이션: 포지션·경력)를 조회하고 변경한다.

| 기능 | API | 기존 기능 |
| --- | --- | --- |
| 큐레이션 조회 | `curation() async throws -> Curation?` | `MemberAccount.profile()`의 `position`·`careerLevel` |
| 큐레이션 업데이트 | `updateCuration(_: Curation) async throws` | `MemberAccount.completeCuration` (온보딩) |
| 포지션 조회 | `curation()?.position` — 큐레이션 조회에 포함 | `MemberAccount.profile()` |
| 포지션 업데이트 | `updatePosition(_: MemberPosition) async throws` | `MemberAccount.updatePosition` (설정) |
| **경력 업데이트** | `updateCareerLevel(_: CareerLevel) async throws` | `MemberAccount.updateCareerLevel` (설정) — **초안에 없어 추가** |
| 상세 정보 조회 | `detail() async throws -> UserDetail` | `MemberAccount.profile()`의 이름·이메일·통계 |

```swift
public protocol UserInfoUseCase: Sendable {
    func detail() async throws -> UserDetail
    func curation() async throws -> Curation?
    func updateCuration(_ curation: Curation) async throws
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
}
```

**모델**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `UserDetail` | `name`, `email`, `statistics: LearningStatistics` | `MemberProfile`에서 분리 |
| `Curation` | `position: MemberPosition`, `careerLevel: CareerLevel` — 둘 다 선택되어야 존재 | 신규 (`MemberProfile`의 optional 두 필드를 묶음) |
| `MemberPosition` | `enum { ios, android, backend, frontend }` | 그대로 |
| `CareerLevel` | `enum { entry, junior, middle, senior }` | 그대로 |
| `LearningStatistics` | `thisWeekSolvedCount`, `thisMonthSolvedCount`, `streakDays`, `weeklyCounts: [WeeklyLearningCount]` | 그대로 |
| `UserInfoError` | `invalidRequest`, `unauthorized`, `memberUnavailable`, `temporarilyUnavailable` | `MemberError` 이름 변경 |

**내부 책임**
- `detail()`과 `curation()`은 같은 서버 응답에서 나온다. 한 화면이 둘을 함께 호출해도 **요청은 한 번**만 보낸다
- 큐레이션·포지션·경력 변경은 같은 필드를 쓰므로 **하나의 직렬화 단위**로 처리한다 (점검표 A-3)

---

## AppSetting

**책임** 앱 알림 설정을 관리한다 — 기기의 알림 권한을 확인·요청하고, 서버가 알림을 보낼 수 있도록 현재 기기를 등록하고 기기 토큰을 최신으로 유지한다 (결정 24).

| 기능 | API | 기존 기능 |
| --- | --- | --- |
| 알림 권한 확인 | `notificationAuthorization() async -> NotificationAuthorizationStatus` | `RequestGenerationReminder.isAuthorized` |
| 알림 권한 요청 | `requestNotificationAuthorization() async -> NotificationAuthorizationStatus` | `RequestGenerationReminder.requestAuthorization` |
| 기기 등록 | `registerDevice() async throws` | `RegisterCurrentDevice` |
| 기기 토큰 업데이트 | `updateDeviceToken(_: DeviceToken) async throws` | `AppRootFeature`의 `deviceTokenRefreshes()` 수신 → `RegisterCurrentDevice` 재호출 (같은 서버 등록 API) |

```swift
public protocol AppSettingUseCase: Sendable {
    func notificationAuthorization() async -> NotificationAuthorizationStatus
    func requestNotificationAuthorization() async -> NotificationAuthorizationStatus
    func registerDevice() async throws
    func updateDeviceToken(_ token: DeviceToken) async throws
}
```

**모델**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `NotificationAuthorizationStatus` | `enum { notDetermined, authorized, denied }` | `NotificationAuthorizationOutcome` 교정 (점검표 D8) + `isAuthorized() -> Bool` 대체 |
| `DeviceID` | `typealias = String` | 신규 |
| `DeviceToken` | `typealias = String` | 신규 |
| `DeviceRegistration` | `deviceID`, `platform`, `appVersion`, `osVersion`, `token: DeviceToken?` | `MemberDeviceInfo` 이름 변경 (`deviceType` → `platform`) |
| `AppSettingError` | `unauthorized`, `temporarilyUnavailable` | 신규 (`MemberError`에서 분리) — 기기 등록 동작만 던진다. 알림 권한 동작은 던지지 않는다 |

**호출부 규칙** — 설정 이동 안내는 `notificationAuthorization()`이 이미 `.denied`일 때, 시스템 권한 요청은 `.notDetermined`일 때. 현재 `SettingsFeature.notificationRowTapped`의 `.previouslyDenied` 분기와 같은 동작이다.

**내부 책임**
- 등록 정보(기기 식별자, 앱·OS 버전, 토큰)를 UseCase가 구성한다
- 알림 권한이 없어도 토큰 없이 등록한다 (현재 동작 유지)

---

## ExternalRepository

**책임** 사용자가 입력한 외부 저장소 주소를 해석해 저장소 정보를 조회한다.

| 기능 | API | 기존 기능 |
| --- | --- | --- |
| 외부 저장소 조회 | `repository(at: ExternalRepositoryURL) async throws -> ExternalRepository` | `FetchExternalRepository` |

```swift
public protocol ExternalRepositoryUseCase: Sendable {
    func repository(at url: ExternalRepositoryURL) async throws -> ExternalRepository
}
```

**모델**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `ExternalRepositoryURL` | `typealias = String` | 신규 |
| `ExternalRepository` | `canonicalURL`, `ownerName`, `repositoryName`, `imageURL?`, `starCount`, `techStack` | 그대로 |
| `ExternalRepositoryError` | `invalidURLFormat`, `offline`, `other` | 그대로 |

**내부 책임** — 주소를 소유자·이름으로 해석하지 못하면 조회 없이 `invalidURLFormat`을 던진다.

---

## QuizDetail

**책임** 퀴즈 세트의 문제를 제공하고, 답안을 제출해 채점 결과를 받고, 문제 북마크를 관리한다.

| 기능 | API | 기존 기능 |
| --- | --- | --- |
| **퀴즈 세트 조회** | `quizSet(_: QuizSetID, in: ProjectID) async throws -> QuizSet` | `LearningLibrary.learningSet` — **초안에 없어 추가** |
| 채점 (선택형) | `grade(_: ChoiceAnswer) async throws -> ChoiceGrading` | `SubmitChoiceAnswer` |
| 채점 (서술형) | `grade(_: EssayAnswer) async throws -> EssayGrading` | `SubmitEssayAnswer` |
| 문제 북마크 등록 | `bookmark(_: QuizID, in: ProjectID) async throws -> QuizBookmarkState` | `SetQuestionBookmark(bookmarked: true)` |
| 문제 북마크 해제 | `unbookmark(_: QuizID, in: ProjectID) async throws -> QuizBookmarkState` | `SetQuestionBookmark(bookmarked: false)` |
| **북마크 목록 조회** | `bookmarks(_: QuizBookmarkFilter) async throws -> QuizBookmarkList` | `LearningLibrary.bookmarkedQuestions` — **초안에 없어 추가** |

```swift
public protocol QuizDetailUseCase: Sendable {
    func quizSet(_ setID: QuizSetID, in projectID: ProjectID) async throws -> QuizSet
    func grade(_ answer: ChoiceAnswer) async throws -> ChoiceGrading
    func grade(_ answer: EssayAnswer) async throws -> EssayGrading
    func bookmark(_ quizID: QuizID, in projectID: ProjectID) async throws -> QuizBookmarkState
    func unbookmark(_ quizID: QuizID, in projectID: ProjectID) async throws -> QuizBookmarkState
    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList
}
```

**모델**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `QuizID` | `typealias = String` | `questionID` |
| `QuizSetID` | `typealias = String` | `setID` |
| `QuizSet` | `id: QuizSetID`, `title`, `description`, `quizzes: [Quiz]` | `LearningSet` |
| `Quiz` | `id: QuizID`, `prompt`, `content: QuizContent`, `sources: [QuizSource]` | `Question` |
| `QuizContent` | `enum { choice(options: [String], submitted: ChoiceSubmission?), essay(submitted: EssaySubmission?) }` | `Question.format` + `choices?` + `myAnswer?` — 형식과 형식별 값이 따로 놀던 optional 세 필드를 case로 묶음 |
| `ChoiceSubmission` | `selectedIndex: Int`, `isCorrect: Bool` | `SubmittedAnswer` (선택형 부분) |
| `EssaySubmission` | `text: String` | `SubmittedAnswer` (서술형 부분) |
| `QuizSource` | `filePath?`, `startLine?`, `endLine?`, `symbol?`, `summary?`, `referenceURL?` | `QuestionSource` |
| `ChoiceAnswer` | `projectID`, `quizID`, `selectedIndex: Int` | 신규 — 제출 인자 묶음 (R3) |
| `ChoiceGrading` | `isCorrect: Bool`, `correctIndex: Int`, `explanation: String` | `ChoiceAnswerResult` |
| `EssayAnswer` | `projectID`, `quizID`, `text: String` | 신규 (R3) |
| `EssayGrading` | `explanation: String`, `rubric: [String]` | `EssayAnswerResult` + `Rubric` (기준 목록 하나뿐인 래퍼 제거) |
| `QuizBookmarkState` | `quizID`, `isBookmarked: Bool` | `BookmarkState` |
| `QuizBookmarkFilter` | `enum { all, project(ProjectID) }` | 신규 — `projectID: String?`의 `nil` = 전체 규약 대체 |
| `QuizBookmark` | `projectID`, `projectName`, `setID`, `setLabel`, `problemNumber`, `quizID`, `prompt` | `BookmarkedQuestion` |
| `QuizBookmarkList` | `totalCount`, `projects: [QuizBookmarkProject]`, `bookmarks: [QuizBookmark]` | `BookmarkedQuestionCollection` |
| `QuizBookmarkProject` | `id: ProjectID`, `name` | `BookmarkedProject` |
| `QuizDetailError` | `invalidAnswer`, `quizSetUnavailable`, `quizUnavailable`, `notFound`, `unauthorized`, `temporarilyUnavailable`, `unexpected` | `LearningProjectError`에서 분리 |

**모델 형태 판단**
- 초안의 `Marker`는 채점하는 주체처럼 읽히지만 채점은 서버가 한다. 반환값은 채점 결과이므로 `Grading`으로 짓고, 정답·해설을 담는 별도 `Marker` 타입은 결과 하나로 합쳤다
- 선택형·서술형 구분은 `Choice`/`Essay` 접두어로 유지했다

**내부 책임**
- 채점 요청 전 입력 검증: 선택형 `selectedIndex >= 0`, 서술형 공백 제거 후 비어 있지 않고 2000자 이하. 위반 시 요청 없이 `invalidAnswer`
- 북마크 등록·해제는 같은 문제(`projectID` + `quizID`)끼리 순서대로 처리한다

---

## Project

**책임** 사용자의 학습 프로젝트 목록을 **준비되지 않은 생성 요청을 제외한 하나의 공유 상태**로 제공하고, 상세 조회와 삭제를 수행한다.

| 기능 | API | 기존 기능 |
| --- | --- | --- |
| Project List 구독 | `projects() async -> AsyncStream<ProjectList>` | `FetchLearningProjects` — Home·ProjectList가 각자 조회하던 것을 하나의 상태로 공유 |
| Project List 새로고침 | `refresh() async throws` | `FetchLearningProjects(page: first)`, `learningProjectsReloadRequested` |
| 다음 페이지 요청 | `requestNextPage() async throws` | `FetchLearningProjects(page: n)` |
| Project Detail 조회 | `detail(of: ProjectID) async throws -> ProjectDetail` | `LearningLibrary.project` |
| 프로젝트 삭제 | `delete(_: ProjectID) async throws` | `LearningLibrary.deleteProject` |

```swift
public protocol ProjectUseCase: Sendable {
    func projects() async -> AsyncStream<ProjectList>
    func refresh() async throws
    func requestNextPage() async throws
    func detail(of projectID: ProjectID) async throws -> ProjectDetail
    func delete(_ projectID: ProjectID) async throws
}
```

**생성자 (R11)**

```swift
public init(
    repository: any LearningProjectRepository,
    preparingProjectIDs: @escaping @Sendable () async -> AsyncStream<Set<ProjectID>>,
    signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
)
```

**모델**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `ProjectID` | `typealias = String` | 신규 |
| `ProjectList` | `summaries: [ProjectSummary]`, `hasNextPage: Bool`, `isLoaded: Bool` | `LearningProjectPage` — 페이지 한 장이 아니라 **지금까지 받은 목록 전체** |
| `ProjectSummary` | `id`, `repositoryName`, `repositoryImageURL?`, `techStack`, `currentSet: ProjectSetLabel`, `next: ProjectNextQuiz?`, `progressPercent` | `LearningProjectSummary` |
| `ProjectSetLabel` | `label`, `title` | `currentSetLabel` + `currentSetTitle` |
| `ProjectNextQuiz` | `setID: QuizSetID`, `quizID: QuizID?` | `nextSetID?` + `nextQuestionID?` — 세트 없이 문제만 있는 조합을 막음 |
| `ProjectDetail` | `id`, `repository: ProjectRepositoryInfo`, `progressPercent`, `sets: [ProjectSetProgress]`, `next: ProjectNextQuiz?` | `LearningProjectDetail` |
| `ProjectRepositoryInfo` | `url`, `name`, `imageURL?`, `starCount`, `techStack` | `LearningProjectDetail`의 저장소 필드 5개 |
| `ProjectSetProgress` | `setID: QuizSetID`, `label`, `title`, `quizCount`, `completedCount` | `LearningProjectSetProgress` |
| `ProjectError` | `notFound`, `unauthorized`, `temporarilyUnavailable`, `unexpected` | `LearningProjectError`에서 분리 |

**상태 규칙**
- `projects()`는 구독 즉시 현재 목록을 보낸다. 아직 받은 적이 없으면 `isLoaded == false`인 빈 목록을 보내고, 첫 구독이 첫 페이지 요청을 시작한다
- `refresh()`는 첫 페이지부터 다시 받아 목록을 **교체**한다. `requestNextPage()`는 다음 페이지를 **이어 붙인다**. 두 동작 모두 결과를 반환하지 않고 스트림에 반영한다 (R9)
- 실패는 동작이 던지고, 스트림은 마지막으로 성공한 목록을 유지한다
- `delete(_:)`가 성공하면 해당 항목을 목록에서 제거해 방출한다

**Generation 상태 필터링** (결정 3·4)
- 주입받은 `preparingProjectIDs`(진행 중 + 준비 중)를 구독하고, 해당 projectID를 목록에서 제외해 방출한다
- 집합이 바뀌면 서버 재요청 없이 **보관 중인 목록에 필터만 다시 적용**한다
- 집합에서 **빠진 projectID가 있으면**(준비 완료 또는 실패) 내부에서 `refresh()`를 수행한다. 준비 완료면 새 프로젝트가 목록에 들어오고, 실패면 서버 응답에 포함되지 않으므로 목록은 그대로다 (결정 23)
- 필터링으로 한 페이지 항목 수가 줄어도 `hasNextPage`는 서버 기준을 따른다

**로그아웃 정리** (결정 5) — `signedOutEvents`를 받으면 보관 목록과 페이지 상태를 비우고 `isLoaded == false`인 빈 목록을 방출한다

**퀴즈 후 진행률** (결정 8·21) — Project는 채점을 알지 못한다.

| 시점 | 목록 | 상세 |
| --- | --- | --- |
| 답안 제출 | 갱신하지 않음 | 갱신하지 않음 — `progressInvalidated` 제거 |
| 퀴즈 닫기 | Router가 `refresh()` 호출 → 첫 페이지로 교체, 모든 구독 화면에 반영 | 열려 있으면 Router가 상세 화면에 갱신 요청 → `detail(of:)` 재호출. 없으면 상세 화면을 연다 (현재 동작 유지) |

- 호출 지점은 현재 `AppRootFeature`의 `quiz(.presented(.delegate(.dismissRequested)))` 처리다
- 해소되는 문제: 현재는 퀴즈 후 목록을 갱신하지 않아 Home "이어 학습"이 이전 `nextSetID`·`currentSetLabel`로 끝낸 세트를 다시 열 수 있다
- 감수하는 점: 2페이지 이상 불러온 `ProjectList`는 첫 페이지로 줄어든다

**내부 책임**
- 서버 요청 단위는 페이지(20개)이며 페이지 번호는 내부 상태로만 관리한다

---

## ProjectGeneration

**책임** 외부 저장소로 학습 프로젝트 생성을 요청하고, **사용자에게 보이는 준비 상태**를 추적하며, 완료 알림을 등록한다.

| 기능 | API | 공개 | 기존 기능 |
| --- | --- | --- | --- |
| 생성 요청 | `request(_: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt` | 공개 | `CreateLearningProject` |
| 생성 요청 상태 | `states() async -> AsyncStream<ProjectGenerationState>` | 공개 | `TrackGeneration.states` · `current` |
| 생성 요청 상태 정리 | 없음 — 준비 완료 타이머·만료 정리·로그아웃 구독으로 내부 수행 | 내부 | `TrackGeneration.end(githubRepoURL:)`, `AppRootFeature.releaseGeneration` 타이머·만료 판정, `AppComposition` 탈퇴 정리 |
| 생성 알림 등록 | 없음 — `request` 성공 시 내부에서 항상 등록 | 내부 | `RequestGenerationReminder`(등록), `ScheduleGenerationReminder`, 확장 앱 대기열 |

```swift
public protocol ProjectGenerationUseCase: Sendable {
    func request(_ request: ProjectGenerationRequest) async throws -> ProjectGenerationReceipt
    func states() async -> AsyncStream<ProjectGenerationState>
}
```

**생성자 (R11)**

```swift
public init(
    repository: any LearningProjectRepository,
    pendingGenerations: any PendingGenerationRepository,
    outcomes: any GenerationOutcomeRepository,
    reminderScheduler: any GenerationReminderScheduler,
    signedOutEvents: @escaping @Sendable () async -> AsyncStream<Void>,
    waitPolicy: GenerationWaitPolicy = .standard,
    now: @escaping @Sendable () -> Date = Date.init,
)
```

**모델**

| 모델 | 정의 | 현재 타입 |
| --- | --- | --- |
| `ProjectGenerationRequest` | `repositoryURL: ExternalRepositoryURL`, `quizLevel: QuizLevel` | 신규 (요청 인자 묶음) |
| `QuizLevel` | `enum { l1, l2, l3 }` | 그대로 |
| `ProjectGenerationReceipt` | `projectID: ProjectID`, `quizLevel: QuizLevel` | `ProjectRegistrationReceipt` — 서버 원문 `requestStatus: String` 제거 |
| `ProjectGenerationState` | `requests: [ProjectGenerationRequestState]`, `preparingProjectIDs: Set<ProjectID>` — `inProgress`·`preparing` 단계의 projectID | `GenerationState` |
| `ProjectGenerationRequestState` | `repositoryURL`, `projectID: ProjectID?`, `requestedAt`, `phase: ProjectGenerationPhase` | `GenerationRecord` |
| `ProjectGenerationPhase` | `enum { inProgress(readyAt: Date), preparing(readyAt: Date), ready, failed }` | `GenerationRecord.Status` + `finishedAt` + `GenerationWaitPolicy.readyDate` |
| `GenerationWaitPolicy` | `minimumWait`(300초), `retentionLimit`(3600초) | 그대로 — 생성자 기본값으로만 쓰인다 |
| `ProjectGenerationError` | `duplicateRequest`, `invalidRequest`, `unauthorized`, `temporarilyUnavailable`, `unexpected` | `LearningProjectError`에서 분리 |

**단계 규칙** (결정 4)

| 단계 | 조건 | 목록 필터 | Home 배너 |
| --- | --- | --- | --- |
| `inProgress(readyAt:)` | 서버 생성 진행 중 | 제외 | 생성 중 |
| `preparing(readyAt:)` | 서버 완료, 요청 후 300초(`readyAt`) 전 | 제외 | 생성 중 |
| `ready` | 서버 완료 **그리고** `readyAt` 경과 | 포함 | 꺼짐 |
| `failed` | 서버 실패 — `readyAt`과 무관하게 즉시 (결정 13) | 포함되지 않음 — 서버 응답에서 자동 제외 (결정 23) | 꺼짐 · **실패 알림** |

- 서버가 늦게 끝나 `readyAt`이 이미 지났으면 `inProgress` → `ready`로 바로 넘어간다
- 현재 `AppRootFeature`가 하던 대기 타이머(`releaseGeneration`)와 만료 판정(`waitPolicy.isExpired`)은 이 규칙 안으로 들어온다

**내부 책임**
- 같은 저장소 주소(정규화 후)가 진행 중이면 서버 요청 없이 `duplicateRequest`
- 요청 성공 시 projectID 연결 → 완료 알림 대상 등록. 실패 시 요청 상태 해제
- 생성 결과 수신을 요청 상태에 반영 (최초 사용 시 관찰 시작)
- `readyAt`에 도달하는 요청마다 **내부 타이머로 `preparing` → `ready` 전환을 방출**한다
- 완료 시 `readyAt`에 완료 알림 예약, 실패 시 **즉시 실패 알림** (결정 13). 현재 `GenerationReminderScheduler`는 완료 알림만 예약한다
- `ready`·`failed`가 된 요청은 보관 기한(3600초) 후 제거한다. **초기화 시 기한이 지난 요청을 검증·정리**한다
- `signedOutEvents`를 받으면 모든 요청 상태와 알림 대상을 비운다 (결정 5)
- 앱과 확장 앱이 같은 구현을 쓴다. 알림 대상은 프로세스를 넘어 유지된다
- **확장 앱** (결정 15) — `Account.signInAvailability()`가 `signedIn`일 때만 `request(_:)`를 호출한다. `states()`를 구독하지 않고, 결과 수신·준비 타이머·로그아웃 정리는 메인 앱 인스턴스가 수행한다. 알림 설정 시트는 띄우지 않는다

---

## 요청 인증 정보

**결정 9·22** — 서버 요청에 붙는 인증 정보(access token)의 읽기·만료 판정은 **Data**가 소유합니다. 서버에 갱신 API가 없으므로 갱신하지 않고, 토큰이 무효하면 로그아웃합니다. Domain에는 UseCase도 계약도 없고, Account는 "로그인이 유효한가"와 "무효가 되었다는 신호"만 다룹니다.

### 변경 전후

| 책임 | 현재 메인 앱 | 현재 확장 앱 | 변경 후 (앱·확장 앱 동일) |
| --- | --- | --- | --- |
| 토큰 읽기 | Composition이 `SessionRecordCoding`에서 직접 | Domain `ResolveSessionAvailability`의 `available(accessToken:)` | Data `RequestCredentialProvider.credential()` |
| 만료 판정 | 없음 — 만료된 토큰으로 요청 | Domain (`expiresAt <= now`) | Data `RequestCredentialProvider` |
| 갱신 | 없음 (`RefreshSession` 미구현) | 없음 | **없음** — `RefreshSession` 제거 (결정 22) |
| 만료·401 | 요청 실패만 전달. 앱 재진입 시 `VerifyAuthorization`이 재인증 요구 | 요청 실패 | Data가 로그인 정보를 지우고 `invalidations()` 방출 → Account가 공유 로그인 표시 정리·`.signedOut` 방출 → 각 관심사 정리 (결정 5·20) |

### 구성

```swift
// DataAuthentication
public actor RequestCredentialProvider {
    public init(secureStorage: any SecureValueStorage, now: @escaping @Sendable () -> Date)
    public func credential() async -> RequestCredential
    public func credentialRejected() async
    public nonisolated func invalidations() -> AsyncStream<Void>
}

public enum RequestCredential: Sendable {
    case available(String)
    case signedOut
}
```

| 동작 | 책임 |
| --- | --- |
| `credential()` | 저장된 토큰을 읽는다. 유효하면 `available`. 로그인 정보가 없으면 `signedOut`. 만료되었으면 로그인 정보를 지우고 `invalidations()`를 방출한 뒤 `signedOut` |
| `credentialRejected()` | 서버가 401을 돌려준 요청에서 호출한다. 로그인 정보를 지우고 `invalidations()`를 방출한다. 이미 지워졌으면 다시 방출하지 않는다 |
| `invalidations()` | 로그인 정보를 지웠을 때 방출한다 |
| 요청 실행기 | `signedOut` → 요청을 보내지 않고 `unauthorized`. 401 → `credentialRejected()` 호출 후 `unauthorized`. 재요청하지 않는다 |

```swift
// Composition — 앱과 확장 앱이 같은 방식으로 조립
let credentials = RequestCredentialProvider(secureStorage: secureStorage, now: Date.init)

let projectRemote = ProjectRemote(
    credential: { await credentials.credential() },
    credentialRejected: { await credentials.credentialRejected() },
)
let account = Account(
    ...,
    signInInvalidations: { credentials.invalidations() }, // 확장 앱은 빈 스트림
)
```

### 요청 흐름

```
Remote 요청 실행기
  ├─ credential()
  │    ├─ 로그인 정보 없음 ─────────────────────────────────▶ signedOut
  │    ├─ 만료 ──▶ 로그인 정보 삭제 · invalidations() ─────▶ signedOut
  │    └─ 유효 ─────────────────────────────────────────────▶ available
  ├─ signedOut → 전송 없이 unauthorized
  ├─ available → 요청 전송
  └─ 401 수신 ──▶ credentialRejected() ──▶ unauthorized
```

### 구현 영향

- Data: `RequestCredentialProvider` 신설, 모든 Remote 요청 실행기(`LearningProjectRequestExecutor` 등)의 헤더 공급·401 처리
- Composition: `AuthenticationAssembly.accessTokenProvider`, `SessionAvailabilityAssembly.accessTokenProvider` 제거 → `RequestCredentialProvider` 연결. `AppComposition.refreshSession` 제거
- Domain: `RefreshSessionUseCase`·`RefreshSession`, `LoginSessionRepository.refresh()`, `SingleFlightCoordinator`, `SessionRefreshOutcome` 제거. `SessionTokens` 공개 제거
- 점검표 A-1(`RefreshSession`의 `SingleFlightCoordinator` 주입)은 대상 제거로 해소

---

## Domain 타깃 구성

**결정 26·27** — 관심사 하나가 Domain 타깃 하나입니다. 관심사 타깃끼리는 import하지 않고, 관심사 간 상태는 R11 클로저로만 전달합니다. 공유 식별자는 기반 타깃 `DomainIdentifier`에 둡니다.

```
DomainAccount  DomainUserInfo  DomainAppSetting  DomainExternalRepository  DomainQuizDetail  DomainProject  DomainProjectGeneration
      │               │                │                    │                     │                │                 │
      └───────────────┴────────────────┴──────── (필요한 타깃만) ─────────────────┴────────────────┴─────────────────┘
                                                            ▼
                                                    DomainIdentifier
```

**`DomainIdentifier` 규칙**
- `public typealias <대상>ID = String` 형태의 식별자와 `ExternalRepositoryURL`처럼 식별 역할의 값 `typealias`만 둔다
- 모델·enum·프로토콜·함수·규칙은 두지 않는다. 다른 타깃에 의존하지 않는다
- 둘 이상의 관심사 공개 API가 쓸 때만 옮긴다. 한 관심사만 쓰면 그 관심사 타깃에 둔다

| 식별자 | 위치 | 쓰는 관심사 |
| --- | --- | --- |
| `ProjectID` | `DomainIdentifier` | Project, ProjectGeneration, QuizDetail |
| `QuizSetID`, `QuizID` | `DomainIdentifier` | QuizDetail, Project |
| `ExternalRepositoryURL` | `DomainIdentifier` | ExternalRepository, ProjectGeneration |
| `AccountID`, `PolicyDocumentID` | `DomainAccount` | Account |
| `DeviceID`, `DeviceToken` | `DomainAppSetting` | AppSetting |

**관심사 타깃**

| 타깃 | UseCase | 현재 위치 | 소유 계약 (현재 이름) |
| --- | --- | --- | --- |
| `DomainAccount` | `AccountUseCase` | `DomainAuthentication` 전체 + `DomainMember`의 탈퇴 | `AuthenticationRepository`, `LoginSessionRepository`·`CurrentSessionRepository`·`SharedSignInStateRepository`(→ `signInRepository`), `PolicyConsentRepository`, 탈퇴 계약 |
| `DomainUserInfo` | `UserInfoUseCase` | `DomainMember`의 `MemberAccount` | `MemberRepository`의 프로필·큐레이션 동작 |
| `DomainAppSetting` | `AppSettingUseCase` | `DomainLearningProject`의 알림 권한 + `DomainMember`의 기기 등록 | `NotificationAuthorization`, `DeviceIdentifierRepository`, `MemberRepository`의 기기 등록 동작 |
| `DomainExternalRepository` | `ExternalRepositoryUseCase` | `DomainLearningProject`의 `FetchExternalRepository` | `ExternalRepositoryLocator`, `ExternalRepositoryLookup` |
| `DomainQuizDetail` | `QuizDetailUseCase` | `DomainLearningProject`의 세트·채점·북마크 | `LearningSetRepository`, `AnswerRepository`, `BookmarkRepository` |
| `DomainProject` | `ProjectUseCase` | `DomainLearningProject`의 목록·상세·삭제 | `LearningProjectRepository`의 목록·상세·삭제 동작 |
| `DomainProjectGeneration` | `ProjectGenerationUseCase` | `DomainLearningProject`의 생성·추적·알림 | `LearningProjectRepository`의 생성 동작, `PendingGenerationRepository`, `GenerationOutcomeRepository`, `GenerationReminderScheduler` |

- 현재 계약 둘이 두 타깃에 걸친다: `MemberRepository`(UserInfo·AppSetting·Account), `LearningProjectRepository`(Project·ProjectGeneration). 타깃마다 필요한 동작만 가진 계약으로 나눈다
- Composition 앱: 일곱 타깃 모두 사용. 확장 앱: `DomainAccount`(`signInAvailability()`), `DomainExternalRepository`, `DomainProjectGeneration`(`request(_:)`) (결정 15)

---

## 기존 기능 대응표

현재 UseCase 20개의 공개 동작 전체와, App·Composition·Feature에 있던 관련 로직입니다. `—`는 공개 API 없이 내부 책임으로 흡수됨을 뜻합니다.

| 현재 | 동작 | 새 관심사 | 새 API |
| --- | --- | --- | --- |
| `SignIn` | `callAsFunction(_:)` | Account | `signIn(with:)` |
| `SignOut` | `callAsFunction()` | Account | `signOut()` |
| `RestoreSession` | `callAsFunction()` | Account | `restoreSignIn()` |
| `VerifyAuthorization` | `callAsFunction()` | Account | `verifySignIn()` |
| `RefreshSession` | `callAsFunction()` | — | 제거 — 서버 갱신 API 없음 (결정 22) |
| `ResolveSessionAvailability` | `callAsFunction()` | Account | `signInAvailability()` |
| `DeleteMemberAccount` | `callAsFunction()` | Account | `withdraw()` |
| `PolicyConsent` | `requiredDocuments()` | Account | `policyConsentStatus().documents` |
| `PolicyConsent` | `storedConsentRecords()` | Account | `policyConsentStatus().consents` |
| `PolicyConsent` | `saveConsentRecords(_:)` | Account | `consent(to:)` |
| `PolicyConsent` | `isConsentValid(storedRecords:for:)` | Account | `policyConsentStatus().isSatisfied` |
| `PolicyConsent` | `clearConsentRecords()` | Account | — (탈퇴 내부) |
| `MemberAccount` | `profile()` | UserInfo | `detail()` + `curation()` |
| `MemberAccount` | `completeCuration(position:careerLevel:)` | UserInfo | `updateCuration(_:)` |
| `MemberAccount` | `updatePosition(_:)` | UserInfo | `updatePosition(_:)` |
| `MemberAccount` | `updateCareerLevel(_:)` | UserInfo | `updateCareerLevel(_:)` |
| `RegisterCurrentDevice` | `callAsFunction()` | AppSetting | `registerDevice()` |
| *(App)* `AppRootFeature` | `deviceTokenRefreshed` → 기기 재등록 | AppSetting | `updateDeviceToken(_:)` |
| `RequestGenerationReminder` | `isAuthorized()` | AppSetting | `notificationAuthorization()` |
| `RequestGenerationReminder` | `requestAuthorization()` | AppSetting | `requestNotificationAuthorization()` |
| `RequestGenerationReminder` | `callAsFunction(projectID:)` | ProjectGeneration | — (`request` 내부 알림 등록) |
| `FetchExternalRepository` | `callAsFunction(url:)` | ExternalRepository | `repository(at:)` |
| `LearningLibrary` | `learningSet(projectID:setID:)` | QuizDetail | `quizSet(_:in:)` |
| `SubmitChoiceAnswer` | `callAsFunction(...)` | QuizDetail | `grade(_: ChoiceAnswer)` |
| `SubmitEssayAnswer` | `callAsFunction(...)` | QuizDetail | `grade(_: EssayAnswer)` |
| `SetQuestionBookmark` | `callAsFunction(bookmarked: true)` | QuizDetail | `bookmark(_:in:)` |
| `SetQuestionBookmark` | `callAsFunction(bookmarked: false)` | QuizDetail | `unbookmark(_:in:)` |
| `LearningLibrary` | `bookmarkedQuestions(projectID:)` | QuizDetail | `bookmarks(_:)` |
| `FetchLearningProjects` | `callAsFunction(page:)` — 첫 페이지 | Project | `projects()` 첫 구독 · `refresh()` |
| `FetchLearningProjects` | `callAsFunction(page:)` — 다음 페이지 | Project | `requestNextPage()` |
| `FetchLearningProjects` | 생성 중 항목 제외 (저장소 직접 조회) | Project | — (`preparingProjectIDs` 클로저 구독 필터) |
| `LearningLibrary` | `project(id:)` | Project | `detail(of:)` |
| `LearningLibrary` | `deleteProject(id:)` | Project | `delete(_:)` |
| *(Feature)* `HomeFeature` · `ProjectListFeature` | 목록 각자 조회 | Project | `projects()` 공유 구독 |
| *(Feature)* `MainShellRouterFeature` · `AppRootFeature` | `learningProjectsReloadRequested` 전파 | Project | `refresh()` 한 번 (모든 구독 화면에 반영) |
| *(Feature)* `QuizRouterFeature` → `AppRootFeature` | `progressInvalidated`(답안 제출마다)·퀴즈 닫기 시 **열린 상세만** 갱신, 목록은 갱신하지 않음 | Project | 퀴즈 닫기 시 Router가 `refresh()` + 상세 갱신 요청, `progressInvalidated` 제거 (결정 21) |
| `CreateLearningProject` | `callAsFunction(githubRepoURL:quizLevel:)` | ProjectGeneration | `request(_:)` |
| `TrackGeneration` | `states()` · `current()` | ProjectGeneration | `states()` |
| `TrackGeneration` | `begin` · `attachProjectID` | ProjectGeneration | — (`request` 내부) |
| `TrackGeneration` | `end(githubRepoURL:)` · `end(projectID:)` | ProjectGeneration | — (준비 완료·만료·로그아웃 내부 정리) |
| `ScheduleGenerationReminder` | `register` · `absorbPendingReminders` · `start` · `waitUntilObservationFinished` | ProjectGeneration | — (내부) |
| *(App)* `AppRootFeature` | `releaseGeneration` 300초 타이머 · 만료 판정 후 `end` | ProjectGeneration | — (`preparing` → `ready` 내부 타이머) |
| *(Composition)* `AppComposition` | 탈퇴 시 생성 기록 전체 `end` | ProjectGeneration | — (`signedOutEvents` 구독) |
| *(Composition)* `AppComposition` | `refreshSession` 공개 | *(Data)* | — (App 소비 없음, 제거) |
| *(Composition)* `AuthenticationAssembly` · `SessionAvailabilityAssembly` | `accessTokenProvider` | *(Data)* | `RequestCredentialProvider.credential()` |
| *(Composition)* `ShareExtensionComposition` | 알림 대기열 직접 기록 | ProjectGeneration | — (`request` 내부) |
| *(App)* `AppRootFeature` | `applicationBecameActive` → `learningProjectsReloadRequested` | Project | `refresh()` |
| *(Feature)* `TutorialFeature` | `deletesCompletedAccountOnSignIn` (운영 `false`) | Account | `withdraw()` |
| *(Composition)* `GenerationReminderAssembly` | 두 UseCase 연결해 관찰 시작 | ProjectGeneration | — (최초 사용 시 내부 시작) |

**새로 생기는 동작**
- `Account.signInStates()` — 로그아웃·탈퇴·로그인 무효화 신호
- **로그아웃 시** 프로젝트 목록·생성 요청 상태 정리 — 현재는 탈퇴 시에만 생성 기록을 정리하고, 로그아웃 시에는 정리하지 않는다
- `Project` 공유 목록 스트림 — 준비 완료·삭제가 모든 화면 목록에 즉시 반영
- **만료·401 시 즉시 로그아웃** — 현재 메인 앱은 요청만 실패하고 앱 재진입 때 재인증을 요구 (결정 22)
- **생성 실패 즉시 반영·실패 알림** — 현재는 실패해도 `readyAt`까지 "생성 중"으로 보이고 알림이 없음 (결정 13)
- **로그인 복원 전 `.unknown` 상태** (결정 14)
- **퀴즈 후 목록 갱신** — 현재는 열린 상세만 갱신 (결정 21)

**제거되는 계약·타입**
- 계약: `GenerationReminderRegistration`, `PolicyConsentUseCase`(→ Account)
- 제거: `RefreshSessionUseCase`, `RefreshSession`, `SessionRefreshOutcome`, `SingleFlightCoordinator`
- 공개에서 제외: `SessionTokens`, `SessionRecord`, `AuthenticationGrant`, `LocalOnboardingState`
- 병합·교정으로 소멸: `NotificationAuthorizationOutcome`, `LoginSessionError`, `AuthorizationStatus`, `Rubric`, `SubmittedAnswer`
- 참조처 없음: `LegalDocument`, `LegalAcceptanceRecord`
