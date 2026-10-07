# 조사: 관심사별 Domain UseCase 재설계와 호출부 전환

설계 결정의 정본은 [재설계 문서](../../docs/review/domain-usecase-redesign.md)의 결정 1–27입니다. 이 문서는
그 결정을 현재 코드(`760e1e3`)에 적용할 때 필요한 구현 판단만 기록합니다.

## R-01. 전환 순서 — 추가 후 전환, 마지막에 제거

- **결정**: ① 새 Domain 타깃 8개를 기존 세 타깃과 **나란히 추가**하고, ② Infrastructure·Data·Composition이 새 UseCase를
  **추가로** 조립해 공개한 뒤, ③ Feature·App 호출부를 관심사 묶음 단위로 새 API로 옮기고, ④ 마지막에 기존 Domain 타깃·
  UseCase·Adapter·공개 속성·테스트를 제거한다.
- **근거**: 기존 API를 먼저 지우면 Domain → Composition → Feature → App 전체가 한 커밋에서만 compile됩니다(수백 파일).
  추가 단계는 각 패키지가 독립적으로 compile되므로 커밋 단위를 위상 순서대로 나눌 수 있습니다. Swift 이름 조회는
  파일 단위 import를 따르므로 같은 이름의 모델(`SignInResult`, `QuizLevel`, `ExternalRepository` 등)이 옛 모듈과 새 모듈에
  동시에 있어도, 한 파일이 둘 중 한쪽만 import하면 충돌하지 않습니다.
- **검토한 대안**: 한 번에 교체(중간 상태 없음, 리뷰·되돌리기 불가능한 초대형 커밋) / 옛 타깃 안에서 이름만 바꾼 뒤 분리
  (같은 파일을 두 번 옮기고 결정 26의 타깃 경계를 중간에 검증할 수 없음).
- **제약**: 전환 기간에 한 파일이 옛 모듈과 새 모듈을 **함께** import하지 않도록 한다. 불가피한 파일(App 루트 등)은 해당
  전환 단위에서 한 번에 옮긴다.

## R-02. 구현 타입 이름

- **결정**: 공개 프로토콜은 `<관심사>UseCase`, 구현은 관심사 이름 그대로 둔다 — `Account`, `UserInfo`, `AppSetting`,
  `QuizDetail`, `Project`, `ProjectGeneration`. `ExternalRepository`는 모델 이름과 겹치므로 구현을 **`ExternalRepositoryResolver`**
  (주소 해석과 조회를 조합하는 책임)로 둔다.
- **근거**: 현재 관례(`SignInUseCase`/`SignIn`)를 유지합니다. 모델 `ExternalRepository`는 Feature 다수가 쓰므로 모델 이름을
  바꾸지 않습니다(원칙 10: 네이밍과 동작 변경 분리).
- **검토한 대안**: `Default…`·`Live…` 접두어 일괄 적용(원칙 10의 표면적 통일 금지) / 모델 이름 변경.

## R-03. 폴더 배치

- **결정**: 소스 루트는 target에서 `Domain` 접두어를 뺀 이름(`Domain/Account/`, `Domain/Identifier/` …), 1뎁스 형태 폴더는
  `Contracts`, `Errors`, `Models`, `UseCases`. 파일이 하나인 타입은 형태 폴더에 직접 둔다
  (`Domain/Account/UseCases/AccountUseCase.swift`, `Domain/Account/UseCases/Account.swift`). 테스트는
  `Domain/Tests/<관심사>/`. `DomainIdentifier`는 `Domain/Identifier/Models/`.
- **근거**: [디렉터리·파일 컨벤션](../../docs/conventions/directory-file.md)의 소스 루트·형태·타입 패밀리 규칙.

## R-04. Tuist·의존성 검사

- **결정**: `DomainModuleName`에 8쌍의 case를 추가하고 관심사 타깃은 `.module(dependencies: [.target(name: "DomainIdentifier")])`
  로 선언한다. `ProjectName.swift`의 `Domain` scheme, `AllTestsScheme.swift`, `tools/package-dependencies/config/source-roots`에
  같은 이름을 추가하고, 제거 단계에서 기존 세 쌍을 지운다. Composition·Feature·App 매니페스트의 `.fromDomain(...)`은 전환
  단위마다 필요한 타깃을 추가하고 제거 단계에서 옛 타깃을 지운다.
- **근거**: Data 조사 결과 `Target.module`은 이미 `dependencies`를 받으므로 `Target+Module.swift` 변경이 필요 없습니다.
  `source-roots`는 매니페스트 타깃과 1:1 일치를 검사합니다. 같은 패키지 안 target 의존은 `allowed-dependencies`(패키지 단위)
  대상이 아닙니다.

## R-05. 요청 인증 정보 구성요소의 위치와 형태

- **결정**:
  - `RequestCredential`(`available(String)` / `signedOut`)은 **`DataShared`** 에 둔다. `DataLearningProject`·`DataMember`·
    `DataAuthentication`의 Remote가 함께 쓰기 때문입니다.
  - `RequestCredentialProvider`는 **`DataAuthentication`** 에 두고 `SessionRecordStorageCoding`으로 저장 기록을 읽고 지운다.
    만료 판정은 `accessTokenExpiresAt <= now`, 만료 시각이 없으면 유효로 본다(현재 `ResolveSessionAvailability`와 동일).
  - Remote의 `accessTokenProvider: () async -> String?`를 `credential: () async -> RequestCredential`와
    `credentialRejected: () async -> Void` 두 클로저로 바꾼다. `signedOut`이면 요청을 보내지 않고 각 Remote의 인증 오류를 던지고,
    HTTP 401이면 `credentialRejected()` 후 인증 오류를 던진다. `AuthenticationRemote.verifyAccessToken`은 `credential`만 쓰며
    401 판단은 Account의 로그인 유효성 확인이 맡는다.
  - 무효 신호 방출은 `Synchronization.Mutex`로 보호한 구독자 목록으로 구현해 `invalidations()`를 동기 함수로 제공한다.
- **근거**: Data는 Domain에 의존하지 않고(조사 결과), Remote는 이미 클로저로 토큰을 받으므로 모양만 바꾸면 됩니다. 결정 22에
  따라 갱신은 없습니다.
- **검토한 대안**: Remote마다 provider 타입을 직접 받기(DataLearningProject가 DataAuthentication에 의존하게 됨).

## R-06. Account가 쓰는 계약 정리

- **결정**:
  - `AuthenticationRepository` 유지(인증 수단 연동): `authenticate(using: SignInMethod) -> AuthenticationGrant`,
    `authorizationStatus() -> SignInVerification`, `clearAuthentication()`. 취소는 `AccountError.signInCancelled`로 던진다.
  - `SignInRepository` 신설(현재 `LoginSessionRepository`·`CurrentSessionRepository`·`SharedSignInStateRepository` 대체):
    `start(with:) -> SignInRecord`, `restore() -> SignInRecord?`, `signOut()`(로컬 기록 삭제 + 공유 표시 로그아웃, 서버 호출
    없음 — 현재 어댑터 동작), `sharedSignInState() -> Bool?`, `hasUsableCredential() -> Bool`.
  - `WithdrawalRepository` 신설(`MemberRepository.deleteAccount()` 이관), `PolicyConsentRepository`는 저장소 연산 이름을
    `consents()`, `record(_:)`, `removeAll()`로 바꾼다.
  - `AuthenticationGrant`는 계약 전용 모델로 남긴다. `SessionTokens`, `SessionRecord`, `SessionRefreshOutcome`,
    `LocalOnboardingState`는 Domain에서 사라지고 Composition 어댑터가 Data `StoredSessionRecord`를 직접 다룬다.
- **해석**: FR-015의 "공개 API에서 제외"는 세션·토큰 이름 타입을 Domain에서 없애는 것으로 적용하고, 토큰·세션 이름이 없는
  계약 전용 모델(`AuthenticationGrant`, `SignInRecord`)은 계약 구현을 위해 공개로 둡니다. `AccountUseCase`의 인자·반환에는
  나타나지 않습니다.
- **로그인 무효·탈퇴 정리**: 두 경우 모두 `signInRepository.signOut()`(로컬, 멱등) → `clearAuthentication()` → `.signedOut`
  방출. 탈퇴는 그 전에 `policyConsentRepository.removeAll()`을 수행한다. 결정 20의 "서버 로그아웃 요청 안 함"은 현재
  `signOut()`이 로컬 정리만 하므로 그대로 충족됩니다.
- **`.unknown` 상태**: `restoreSignIn()`이 `temporarilyUnavailable`을 반환하면 상태는 `.unknown`을 유지합니다.

## R-07. 큐레이션 완료 시 로컬 온보딩 표시

- **결정**: `UserInfoRepository.updateCuration(_:)`의 Composition 어댑터가 서버 반영 후 Data `SessionRecordStorageCoding`으로
  저장 기록의 `needsCuration`을 `false`로 갱신한다(현재 `CurationRepositoryAdapter`가 Domain `LoginSessionRepository`로 하던 일).
- **근거**: `DomainUserInfo`는 `DomainAccount`에 의존할 수 없고(결정 26), 이 갱신은 저장 기술 세부이므로 Composition이 맡는
  것이 D-ARCH-004와 맞습니다.

## R-08. 알림 권한 상태 조회

- **결정**: `InfrastructureLocalNotification.NotificationAuthorizationClient`에 권한 요청 없이 현재 설정을 읽는
  `authorizationSetting() async -> NotificationAuthorizationSetting`(`notDetermined`/`authorized`/`denied`)을 추가하고, Data
  `LocalReminderNotifier`에 `authorizationSetting() async -> ReminderAuthorizationSetting`을 추가한다. Domain
  `AppSetting.notificationAuthorization()`은 이를 매핑하고, `requestNotificationAuthorization()`은 요청 결과
  `authorized → .authorized`, `declined`·`previouslyDenied → .denied`로 매핑한다.
- **근거**: 현재 클라이언트는 `isAuthorized() -> Bool`만 있어 `notDetermined`와 `denied`를 구분할 수 없고, 요청 API는 권한
  대화상자를 띄우는 부수효과가 있습니다. 재설계 문서의 호출부 규칙(`.denied`면 설정 이동, `.notDetermined`면 요청)을 지키려면
  조회가 필요합니다.
- **호출부**: `SettingsFeature.notificationRowTapped`는 `notificationAuthorization()`이 `.authorized`·`.denied`면 설정을 열고,
  `.notDetermined`면 요청합니다. 기존 `previouslyDenied` 분기와 사용자 결과가 같습니다.

## R-09. 생성 알림과 실패 알림

- **결정**:
  - `ProjectGeneration.request(_:)`는 성공 시 **항상** `PendingGenerationRepository.enqueueReminder(projectID:)`로 알림 대상을
    영속 등록한다(앱·확장 앱 동일). 메인 앱 인스턴스는 상태 관찰을 시작할 때와 상태 변경마다 대기열을 흡수한다.
  - `GenerationReminderScheduler.schedule(identifier:at:)`를 `schedule(_ reminder: GenerationReminder, at:)`로 바꾸고
    `GenerationReminder`에 `projectID`와 `kind`(`completed`/`failed`)를 둔다. 완료는 `readyAt`에, 실패는 현재 시각에 예약한다.
    예약 전 `isAuthorized()`를 확인하는 현재 동작을 유지한다.
  - Composition `GenerationReminderSchedulerAdapter`가 종류별 제목·본문을 선택한다. `AppComposition.Environment`에
    `generationFailureReminderTitle`, `generationFailureReminderBody`를 추가하고 App이 지역화 문자열을 공급한다.
- **근거**: 결정 13(실패 알림)과 "알림은 항상 등록, 권한 책임은 AppSetting". 현재 앱은 권한 허용 시에만 등록하고 확장 앱은
  대기열에 기록하므로, 대기열 경로 하나로 합치면 두 프로세스가 같은 구현을 씁니다(결정 15).

## R-10. 준비 시각 타이머와 시계 주입

- **결정**: `ProjectGeneration`은 `now: () -> Date`와 `sleep: (TimeInterval) async throws -> Void`(기본
  `Task.sleep`)를 주입받는다. 상태 관찰이 시작되면 `inProgress` 요청이 없는 `preparing` 요청마다 가장 이른 `readyAt`까지 대기한
  뒤 상태를 다시 계산해 방출한다. 관찰 시작 시 보관 기한(3600초)이 지난 기록을 `releaseGeneration`으로 제거한다.
- **근거**: 테스트에서 실제 시간 대기 없이 단계 전이를 검증해야 합니다(SC-005).

## R-11. 목록 공유 상태와 첫 로드

- **결정**: `Project`는 `actor`이며 받은 목록·다음 페이지 번호·제외 집합·구독자를 보관한다. 첫 구독이 첫 페이지 로드를
  시작하고, 로드가 진행 중일 때 `refresh()`가 호출되면 **같은 작업을 기다려** 그 오류를 던진다. 화면은 오류 표시를 위해
  진입 시 `refresh()`를 호출할 수 있다.
- **근거**: 스트림은 오류를 전달하지 않으므로(R6 규칙: 실패는 동작이 던짐) 화면이 실패를 표시할 경로가 필요하고, 중복 요청은
  피해야 합니다.

## R-12. Feature 주입 모양

- **결정**: 현재 방식(Router는 UseCase 존재 타입을 받고, 말단 Feature는 쓰는 동작 하나를 클로저로 받음)을 유지한다. Router
  init의 인자는 관심사 UseCase 7종으로 바뀌고, 말단 클로저의 모델·오류 타입이 새 모델로 바뀐다.
- **근거**: [Domain 패키지 규칙](../../docs/package-rules/domain.md)의 "말단 화면 Feature는 자신이 쓰는 동작 하나만 클로저로
  받는다"와 D-ARCH-003.

## R-13. 기존 미커밋 변경

- **관찰**: 브랜치 생성 시점에 사용자 소유 미커밋 변경 31개 파일(주로 선언 순서·`MARK` 정리)이 작업 트리에 있고, 그중 일부
  (`CreateLearningProjectTests.swift`, `HomeFeatureGenerationOutcomeTests.swift`, Composition 테스트 더블 등)는 이 기능이
  수정·삭제할 파일입니다.
- **결정**: 구현 단계 시작 전에 소유권을 확인한다(Constitution 원칙 7: 사용자 소유 변경을 커밋 단위가 소비하지 않음).
  계획은 이 변경을 전제로 하지 않는다.
