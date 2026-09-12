# Git It iOS View 컨벤션

**상태**: 초안

**작성일**: 2026-08-17

**최종 수정일**: 2026-09-13 (표본 데이터 규칙 폐기, 토큰 컨벤션과 중복된 시각 어휘 규칙 제거)

## 목적

이 문서는 UI 패키지의 재사용 컴포넌트와 Feature 패키지의 화면이 **공통으로** 지켜야
하는 구현 컨벤션 중 공개 생성 경로, 화면 조립과 프리뷰를 정의합니다. 디자인 토큰
사용 규칙은 [View 토큰 컨벤션](./view-tokens.md), View 내부 선언(`Constant`, `Style`
등)은 [View 내부 선언 컨벤션](./view-declarations.md)이 소유합니다. TCA
상태·Effect·의존성 규칙은 [TCA 컨벤션](./tca/README.md)을 따릅니다.

공개 이름은 [네이밍 컨벤션](./naming.md), 각 패키지의 소유 범위와 제약조건은
[UI 패키지 규칙](../package-rules/ui.md) · [Feature 패키지 규칙](../package-rules/feature.md)을
정본으로 따릅니다. 문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](common/README.md)이 소유합니다.

## 1. 적용 범위

다음 선언에 적용합니다.

- `sources/Projects/UI/Component/**`의 모든 컴포넌트 공개 생성 경로
- `sources/Projects/Feature/**`의 모든 화면 생성 경로, 화면 조립과 프리뷰

다음은 이 문서가 다루지 않습니다.

- 디자인 토큰 사용 규칙 — [View 토큰 컨벤션](./view-tokens.md)
- View 내부 선언(`Constant`, `Style`, 중첩 규칙) — [View 내부 선언 컨벤션](./view-declarations.md)
- 컴포넌트를 **분리할지 말지**의 판단 — [UIComponent 컨벤션](./ui-component/reuse.md)
- 컴포넌트의 **역할 분류 기준** — [UIComponent 컨벤션](./ui-component.md#3-컴포넌트-역할-분류)
- 폴더 뎁스와 파일 분할 — [디렉터리·파일 컨벤션](./directory-file.md)
- 공개 **이름**의 어휘 선택 — [네이밍 컨벤션](./naming.md)
- `// MARK:` 구획, 선언 순서, 들여쓰기 — Swift Style의 `organizeDeclarations`가
  빌드 시 자동 적용하므로 사람이 관리하지 않습니다.

## 2. 표현 계층

표현은 세 계층으로 나뉘며 각 계층은 아래 계층만 사용합니다.

| 계층 | 소유 | 소유하지 않는 것 |
|---|---|---|
| DesignSystem | 디자인 토큰, 토큰 적용 modifier | 컴포넌트, 화면 |
| UIComponent | 화면에서 독립된 역할별 재사용 컴포넌트 | 화면 흐름, Feature 타입 |
| Feature 화면 | 화면 조립, 상태 분기, 화면 흐름 | 재사용 컴포넌트, 시각 어휘 정의 |

### 2.1 검토·디버그 전용 컴포넌트

→ [검토·디버그 전용 컴포넌트](./view/debug-component.md)

## 3. 공개 생성 경로

View의 공개 생성 경로는 그 View가 외부에서 무엇을 받는지 선언하는 계약입니다. 컴포넌트는 표시 값과 상호작용만 받고, 화면은 Store 하나만
받으며, 접근 수준으로 그 경계를 코드에 드러냅니다.

### 3.1 표시 값, Binding과 콜백

→ [표시 값, Binding과 콜백](./view/display-value-binding-callback.md)

### 3.2 컴포넌트의 공개 생성 경로는 두 가지입니다

→ [컴포넌트의 공개 생성 경로는 두 가지입니다](./view/component-init.md)

### 3.3 팩토리를 정의하는 기준

→ [팩토리를 정의하는 기준](./view/factory-criteria.md)

### 3.4 화면의 생성 경로

Feature 화면은 TCA `Store`를 화면 상태의 단일 정본으로 사용하므로 `init(store: StoreOf<Feature>)`를 생성 경로로
둡니다.

→ [화면의 생성 경로](./view/screen-init.md)

### 3.5 접근 수준

→ [접근 수준](./view/access-level.md)

## 4. 화면 조립

화면은 골격 컴포넌트 위에 UIComponent와 화면 전용 서브뷰를 배치해 조립합니다. 화면이 직접 소유하는 것과 상위·하위에 위임하는 것을 구분하는 것이
조립 규칙의 핵심입니다.

### 4.1 화면 골격

→ [화면 골격](./view/screen-skeleton.md)

### 4.2 화면이 소유하는 것과 소유하지 않는 것

→ [화면이 소유하는 것과 소유하지 않는 것](./view/screen-ownership.md)

### 4.3 화면 전용 서브뷰

UIComponent가 지원하지 않는 표현이면서 한 화면에서만 쓰는 렌더링 조각은, 화면 타입에 중첩한 `View` 타입으로 정의해 화면에서 그 책임을
분리합니다.

→ [화면 전용 서브뷰](./view/screen-subview.md)

## 5. 프리뷰

프리뷰는 대상에 따라 정해진 위치와 이름 규칙을 따르고, 화면 프리뷰는 `Previews/`로 분리합니다.

→ [프리뷰](./view/preview.md)

## 6. 검토 체크리스트

### 공개 계약

- [ ] 컴포넌트의 공개 생성 경로가 표시 값·`Binding`·콜백을 직접 받는 초기화 메서드와
      시각 변형 팩토리뿐인가?
- [ ] 표시 상태를 묶는 `ViewModel`, `State` 또는 동등한 wrapper가 없는가?
- [ ] 팩토리 이름이 Feature 업무 역할이 아니라 시각 의미를 표현하는가?
- [ ] 변경 가능한 외부 상태는 `Binding`, 일회성 입력은 콜백으로 구분되는가?
- [ ] UI 컴포넌트 계약과 구현에 TCA `Store`, `Action`, `Effect` 또는 dependency 접근
      타입이 없는가?
- [ ] Feature 화면이 `StoreOf<Feature>`를 초기화 인자로 받고 별도 화면 `ViewModel`을
      만들지 않는가?
- [ ] 화면의 `public` 여부가 App Navigation 생성 여부와 일치하는가?

### 화면 조립과 프리뷰

- [ ] 화면 전용 서브뷰가 화면 타입에 중첩되어 있고, `body`에서 `Self.`으로
      호출되는가?
- [ ] 재사용 가능한 표현을 화면 전용 서브뷰로 남겨 두지 않았는가?
- [ ] 서브뷰 파일의 `import`가 SwiftUI·DesignSystem·UIComponent로 한정되는가?
- [ ] 서브뷰 입력에 `Store`·Feature `State`·Domain 모델이 없는가?
- [ ] 화면이 `preferredColorScheme`을 다시 지정하지 않는가?
- [ ] 검토 전용 UI가 `UIComponentPreviewApp` target에 있는가?
- [ ] 컴포넌트 프리뷰가 모든 시각 변형을 포함하는가?
- [ ] 화면 프리뷰가 그 화면 폴더의 `Previews/` 안 `<화면 타입 이름>Previews.swift`에 있는가?

디자인 토큰과 View 내부 선언의 체크리스트는 각 문서 —
[View 토큰 컨벤션](./view-tokens.md#3-검토-체크리스트),
[View 내부 선언 컨벤션](./view-declarations.md#3-검토-체크리스트) — 이 소유합니다.

## 관련 문서

- [아키텍처](../architecture.md)
- [네이밍 컨벤션](./naming.md)
- [View 토큰 컨벤션](./view-tokens.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [UIComponent 컨벤션](./ui-component.md)
- [TCA 컨벤션](./tca/README.md)
- [UI 패키지 규칙](../package-rules/ui.md)
- [Feature 패키지 규칙](../package-rules/feature.md)

## 문서 변경 기준

공개 생성 경로, 화면 조립 또는 프리뷰 배치 규칙이 바뀔 때 수정합니다. 디자인 토큰
사용 규칙이 바뀌면 이 문서가 아니라 [View 토큰 컨벤션](./view-tokens.md)을, View
내부 선언(`Constant`, `Style`, 중첩 규칙)이 바뀌면
[View 내부 선언 컨벤션](./view-declarations.md)을 갱신합니다. 한 패키지에만 적용되는
규칙은 해당 패키지 규칙 문서에서 관리합니다.
