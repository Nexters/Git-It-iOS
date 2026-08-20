# Git It iOS TCA 컨벤션

**상태**: 초안

**작성일**: 2026-08-21

**최종 수정일**: 2026-08-21

## 목적

이 문서는 Feature가 TCA(The Composable Architecture)로 사용자 기능의 상태와 상호작용을
구현하는 공통 방식을 정의합니다. Feature 패키지의 책임과 허용 의존성은
[Feature 패키지 규칙](../package-rules/feature.md)이 소유하고, `State`, `Action`,
`Reducer`, Effect와 화면 연결의 구체적인 구현 방식은 이 문서가 소유합니다.

## 1. 적용 범위

- `sources/Projects/Feature/Presentation/**`의 TCA Feature와 화면에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트에 적용합니다.
- App이 Feature의 Reducer와 화면을 생성하거나 delegate·navigation intent를 해석할 때
  공개 계약 부분에 적용합니다.
- Domain 규칙, production 구현 선택과 앱 전체 Navigation 정책은 이 문서의 범위가
  아닙니다.

## 2. Feature 구성

- 하나의 사용자 기능은 `@Reducer`가 붙은 Feature 타입 하나를 중심으로 구성합니다.
- `State`, `Action`, 화면 전환에 필요한 목적지 상태와 cancellation ID는 해당 Feature
  타입이 소유합니다.
- 한 사용자 기능의 Reducer와 화면은 `Presentation/Screens/<기능>/`에 함께 둡니다.
- 여러 화면이 공유하는 View가 아닌 Presentation 보조 타입만
  `Presentation/Shared/`에 둘 수 있습니다.
- Feature의 공개 표면은 App이 생성하는 Reducer와 화면, App이 해석할 delegate 또는
  navigation intent로 제한합니다.

## 3. State와 Action

### 3.1 State

- `State`는 사용자가 인지하는 Presentation 상태와 화면 흐름에 필요한 값만 소유합니다.
- 화면에 필요한 Domain 모델은 보존할 수 있지만 Domain 규칙이나 Data DTO를 복제하지
  않습니다.
- 같은 값을 화면 `ViewModel`, `@State` 또는 별도 참조 타입에 복제하지 않습니다.
- 실패는 사용자가 관찰할 수 있는 상태 또는 재시도 경로로 표현합니다.

### 3.2 Action

- `Action`은 사용자 입력, 시스템 수명 주기, Effect 응답과 외부 흐름 출력을 구분합니다.
- 사용자가 직접 발생시킬 수 없는 응답 Action은 입력 출처가 드러나는 이름을 사용합니다.
- App이 해석해야 하는 출력은 `delegate` 또는 navigation intent로 명시합니다.
- View의 이벤트 클로저에서 상태 변경 정책을 구현하지 않고 사용자 의도를 Action으로
  전달합니다.

## 4. Reducer와 Effect

- Reducer는 주입받은 Domain contract를 호출하고 결과를 Action으로 되돌려 State를
  갱신합니다.
- 화면 상태를 바꾸는 판단과 사용자 의도 해석은 Reducer가 소유합니다.
- Effect에 필요한 Domain dependency는 Reducer의 초기화 메서드 또는 명시적인 초기화
  인자로 주입합니다.
- production dependency는 Reducer의 저장 프로퍼티로 보존합니다.
- TCA Dependencies의 `@Dependency`, Service Locator 또는 전역 mutable container를
  production dependency 전달 수단으로 사용하지 않습니다.
- 동시에 실행되면 안 되는 Effect나 화면 이탈 뒤 종료해야 하는 Effect에는 안정적인
  cancellation ID와 취소 경로를 둡니다.
- 오류를 무시하거나 View가 Domain 오류를 직접 해석하게 하지 않습니다.

## 5. 화면과 UIComponent 연결

- TCA 화면은 `StoreOf<Feature>`를 초기화 인자로 받고 화면 상태의 단일 정본으로
  사용합니다.
- 화면은 Store를 관찰해 렌더링하고 사용자 이벤트를 Action으로 보냅니다.
- UIComponent가 요구하는 읽기 전용 값은 Store에서 파생해 전달하고, 변경 가능한 값은
  SwiftUI `Binding`으로 연결합니다.
- 컴포넌트 콜백에서 사용자 의도를 Feature Action으로 보내며 UIComponent에 Store,
  Action 또는 Feature 타입을 전달하지 않습니다.
- 화면은 상태 분기, 화면 목적지 생성과 컴포넌트 조립을 소유합니다.
- 화면 전용 렌더링 조각은 private 연산 프로퍼티나 메서드로 유지합니다. 독립된 표현
  계약이 생기면 UI 패키지로 옮기고 화면 파일 안에 별도 `View` 타입을 만들지 않습니다.
- 화면은 DesignSystem의 시각 어휘와 UIComponent의 공개 생성 경로를 사용하며 토큰,
  공통 컴포넌트 또는 이미지 자산을 중복 정의하지 않습니다.

구체적인 View 생성 경로와 내부 선언은 [View 컨벤션](./view.md)을, UIComponent 입력
경계는 [UIComponent 컨벤션](./ui-component.md)을 따릅니다.

## 6. 테스트

- Domain dependency는 initializer로 Test Double을 주입합니다.
- 사용자 입력은 `store.send`, Effect 응답과 delegate 출력은 `store.receive`로
  검증합니다.
- 상태 변화는 관련 Action을 처리하는 단계에서 명시합니다.
- 동시에 실행되면 안 되는 Effect의 취소와 화면 이탈 시 정리를 검증합니다.
- 미완료 Effect는 테스트 종료 전에 취소하고 `finish()`로 정리합니다.
- 테스트는 `Tests/<기능>/` 아래에서 State, Effect, 사용자 상호작용과 delegate 출력을
  중심으로 구성합니다.

테스트 이름, 비동기 종료, Test Double과 target 구성의 공통 규칙은
[테스트 컨벤션](./test.md)을 따릅니다.

## 7. 제약조건

- Data DTO나 Data API를 참조하지 않습니다.
- Infrastructure의 기술 API를 참조하지 않습니다.
- Composition에서 dependency를 조회하지 않습니다.
- Repository 또는 production 구현체를 Feature 내부에서 생성하지 않습니다.
- Domain의 비즈니스 규칙을 Reducer에 다시 구현하지 않습니다.
- Feature State, Action 또는 업무 모델을 UIComponent 공개 API에 노출하지 않습니다.
- TCA Store와 같은 상태를 복제하는 화면 ViewModel을 정의하지 않습니다.
- 다른 Feature의 목적지 생성과 애플리케이션 전체 Navigation 정책을 소유하지 않습니다.

## 8. 검토 체크리스트

- [ ] 사용자 기능 하나가 하나의 Feature 타입을 중심으로 구성되는가?
- [ ] State가 Presentation 상태만 소유하고 Domain 규칙이나 DTO를 복제하지 않는가?
- [ ] Action이 사용자 입력, Effect 응답과 외부 출력을 구분하는가?
- [ ] dependency가 Reducer 초기화 인자로 주입되고 저장 프로퍼티로 보존되는가?
- [ ] Effect의 오류·취소·완료 경로가 명시적인가?
- [ ] 화면이 Store를 단일 정본으로 사용하고 별도 ViewModel을 만들지 않는가?
- [ ] UIComponent에 TCA 또는 Feature 타입이 노출되지 않는가?
- [ ] TestStore가 send·receive·상태 변화·Effect 종료를 검증하는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [Feature 패키지 규칙](../package-rules/feature.md)
- [View 컨벤션](./view.md)
- [UIComponent 컨벤션](./ui-component.md)
- [테스트 컨벤션](./test.md)

## 문서 변경 기준

TCA 버전 변경, Feature의 상태·Action·Effect 구성 방식, dependency 주입 방식 또는 화면과
Store의 연결 규칙이 바뀔 때 수정합니다. Feature 패키지의 책임이나 의존 방향이 바뀌면
이 문서보다 아키텍처와 Feature 패키지 규칙을 먼저 갱신합니다.
