# Router-Feature와 화면 전환 소유

[Git It iOS TCA 컨벤션 — Navigation과 화면 연결](../navigation.md)의 규칙 문서입니다.

**화면 전환이 있는 흐름은 그 전환을 전담하는 Router-Feature를 둡니다.** 화면의
Feature는 자신의 화면 상태만 소유하고 어떤 화면 다음에 어떤 화면이 오는지는 알지
않습니다. 전환할 화면이 하나뿐이면 전환 관심사가 없으므로 Router를 두지 않습니다.

**Router-Feature의 관심사는 화면 전환 하나입니다.** Router는 화면 집합을 대표하는
Feature가 아니라 전환만 소유하는 Feature이며, 전환과 무관한 관심사(진입 준비, 결과
판단, 흐름 공용 오류 표시)를 자신의 `State`에 담지 않고 별개 Feature로 조합합니다.
Feature의 정의 단위가 화면이 아니라 관심사라는 근거는
[Feature 컨벤션 — 정의 단위 — 관심사](../feature/definition-unit.md), Router 파일이 놓이는 자리는
[디렉터리·파일 컨벤션 — Feature 패키지의 흐름 배치](../../directory-file/feature-layout.md)이
소유합니다.

**Router의 정의 단위**

- **Router 하나의 관심사 단위는 하나의 전환 컨텍스트입니다.** 전환 컨텍스트는 순차
  흐름에서는 하나의 `FlowNavigationStack`, 셸 흐름에서는 하나의 `TabShell`입니다.
  **전환 컨텍스트 하나에 Router 하나**를 둡니다.
- **흐름과 Router는 1:1이 아닙니다.** 한 흐름 안에 전환 컨텍스트가 둘이면 Router도
  둘이고, 전환 컨텍스트를 포함하는 쪽의 Router가 포함되는 쪽의 Router를 조합합니다.
  셸인 `MainShellRouterFeature`가 스택을 소유한 `SettingsRouterFeature`를 조합하는
  것이 그 예입니다.
- **하나의 Router가 두 전환 컨텍스트를 함께 쥐지 않습니다.** 전환 컨텍스트를 갖지 않는
  Router가 오버레이나 `@Presents`로 push를 대신 구현하는 것도 여기에 해당합니다. push는
  그 스택을 소유한 Router가 수행하고, 스택이 없다면 스택을 소유하는 Router를 새로
  둡니다.
- **전환이 아닌 관심사는 Router가 소유하지 않고 조합합니다.** 진입 준비, 결과 판단과
  흐름 공용 오류 표시는 각각 자신의 Feature로 두고 Router가 `Scope`로 조합하며, Router
  자신의 `State`에는 전환 상태만 둡니다. 여러 Router가 같은 준비 관심사를 쓰면 그
  Feature를 각각 조합합니다 — 화면이 없는 `SingleQuestionEntryFeature`가 그 예입니다.
- Router가 조합한 관심사 Feature의 `delegate`는 Router가 해석합니다. 그 결과가 전환이면
  Router가 활성 화면 값을 바꾸고, 흐름 이탈이면 Router 자신의 `delegate`로 올립니다.

**흐름의 두 종류**

Router가 조합하는 화면의 관계에 따라 흐름을 두 종류로 나눕니다. 아래 **Router View와
뒤로가기**는 두 종류에 공통이고, 그 뒤의 **구성**·**화면 이동 이벤트**는 순차 흐름에만
적용합니다.

| | 순차 흐름 | 셸 흐름 |
| --- | --- | --- |
| 예 | `ProjectRegistration` | `MainShell` |
| 화면 관계 | 정해진 순서로 이어지는 여정 | 병렬로 존재하고 임의 순서로 오감 |
| Router가 소유하는 골격 | `FlowNavigationStack` — 화면들이 배경을 공유 | `TabShell` — 각 화면이 자기 `ScreenContainer`를 가짐 |
| 활성 화면 값 | 세부 화면을 연관값으로 갖는 계층형 enum | 화면을 나열하는 평평한 enum |
| 흐름 차원의 뒤로가기 | 있음 | 없음 |
| 이동 이벤트 | 기록함 | 기록하지 않음 — 전환 순서에 의미가 없음 |
| 화면의 위치 | 같은 흐름의 화면 폴더 | 대체로 다른 흐름 |

**Router가 조합하는 대상**

- Router는 같은 흐름의 화면 Feature뿐 아니라 **다른 흐름의 진입 Feature**도
  조합할 수 있습니다. `MainShellRouterFeature`가 `HomeFeature`를 `Scope`로 조합하는
  것이 그 예입니다.
- 따라서 자신의 화면을 하나도 갖지 않고 `Router/`만 있는 흐름이 존재할 수 있습니다
  ([디렉터리·파일 컨벤션 — Feature 패키지의 흐름 배치](../../directory-file/feature-layout.md)).
- 조합 대상이 다른 흐름이어도 경계는 같습니다. 자식은 `delegate`로만 상위 의도를
  알리고 Router가 그것을 해석하며, Router는 자식의 내부 상태를 직접 바꾸지 않습니다.
- **형제 Router는 서로를 알지 않습니다.** Router가 조합할 수 있는 것은 자신이 소유한
  하위 화면 Feature와 자신이 진입시키는 하위 흐름뿐입니다. 같은 계층의 다른 흐름
  Router를 `Scope`로 조합하거나 그 State를 생성해서는 안 됩니다. 다른 흐름으로 나가야
  하면 자신을 조합하는 상위(App 또는 상위 Router)에게 `delegate`로 알리고 목적지 결정은
  그 상위가 합니다. 이 규칙이 없으면 흐름 사이에 순환 참조가 생기고, Router 하나를
  단독으로 테스트할 수 없게 됩니다.

**Router View와 뒤로가기**

- Router View는 그 흐름의 **골격 컴포넌트**와 흐름 공용 sheet·alert를 소유하고, 활성
  화면 값에서 해당 화면을 그립니다. 각 화면의 Store는 Router State가 항상 보유하는
  child state에서 `scope`로 얻습니다. Router View가 전환 관심사 Feature 하나만
  관찰해야 하는 것은 아니며, 그 흐름이 조합하는 다른 관심사 Feature도 함께 관찰할 수
  있습니다.
- 골격 컴포넌트는 순차 흐름이면 `FlowNavigationStack`, 셸 흐름이면 `TabShell`입니다.
  셸 흐름에서는 각 화면이 자신의 `ScreenContainer`를 소유하므로 Router가 이를 다시
  감싸지 않습니다. 순차 흐름의 화면들이 배경을 공유해야 하면 Router가
  `FlowNavigationStack`을 `ScreenContainer`로 감쌉니다.
- **활성 화면 값 타입은 Router가 소유합니다.** 순차 흐름의 계층형 enum과 셸 흐름의 탭
  enum 모두 `Router/`에 둡니다.
- **순차 흐름의 화면 전환은 `FlowNavigationStack`의 push입니다.** Router View는 활성
  화면 값에서 경로 배열을 파생시켜 전달하고, 그 경로가 곧 스택입니다. 활성 화면 값이
  정본이므로 `StackState`와 `NavigationStack`의 쓰기 가능한 경로 `Binding`은 쓰지
  않습니다. 활성 화면 값의 첫 화면이 스택의 루트이고, 나머지 화면은 push된 목적지로
  그립니다.
- **TCA 표준 예제의 `StackState`·`StackAction`과 `NavigationStackStore`를 이 흐름
  모델에 쓰지 않습니다.** 그 모델은 경로 배열이 상태 정본이어서 화면 State가 push
  시점에 생성되고 pop 시점에 제거됩니다. 이 문서의 순차 흐름은 반대로 Router가 화면
  State를 **항상 보유**해 되돌아간 화면의 입력값을 보존하도록 정했으므로, 두 모델은
  양립하지 않습니다. 표준 예제를 그대로 옮기지 않고 이 프로젝트의 흐름 모델을
  우선합니다.
- `FlowNavigationStack`은 navigation bar와 시스템 뒤로가기 제스처를 감춥니다. 뒤로가기
  입력 경로는 각 화면이 소유한 `ScreenControlBar` 하나뿐입니다.
- **뒤로가기는 활성 화면 값을 이전 값으로 되돌리는 상태 전이입니다.** View를 pop하거나
  화면 Feature를 다시 주입해 State를 새로 만들지 않습니다. child state를 항상 보유하므로
  되돌아간 화면의 입력값은 그대로 보존됩니다.
- 흐름 내 뒤로가기 입력은 화면의 View Action으로 들어와 Router가 해석합니다. 화면
  Feature는 자신의 이전 화면이 무엇인지 알지 않습니다.

**구성** (순차 흐름)

- Router의 `State`는 조합하는 각 화면 Feature의 State를 **항상 함께 보유**합니다. 현재
  어떤 화면이 활성 상태인지는 별도의 연관값 enum(예: `ActiveScreen`)으로 표현하며, 이
  값은 최상위 화면 Feature 단위를 case로 갖고 그 내부에 세부 화면이 있으면(예: 하나의
  화면 Feature가 여러 단계를 가짐) 그 세부 화면을 연관값으로 함께 포함하는 계층형
  값입니다.
- 이 활성 화면 값에는 "완료"처럼 상위로 나가야 함을 뜻하는 case를 두지 않습니다. 흐름을
  벗어나는 것은 활성 화면 전환이 아니라 Router의 `delegate`입니다.
- 상위로 나가야 하는 조건이 **한 화면 Feature의 `delegate` 하나로 그대로 드러나면**
  Router가 그 `delegate`를 자신의 `delegate`로 바꿔 올립니다. 별도 Feature를 두지
  않습니다. `ProjectRegistrationRouterFeature`가 진행 화면의
  `projectRegistered`를 그대로 올리는 것이 그 예입니다.
- 상위로 나가야 하는지가 **여러 신호의 조합이나 추가 단계에 달려 있으면**, 그 판단만
  하는 별도의 얇은 조건부 Feature를 두고 판단 결과를 `delegate`로 Router에 알립니다. 이
  조건부 Feature는 "완료 여부"가 아니라 "Router 전환 여부"를 판단하는 책임만 가집니다.
  큐레이션 성공과 splash 표시를 함께 봐야 하는 `OnboardingExitFeature`가 그 예입니다.
- Router의 `body`는 조합하는 모든 화면 Feature와 조건부 Feature를 `Scope`로 구성하고,
  뒤이어 Router 자신의 `Reduce`에서 화면 Feature의 `delegate`를 해석해 활성 화면을
  전환하거나 조건부 Feature로 조정 신호를 전달합니다.
- 활성 화면이 현재 Feature 수명 안에서 완결되는 sheet·alert가 아니라 순차적으로 이어지는
  여정이면 `@Presents`/`Destination` 대신 이 방식(항상 존재하는 Child + 활성 enum)을
  사용합니다. `@Presents`의 존재/부재 의미론은 이런 순차 여정에 적합하지 않습니다.

**화면 이동 이벤트** (순차 흐름)

- Router는 자신이 관리하는 활성 화면이 실제로 바뀔 때마다 전환 이전 화면, 전환 이후
  화면과 전환을 유발한 Action을 식별할 수 있는 값을 담은 이동 이벤트를 State에 기록해
  테스트가 직접 조회할 수 있게 합니다.
- 이 이벤트는 최상위 화면 Feature 간 전환뿐 아니라 같은 최상위 단위 안에서 세부 화면만
  바뀌는 전환도 포함합니다. 활성 화면 값이 계층형이므로 이 두 경우는 같은 비교 로직
  (전환 전후 값이 다른가)으로 함께 처리할 수 있습니다.
- 화면 Feature 내부 상태가 바뀌어도 활성 화면 값 자체가 바뀌지 않으면(예: 같은 화면
  안에서 선택 값만 바뀌는 경우) 이동 이벤트를 남기지 않습니다. 조건부 Feature의
  `delegate`가 Router 자신의 `delegate`로 전달되는 전이도 활성 화면 값을 바꾸지 않으면
  이동 이벤트를 남기지 않습니다.
- 이 이벤트는 production analytics·로깅 인프라 연동을 포함하지 않습니다. 단위 테스트가
  `TestStore`로 Action을 보낸 뒤 State에 기록된 이벤트 목록을 조회해 전환 순서와
  전후 화면을 검증하는 용도로 한정합니다.
- 활성 화면과 이동 이벤트 목록은 View에서 읽기 전용으로만 사용하고, 테스트에서는
  모듈 내부 접근으로 직접 검증할 수 있도록 공개 setter를 모듈 밖으로 노출하지 않습니다.

**Router가 상위로 내보내는 delegate**

- Router는 자신을 조합하는 상위(App 또는 다른 Router)에게 하나의 `delegate`로 전환
  의도를 알립니다. Router 내부의 화면 전환 방식(activeScreen enum, 이동 이벤트)은
  상위에 노출하지 않습니다.
- Router보다 긴 생명주기가 필요한 상태는 Router의 State나 화면 Feature의 State에
  두지 않습니다. TCA `@Shared`나 `Binding`으로 공유하지 않고, 정본을 가진 상위 계층(App의 State,
  또는 Domain/Infrastructure 정본)이 소유하고 하위 Feature는 `delegate`로 알리거나
  필요할 때 생성자 주입 UseCase로 정본을 다시 조회합니다. Router가 재생성되어도(예:
  상위가 로그아웃 후 Router State를 새로 만드는 경우) 이 정본은 영향받지 않습니다.
