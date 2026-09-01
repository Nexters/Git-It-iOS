# 구현 계획: 생성 리마인드 명명·경계 리팩터링

**Git-flow 유형**: `feature`

**브랜치**: `feature/generation-reminder-refactoring`

**날짜**: 2026-09-01 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/021-generation-reminder-refactoring/spec.md`의 기능 명세

## 요약

코드 리뷰가 식별한 네 부류의 구조 문제를 동작 변경 없이 해소한다.

1. **Infrastructure 경계 복원** — 범용 기술 계약이 소유하던 서비스 개념(알림 문구,
   `generation-completed` 식별자)을 `LocalNotificationRequest` 값으로 분리해 Composition이
   소유하게 한다.
2. **어휘 통일** — 같은 사건을 세 어휘로 부르던 Domain·Data·Composition을
   `GenerationOutcome` 하나로 맞추고, 관찰 계약에 `Observe` 접두어를 되살려 1회 조회와 수명을
   구분한다. 최장 타입 이름 49자 → 34자.
3. **조립과 실행 분리** — `AppComposition` 생성자의 부작용(네트워크 호출, 전역 상태 쓰기,
   취소 불가 관찰)을 `start()` 진입점으로 옮기고, Infrastructure 타입을 공개 API로 승격하던
   typealias를 Composition 소유 클래스로 대체한다.
4. **죽은 코드·중복 테스트 제거와 검증 공백 보강** — 사용처 0인 컴포넌트, 소비되지 않는
   delegate, 항진 테스트를 제거하고 `InfrastructurePushMessagingTests` target을 신설한다.

조사 과정에서 코드 리뷰 리포트의 권고안 하나가 **실행 불가**임을 확인했다. AppDelegate를
App 패키지로 옮기는 안은 App → Infrastructure 의존을 만들어 `docs/architecture.md:69`의 허용
의존성 표를 위반한다. 대신 Composition이 자신의 타입으로 감싼다([research.md](./research.md) R-001).

## 기술 맥락

**언어/버전**: Swift 6 (iOS 26.0 이상)

**주요 의존성**: The Composable Architecture, SwiftUI, FirebaseCore·FirebaseMessaging,
UserNotifications, Synchronization(`Mutex`), Lottie

**저장소**: 이 기능은 영속 저장을 다루지 않는다. 리마인드 등록 집합은 앱 실행 중에만
메모리에 유지된다.

**테스트**: Swift Testing(`@Suite`/`@Test`, 한국어 동작 문장). 실행은 Tuist 공유 scheme의
`build-for-testing` → `test-without-building`.

**대상 플랫폼**: iOS 26.0+ Simulator·기기. 기본 테스트 destination
`platform=iOS Simulator,name=iPhone 17 Pro`.

**프로젝트 유형**: 모바일 앱 (Tuist 기반 멀티 패키지)

**성능 목표**: 해당 없음. 이 기능은 런타임 성능 특성을 바꾸지 않는다.

**제약 조건**:

- 최종 사용자에게 관찰되는 동작을 바꾸지 않는다(FR-018). 화면 전이, 알림 발송 시점과 문구
  내용, 서버 payload 계약이 모두 보존 대상이다.
- `docs/architecture.md` §3.1의 허용 의존성 표를 벗어나는 새 의존성을 만들지 않는다.
- 형태 폴더 어휘를 늘리려면 같은 변경에서 `docs/conventions/file-vocabulary.md` §3을 갱신한다.

**규모/범위**: 변경 대상 약 45개 Swift 파일(생성 12, 삭제 8, 수정 25 예상)과 Tuist manifest
2개, 공용 문서 1개. 7개 패키지 중 6개(App·Composition·Feature·Domain·Data·Infrastructure·UI)를
건드리며 UI는 삭제만 한다.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | ✅ | 새 패키지 의존성을 만들지 않는다. Composition → Infrastructure, App → Composition은 기존 허용 방향이다. 오히려 App이 Infrastructure 타입을 이름으로 다루던 경로를 제거한다. |
| 2. 상태와 데이터 안전성 | ✅ | `start()`가 취소 가능한 핸들을 반환해 현재 취소 수단이 없는 관찰 Task에 소유자와 수명을 부여한다. |
| 3. 검증 가능한 변경 | ✅ | 변경 전 테스트 로그를 기준선으로 고정하고 변경 후와 비교한다([quickstart.md](./quickstart.md)). R-006·R-009의 예외는 이유·영향·미검증 범위를 PR에 남긴다. |
| 4. 스킬별 수정 경로 | ✅ | 이 스킬은 자신의 산출물만 쓴다. `docs/conventions/file-vocabulary.md`는 `tasks.md`에 정확한 저장소 상대경로로 파일 단위 배정한다. |
| 5. Spec-Kit 범위 | ✅ | `plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/**`만 생성했다. |
| 6. 한국어 산출물 | ✅ | 모든 산출물이 한국어이며 코드 식별자·경로·명령어는 원문을 유지했다. |
| 7. 위험 기반 실행 단위 | ⚠ | 단일 패키지 단위가 기본이나 이 기능은 다중 패키지 integration unit 6개를 사용한다. 근거는 [복잡성 추적](#복잡성-추적)에 기록했다. |
| 8. Git-flow 브랜치 | ✅ | `/speckit-specify`가 `feature/generation-reminder-refactoring`을 HEAD `a515aac`에서 생성하고 검증했다. |
| 9. 세션 지식 기록 | ⚠ | R-001(리포트 권고안이 의존성 표와 충돌해 실행 불가)은 여러 문서 근거를 종합한 판단이므로 `$speckit-tacit-knowledge` 대상이다. 계획 산출물이나 구현 작업으로 만들지 않고 별도 스킬로 기록한다. |
| 10. 책임 기반 네이밍 | ✅ | 이 기능의 핵심이다. 표면적 통일이 아니라 `docs/conventions/naming.md` §2.2·§3.2·§3.3·§4의 개별 기준을 각 이름에 적용했다([research.md](./research.md) R-004). |

**브랜치 네임스페이스**: `feature/` 사용. `/speckit-specify`가 명세 산출물 생성 전에 브랜치를
직접 생성하고 검증했으며, `before_specify` 훅은 등록되어 있지 않다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정했다. 구현 파일은 아래에 정확한 경로로 기록하며 계획
단계에서 수정하지 않는다.

**세션 지식 기록**: 원칙 9의 문턱을 충족하는 항목은 R-001 하나다. `$speckit-tacit-knowledge`로
별도 기록한다.

**Git 실행 직렬화**: 구현 시 `git commit`·pre-commit·staged formatter 체인을 하나만 실행한다.
현재 작업 트리에 사용자 소유 미커밋 변경이 있으므로(U0), 각 단위의 staging 범위를 정확한 파일
목록으로 제한한다.

**커밋 단위 구현**: 아래 [실행 단위](#실행-단위)가 순서·목적·파일·검증을 정의한다. 각 단위는
독립적으로 리뷰·되돌리기가 가능하다.

**책임 기반 네이밍**: [data-model.md §6](./data-model.md)의 이름 변경 표가 각 이름의 근거를
`docs/conventions/naming.md` 조항과 함께 기록한다.

**실행 단위 진행**: 패키지 위상 순서와 integration unit 근거를 아래에 기록했다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/021-generation-reminder-refactoring/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── spec.md              # /speckit-specify 산출물
├── research.md          # 0단계 산출물
├── data-model.md        # 1단계 산출물
├── quickstart.md        # 1단계 산출물
├── contracts/           # 1단계 산출물
│   ├── infrastructure-push-messaging.md
│   ├── domain-generation-outcome.md
│   └── composition-public-surface.md
├── checklists/
│   └── requirements.md  # /speckit-specify 산출물
└── tasks.md             # 2단계 산출물(/speckit-tasks)
```

### 소스 코드(저장소 루트)

변경 대상만 표시한다. `→` 는 이동·개명, `+` 는 생성, `−` 는 삭제다.

```text
sources/Projects/
├── Infrastructure/PushMessaging/
│   ├── Local/                                       + 하위 능력 폴더
│   │   ├── Clients/LocalNotificationClient.swift    → (Remote 개념 제거, enum 중첩)
│   │   ├── Clients/UserNotificationCenterLocalClient.swift  → (문구·식별자 제거)
│   │   └── Models/LocalNotificationRequest.swift    +
│   ├── Remote/                                      + 하위 능력 폴더
│   │   ├── AppDelegates/FirebaseMessagingAppDelegate.swift  → 이동
│   │   ├── Clients/PushMessagingClient.swift        → 이동
│   │   ├── Clients/FirebaseMessagingPushClient.swift → 이동
│   │   ├── Models/PushNotificationCallbacks.swift   → (PushNotificationHandlers 개명)
│   │   └── Models/RemoteNotificationPayload.swift   → 이동
│   └── Clients/LocalNotificationAuthorizationOutcome  − (프로토콜에 중첩)
│
├── Infrastructure/Tests/PushMessaging/              + 신규 테스트 target 소스
│
├── Domain/LearningProject/
│   ├── Contracts/GenerationOutcomeRepository.swift  → 개명
│   ├── Models/LearningProject/GenerationOutcome.swift → 개명
│   ├── Models/Notification/NotificationAuthorizationOutcome.swift → 이동
│   ├── UseCases/ObserveGenerationOutcomes/          → 개명
│   ├── UseCases/RequestGenerationReminder/          → (isAuthorized 제거)
│   └── UseCases/NotificationAuthorizationStatus/    +
│
├── Data/LearningProject/
│   ├── Contracts/GenerationOutcomeStream.swift      → 개명
│   ├── DTOs/GenerationOutcomeDTO.swift              → 개명
│   └── Remotes/PushGenerationOutcomeStream.swift    → 개명
│
├── Composition/Adapter/
│   ├── AppDelegates/PushNotificationAppDelegate.swift + (typealias → 실제 클래스)
│   ├── Adapters/GenerationOutcomeRepositoryAdapter.swift → 개명, @unknown default 제거
│   ├── Adapters/GenerationReminderRegistryAdapter.swift  −
│   ├── Assemblies/GenerationReminderScheduler.swift → 이동·개명, 알림 값 생성 소유
│   ├── Assemblies/AppComposition.swift              → start() 분리
│   ├── Assemblies/LearningProjectAssembly.swift     → 개명 반영
│   └── Factories/PushNotificationAppDelegate.swift  −
│
├── Feature/
│   ├── Home/Reducers/HomeFeature.swift              → 개명 반영, Bool 상태, cancellable
│   ├── MainShell/Reducers/MainShellFeature.swift    → 개명 반영
│   └── ProjectRegistration/
│       ├── Reducers/ProjectRegistrationFeature.swift → delegate·CancelID·@unknown 제거
│       └── Screens/NotificationOptionSheet.swift     → bellIconSize 제거
│
├── App/GitIt/
│   ├── GitItApp.swift                               → start() 호출, delegate 타입 교체
│   └── Reducers/AppRootFeature.swift                → 개명 반영, 빈 분기 제거
│
└── UI/
    ├── Component/Controls/TextField.swift           −
    └── Tests/Component/Unit/Controls/TextFieldTests.swift −

sources/Tuist/ProjectDescriptionHelpers/
├── ProjectName.swift                                → testTargets 추가
└── Projects/InfrastructureModuleName.swift          → 테스트 target 정의

docs/conventions/
└── file-vocabulary.md                               → Composition AppDelegates 행 추가
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지한다. 새 target은
`InfrastructurePushMessagingTests` 하나뿐이며, 나머지는 기존 target 안에서의 폴더 재배치와
개명이다. `Infrastructure/PushMessaging/` 하위 능력 폴더 분리는 source glob이
`<sourceDirectory>/**`이므로 manifest 변경 없이 반영된다.

## 패키지 위상 순서

`docs/architecture.md` §3.1의 허용 의존성 표에서 도출한 구현 순서다.

```text
Infrastructure · Domain · UI   (의존성 없음)
        ↓
      Data                     (→ Infrastructure)
        ↓
Composition · Feature          (Composition → Domain·Data·Infrastructure / Feature → Domain·UI)
        ↓
       App                     (→ Feature·Composition·Domain)
```

Tuist manifest(`sources/Tuist/**`)와 공용 문서(`docs/**`)는 패키지에 속하지 않는다. 각각을
아래 실행 단위에 파일 단위로 배정했다(원칙 7).

## 실행 단위

각 단위는 하나의 목적, 정확한 파일, 검증과 되돌리기 가능성을 갖는다. `[통합]`은 분리하면
중간 상태가 컴파일되지 않는 다중 패키지 integration unit이다.

### U0 — 기준선 정리 *(사용자 승인 필요)*

**목적**: 작업 트리에 남은 사용자 소유 변경 14건을 커밋해 리팩터링 기준선을 하나로 만든다.

**패키지**: App, Composition, Data, Feature, Infrastructure + Tuist manifest

**파일**: `git status`가 보고하는 소스 14건. `issue/`와
`specs/020-local-reminder-notification/**`은 **포함하지 않는다**(이 기능의 소유가 아니다).

**승인 필요 사유**: Constitution 원칙 7이 "사용자 소유 변경의 소비"를 명시적 승인 대상으로
규정한다. 이 14건은 `feature/local-reminder-notification` 작업의 결과이며 이 기능이 만들지
않았다.

**검증**: `build` 통과. 이후 `test`로 기준선 로그를 저장한다.

**대안**: 사용자가 승인하지 않으면 커밋된 HEAD를 기준선으로 삼고 U1 이후를 진행하되,
클라이언트 개명이 중복 작업이 됨을 감수한다([research.md](./research.md) R-008).

---

### U1 — Infrastructure 경계 복원 `[통합: Infrastructure + Composition]`

**목적**: 범용 기술 계약에서 서비스 개념과 사용자 문구를 제거한다. (시나리오 1)

**분리 불가 근거**: `LocalNotificationClient`의 연산 시그니처가 바뀌므로 유일한 소비자인
Composition의 스케줄러·게이트웨이 어댑터가 같은 커밋에서 바뀌지 않으면 컴파일되지 않는다.

**파일**:

- `Infrastructure/PushMessaging/Local/Clients/LocalNotificationClient.swift` (이동·수정)
- `Infrastructure/PushMessaging/Local/Clients/UserNotificationCenterLocalClient.swift` (이동·수정)
- `Infrastructure/PushMessaging/Local/Models/LocalNotificationRequest.swift` (생성)
- `Infrastructure/PushMessaging/Remote/**` (이동만)
- `Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift` (알림 값 생성 추가)
- `Composition/Adapter/Adapters/NotificationAuthorizationGatewayAdapter.swift` (중첩 enum 반영)

**검증**: `build`, quickstart 시나리오 1의 두 grep이 0줄.

**커밋**: `[Refactor] Infrastructure 로컬 알림 계약에서 서비스 개념 분리`

---

### U2 — 생성 결과 모델 어휘 통일 `[통합: Domain + Data + Composition + Feature + App]`

**목적**: 모델·저장소 계약·DTO·스트림 이름을 `GenerationOutcome` 어휘로 맞춘다. (시나리오 2)

**분리 불가 근거**: 공개 타입 개명이다. `GenerationOutcome`은 Domain이 정의하고
Data(DTO 대응), Composition(변환), Feature(Action payload), App(주입)이 모두 이름으로 참조한다.
한 패키지만 바꾸면 나머지가 컴파일되지 않는다.

**파일**: [data-model.md §6](./data-model.md)의 1~6번 항목에 해당하는 Domain·Data 파일과,
그 이름을 참조하는 Composition·Feature·App 파일 및 각 테스트.

**검증**: `build`, `compile`, `test`. quickstart 시나리오 2의 옛 어휘 grep이 0줄.

**커밋**: `[Rename] 생성 결과 모델·계약 어휘를 GenerationOutcome으로 통일`

---

### U3 — UseCase 관찰 이름 복원과 권한 조회 분리 `[통합: Domain + Composition + Feature + App]`

**목적**: `Observe` 접두어로 관찰 수명을 드러내고, 이름이 설명하지 않는 `isAuthorized()`를
별도 계약으로 분리한다. (시나리오 2)

**분리 불가 근거**: UseCase 계약 개명과 계약 축소가 동시에 일어나며, 주입 경로가
Composition → App → Feature로 이어져 세 패키지가 함께 바뀌어야 컴파일된다.

**파일**:

- `Domain/LearningProject/UseCases/ObserveGenerationOutcomes/**` (개명)
- `Domain/LearningProject/UseCases/RequestGenerationReminder/**` (`isAuthorized` 제거)
- `Domain/LearningProject/UseCases/NotificationAuthorizationStatus/**` (생성)
- `Domain/LearningProject/Models/Notification/NotificationAuthorizationOutcome.swift` (이동)
- `Composition/Adapter/Assemblies/AppComposition.swift`, `LearningProjectAssembly.swift`
- `Feature/Home/**`, `Feature/MainShell/**`, `Feature/ProjectRegistration/Reducers/**` 및 테스트 대역
- `App/GitIt/GitItApp.swift`, `Reducers/AppRootFeature.swift`, `Screens/AppRootView.swift` 및 테스트 대역

**검증**: `build`, `compile`, `test`.

**커밋**: `[Refactor] 생성 결과 관찰 UseCase 이름 복원과 알림 권한 조회 분리`

---

### U4 — 조립과 실행 분리 `[통합: Composition + App + docs]`

**목적**: 생성자 부작용을 `start()`로 옮기고, Infrastructure 타입을 공개 API로 승격하던
typealias를 Composition 소유 클래스로 대체한다. (시나리오 3)

**분리 불가 근거**: `AppComposition`의 공개 표면 변경과 App의 호출부 변경, 그리고 typealias
삭제와 App의 delegate 타입 교체가 같은 커밋에서 일어나야 컴파일된다. 형태 폴더 어휘 추가는
FR-012에 따라 같은 변경에 포함해야 한다.

**파일**:

- `Composition/Adapter/Assemblies/AppComposition.swift` (`start()` 분리)
- `Composition/Adapter/Assemblies/GenerationReminderScheduler.swift` (Factories에서 이동·개명,
  `waitUntilObservationFinished` 제거, `GenerationReminderRegistry` 직접 구현)
- `Composition/Adapter/Adapters/GenerationReminderRegistryAdapter.swift` (삭제)
- `Composition/Adapter/AppDelegates/PushNotificationAppDelegate.swift` (생성)
- `Composition/Adapter/Factories/PushNotificationAppDelegate.swift` (삭제)
- `Composition/Tests/Adapter/**` (스케줄러 테스트 갱신, 공개 표면 테스트 갱신)
- `App/GitIt/GitItApp.swift` (`start()` 호출, delegate 타입 교체)
- `docs/conventions/file-vocabulary.md` (Composition 행에 `AppDelegates/` 추가)

**검증**: `build`, `test`. quickstart 시나리오 3의 세 grep이 0줄.

**커밋**: `[Refactor] AppComposition의 조립과 실행 분리 및 AppDelegate 소유 정리`

---

### U5 — 사용처 없는 UI 컴포넌트 제거 `[단일: UI]`

**목적**: production 참조가 0인 `TextField`와 그 전용 테스트를 제거한다. (시나리오 4)

**순서 근거**: 다른 단위와 의존하지 않는다. 개명 단위(U2·U3) 뒤에 두어 각 커밋의 diff가 하나의
관심사만 담게 한다.

**파일**:

- `UI/Component/Controls/TextField.swift` (삭제)
- `UI/Tests/Component/Unit/Controls/TextFieldTests.swift` (삭제)

**검증**: `build`, `test`.

**커밋**: `[Remove] 사용처 없는 UIComponent TextField 제거`

---

### U6 — Feature·App 죽은 코드 제거 `[통합: Feature + App]`

**목적**: 소비되지 않는 delegate, 미사용 상수, 사용되지 않는 취소 id, 프로젝트 소유 enum의
미지 케이스 분기를 제거한다. (시나리오 4)

**분리 불가 근거**: `Delegate.notificationOptionSelected`를 제거하면 `AppRootFeature`의 수신
분기도 같은 커밋에서 사라져야 `switch` 전수성이 유지된다.

**파일**:

- `Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`
- `Feature/ProjectRegistration/Screens/NotificationOptionSheet.swift`
- `Feature/Home/Reducers/HomeFeature.swift` (2케이스 enum → `Bool`, 관찰 Effect에 `cancellable`)
- `App/GitIt/Reducers/AppRootFeature.swift`
- `Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`
  (delegate 검증 구문 제거)

**검증**: `build`, `test`. quickstart 시나리오 4의 grep이 0줄.

**커밋**: `[Remove] 소비되지 않는 delegate와 미사용 선언 제거`

---

### U7 — 중복·항진 테스트 정리 `[단일: Feature 테스트]`

**목적**: 완전히 포함되는 테스트 1건을 삭제하고, 본문이 같고 상수만 다른 3건을 파라미터화
테스트로 합치며, 기본값만 확인하는 항진 테스트를 제거한다. (시나리오 4)

**순서 근거**: U6이 같은 파일의 delegate 검증 구문을 먼저 제거하므로 그 뒤에 둔다.

**파일**: `Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`

**검증**: `test`. 통합 전후 검증 입력 조합 수가 줄지 않았음을 PR에 기록(SC-008).

**커밋**: `[Test] ProjectRegistration 중복·항진 테스트 정리`

---

### U8 — 테스트 target 신설과 검증 공백 보강 `[통합: Tuist manifest + Infrastructure + Composition + Feature 테스트]`

**목적**: `InfrastructurePushMessagingTests`를 신설하고 매핑 검증을 추가한다. (시나리오 5)

**분리 불가 근거**: manifest의 target 정의와 테스트 소스가 함께 있어야 target이 빌드된다.
manifest만 바꾸면 소스 없는 target이, 소스만 추가하면 빌드되지 않는 파일이 남는다.

**파일**:

- `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`
- `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`
- `sources/Projects/Infrastructure/Tests/PushMessaging/**` (생성)
- `Composition/Tests/Adapter/Adapters/NotificationAuthorizationGatewayAdapterTests.swift` (생성)
- `Feature/Tests/Home/Reducers/HomeFeatureGenerationOutcomeTests.swift`
  (두 갱신 트리거가 겹칠 때의 동작 고정, R-009)

**검증**: `make tuist` 후 `build`, `compile`, `test`. quickstart 시나리오 5의 grep과 실행 확인.

**커밋**: `[Test] InfrastructurePushMessaging 테스트 target 신설과 경계 변환 검증 추가`

---

### U9 — 전체 검증과 마무리 `[no-write]`

**목적**: 전체 읽기 전용 검증을 수행하고 포맷 훅을 실행한다.

**검증**:

- `build`, `compile`, `test` 전체 실행
- `./tools/script-verification/bin/run.sh`
- 변경 전 기준선 로그와 비교해 새로 실패하는 테스트 0건 확인(SC-003)
- 포맷 훅 실행 후 변경 파일 재stage

**주의**: `make tuist`는 파생 산출물만 갱신하므로 `[no-write]` 검증에서 실행할 수 있으나,
실행 전후 Git 상태를 비교해 추적 파일 diff가 바뀌지 않았음을 확인한다(원칙 7).

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 다중 패키지 integration unit 6개(U1~U4, U6, U8) — 단일 패키지 기본 원칙의 예외 | 모두 공개 API 개명·계약 변경·manifest 연결이며, 분리하면 중간 커밋이 컴파일되지 않는다. Constitution 원칙 7이 명시적으로 허용하는 "공개 API 이전, 공용 manifest·구성 변경, 양쪽 변경이 함께 있어야 compile되는 migration" 유형이다 | 패키지별로 쪼개면 U2 기준 5개 커밋 중 4개가 빌드되지 않는 상태로 남는다. 되돌리기 단위가 오히려 커지고 이등분 탐색이 불가능해진다 |
| U4가 `docs/conventions/file-vocabulary.md`를 함께 변경 — 소스 단위에 문서 포함 | FR-012와 어휘 표 자체가 "표에 없는 형태 폴더를 추가하려면 같은 PR에서 표를 갱신한다"고 규정한다. 문서와 폴더 배치가 갈라지면 어휘 정본이 깨진다 | 문서를 별도 커밋으로 분리하면 두 커밋 사이에 어휘 정본과 실제 구조가 불일치하는 구간이 생긴다 |
| U0이 사용자 소유 미커밋 변경을 소비 | 두 기준선이 공존하면 이후 모든 단위의 "변경 전" 상태가 모호해진다 | 작업 트리 변경을 되돌리는 것은 사용자 소유 변경의 파괴적 폐기이며 승인 범위 밖이다. 그대로 두면 같은 파일에 두 방향 변경이 겹친다 |
| `ObserveGenerationOutcomes`(25자)가 `LearningProjectOutcomes`(23자)보다 길어짐 | `docs/conventions/naming.md` §3.3이 요구하는 조회·관찰 수명 구분을 이름에 되살린다 | 같은 문서 §2.2가 "짧은 이름 자체가 목표는 아닙니다"라고 명시한다. 길이보다 독립적 해석 가능성이 우선이다 |

## 설계 후 헌법 재점검

1단계 설계를 마친 뒤 다시 평가했다.

- **원칙 1** — 설계가 새 의존성을 만들지 않음을 확인했다. R-001에서 App → Infrastructure를
  요구하는 대안을 기각한 것이 이 점검의 결과다.
- **원칙 2** — `start()`가 반환하는 취소 핸들로 관찰 Task에 명시적 수명이 생긴다. 설계 전보다
  개선된다.
- **원칙 7** — integration unit 6개의 근거를 위 표에 기록했다. 각 단위가 단일 목적을 갖고
  독립적으로 되돌릴 수 있음을 확인했다.
- **원칙 10** — 설계 산출물의 모든 이름을 `docs/conventions/naming.md` 조항과 대조했다.
  `GenerationReminderRegistry`처럼 이미 기준을 충족하는 이름은 통일을 이유로 바꾸지 않았다.

**게이트 통과**. 2단계(`/speckit-tasks`)로 진행 가능하다.
