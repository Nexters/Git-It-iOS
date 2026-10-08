# Git It iOS TCA 컨벤션 — Navigation과 화면 연결

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-09-13 (Router의 정의 단위를 전환 컨텍스트로 확정하고 Router 조합 추가)

## 목적

이 문서는 Feature가 sheet·alert·내부 화면을 소유하는 방식, Feature 바깥으로 이동해야
할 때 delegate로 의도를 알리는 방식, TCA 화면이 Store를 연결하는 경계, 그리고 여러
화면 Feature를 순차적으로 조합하는 Router-Feature 패턴을 정의합니다. Feature 분리
기준은 [Feature 컨벤션](./feature.md), State·Action 설계는
[State 컨벤션](./state.md)·[Action 컨벤션](./action.md), Reducer·Effect 작성 방식은
[Effect 컨벤션](./effect.md)이 소유합니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](../common/README.md)이 소유합니다.

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

Feature는 자신의 수명 안에서 완결되는 화면만 소유하고, 그 바깥으로 나가는 이동은 의도만 출력합니다. 화면은 Store를 단일 정본으로 관찰하며, 여러
화면으로 이어지는 흐름은 전환을 전담하는 Router가 조합합니다.

### 2.1 Navigation 경계

현재 Feature 수명 안에서 완결되는 sheet·alert·내부 화면만 Destination 또는 Child State로 소유합니다.

→ [Navigation 경계](./navigation/boundary.md)

### 2.2 TCA 화면

화면은 `@ViewAction`으로 Store를 관찰하고 View Action만 보내며, UIComponent 콜백을 View Action으로 해석합니다.

→ [TCA 화면과 Store 연결](./navigation/tca-screen.md)

### 2.3 Router-Feature와 화면 전환 소유

화면 전환이 있는 흐름은 그 전환을 전담하는 Router-Feature를 둡니다.

→ [Router-Feature와 화면 전환 소유](./navigation/router.md)

## 3. 검토 체크리스트

- [ ] 화면이 Store를 단일 정본으로 사용하고 View Action만 보내는가?
- [ ] UIComponent에 TCA, Feature 또는 Domain 업무 타입이 노출되지 않는가?
- [ ] Feature가 다른 최상위 Feature를 직접 생성하거나 App Navigation 방식을 명령하지
      않는가?
- [ ] 전환 컨텍스트(순차 흐름 스택·탭 셸) 하나마다 Router가 하나인가?
      한 Router가 두 전환 컨텍스트를 쥐거나, 스택 없이 push를 대신 구현하지 않는가?
- [ ] Router의 `State`에 전환 상태만 있고, 진입 준비·결과 판단·공용 오류 표시는 별개
      Feature로 조합되어 있는가?
- [ ] Router의 State가 조합하는 화면 Feature의 State를 항상 함께 보유하는가?
- [ ] 활성 화면 값에 "완료" 같은 상위 이탈 의미의 case가 없는가? 이탈 조건이 한
      `delegate`로 드러나지 않는다면 조건부 Feature로 분리되어 있는가?
- [ ] 순차 흐름의 화면 전환이 활성 화면 값에서 파생한 순차 흐름 스택 경로로
      표현되고, `StackState`나 쓰기 가능한 경로 `Binding`을 쓰지 않았는가?
- [ ] 뒤로가기가 활성 화면 값을 되돌리는 상태 전이이고, 화면 Feature의 State를 새로
      만들지 않는가?
- [ ] 화면 Feature가 자신의 다음·이전 화면을 알지 않고 `delegate`로만 의도를 알리는가?
- [ ] 형제 Router를 `Scope`로 조합하거나 그 State를 생성하지 않고, 다른 흐름으로의
      이탈을 `delegate`로 상위에 위임하는가?
- [ ] 순차 흐름의 화면 이동 이벤트가 State에 기록되고 테스트가 직접 조회할 수 있는가?
      (셸 흐름은 기록하지 않습니다.)
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
