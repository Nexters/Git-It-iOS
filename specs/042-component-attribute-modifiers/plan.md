# 구현 계획: UI 컴포넌트 초기화 계약 재구성 — 시각 속성 메서드와 표시 값 모델

**Git-flow 유형**: `feature`

**브랜치**: `feature/component-attribute-modifiers` (speckit-specify가 생성, 현재 HEAD에서 재사용 확인)

**날짜**: 2026-09-21 | **명세**: [spec.md](./spec.md)

**입력**: `specs/042-component-attribute-modifiers/spec.md`의 기능 명세

## 요약

UIComponent 공개 컴포넌트의 초기화 계약을 두 방향으로 재구성한다.

**시각 속성**: 초기화 인자에서 빼고, 속성 종류별 공개 계약의 `Self` 반환 메서드로 선언하게 한다.
- 계약은 다섯 개다.
  - `StyleConfigurable.style(_:)`
  - `SizeConfigurable.size(_:)`
  - `TextStyleConfigurable.textStyle(_:)`
  - `ForegroundColorConfigurable.foregroundColorToken(_:)`
  - `BackgroundColorConfigurable.backgroundColorToken(_:)`
- 각 계약은 `View`를 정제한다. 요구사항은 메서드 하나라서 공개 setter 같은 두 번째 선언 경로가
  생기지 않는다.
- 각 컴포넌트는 시각 속성을 기본값을 가진 `private var`로 두고, 메서드를 값 복사로 구현한다.
- 대상은 명세 FR-002의 12개 컴포넌트다. 여기에 실측으로 찾은 `ContinuousProgressBar`(높이 = 크기)를
  더한다. `ActionButton`을 감싸는 Feature 래퍼 `FeedbackActionButton`도 같은 계약을 채택한다.

**표시 값 모델**: 표시 값이 2개 이상인 20개 컴포넌트와 `SelectionCardList.Item`은 표시 값을 중첩
타입 `DisplayModel` 하나로 받는다. 상태·동작 설정·접근성 문구·`Binding`·콜백·자식 View는 개별 인자로
남는다. Feature View가 호출 지점에서 모델을 만들고, State·Reducer는 모델 타입을 모른다.

**상태 `Binding`**(명확화 2026-09-21, FR-017): 컴포넌트가 상호작용으로 스스로 바꾸는 상태는 값 인자와
변경 콜백의 짝 대신 기본값 없는 `Binding` 하나로 받는다. 대상은 컴포넌트 8개와
`ChoiceAnswerOption.ExpansionControl`이다. `SelectionCardList`는 `selection: Binding<String?>`을 받는다.
Feature 화면 View는 `Binding(get:set:)`의 setter로 기존 View Action을 보낸다. 그래서 Action·Reducer·Reducer
테스트는 바뀌지 않는다([research.md](./research.md) §9).

**기본값**: 기본값이 없던 세 속성은 `StyledText` `.body1`, `LabeledCard` `.neutral`,
`HomeProjectCard` `.purple`로 정한다. `StyledText`의 정렬은 SwiftUI `.multilineTextAlignment(_:)`로
옮긴다. `HomeProjectCard.Variant`는 순수 이름 변경으로 `Style`이 된다.

**문서**: 명세 FR-016 문서와 계획 단계에서 찾은 추가 문서 7개를 개정한다. 추가 문서는 추상화 기준선,
형태 어휘, UIComponent 폴더 규칙, `Binding` 보존 규칙 등이다.

**렌더링**: 결과는 바뀌지 않는다. 동일성은 호출부 값 대조와 프리뷰로 판정한다.

실측과 결정의 근거는 [research.md](./research.md), 엔터티는 [data-model.md](./data-model.md), 공개 API는
[contracts/component-init-contracts.md](./contracts/component-init-contracts.md), 검증 절차는
[quickstart.md](./quickstart.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 6 (Tuist 프로젝트 설정 기준), iOS 26.0 이상

**주요 의존성**: SwiftUI, 프로젝트 내부 `DesignSystem`·`UIComponent`(UI 패키지), Feature의 TCA는 호출부
전환에만 관련된다

**저장소**: 해당 없음 — 저장 형식을 바꾸지 않는다

**테스트**: Swift Testing(`UIComponentTests`, `FeatureTests`).
- 계약 단위 테스트를 `sources/Projects/UI/Tests/Component/Unit/Contracts/`에 추가한다.
- 기존 UI 테스트는 호출부만 전환한다.
- 스냅샷 도구가 없으므로 렌더링 동일성은 프리뷰와 diff로 검증한다(명세 가정).

**대상 플랫폼**: iOS Simulator `platform=iOS Simulator,name=iPhone 17 Pro` (빌드 실행기 기본값)

**프로젝트 유형**: 모바일 앱 — Tuist 멀티 패키지 중 UI 공개 API와 Feature 호출부의 동시 전환

**성능 목표**: 해당 없음 — 값 타입 복사 메서드 추가뿐이며 새 성능 목표를 두지 않는다

**제약 조건**:
- 렌더링 결과 불변(FR-013)
- 선언 경로는 하나다(FR-008)
- SwiftUI 수정자와 이름이 충돌하지 않는다(FR-010)
- 패키지 의존 방향은 그대로다
- 생성자 주입을 유지한다
- 컴포넌트 단위로 검증할 수 있어야 한다(FR-014)

**규모/범위**:
- 시각 속성 대상: 컴포넌트 13개와 Feature 래퍼 1개
- 표시 값 모델 대상: 컴포넌트 20개와 중첩 값 타입 1개
- 두 대상에 모두 속하는 컴포넌트는 4개다(`LabeledCard`, `LabeledProgressBar`, `SelectionCard`,
  `HomeProjectCard`).
- 호출부 규모: `StyledText` 170곳을 포함해 대상 컴포넌트 호출부 약 430곳이다. 여기에
  `FeedbackActionButton` 31곳이 더해진다.
- App·Composition 호출부는 0곳이다([research.md](./research.md) §1).
- 상태 `Binding` 대상: 컴포넌트 8개와 중첩 타입 1개. 호출부는 Feature 18곳, UI 17곳, 테스트 14곳이다
  ([research.md](./research.md) §9.1).
- 개정 문서: 명세 FR-016의 10개와 추가 7개, 그리고 상태 `Binding` 규칙 반영(§9.6)

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | UI는 여전히 프로젝트 내부 패키지에 의존하지 않는다. Feature는 UI 공개 API만 쓴다. `DisplayModel`은 UI가 소유하고 Feature는 View에서만 만든다. Feature State·업무 모델을 UI 공개 API에 노출하지 않는다([package-rules/feature.md](../../docs/package-rules/feature.md)) |
| 2. 상태와 데이터 안전성 | 통과 | 컴포넌트는 여전히 표시 상태의 정본을 소유하지 않는다. 시각 속성과 `DisplayModel`은 값 타입이며 `@State`가 아니다. 상태 `Binding`은 Feature Store 정본의 참조이고, setter는 기존 View Action을 거쳐 Reducer가 정본을 바꾼다. `Mirror` 기반 "상태를 보관하지 않는다" 테스트 중 대상 3개는 필터를 `State` 저장소로 바꿔 의도를 유지한다([research.md](./research.md) §9.4) |
| 3. 검증 가능한 변경 | 통과 | 단위마다 `compile`, 테스트를 바꾼 단위는 `test`를 실행한다. SC-007 계약 테스트를 추가하고 SC-001·SC-008은 조회 명령으로 판정한다([quickstart.md](./quickstart.md)). 렌더링 동일성은 자동 도구가 없어 diff 대조와 프리뷰로 검증하며, PR에 미검증 범위로 기록한다 |
| 4·5. 스킬별 수정 경로 | 통과 | 이 계획은 `plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/**`만 작성했다. `docs/**`·`.agents/**` 개정은 `tasks.md`에 파일 단위로 적어 `/speckit-implement`가 수행한다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 작성했다 |
| 7. 위험 기반 실행 단위 | 통과 | UI 공개 초기화 메서드를 바꾸면 Feature 호출부를 함께 바꿔야 compile된다. 그래서 컴포넌트 묶음마다 UI+Feature 불가분 integration unit으로 둔다(아래 "실행 단위"). App은 UIComponent를 import하지 않아 변경 대상이 아니다 |
| 8. Git-flow 브랜치 | 통과 | `feature/component-attribute-modifiers` 하나에서 한 PR로 닫는다 |
| 9. 세션 지식 기록 | 해당 없음 | 기록 조건을 충족하는 사건이 없다 |
| 10. 책임 기반 네이밍 | 통과 | 계약 이름은 능력(`…Configurable`), 메서드는 속성 이름, 모델은 소유 컴포넌트 아래 `DisplayModel`이다. `Variant` → `Style` 이름 변경은 설계 변경과 다른 단위(U4)로 분리한다([research.md](./research.md) §3·§4.3·§5) |
| 11. 컨벤션 근거 | 통과(개정 예정 문서 기록) | 명세 규칙과 충돌하는 컨벤션을 찾았다(추상화 근거, UIComponent 1뎁스 폴더, wrapper 금지, 초기화 인자 규칙). 모두 명세 FR-012·FR-016이 개정을 요구하는 범위다. 개정은 같은 PR의 U10에서 한다. 계획은 컨벤션 문서를 수정하지 않았다. 충돌과 결정은 아래 "적용 컨벤션"과 [research.md](./research.md) §6·§7에 있다 |

**설계 후 재점검(1단계 완료 시점)**: 판정이 바뀐 원칙은 없다. 명확화(FR-017) 반영 뒤 재점검에서도 같다.
- 원칙 2: 상태 `Binding`의 정본은 Feature Store에 남고, 서버 정본 변경은 View Action을 거친다
  ([tca/action/binding.md](../../docs/conventions/tca/action/binding.md)).
- 원칙 7: 상태 `Binding` 대상은 기존 단위(U5~U7)에 합치고, 나머지 4개 컴포넌트는 새 단위 U9로 둔다.
- 원칙 1: `DisplayModel`의 소유자는 UI, 생성 지점은 Feature View로 고정했다. `HomeProjectDisplay`처럼
  State에 담기는 `ViewModels/` 타입은 모델을 보유하지 않는다([data-model.md](./data-model.md) §3).
- 원칙 7: App 호출부 0곳을 실측으로 확인했다. integration unit은 UI+Feature로 한정된다.
- 원칙 11: 계획 단계에서 개정 대상 문서 7개를 추가로 찾았다([research.md](./research.md) §7).

**브랜치 네임스페이스**: 이 헌법 개정 후 생성된 `feature/` 브랜치다. `/speckit-specify`가 현재 HEAD에서
생성했으며 이 계획은 같은 브랜치를 재사용한다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정한다. 이 산출물 밖의 구현 파일은 정확한 경로를 `tasks.md`에
기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: Constitution 원칙 9를 따른다. 조건을 충족하면 전용 스킬을 별도로 사용하며,
계획 산출물이나 구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit, staged formatter 체인은 한 번에
하나만 실행한다. 빌드 실행기의 `build`·`compile`·`test`는 `sources/DerivedData/PreCommit`을
공유하므로 순차 실행한다.

**커밋 단위 구현**: `/speckit-implement`는 아래 "실행 단위"를 커밋 단위로 쓴다. 단위마다 작업
ID, 정확한 파일, 검증과 커밋 메시지를 명시하고, 구현·검증·완료 표시·정확한 staging·commit 확인을
마친 뒤 다음 단위로 간다. 마지막 단위는 전체 검증과 `after_implement` 포맷 훅까지 실행한 뒤
commit한다.

**컨벤션 근거**: 아래 "적용 컨벤션"에 기록했다.

**책임 기반 네이밍**: 위 원칙 10 행과 [research.md](./research.md) §3·§5를 따른다.

**실행 단위 진행**: 아래 "실행 단위"를 따른다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/architecture.md](../../docs/architecture.md) | UI는 프로젝트 내부 패키지에 의존하지 않고 Feature는 Domain·UI에만 의존한다. 표현 API 방향은 `Feature → UIComponent → DesignSystem`이다. 변경 패키지의 위상 순서는 UI → Feature다 |
| [docs/package-rules/ui.md](../../docs/package-rules/ui.md) | UIComponent는 Feature·Domain 타입을 참조하지 않는다. DesignSystem 밖에 공통 시각 어휘를 정의하지 않는다(계약은 DesignSystem 토큰 타입만 받는다). "표시 상태 wrapper 금지" 제약은 명세 명확화에 따라 U10에서 삭제한다 |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | Feature는 State·업무 모델을 UIComponent의 표시 값과 `Binding`으로 연결하고, Feature State·업무 모델을 UI 공개 API에 노출하지 않는다. 그래서 `DisplayModel`은 View 호출 지점에서 만든다. 재사용 UI 컴포넌트를 Feature가 소유하지 않으므로 `FeedbackActionButton`은 계약만 채택하고 새 시각 어휘를 만들지 않는다 |
| [docs/conventions/view.md](../../docs/conventions/view.md) · [view/component-init.md](../../docs/conventions/view/component-init.md) · [view/display-value-binding-callback.md](../../docs/conventions/view/display-value-binding-callback.md) | 공개 생성 경로는 초기화 메서드 하나이며 정적 팩토리를 두지 않는다(039 원칙 유지). 현재 "시각 변형은 초기화 인자" 규칙과 "표시 상태 wrapper 금지"는 이 명세가 개정한다(FR-012·FR-016, U10). Feature 모델 직접 전달 금지(`ProjectRow(project:)`)는 유지한다 |
| [docs/conventions/view-declarations/binding.md](../../docs/conventions/view-declarations/binding.md) · [tca/action/binding.md](../../docs/conventions/tca/action/binding.md) · [tca/navigation/tca-screen.md](../../docs/conventions/tca/navigation/tca-screen.md) | 외부 상태를 `@State`로 복제하지 않고 `Binding`에 `.constant` 기본값을 두지 않는다. 서버 정본을 바꾸는 작업은 binding setter에서 실행하지 않고 명시적 View Action을 거친다. 그래서 Feature setter는 기존 View Action만 보내고 `BindableAction`을 도입하지 않는다. UIComponent 콜백·`Binding` 연결은 화면 View가 맡는다 |
| [docs/conventions/view/access-level.md](../../docs/conventions/view/access-level.md) | 컴포넌트는 `public`이다. 공개 계약에 필요한 비상태 보조 타입(`DisplayModel`, `Style`)만 `public`이고, 저장 프로퍼티는 `private`이다 |
| [docs/conventions/view/preview.md](../../docs/conventions/view/preview.md) | 컴포넌트 프리뷰는 파일 하단 `#Preview`에서 모든 시각 변형을 나열한다. 전환 후 프리뷰도 메서드로 같은 변형을 모두 나열해야 한다 |
| [docs/conventions/view-declarations.md](../../docs/conventions/view-declarations.md) · [view-declarations/internal-declarations.md](../../docs/conventions/view-declarations/internal-declarations.md) · [view-declarations/style.md](../../docs/conventions/view-declarations/style.md) · [view-declarations/ownership.md](../../docs/conventions/view-declarations/ownership.md) | View 소유 선언은 소유 View 이름 아래 같은 파일에 두고 이름에 View 이름을 반복하지 않는다(`HomeProjectCard.DisplayModel`). 변형별 표현 값은 `Style`이 소유한다(FR-013). `Style`을 초기화 인자로 받는다는 서술과 "표시 값은 별도 타입으로 감싸지 않는다" 서술은 U10에서 개정한다 |
| [docs/conventions/ui-component.md](../../docs/conventions/ui-component.md) · [ui-component/folder-file.md](../../docs/conventions/ui-component/folder-file.md) · [ui-component/public-contract.md](../../docs/conventions/ui-component/public-contract.md) · [ui-component/verification.md](../../docs/conventions/ui-component/verification.md) | 1뎁스는 역할 폴더와 `Resources/`뿐이라서 `Contracts/` 도입 시 같은 PR에서 갱신한다(U10). 공개 입력과 상태별 표현을 단위 테스트로 검증한다(SC-007 계약 테스트) |
| [docs/conventions/abstraction.md](../../docs/conventions/abstraction.md) · [abstraction/protocol-criteria.md](../../docs/conventions/abstraction/protocol-criteria.md) · [abstraction/structure-baseline.md](../../docs/conventions/abstraction/structure-baseline.md) | 프로토콜은 근거 A·B가 있을 때만 둔다. 시각 속성 계약은 어느 쪽에도 해당하지 않는다. 명세 FR-004가 요구하므로 U10에서 적용 제외 범주를 추가하고 기준선 수치·목록을 갱신한다([research.md](./research.md) §6) |
| [docs/conventions/file-vocabulary.md](../../docs/conventions/file-vocabulary.md) · [file-vocabulary/one-type-per-file.md](../../docs/conventions/file-vocabulary/one-type-per-file.md) · [file-vocabulary/shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md) · [directory-file/shape-rules.md](../../docs/conventions/directory-file/shape-rules.md) | 파일 하나에 최상위 타입 하나이며, 계약은 파일 하나씩 둔다. 중첩 `DisplayModel`은 최상위 개수에 들지 않는다. 형태 어휘 표에 `UI/Component/`의 `Contracts/` 행을 같은 PR에서 추가한다 |
| [docs/conventions/naming.md](../../docs/conventions/naming.md) (protocol-contract, public-type, rename) | 프로토콜 이름은 제공 능력을 표현한다. 표면 통일용 접두어·접미어를 쓰지 않는다. 이름 변경(`Variant` → `Style`)은 설계 변경과 분리한다 |
| [docs/conventions/test.md](../../docs/conventions/test.md) · [test/swift-testing.md](../../docs/conventions/test/swift-testing.md) · [test/korean-behavior-sentence.md](../../docs/conventions/test/korean-behavior-sentence.md) · [test/test-folder-target.md](../../docs/conventions/test/test-folder-target.md) | Swift Testing, 한국어 동작 문장 테스트 이름, 한 테스트에 한 계약을 쓴다. 계약 테스트는 production 형태 폴더를 미러링한 `Tests/Component/Unit/Contracts/`에 둔다 |
| [docs/conventions/view-tokens.md](../../docs/conventions/view-tokens.md) | 색·타이포는 DesignSystem 토큰만 쓴다. 계약 메서드는 `ColorToken`·`TextStyleToken`을 받고 원시 `Color`·`Font`를 받지 않는다 |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/042-component-attribute-modifiers/
├── plan.md              # 이 파일
├── research.md          # 기준선 실측, 계약·이름·기본값·모델·위치 결정, 문서 개정 전수 조회
├── data-model.md        # 계약·시각 속성 값·표시 값 모델 엔터티
├── quickstart.md        # 단위별·최종 검증 절차
├── contracts/
│   └── component-init-contracts.md   # 전환 후 공개 초기화 메서드와 계약 시그니처
└── tasks.md             # /speckit-tasks 산출물(이 명령이 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/UI/Component/
├── Contracts/                          # (신규 형태 폴더) U1
│   ├── StyleConfigurable.swift
│   ├── SizeConfigurable.swift
│   ├── TextStyleConfigurable.swift
│   ├── ForegroundColorConfigurable.swift
│   └── BackgroundColorConfigurable.swift
├── Displays/
│   ├── StyledText.swift                # U1 시각 속성
│   ├── TagBadge.swift                  # U2 시각 속성
│   ├── LabeledCard.swift               # U5 시각 속성 + 모델
│   ├── RubricView/RubricView.swift     # U8 모델
│   └── ScreenHeaderTitle.swift         # U8 모델
├── Controls/
│   ├── ActionButton.swift              # U2
│   ├── IconGlassButton.swift           # U2
│   ├── IconPlainButton.swift           # U3
│   ├── SelectionCardList/SelectionCardList.swift, SelectionCardList+Item.swift   # U5
│   ├── Chip/Chip.swift, SelectableSettingRow/SelectableSettingRow.swift, BookmarkButton.swift   # U9 상태 Binding
│   ├── ChoiceAnswerOption.swift        # U7
│   ├── LabeledTextField/LabeledTextField.swift   # U7
│   ├── PolicyAgreementRow/PolicyAgreementRow.swift   # U7
│   ├── ScreenControlBar/ScreenControlBar.swift   # U7
│   └── TextField.swift                 # U7
├── CollectionItems/
│   ├── SelectionCard/SelectionCard.swift   # U5
│   ├── HomeProjectCard/HomeProjectCard.swift   # U4 이름 변경, U5 시각 속성 + 모델
│   ├── ChoiceResultRow.swift, LearningSetRow.swift   # U6
│   ├── ProjectRow/ProjectRow.swift     # U6
│   └── SavedQuestionCard/SavedQuestionCard.swift   # U6
├── Indicators/
│   ├── ContinuousProgressBar.swift     # U2
│   ├── LabeledProgressBar.swift        # U5
│   ├── EmptyState/EmptyState.swift, PageIndicator.swift, ProgressSegments.swift   # U8
├── Overlays/ConfirmationSheet.swift, WebSheet.swift   # U8
├── Overlays/ModalOverlay.swift         # U9 상태 Binding
└── Scaffolds/ScreenContainer.swift, OverlayContainer.swift   # U3

sources/Projects/UI/Tests/Component/Unit/
├── Contracts/                          # (신규) 계약별 테스트 — U1(텍스트 스타일·전경색), U2(스타일·크기), U3(배경색)
└── <역할>/…Tests.swift                  # 기존 테스트의 호출부 전환(각 컴포넌트 단위)

sources/Projects/Feature/
├── Shared/Views/FeedbackActionButton.swift   # U2 계약 채택
├── Home/ViewModels/HomeProjectDisplay.swift  # U4 이름 변경
├── Tests/Home/Home/ViewModels/HomeProjectDisplayTests.swift   # U4
└── <흐름>/**                            # 각 단위 컴포넌트의 호출부(View·SubViews·Previews)

docs/conventions/…, docs/package-rules/…, .agents/skills/implement-figma-ui/references/component-index.md   # U10
```

Feature 호출부 파일의 정확한 목록은 컴포넌트마다 `/speckit-tasks`가 조회해 `tasks.md`에 적는다.
[research.md](./research.md) §1.2·§1.3이 컴포넌트별 호출부 수를 기준선으로 고정한다.

**구조 결정**:
- 계약은 여러 역할 폴더가 함께 채택하므로 `UI/Component/Contracts/`에 둔다. 기존 형태 어휘
  `Contracts`를 재사용한다.
- 표시 값 모델은 소유 컴포넌트 파일에 중첩한다.
- 폴더 이동과 파일 분할은 하지 않는다.
- 근거와 기각한 대안은 [research.md](./research.md) §5·§6에 있다.

## 실행 단위

**변경 패키지**: UI(`UIComponent`, `UIComponentTests`)와 Feature(`Feature`, `FeatureTests`)다. App과
Composition은 UIComponent를 쓰지 않아 대상이 아니다.

**불가분 근거**: UI 공개 초기화 메서드를 바꾸면 Feature 호출부가 즉시 compile되지 않는다. 그래서 각
단위는 "UI 컴포넌트 전환 + 그 컴포넌트의 UI 내부·프리뷰·테스트 호출부 + Feature 호출부"를 함께 담는
UI+Feature integration unit이다. 두 전환(시각 속성, 표시 값 모델)이 겹치는 컴포넌트는 같은 단위에서
함께 바꿔 호출부를 한 번만 고친다.

**위상 순서**: UI → Feature. 다른 컴포넌트를 안에서 쓰는 컴포넌트는 안쪽 컴포넌트의 단위 뒤에 둔다
([research.md](./research.md) §1.4).

| 순서 | 단위 | 시나리오 | 포함 내용 | 선행 |
| --- | --- | --- | --- | --- |
| U1 | 계약 도입과 `StyledText` | 1·2 | `Contracts/` 계약 5개. `StyledText` 텍스트 스타일·전경색 전환, `alignment` 제거와 `.multilineTextAlignment` 이관. 호출부 170곳 전환. 텍스트 스타일·전경색 계약 테스트 | 없음 |
| U2 | 스타일·크기 컴포넌트 | 1·2 | `ActionButton`, `TagBadge`, `IconGlassButton`, `ContinuousProgressBar` 시각 속성 전환. `FeedbackActionButton` 계약 채택과 Feature 호출부 31곳 전환. 스타일·크기 계약 테스트 | U1 |
| U3 | 색 컴포넌트 | 1·2 | `IconPlainButton`, `ScreenContainer`, `OverlayContainer` 시각 속성 전환. 배경색 계약 테스트 | U1 |
| U4 | `HomeProjectCard.Variant` 이름 변경 | 1 | `Variant` → `Style` 순수 이름 변경(UI 1, Feature 1, 테스트 2 파일) | U1 |
| U5 | 시각 속성 + 표시 값 모델 | 1·4 | `LabeledCard`, `LabeledProgressBar`, `SelectionCard`, `SelectionCardList`(+`Item`), `HomeProjectCard`. 경로별 기본 스타일 보존(research §4.6). `SelectionCardList` `selection: Binding<String?>` 전환(§9) | U2, U4 |
| U6 | 모델: CollectionItems | 4 | `ChoiceResultRow`, `LearningSetRow`, `ProjectRow`, `SavedQuestionCard`. `ChoiceResultRow.isExpanded`·`SavedQuestionCard.isBookmarked` 상태 `Binding` 전환과 `ChoiceResultRowTests` 단언 조정(§9) | U2, U3 |
| U7 | 모델: Controls | 4 | `ChoiceAnswerOption`, `LabeledTextField`, `PolicyAgreementRow`, `ScreenControlBar`, `TextField`. `PolicyAgreementRow.isSelected`·`ExpansionControl.toggleable` 상태 `Binding` 전환(§9) | U2 |
| U8 | 모델: Displays·Indicators·Overlays | 4 | `RubricView`, `ScreenHeaderTitle`, `EmptyState`, `PageIndicator`, `ProgressSegments`, `ConfirmationSheet`, `WebSheet` | U2 |
| U9 | 상태 `Binding`: Controls·Overlays | 4 | `Chip`, `SelectableSettingRow`, `BookmarkButton`, `ModalOverlay` 상태 `Binding` 전환. `SavedQuestionCard`의 내부 `BookmarkButton` 호출, Feature 호출부의 `Binding(get:set:)` 연결, `ChipTests`·`BookmarkButtonTests` 단언 조정 | U6, U8 |
| U10 | 문서 개정과 최종 검증 | 3 | 명세 FR-016 문서와 [research.md](./research.md) §7·§9.6 추가 문서 개정. SC-001~SC-009 조회, 전체 `build`·`compile`·`test`, `after_implement` 포맷 훅 | U1~U9 |

- **순서의 근거**:
  - U1이 계약과 가장 많이 쓰이는 `StyledText`를 먼저 전환한다. 이후 단위의 컴포넌트 본문은 새
    `StyledText` 방식을 그대로 쓴다.
  - `ProjectRow`(U6)는 `TagBadge`·`IconGlassButton`·`IconPlainButton`·`ContinuousProgressBar`를,
    `ConfirmationSheet`·`WebSheet`(U8)는 `ActionButton`·`IconGlassButton`을,
    `ScreenControlBar`(U7)는 `IconGlassButton`을, `SelectionCard`(U5)는 `TagBadge`를 안에서 쓴다.
    그래서 U2·U3 뒤에 둔다.
  - U4는 순수 이름 변경이라 U5의 설계 변경과 분리한다.
  - U6~U8은 서로 파일이 겹치지 않아 순서를 바꿀 수 있다.
  - U9는 확정된 U5~U8 범위를 넓히지 않도록 U8 뒤에 둔다. `SavedQuestionCard.swift`는 U6과 U9에서 한
    번씩 바뀐다([research.md](./research.md) §9.5).
  - U1은 `b4b1a79`로 commit을 마쳤다. 상태 인자를 바꾸지 않았으므로 FR-017의 영향을 받지 않는다.
- **단위 완료 조건**:
  - 단위마다 `compile`을, 테스트를 바꾸거나 추가한 단위는 `test`까지 실행한다.
  - 그 단위 컴포넌트의 [quickstart.md](./quickstart.md) §2 조회가 0줄이다.
  - 호출부 값 대조(§3)와 프리뷰 확인을 마친다.
- **U1 추가 확인**: `.multilineTextAlignment`가 걸린 상위 컨테이너 안에서 정렬을 넘기지 않던
  `StyledText`를 전수 조회한다. 해당하는 곳에는 `.multilineTextAlignment(.leading)`을 명시해 렌더링을
  보존한다([research.md](./research.md) §4.2).
- **범위 주의**:
  - `ActionMenu.Item.role`과 `IconPlainButton`의 수치 인자는 시각 속성 대상이 아니다
    ([research.md](./research.md) §1.2).
  - 시각 속성·표시 값 규칙을 Feature 화면 전용 서브뷰로 넓히지 않는다(명세 가정).
    `FeedbackActionButton`만 감싼 컴포넌트의 계약을 따른다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
| --- | --- | --- |
| 추상화 근거 A·B에 해당하지 않는 공개 프로토콜 5개 추가 | 명세 FR-004·SC-002가 속성 종류별 공통 계약으로 같은 이름·형태의 메서드를 강제하도록 요구한다 | 계약 없이 컴포넌트마다 메서드만 두면 이름과 형태가 컴포넌트마다 달라질 수 있다(명세 시나리오 2). 추상화 컨벤션에 적용 제외 범주를 추가하고 기준선을 갱신한다(U10, [research.md](./research.md) §6) |
| 형태 어휘 표에 없는 `Contracts/`를 `UI/Component/` 1뎁스에 도입 | 여러 역할 폴더가 채택하는 계약의 자리가 컨벤션에 없다 | 역할 폴더 하나에 두면 특정 역할의 소유처럼 보인다. DesignSystem은 토큰과 적용 API만 소유한다. 기존 어휘 `Contracts`를 재사용하고, [shape-rules](../../docs/conventions/directory-file/shape-rules.md)가 요구하는 대로 같은 PR에서 표와 folder-file 규칙을 갱신한다(U10) |
| 표시 값 1~4개인 컴포넌트에도 중첩 `DisplayModel` 추가(인자 수 증가 없이 한 단계 감싸기) | 명세 FR-015와 명확화가 표시 값 2개 이상이면 예외 없이 모델로 받도록 정했다 | 컴포넌트별 판단(짧은 인자는 개별 유지)은 명세가 명확화에서 기각한 선택지다 |
| Feature 래퍼 `FeedbackActionButton`이 UI 계약을 채택 | 안쪽 `ActionButton`의 시각 속성 인자가 사라지면 래퍼가 값을 전달할 경로가 없다 | 래퍼 초기화 인자에 `style`·`size`를 남기면 Feature 호출부 31곳만 이전 방식이 된다. 선언 방식이 둘로 갈려 명세 시나리오 3의 "새 방식 하나"와 어긋난다([research.md](./research.md) §4.4) |
