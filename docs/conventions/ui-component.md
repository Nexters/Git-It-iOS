# Git It iOS UIComponent 컨벤션

**상태**: 초안

**작성일**: 2026-08-21

**최종 수정일**: 2026-08-31 (문서 간 중복 제거와 소유 문서 정리)

## 목적

이 문서는 `UIComponent`의 재사용 가능한 표현 계약을 정의하고 컴포넌트의 역할 분류, 공개
입력, 선언·자산 구성과 검증 방식을 통일합니다. UI 패키지의 책임과 의존 방향은
[UI 패키지 규칙](../package-rules/ui.md)이, 폴더 뎁스와 파일 분할의 공통 규칙은
[디렉터리·파일 컨벤션](./directory-file.md)이 소유하고, 컴포넌트 구현 방식과 역할
폴더의 목록은 이 문서가 소유합니다. 상위 문서와의 우선순위는
[컨벤션 공통 규칙](./README.md#상위-문서와-충돌-해소)을 따릅니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/` 아래의 모든 컴포넌트와 역할 폴더
- `sources/Projects/UI/Component/Resources/`의 이미지·애니메이션·일러스트레이션 자산
- `UIComponentPreviewApp`과 UI 자동화 target의 컴포넌트 레이아웃 검증

DesignSystem 토큰의 정의, Feature 화면 상태와 화면 흐름은 이 문서의 범위가 아닙니다.

## 2. 공개 계약

- 컴포넌트는 화면과 Feature 구현에서 독립적으로 해석 가능한 표현 계약이어야 합니다.
- 표시 값·`Binding`·콜백으로 입력을 나누는 방식과 표시 상태 wrapper 금지는
  [View 컨벤션 §3](./view.md#3-공개-생성-경로)이 소유합니다.
- Feature의 `State`, `Action`, 업무 모델과 TCA의 `Store`, `Reducer`, `Effect`를 공개
  API**와 구현 모두**에 사용하지 않습니다.
- 외부 라이브러리가 필요하면 구현에 필요한 범위로 격리하고 외부 타입을 Feature에
  공개하지 않습니다.
- 컴포넌트의 공개 이름은 [네이밍 컨벤션](./naming.md)을 따르며 시각 의미와 재사용
  책임을 드러냅니다.

## 3. 컴포넌트 역할 분류

### 3.1 분류 축은 역할입니다

컴포넌트는 **화면에서 맡는 역할**로 분류하고, 역할 이름의 폴더에 둡니다. 역할은
컴포넌트의 **공개 계약**으로 판정합니다. 구현이 다른 컴포넌트를 렌더링하는지, 파일이
몇 개인지, 어느 화면에서 처음 만들어졌는지는 판정 근거가 아닙니다.

이전 `Leaf`·`Composite` 분류는 "렌더링 트리에 프로젝트가 소유한 다른 View를 포함하는가"
라는 구현 의존 구조를 기준으로 했고, 다음 문제가 있었습니다.

- 내부 구현을 바꾸면 공개 계약이 그대로인데도 분류가 바뀝니다.
- 호출부는 컴포넌트가 말단인지 조합인지 알 필요가 없어 분류가 사용에 도움을 주지
  않습니다.
- 분류를 유지하려고 구현이 왜곡됩니다. 말단 자격을 잃지 않으려고 `StyledText` 대신
  `Text.designSystemStyled(_:style:)`를 쓰는 규칙이 그 예입니다.
- 실제로 24개 중 대부분이 `Composite`에 몰려 분류가 정보를 주지 못했습니다.

### 3.2 판정 순서

위에서부터 순서대로 확인하고 **처음 만족하는 역할**을 사용합니다. 순서가 곧 우선순위
이므로 두 역할에 모두 해당하는 컴포넌트도 하나의 폴더로 결정됩니다.

| 순서 | 폴더 | 판정 질문 |
| --- | --- | --- |
| 1 | `Scaffolds/` | 화면 전체 또는 화면의 고정 영역을 정의하고 그 안에 임의의 콘텐츠를 담는가? |
| 2 | `Overlays/` | 기존 화면 위에 겹쳐 떠서 표시되거나 화면 콘텐츠를 덮는가? |
| 3 | `Controls/` | 표시하는 정보를 모두 제거해도 조작 단위로 남는가? |
| 4 | `CollectionItems/` | 목록·그리드에서 하나의 항목으로 반복 배치되는가? |
| 5 | `Indicators/` | 진행·완료·부재처럼 시간에 따라 변하는 상태를 알리는가? |
| 6 | `Displays/` | 위에 해당하지 않는 읽기 전용 표시인가? |

`Controls/`의 판정 질문은 "표시 값을 모두 지웠을 때 무엇이 남는가"로 읽습니다.
`AccountActionRow`는 title을 지우면 동작을 실행하는 행이 남으므로 `Controls/`이고,
`SettingRow`는 title과 value를 지우면 남는 것이 없으므로 `CollectionItems/`입니다.
같은 목록에 놓이는 두 행이 서로 다른 폴더에 있는 이유는 **정보 표시가 계약의
중심인지, 조작이 계약의 중심인지**가 다르기 때문입니다.

컬렉션 전체를 그리면서 선택을 소유하는 컴포넌트는 항목이 아니라 조작 단위이므로
`Controls/`에 둡니다(`SelectionCardList`).

**UIComponent에는 제품 컴포넌트만 둡니다.** 레이아웃 카탈로그나 TestFlight 검토
제어처럼 제품 화면에서 쓰지 않는 UI는 역할 폴더를 갖지 않고 `UIComponentPreviewApp`
target이 소유합니다.

### 3.3 역할별 소유 범위

| 폴더 | 소유하는 책임 | 소유하지 않는 것 |
| --- | --- | --- |
| `Scaffolds/` | 화면 배경·안전 영역·상하단 고정 영역·탭 구조 | 담기는 콘텐츠의 의미 |
| `Overlays/` | 겹쳐 뜨는 표면의 배치·표시 전환·닫기 신호 | 표면 안에 놓이는 화면 흐름 |
| `Controls/` | 사용자 입력 수집과 조작 결과 전달 | 입력값의 업무적 해석 |
| `CollectionItems/` | 한 항목의 요약 표시와 항목 단위 동작 | 목록의 정렬·페이지네이션 |
| `Indicators/` | 진행·완료·부재 상태의 시각 표현 | 상태를 만들어 내는 로직 |
| `Displays/` | 텍스트·이미지·본문의 토큰 기반 렌더링 | 표시할 값의 결정 |

검토 전용 UI의 표현 예외는 [View 컨벤션 §2.1](./view.md#21-검토디버그-전용-컴포넌트)이
소유하며, 그 UI는 `UIComponentPreviewApp` target에 둡니다.

### 3.4 현재 컴포넌트 배치

이 표가 배치의 정본입니다. 컴포넌트를 추가하거나 역할을 바꾸면 같은 PR에서 갱신합니다.

| 폴더 | 컴포넌트 |
| --- | --- |
| `Scaffolds/` | `BottomActionBar`, `ScreenContainer`, `ScreenHeader`, `TabShell` |
| `Overlays/` | `ActionMenu`, `ModalOverlay`, `ScreenEdgeScrim`, `SheetSurface`, `WebSheet` |
| `Controls/` | `AccountActionRow`, `ActionButton`, `AppleSignInButton`, `BookmarkButton`, `Chip`, `ChoiceAnswerOption`, `IconGlassButton`, `IconPlainButton`, `LabeledTextField`, `PolicyAgreementRow`, `PressOverlayStyle`, `SelectableSettingRow`, `SelectionCardList`, `TextField` |
| `CollectionItems/` | `ChoiceResultRow`, `HomeProjectCard`, `LearningSetRow`, `ProjectRow`, `SavedQuestionCard`, `SelectionCard`, `SettingRow` |
| `Indicators/` | `ContinuousProgressBar`, `EmptyState`, `LabeledProgressBar`, `PageIndicator`, `ProgressSegments` |
| `Displays/` | `LaunchLogo`, `OnboardingMockup`, `ResourceAnimation`, `ResourceImage`, `RubricView`, `SplashView`, `StyledText`, `TagBadge`, `WebContentView` |

### 3.5 재분류 기준

**폴더는 공개 계약이 바뀔 때만 옮깁니다.** 내부 구현에서 다른 컴포넌트를 쓰기
시작하거나 파일을 나누는 변경으로는 폴더가 바뀌지 않습니다.

계약 변경으로 역할이 바뀌면 이동을 rename과 함께 하나의 변경으로 처리하지 않고,
[네이밍 컨벤션 §8](./naming.md#8-rename과-설계동작-변경-분리)에 따라 계약 변경과 이동을
구분해 기록합니다.

## 4. 재사용 판단

재사용 가능성은 사용처의 수나 외형의 유사성이 아니라 공개 입력의 의미적 통일성으로
판단합니다. 다음 질문에 모두 같은 답을 할 수 있을 때 하나의 컴포넌트를 재사용합니다.

1. 각 초기화 인자와 `Binding`은 같은 사용자 인지 역할을 표현하는가?
2. 같은 상태 값은 모든 사용처에서 같은 상태와 표현 규칙을 의미하는가?
3. nil, 빈 값과 범위 밖 값 같은 경계값을 같은 방식으로 해석하는가?
4. 특정 Feature 모델을 다른 의미로 치환하거나 범용 이름 뒤에 숨기지 않는가?

현재 사용처가 하나라는 사실만으로 재사용 가능성을 인정하거나 부정하지 않습니다.
화면 문맥이 달라도 입력과 상태 의미가 같으면 같은 계약을 사용할 수 있고, 외형이 같아도
의미가 다르면 별도 컴포넌트로 유지합니다.

역할이 다르면 재사용하지 않습니다. 같은 외형이라도 조작이 계약의 중심인 컴포넌트와
정보 표시가 중심인 컴포넌트는 §3.2에 따라 다른 폴더의 다른 컴포넌트입니다.

## 5. 파일·선언·자산 구성

### 5.1 폴더와 파일

- 폴더 뎁스와 타입 패밀리 폴더는
  [디렉터리·파일 컨벤션 §5](./directory-file.md#5-2뎁스--타입-패밀리-폴더)를,
  파일당 타입 개수와 파일 이름 규칙은
  [파일·형태 어휘 컨벤션 §2](./file-vocabulary.md#2-파일-규칙)를 따릅니다.
- `UI/Component/`의 1뎁스는 §3.2의 역할 폴더와 `Resources/`뿐입니다. `Components/`
  같은 target 이름을 반복하는 중간 폴더를 두지 않습니다.
- 컴포넌트 파일과 타입 이름은 표현 대상을 사용하고 `View` 접미어를 붙이지 않습니다.

```text
UI/Component/
└── Scaffolds/
    └── ScreenHeader/
        ├── ScreenHeader.swift
        ├── ScreenHeader+Constant.swift
        ├── ScreenHeader+Control.swift
        └── ScreenHeader+Style.swift
```

### 5.2 중첩 선언

- 어떤 보조 타입을 중첩하는지, `Style`이 무엇을 소유하는지, 중첩할 수 없는 경우를
  어떻게 처리하는지는
  [View 내부 선언 컨벤션 §2](./view-declarations.md#2-view-내부-선언)가 소유합니다.
- 중첩 선언을 파일로 나눌 때의 이름과 위치는
  [파일·형태 어휘 컨벤션 §2.2](./file-vocabulary.md#22-중첩-타입-분리)를 따르고, 나눈
  파일은 소유 컴포넌트의 2뎁스 폴더에 둡니다.

### 5.3 자산

- 이미지, Lottie 애니메이션과 일러스트레이션처럼 컴포넌트가 렌더링하는 자산은
  `Component/Resources/`가 소유합니다.
- Feature는 자산 이름이나 bundle 탐색을 직접 해석하지 않고 UIComponent의 표현 API를
  사용합니다.
- 폰트와 토큰 카탈로그는 `DesignSystem/`이 소유하며 UIComponent 자산과 섞지 않습니다.

## 6. 상태와 생성 경로

컴포넌트의 공개 생성 경로는 표시 값·`Binding`·콜백을 직접 받는 초기화 메서드와 시각
변형별 `public static func` 팩토리 둘뿐입니다. 두 경로의 정의 기준, 외부 상태를
`@Binding`으로 보존하고 `@State`에 복제하지 않는 규칙, 접근 수준과 `Constant`·`Style`의
세부 구현은 [View 컨벤션 §3](./view.md#3-공개-생성-경로)과
[View 내부 선언 컨벤션 §2](./view-declarations.md#2-view-내부-선언)가 소유합니다.

컴포넌트는 그 위에 UI 패키지 고유의 제약을 하나 더 지킵니다. **표시 상태를 소유하지
않습니다** — 컴포넌트는 전달받은 값을 렌더링할 뿐이고, 그 값의 정본은 언제나 호출부인
Feature 화면의 `State`입니다.

## 7. 분리 절차

1. 화면과 사용처에서 독립적으로 이름 붙일 수 있는 표현 책임을 찾습니다.
2. 후보들의 외형이 아니라 입력 필드, 상태와 경계값을 비교합니다.
3. 의미가 모두 일치할 때만 하나의 초기화 인자·`Binding`·콜백 계약을 정의합니다.
4. Feature의 State, Action 또는 업무 모델 없이 계약을 정의합니다.
5. 정의한 공개 계약에 §3.2의 판정 질문을 순서대로 적용해 역할 폴더를 정합니다.
6. 보조 타입은 컴포넌트 내부에 중첩하고 표시 상태 wrapper는 추가하지 않습니다.
7. 분리 전후의 표시 상태, 사용자 입력 전달과 접근성 의미가 보존되는지 검증합니다.
8. §3.4의 배치 표에 새 컴포넌트를 추가합니다.

## 8. 검증

- 공개 입력·`Binding`, 상태별 표현과 레이아웃 계약을 단위 테스트 또는
  UI 자동화 테스트로 검증합니다.
- UI production target의 Tuist dependency와 Swift import에
  `ComposableArchitecture`가 없는지 확인합니다.
- 컴포넌트 분리 전후의 표시 상태와 사용자 입력 전달을 확인합니다.
- 테스트 이름, Test Double, 파일과 target 구성은 [테스트 컨벤션](./test.md)을 따릅니다.

## 9. 검토 체크리스트

- [ ] 화면과 Feature 상태에서 독립적으로 설명할 수 있는 표현 계약인가?
- [ ] 읽기 값·변경 값·일회성 입력이 초기화 값·Binding·콜백으로 구분되는가?
- [ ] Feature, Domain 또는 TCA 타입이 공개 API와 구현에 없는가?
- [ ] 외형이 아니라 입력·상태·경계값·접근성 의미로 재사용을 판단했는가?
- [ ] §3.2의 판정 질문을 순서대로 적용해 역할 폴더를 정했는가?
- [ ] 역할 판정 근거가 구현 의존 구조가 아니라 공개 계약인가?
- [ ] §3.4의 배치 표가 실제 폴더와 일치하는가?
- [ ] 폴더 뎁스와 파일 이름이 [디렉터리·파일 컨벤션](./directory-file.md)을 따르는가?
- [ ] 보조 선언이 View에 중첩되고 표시 상태 wrapper가 없는가?
- [ ] 자산과 DesignSystem 토큰의 소유 경계가 분리되는가?
- [ ] 레이아웃과 사용자 입력 전달을 독립적으로 검증했는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [UI 패키지 규칙](../package-rules/ui.md)
- [디렉터리·파일 컨벤션](./directory-file.md)
- [파일·형태 어휘 컨벤션](./file-vocabulary.md)
- [View 컨벤션](./view.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [네이밍 컨벤션](./naming.md)
- [테스트 컨벤션](./test.md)
- [컴포넌트 인덱스](../../.agents/skills/implement-figma-ui/references/component-index.md)

## 문서 변경 기준

UIComponent의 공개 입력 형태, 역할 폴더의 목록과 판정 순서, 컴포넌트 배치 또는 레이아웃
검증 방식이 바뀔 때 수정합니다. 폴더 뎁스와 파일 분할의 공통 규칙이 바뀌면 이 문서보다
[디렉터리·파일 컨벤션](./directory-file.md)을 먼저 갱신합니다. Figma 노드와 코드
컴포넌트의 대응만 바뀌면 이 문서가 아니라
[컴포넌트 인덱스](../../.agents/skills/implement-figma-ui/references/component-index.md)를
수정합니다.
