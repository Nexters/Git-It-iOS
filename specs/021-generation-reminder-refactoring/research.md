# 조사: 생성 리마인드 명명·경계 리팩터링

**기능 브랜치**: `feature/generation-reminder-refactoring`

**날짜**: 2026-09-01

**명세**: [spec.md](./spec.md)

이 문서는 계획 수립 중 확인이 필요했던 미해결 항목과 그 결론을 기록한다. 각 항목은
저장소의 실제 문서·소스를 근거로 판단했으며, 근거 경로를 함께 남긴다.

---

## R-001. Composition이 재노출하는 AppDelegate의 소유 위치

**결정**: `FirebaseMessagingAppDelegate`를 감싸는 **Composition 소유의 concrete 클래스**를
새로 두고, 기존 `public typealias PushNotificationAppDelegate = FirebaseMessagingAppDelegate`를
제거한다. App은 그 Composition 타입만 참조한다.

**근거**:

- `docs/package-rules/composition.md`는 "내부 Adapter와 Infrastructure 객체는 공개 API에
  노출해서는 안 됩니다"라고 규정한다. `public typealias`는 `FirebaseMessagingAppDelegate`를
  Composition 공개 API로 승격하므로 이 제약을 위반한다.
- 코드 리뷰 리포트가 제시한 대안(“AppDelegate를 `App/GitIt/AppDelegates/`로 이전”)은
  **실행할 수 없다.** `docs/architecture.md:69`의 허용 의존성 표에서 App의 의존성은
  `Feature, Composition, Domain`이며 Infrastructure가 없다. App이 `UIApplicationDelegate`
  구현을 소유하려면 `FirebaseMessagingAppDelegate`를 상속하거나 참조해야 하는데, 이는
  App → Infrastructure 의존을 만든다.
- Composition → Infrastructure와 App → Composition은 모두 허용된 방향이므로, Composition이
  자신의 타입으로 감싸는 것이 유일하게 의존성 표를 지키는 배치다.

**검토한 대안**:

- *App이 AppDelegate를 소유한다* — 기각. App → Infrastructure 의존이 필요해 허용 표를 위반한다.
- *typealias를 `internal`로 낮춘다* — 기각. App이 `@UIApplicationDelegateAdaptor`에 넘길
  타입을 이름으로 지목할 수 없어 컴파일되지 않는다.
- *App이 `UIApplicationDelegate`를 직접 구현하고 Composition이 콜백만 주입한다* — 기각.
  `Messaging.messaging().appDidReceiveMessage(_:)`와 APNs 토큰 전달이 Firebase 구체 API를
  요구하므로 App에 Infrastructure 의존이 다시 생긴다.

---

## R-002. Composition의 AppDelegate를 어느 형태 폴더에 둘 것인가

**결정**: `docs/conventions/file-vocabulary.md` §3의 Composition 행에 `AppDelegates/`
(“플랫폼 생명주기 delegate 타입”)를 **같은 변경에서 추가**하고, 새 타입을
`Composition/Adapter/AppDelegates/`에 둔다.

**근거**:

- 현재 이 파일은 `Composition/Adapter/Factories/`에 있으나, 같은 문서가 정의한 `Factories/`의
  담는 선언은 “구현 선택과 생성”이다. 플랫폼 생명주기 delegate는 어느 쪽도 아니다.
- 같은 어휘 표는 Infrastructure와 App 행에 이미 `AppDelegates/`를 “플랫폼 생명주기 delegate
  타입”으로 등재하고 있다. 새 어휘를 발명하는 것이 아니라 기존 어휘를 한 행에 더 적용한다.
- 어휘 표는 “표에 없는 형태를 추가하려면 같은 PR에서 이 표를 갱신한다”고 규정하므로,
  문서 갱신을 작업 목록에 파일 단위로 포함한다(Constitution 원칙 4는 `docs/**`를 정확한
  경로로 명시한 작업에 한해 허용한다).

**검토한 대안**:

- *`Assemblies/`에 둔다* — 기각. “조립 진입 타입과 객체 수명 선택”이라는 정의와 delegate의
  책임(플랫폼 콜백 수신)이 일치하지 않는다. 어휘를 늘리지 않으려고 의미를 늘리는 선택이다.
- *`Adapters/`에 둔다* — 기각. 이 폴더는 “Domain 계약을 구현하는 Adapter”만 담는다.

---

## R-003. 로컬 알림 문구와 식별자의 소유 계층

**결정**: Infrastructure는 `LocalNotificationRequest`(식별자·제목·본문) 값을 받아 발송만
하고, 그 값의 생성은 **Composition의 리마인드 coordinator**가 소유한다.

**근거**:

- `docs/package-rules/infrastructure.md`는 “Domain 모델과 비즈니스 규칙을 정의해서는 안
  됩니다”, “서비스 고유 데이터 형식을 소유해서는 안 됩니다”를 제약으로 둔다. 현재
  `UserNotificationCenterLocalClient:59-63`은 `"세트 생성 완료"` 문구와
  `"generation-completed-\(projectID)"` 식별자를 직접 소유한다.
- 문구를 Feature나 Domain으로 올리는 선택지도 있으나, 발송 시점이 화면과 무관한 백그라운드
  경로(생성 결과 스트림 수신)이므로 화면 계층이 소유할 근거가 없다. 발송을 실행하는 주체가
  coordinator이므로 값 생성도 같은 곳에 두는 것이 수명과 일치한다.

**검토한 대안**:

- *Domain이 문구를 소유한다* — 기각. 문구는 표현 계층 관심사이며 Domain 모델·정책이 아니다.
  `docs/package-rules/domain.md`의 책임 범위를 넘는다.
- *문자열 리소스 카탈로그로 분리한다* — 이번 범위에서 제외. 로컬라이제이션 도입은 별도
  기능이며 지금 도입하면 동작 무변경 검증 범위가 커진다. 값의 소유 위치만 먼저 바로잡는다.

---

## R-004. 생성 결과 어휘의 최종 형태

**결정**: 세 패키지가 `GenerationOutcome` 어휘를 공유한다.

| 현재 | 변경 후 | 패키지 |
| --- | --- | --- |
| `LearningProjectGenerationOutcome` | `GenerationOutcome` | Domain |
| `LearningProjectGenerationOutcomeRepository` | `GenerationOutcomeRepository` | Domain |
| `LearningProjectGenerationOutcomeRepositoryAdapter` | `GenerationOutcomeRepositoryAdapter` | Composition |
| `ProjectGenerationOutcomeDTO` | `GenerationOutcomeDTO` | Data |
| `ProjectGenerationOutcomeRemote` | `GenerationOutcomeStream` | Data |
| `PushProjectGenerationOutcomeRemote` | `PushGenerationOutcomeStream` | Data |
| `LearningProjectOutcomes` / `…UseCase` | `ObserveGenerationOutcomes` / `…UseCase` | Domain |
| `GenerationCompletionReminderCoordinator` | `GenerationReminderScheduler` | Composition |

**근거**:

- `docs/conventions/naming.md` §4는 “패키지 이름을 접두어처럼 붙여 경계를 표시하지
  않습니다”라고 규정한다. `LearningProject…` 접두어는 `DomainLearningProject` 모듈과
  `LearningProject/` 관심사 폴더가 이미 제공하는 문맥의 반복이다.
- 같은 문서 §3.3은 “조회, 관찰, 저장, 삭제와 취소처럼 동작과 수명에 차이가 있으면
  이름에서도 구분합니다”라고 요구한다. 무한 스트림을 반환하는 계약에 `Observe`를 되살려
  1회 조회 계약(`FetchLearningProjects`)과 구분한다.
- §3.2는 `Remote` 역할어를 “실제 연산 집합과 수명 경계가 그 역할을 충족할 때만” 쓰라고
  규정한다. `PushProjectGenerationOutcomeRemote`는 네트워크를 호출하지 않고 push로 도착한
  payload를 여러 구독자에게 전달하는 인메모리 허브이므로 `Remote`가 아니다.
- 최장 이름은 49자에서 34자(`GenerationOutcomeRepositoryAdapter`)로 줄어 SC-002의 40자 상한을
  충족한다.

**검토한 대안**:

- *`LearningSetGenerationOutcome`으로 통일* — 보류. 생성되는 대상이 학습 세트라는 점은 더
  정확하지만, 식별자 필드가 `projectID`이고 서버 payload도 `projectId`를 쓴다. 어휘를 바꾸면
  필드명과 외부 계약 사이의 불일치가 새로 생긴다. 단일 어휘 확보가 우선이므로
  `GenerationOutcome`을 선택한다.
- *현행 유지* — 기각. 세 패키지의 어휘 불일치가 명세의 P2 시나리오 자체다.

---

## R-005. `Data` 패키지의 새 형태 폴더

**결정**: `Streams/`를 추가하지 않고 기존 `Remotes/` 대신 **`Contracts/`와 `Stores/`를
재사용하지 않는다**. `PushGenerationOutcomeStream`은 `Data/LearningProject/Remotes/`에
그대로 두되, 파일·타입 이름만 바꾼다.

**근거**:

- 어휘 표의 `Remotes/`는 “네트워크 계약 구현”이다. push 수신 허브는 엄밀히 네트워크 계약
  구현이 아니지만, 값의 출처가 원격 서버(APNs → FCM)라는 점에서 로컬 저장(`Stores/`)보다는
  `Remotes/`에 가깝다.
- 새 형태 폴더(`Streams/`)를 추가하면 어휘 표 갱신이 한 건 더 늘어난다. R-002에서 이미
  Composition 행을 갱신하므로, 근거가 약한 두 번째 어휘 확장은 이번 범위에서 피한다.
- 타입 이름이 `…Stream`으로 바뀌면 역할어 오용(R-004)은 해소되며, 폴더 위치는 후속 기능에서
  Data 계층의 push 수신 경로가 더 늘어날 때 재검토한다.

**검토한 대안**:

- *`Streams/` 신설* — 보류. 파일 한 개를 위해 어휘를 늘리는 비용이 이득보다 크다. 이 판단은
  `/speckit-clarify` 재검토 후보로 남긴다.

---

## R-006. 리마인드 정책의 소유 경계

**결정**: 판정 로직(등록 여부 · 완료 상태 · 권한 확인 후 발송)을 **Composition에 유지**하고,
그 근거를 PR과 세션 지식 기록에 남긴다.

**근거**:

- `docs/package-rules/composition.md`는 “비즈니스 규칙을 Adapter 내부에 구현해서는 안
  됩니다”라고 규정하므로 이 배치는 규칙과 긴장 관계에 있다.
- 그러나 이 판정의 마지막 단계는 “알림 권한이 있으면 플랫폼에 알림을 낸다”는 부작용
  실행이며, Domain으로 올리면 Domain이 발송 실패·권한 상태를 다시 계약으로 받아야 해
  계약이 두 개 더 늘어난다.
- 명세는 “동작 변경 없이 구조와 어휘만 정리한다”를 제약으로 둔다. 정책 이동은 실행 주체와
  오류 경로를 바꾸므로 동작 무변경 보장이 약해진다.

**검토한 대안**:

- *`DeliverGenerationReminder` Domain UseCase 신설* — 이번 범위에서 제외. 명세의 `가정`과
  체크리스트에 `/speckit-clarify` 1순위 후보로 기록했다.

---

## R-007. 삭제 대상 UI 컴포넌트의 실제 참조

**결정**: `UI/Component/Controls/TextField.swift`와 그 전용 테스트
`UI/Tests/Component/Unit/Controls/TextFieldTests.swift`를 함께 삭제한다.

**근거**:

- 저장소 전체 검색 결과 이 타입의 참조는 자기 파일의 `#Preview` 3건과 위 테스트 파일 4건뿐이며
  production 사용처가 0이다.
- 대체 컴포넌트 `LabeledTextField`가 같은 역할(플레이스홀더·에러 표시·상태 색상)을 수행하며
  `ProjectRegistrationScreen`이 실제로 사용한다.
- 테스트는 생성자 호출만 확인하는 계약 테스트이므로 대상 삭제와 함께 사라지는 것이 맞다.

**검토한 대안**:

- *`LabeledTextField`가 `label`을 선택 인자로 받아 흡수* — 기각. 두 컴포넌트의 레이아웃이
  다르고(레이블 인라인 vs 없음) 흡수하려면 `LabeledTextField`의 뷰 구조를 바꿔야 해
  동작 무변경 범위를 벗어난다.

---

## R-008. 기준선(미커밋 변경)의 처리

**결정**: 현재 작업 트리의 **소스 14건**을 이 기능의 첫 커밋으로 정리한 뒤 시나리오를
시작한다. `issue/`와 `specs/020-local-reminder-notification/**`은 이 기능의 소유가 아니므로
건드리지 않는다.

**근거**:

- 커밋된 HEAD(`a515aac`)는 자기 일관적이다. `AppComposition:51`이
  `UNUserNotificationCenterLocalNotificationClient()`를 참조하고 그 파일도 커밋 트리에 있으며,
  커밋된 `ExternalDependenciesName`에는 `FirebaseCore`·`FirebaseMessaging` case가 모두 있다.
- 작업 트리는 그보다 진행된 상태이며, 그중 로컬 알림 클라이언트 이름 변경
  (`UNUserNotificationCenterLocalNotificationClient` → `UserNotificationCenterLocalClient`)은
  이 기능이 지향하는 방향과 이미 일치한다. 되돌리면 같은 작업을 두 번 한다.
- 두 기준선이 공존하면 이후 모든 작업의 “변경 전” 상태가 모호해진다.

**주의**: 이 14건은 **사용자가 소유한 기존 변경**이다. Constitution 원칙 7은 “사용자 소유
변경의 소비”를 명시적 승인이 필요한 경우로 규정하므로, 구현 단계에서 이 커밋을 만들기 전에
사용자 확인을 받는다.

**검토한 대안**:

- *커밋된 HEAD를 기준선으로 삼고 작업 트리 변경을 보존한 채 진행* — 기각. 같은 파일에 두
  방향의 변경이 겹쳐 충돌하고, 이름 변경 작업이 중복된다.
- *작업 트리 변경을 되돌린다* — 기각. 사용자 소유 변경의 파괴적 폐기이며 승인 범위 밖이다.

---

## R-009. 동작을 바꾸지 않기 위해 유지하는 항목

**결정**: 코드 리뷰 리포트가 지적했으나 **이번 범위에서 고치지 않는** 항목과 그 이유를
아래에 고정한다.

| 항목 | 유지 이유 |
| --- | --- |
| Home 목록 갱신 경로 2개(등록 완료 · 생성 완료) | 하나로 합치면 갱신 시점이 바뀐다. 대신 두 트리거가 겹칠 때의 동작을 고정하는 테스트를 추가한다. |
| `ProjectRegistrationScreen`의 View 로컬 단계 플래그 | 단계 전이를 Feature State로 올리면 화면 흐름 소유가 바뀌어 동작 무변경 보장이 약해진다. 별도 기능으로 분리한다. |
| 인증 결과 계열(`AuthenticationOutcomes`)의 이름 | 이 기능이 다루는 생성 결과 계열 밖이다. 같은 규칙 위반이지만 범위를 분리한다. |
| `InfrastructurePushMessaging` target 분리 | 원격 푸시와 로컬 알림을 하위 폴더로만 나눈다. target 분리는 링크 비용이 실제 문제가 될 때 승격한다. |
| 저장소 전반의 `@unknown default` | 이 기능이 만지는 파일에서만 제거한다. 나머지 약 25곳은 별도 정리 대상이다. |

**근거**: 명세 FR-018이 동작 무변경을 요구하며, 위 항목은 모두 수정 시 관찰 가능한 동작 또는
소유 경계가 함께 바뀐다. 범위를 분리해 각각 독립적으로 검증하는 편이 안전하다.

## R-010. `LocalNotificationAuthorizationOutcome`을 프로토콜에 중첩할 수 없음

**결정**: `LocalNotificationAuthorizationOutcome`을 최상위 타입으로 유지하고,
`LocalNotificationClient`와 별도 파일(`Local/Models/LocalNotificationAuthorizationOutcome.swift`)로
분리한다. 이름은 바꾸지 않는다.

**근거**: 계획 단계에서는 "파일 하나에 타입 하나" 규칙(FR-003)을 지키기 위해 이 enum을
`protocol LocalNotificationClient` 안에 중첩하기로 했으나, 구현 단계에서 swiftc로 직접
검증한 결과 Swift는 protocol 내부에 타입을 중첩하는 것을 언어 차원에서 금지한다
(`error: type 'X' cannot be nested in protocol 'Y'`). 이 사례는
`docs/conventions/file-vocabulary.md` §2.4 "중첩할 수 없는 타입"이 이미 다루며, 해법은
"최상위에 두고 이름에 소유 타입을 남긴다"이다. `LocalNotificationAuthorizationOutcome`은
이미 이름에 소유 개념(`LocalNotification`)을 담고 있으므로 이름 변경 없이 파일만 분리하면
같은 목적(파일당 외부 참조 타입 하나)을 달성한다.

**검토한 대안**:

- protocol 안에 `enum AuthorizationOutcome`을 중첩 — swiftc 컴파일 오류로 기각.
- 소유 타입 이름을 접두어로 붙인 새 이름(`LocalNotificationClientAuthorizationOutcome`) —
  이미 `LocalNotification` 접두어로 소유 개념을 담고 있어 불필요하게 길어지므로(44자)
  기각하고 기존 이름을 유지한다.
