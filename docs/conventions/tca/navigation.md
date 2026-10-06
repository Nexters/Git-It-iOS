# Git It iOS TCA 컨벤션 — Navigation과 화면 연결

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([TCA 컨벤션](./README.md)에서 분리)

## 목적

이 문서는 Feature가 sheet·alert·내부 화면을 소유하는 방식, Feature 바깥으로 이동해야
할 때 delegate로 의도를 알리는 방식, TCA 화면이 Store를 연결하는 경계, 그리고 여러
화면 Feature를 순차적으로 조합하는 Router-Feature 패턴을 정의합니다. Feature 분리
기준은 [Feature 컨벤션](./feature.md), State·Action 설계는
[State 컨벤션](./state.md)·[Action 컨벤션](./action.md), Reducer·Effect 작성 방식은
[Effect 컨벤션](./effect.md)이 소유합니다.

상위 문서와의 우선순위는
[컨벤션 공통 규칙](../README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Navigation 출력, Destination·Router-Feature 구성과
  화면-Store 연결에 적용합니다.
- App이 Feature의 Reducer와 화면을 생성하거나 delegate·navigation intent를 해석할 때
  공개 계약 부분에 적용합니다.
- Feature 분리 기준, `State`·`Action` 설계와 Reducer·Effect 작성 방식은
  [Feature](./feature.md)·[State](./state.md)·[Action](./action.md)·
  [Effect](./effect.md) 컨벤션이 적용 범위를 소유합니다.
- 앱 전체 Navigation 정책은 이 문서의 범위가 아닙니다.

## 2. Navigation과 화면 연결

### 2.1 Navigation 경계

- 현재 Feature 수명 안에서 완결되는 sheet, alert와 내부 화면은 Destination 또는 Child
  State로 소유할 수 있습니다.
- Feature 바깥으로 이동해야 하면 현재 Feature는 delegate 또는 navigation intent를
  출력하고 App이 목적지와 전환 방식을 결정합니다.
- Feature는 다른 최상위 Feature를 직접 생성하거나 push, present와 같은 App Navigation
  방식을 명령하지 않습니다.

### 2.2 TCA 화면

- 화면은 `@ViewAction`을 적용해 Store를 관찰하고, View가 `View` Action만 보낼 수 있는
  경계를 코드로 드러냅니다([Action 컨벤션 §2](./action.md#2-출처-분류)).
- UIComponent에 `Store`, `Action`, Feature `State`나 Domain 업무 모델을 전달하지
  않습니다. UIComponent 콜백은 View Action으로 해석합니다.
- Store와 같은 상태를 복제하는 화면 ViewModel을 정의하지 않습니다. 화면 상태의 정본은
  Reducer의 `State`입니다.

화면의 생성 경로(`init(store:)`), Store 상태를 컴포넌트 표시 값·`Binding`으로 연결하는
형태와 화면 조립은 [View 컨벤션 §3.4](../view.md#34-화면의-생성-경로)·
[§4](../view.md#4-화면-조립)가, UIComponent 입력 경계는
[UIComponent 컨벤션 §2](../ui-component.md#2-공개-계약)가 소유합니다.

### 2.3 Router-Feature와 화면 이동 추적

여러 화면 Feature를 순차적인 여정으로 조합해야 하고 그 조합 자체가 이동 추적처럼
독립적으로 검증할 가치가 있는 책임이면, 조합을 전담하는 별도의 Router-Feature를 둘 수
있습니다. Router-Feature는 화면 Feature가 아니라 화면 Feature들의 조합과 전환만
책임지는 상위 Feature입니다.

**구성**

- Router의 `State`는 조합하는 각 화면 Feature의 State를 **항상 함께 보유**합니다. 현재
  어떤 화면이 활성 상태인지는 별도의 연관값 enum(예: `ActiveScreen`)으로 표현하며, 이
  값은 최상위 화면 Feature 단위를 case로 갖고 그 내부에 세부 화면이 있으면(예: 하나의
  화면 Feature가 여러 단계를 가짐) 그 세부 화면을 연관값으로 함께 포함하는 계층형
  값입니다.
- 이 활성 화면 값에는 "완료"처럼 상위로 나가야 함을 뜻하는 case를 두지 않습니다. 상위로
  나가야 하는 조건(예: 마지막 화면의 제출 성공)을 관찰해 "Router가 전환해야 하는가"만
  판단하는 별도의 얇은 조건부 Feature를 두고, 그 판단 결과를 `delegate`로 Router에
  알립니다. 이 조건부 Feature는 "완료 여부"가 아니라 "Router 전환 여부"를 판단하는
  책임만 가집니다.
- Router의 `body`는 조합하는 모든 화면 Feature와 조건부 Feature를 `Scope`로 구성하고,
  뒤이어 Router 자신의 `Reduce`에서 화면 Feature의 `delegate`를 해석해 활성 화면을
  전환하거나 조건부 Feature로 조정 신호를 전달합니다.
- 활성 화면이 현재 Feature 수명 안에서 완결되는 sheet·alert가 아니라 순차적으로 이어지는
  여정이면 `@Presents`/`Destination` 대신 이 방식(항상 존재하는 Child + 활성 enum)을
  사용합니다. `@Presents`의 존재/부재 의미론은 이런 순차 여정에 적합하지 않습니다.

**화면 이동 이벤트**

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
  두지 않습니다. [State 컨벤션 §2](./state.md#2-정본과-파생값)·
  [Effect 컨벤션 §2.2](./effect.md#22-의존성-주입)가 금지하는 TCA
  `@Shared`, `Binding`, `inout` 기반 공유 대신, 정본을 가진 상위 계층(App의 State,
  또는 Domain/Infrastructure 정본)이 소유하고 하위 Feature는 `delegate`로 알리거나
  필요할 때 생성자 주입 UseCase로 정본을 다시 조회합니다. Router가 재생성되어도(예:
  상위가 로그아웃 후 Router State를 새로 만드는 경우) 이 정본은 영향받지 않습니다.

## 3. 검토 체크리스트

- [ ] 화면이 Store를 단일 정본으로 사용하고 View Action만 보내는가?
- [ ] UIComponent에 TCA, Feature 또는 Domain 업무 타입이 노출되지 않는가?
- [ ] Feature가 다른 최상위 Feature를 직접 생성하거나 App Navigation 방식을 명령하지
      않는가?
- [ ] Router의 State가 조합하는 화면 Feature의 State를 항상 함께 보유하는가?
- [ ] 활성 화면 값에 "완료" 같은 상위 이탈 의미의 case가 없고, 이탈 판단이 별도의
      조건부 Feature로 분리되어 있는가?
- [ ] 화면 이동 이벤트가 State에 기록되고 테스트가 직접 조회할 수 있는가?
- [ ] Router보다 긴 생명주기가 필요한 상태가 Router나 화면 Feature의 State가 아니라
      상위 정본에 있는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [Feature 컨벤션](./feature.md)
- [State 컨벤션](./state.md)
- [Action 컨벤션](./action.md)
- [Effect 컨벤션](./effect.md)
- [View 컨벤션](../view.md)
- [UIComponent 컨벤션](../ui-component.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)
- [App 패키지 규칙](../../package-rules/app.md)

## 문서 변경 기준

Navigation 출력 방식, Destination·Router-Feature 구성 또는 화면과 Store의 연결 규칙이
바뀔 때 수정합니다. Feature 분리 기준이 바뀌면 [Feature 컨벤션](./feature.md)을,
State·Action 구성이 바뀌면 [State 컨벤션](./state.md)·[Action 컨벤션](./action.md)을,
Reducer·Effect 작성 방식이 바뀌면 [Effect 컨벤션](./effect.md)을 갱신합니다.
