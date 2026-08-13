# Tasks: 디자인 토큰 시스템

**Input**: Design documents from `/specs/002-design-token-system/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/design-token-api.md](./contracts/design-token-api.md), [quickstart.md](./quickstart.md)

**테스트**: 사용자 스토리 3("토큰 정의를 화면 없이 검증한다")이 곧 시뮬레이터·렌더링 없는
검증 능력 자체를 요구하므로, 이 스토리의 테스트 작성은 선택 사항이 아니라 구현
작업이다. 사용자 스토리 1·2는 별도 TDD 테스트 없이 quickstart.md의 수동 시나리오로
검증한다.

**구성**: 이 명세는 `UI` 패키지(그중 `DesignSystem` 타겟)만 변경한다. `Domain → Data →
Core → Composition → UI → Feature → App` 순서에서 적용 대상은 `UI` 하나뿐이므로 패키지
단계도 하나만 존재한다.

## 형식: `[ID] [P?] [스토리?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[스토리]**: 작업이 지원하는 사용자 스토리(US1, US2, US3). 여러 스토리가 함께 쓰는
  작업은 라벨을 병기한다.
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 패키지(`UI`)를
  가진다.

## 패키지 소유권 규칙

- `sources/Projects/UI/DesignSystem/**`, `sources/Projects/UI/DesignSystemTests/**`,
  `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`는 모두 `UI`
  패키지가 소유한다.
- 준비, 테스트, 구현, 정리를 별도 구현 단계로 나누지 않고 아래 "작업 패키지 1: UI" 하나
  안의 하위 절로만 둔다.
- 전체 기능을 대상으로 하는 검증은 마지막(그리고 유일한) 패키지 뒤에 `[no-write]`로만
  둔다.

---

## 작업 패키지 1: UI

**목표**: 프레임워크 비의존 디자인 토큰 값 모델(`Token/`)과 SwiftUI 적용 수단
(`Application/`)을 `DesignSystem` 타겟에 구현하고, 화면 렌더링 없이 값을 검증하는
`DesignSystemTests` 타겟을 신설한다.

**소유 경로**: `sources/Projects/UI/DesignSystem/Token/`,
`sources/Projects/UI/DesignSystem/Application/`,
`sources/Projects/UI/DesignSystemTests/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`

**관련 사용자 스토리**: US1, US2, US3 (이 명세의 유일한 패키지이므로 세 스토리 모두 이
단계 안에서 완결된다)

**독립 검증**: 다른 프로젝트 내부 패키지에 의존하지 않으므로(package-rules/ui.md), 이
패키지의 빌드·테스트만으로 세 사용자 스토리의 수용 시나리오를 모두 검증할 수 있다.

### 준비와 기반

- [ ] T001 [US1] [US3] `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`에
  `DesignSystemTests` 타겟(product: `.unitTests`, dependencies:
  `[.target(name: DesignSystem)]`)을 추가하고, `Noto Sans KR`·`Plus Jakarta Sans`의
  `Regular`·`Medium`·`Bold` 6개 정적 폰트를 `ResourceFileElements`로 코드 기반 선언해
  `DesignSystem` 리소스에 등록한다. UI 프로젝트의 자동 공유 스킴이 생성한
  `DesignSystem` 스킴에 `DesignSystemTests`가 testable로 포함되는지 확인한다
- [ ] T002 [no-write] 저장소 루트에서 `make tuist`를 실행해 `DesignSystemTests` 타겟과
  스킴이 워크스페이스에 반영되었는지 확인한다

### 테스트 (US3)

- [ ] T003 [P] [US3] `sources/Projects/UI/DesignSystemTests/ColorTokenTests.swift`에
  `ColorToken.Name.allCases` 24개(Blue 5·Purple 5·Grey 7·Opacity 4·State 3)의 개수와
  각 hex 값을 spec.md FR-005~FR-007 표와 대조하는 Swift Testing 테스트를 작성한다
- [ ] T004 [P] [US3] `sources/Projects/UI/DesignSystemTests/GradientTokenTests.swift`에
  `GradientToken.Name.allCases` 3개의 정지점 2개·위치 0/1·기본 좌표 `(0.5,0)`→`(0.5,1)`을
  spec.md FR-008·FR-008a와 대조하는 테스트를 작성한다
- [ ] T005 [P] [US3] `sources/Projects/UI/DesignSystemTests/TextStyleTokenTests.swift`에
  `TextStyleToken.Name.allCases` 10개의 weight·sizeInPoints·lineHeightPercent를 spec.md
  FR-009 표와 대조하는 테스트를 작성한다
- [ ] T006 [P] [US3] `sources/Projects/UI/DesignSystemTests/LayoutTokenTests.swift`에
  `LayoutToken.margin.value == 20`, `LayoutToken.gutter.value == 12`를 검증하는 테스트를
  작성한다
- [ ] T007 [no-write] [US3] `xcodebuild test -workspace GitIt.xcworkspace -scheme
  DesignSystemTests -destination 'platform=iOS Simulator,name=iPhone 17'`을 실행해
  T003~T006이 Token 모델 미구현으로 컴파일 실패하는지 확인한다(Red 단계)

### 구현 — Token 값 모델 (US1, US2)

- [ ] T008 [P] [US1] [US2] `sources/Projects/UI/DesignSystem/Token/RGBAComponents.swift`에
  `red`·`green`·`blue`·`alpha`(`Double`, 0...1) 구조체를 구현한다(data-model.md
  RGBAComponents)
- [ ] T009 [P] [US1] [US2] `sources/Projects/UI/DesignSystem/Token/FontFamilyToken.swift`에
  `Name`(`notoSans`, `plusJakartaSans`)·`postScriptName`·`scriptScope`(`korean`,
  `english`)를 구현한다. 한글과 기본 문자는 적용 계층에서 `notoSans`를 선택한다
  (data-model.md FontFamilyToken, FR-010)
- [ ] T010 [P] [US1] [US2] `sources/Projects/UI/DesignSystem/Token/LayoutToken.swift`에
  `Name`(`margin`, `gutter`)·`value`를 구현한다(data-model.md LayoutToken, FR-013)
- [ ] T011 [P] [US1] [US2] `sources/Projects/UI/DesignSystem/Token/ColorToken.swift`에
  `Name`(24 케이스)·`displayName`·`Group`(`blue`/`purple`/`grey`/`opacity`/`state`)·
  `value`(`RGBAComponents`)를 구현한다. T008 완료 필요(data-model.md ColorToken,
  FR-005~FR-007)
- [ ] T012 [P] [US1] [US2] `sources/Projects/UI/DesignSystem/Token/GradientToken.swift`에
  `Name`(3 케이스)·`kind`(`.linear`)·`start`/`end`(`UnitPointRatio`)·
  `stops`(`[GradientStop]`)를 구현한다. T008 완료 필요(data-model.md GradientToken,
  FR-008·FR-008a)
- [ ] T013 [P] [US1] [US2] `sources/Projects/UI/DesignSystem/Token/TextStyleToken.swift`에
  `Name`(10 케이스)·`displayName`·`fontFamilyPair`·`weight`·`sizeInPoints`·
  `lineHeightPercent`·`letterSpacingPercent`·`paragraphSpacing`·`paragraphIndent`를
  구현한다. T009 완료 필요(data-model.md TextStyleToken, FR-009~FR-011)
- [ ] T014 [US1] [US2] `sources/Projects/UI/DesignSystem/Token/DesignTokenSet.swift`에
  `colors`·`gradients`·`fontFamilies`·`textStyles`·`layouts` 딕셔너리와 `current` 정적
  상수를 구현한다. T010·T011·T012·T013 완료 필요(data-model.md DesignTokenSet,
  FR-020·FR-022)

### 구현 — Application 계층 (US1)

- [ ] T015 [P] [US1] `sources/Projects/UI/DesignSystem/Application/Text+TextStyleToken.swift`에
  한글 유니코드 블록(U+AC00–D7A3, U+1100–U+11FF, U+3130–U+318F)과 ASCII 영문 알파벳
  (U+0041–U+005A, U+0061–U+007A)을 문자 단위로 판별하고, 기본 문자(숫자·공백·기호를
  포함한 그 외 문자)는 `Noto Sans`로 선택하는 로직을 구현한다(research.md §7, FR-010)
- [ ] T016 [P] [US1] `sources/Projects/UI/DesignSystem/Application/LineHeightConverging.swift`에
  "목표 행 높이 = 폰트 크기 × 행간 백분율" 계산과 `lineSpacing`/`padding` 변환을
  구현한다(research.md §4, FR-011)
- [ ] T017 [P] [US1] `sources/Projects/UI/DesignSystem/Application/View+TokenColor.swift`에
  `tokenForeground(_:)`·`tokenBackground(_:)` modifier를 구현한다. T014 완료
  필요(contracts/design-token-api.md)
- [ ] T018 [US1] `sources/Projects/UI/DesignSystem/Application/View+TokenTextStyle.swift`에
  `tokenTextStyle(_:)` modifier를 구현한다. T014·T015·T016 완료
  필요(contracts/design-token-api.md, FR-014·FR-015)
- [ ] T019 [P] [US1] `sources/Projects/UI/DesignSystem/Application/View+TokenGradient.swift`에
  `tokenGradientBackground(_:)` modifier를 구현한다. T014 완료
  필요(contracts/design-token-api.md, research.md §5)
- [ ] T020 [P] [US1] `sources/Projects/UI/DesignSystem/Application/View+TokenLayout.swift`에
  `tokenScreenMargin()`·`tokenGutter`를 구현한다. T014 완료
  필요(contracts/design-token-api.md, FR-013)

### 정리와 패키지 검증

- [ ] T021 `sources/Projects/UI/DesignSystem/Placeholder.swift`를 삭제한다(T008~T020의
  실제 소스가 타겟 그룹을 대신 유지)
- [ ] T022 [no-write] [US3] `DesignSystemTests` 스킴을 다시 실행해 T003~T006이 모두
  통과하는지 확인한다(Green 단계)
- [ ] T023 [no-write] `DesignSystem`·`UIComponent` 스킴을 빌드해 `UI` 패키지 전체가
  회귀 없이 컴파일되는지 확인한다(`UIComponent`는 `DesignSystem`에 의존)

**승인 게이트**: T001~T023의 변경 파일과 검증 결과를 보고한 뒤 중단한다. `UI`는 이
명세의 유일한 적용 대상 패키지이므로 다음 패키지는 없으며, 사용자 승인 후 아래 전체
완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 1(UI)의 구현·검증·결과 보고와 사용자 승인이 완료되어야 한다.

- [ ] T024 [no-write] [US1] quickstart.md 시나리오 2(토큰만으로 화면 구성)를 Xcode
  Preview로 실행해 색상·글꼴·행간·여백이 참고 디자인과 일치하고 하드코딩 값이
  0건인지(SC-003) 확인한다
- [ ] T025 [no-write] [US2] quickstart.md 시나리오 3(`blue300` 값 임시 변경 후 재검토)을
  실행해 정의 파일 1곳 수정만으로 반영되고 사용처 수정이 0줄인지(SC-002) 확인한다
- [ ] T026 [no-write] [US1] [US2] [US3] spec.md의 사용자 스토리 1·2·3 수용 시나리오
  전체를 최종 대조하고 SC-001~SC-008 충족 여부를 기록한다

## Dependencies & Execution Order

### 패키지 순서와 승인 게이트

- 이 명세가 적용되는 패키지는 `UI` 하나뿐이다. `Domain → Data → Core → Composition →
  UI → Feature → App` 순서에서 `UI` 앞뒤 패키지는 모두 건너뛴다.
- `UI` 패키지의 모든 작업(T001~T023)과 검증이 끝나기 전에는 전체 완료 검증(T024~T026)을
  시작하지 않는다.
- `UI` 패키지의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤에만 전체
  완료 검증으로 진행한다.

### 사용자 스토리 추적성

- **US1**(화면 구현자가 토큰만으로 스타일을 적용): T008~T020(Token·Application 구현),
  T024(최종 검증)
- **US2**(디자인 값이 바뀌어도 화면 코드를 고치지 않는다): T008~T014(Token 구현이 곧
  단일 정의 지점), T025(최종 검증)
- **US3**(토큰 정의를 화면 없이 검증한다): T001·T003~T007·T022(테스트 작성·실행),
  T026(최종 검증)
- 세 스토리 모두 `UI` 패키지 완료 후 quickstart.md 시나리오와 spec.md 수용 시나리오로
  독립 검증한다.

### 패키지 내부 실행

- T003~T006(테스트 작성)은 서로 다른 파일이며 상호 의존이 없어 병렬 실행 가능하다.
  Token 모델 구현(T008~T014) 이전에 작성해 T007에서 예상대로 실패하는지 확인한다.
- T008·T009·T010은 서로 의존하지 않아 병렬 실행 가능하다.
- T011·T012는 T008 완료 후, T013은 T009 완료 후 각각 병렬 실행 가능하다.
- T014는 T010~T013 전체 완료가 필요한 동기화 지점이라 병렬 실행하지 않는다.
- T015·T016·T017·T019·T020은 T014(및 T017은 그 자체) 완료 후 서로 다른 파일이라 병렬
  실행 가능하다. T018은 T014·T015·T016 모두 완료된 뒤 실행한다.
- 다른 패키지의 작업은 존재하지 않으므로(이 명세는 `UI` 단일 패키지) 패키지 간 병렬
  실행 문제는 발생하지 않는다.

### 패키지 내부 병렬 실행 예시

```text
# 테스트 작성 단계 — 함께 실행 가능
T003, T004, T005, T006

# Token 모델 1라운드 — 함께 실행 가능
T008, T009, T010

# Token 모델 2라운드(1라운드 완료 후) — 함께 실행 가능
T011, T012, T013

# Application 계층(T014 완료 후) — 함께 실행 가능
T015, T016, T017, T019, T020
```

## Implementation Strategy

1. `UI` 패키지(유일한 적용 대상)의 준비(T001~T002)를 완료한다.
2. 사용자 스토리 3의 테스트(T003~T007)를 작성하고 Red 상태를 확인한다.
3. Token 값 모델(T008~T014)과 Application 계층(T015~T020)을 구현한다.
4. 정리와 패키지 검증(T021~T023)으로 Green 상태와 회귀 없음을 확인한다.
5. 변경 파일과 검증 결과를 보고하고 사용자 승인을 받는다.
6. 승인 후 전체 완료 검증(T024~T026)으로 세 사용자 스토리를 최종 확인한다.

## Notes

- 작업 ID는 실제 실행 순서대로 증가한다.
- 모든 파일 변경 작업은 정확한 경로를 포함한다.
- 이 기능은 패키지가 하나뿐이라 패키지 간 승인 게이트는 한 번만 존재하지만, "패키지
  구현 → 검증 → 보고 → 승인 → 다음 단계" 절차는 동일하게 적용한다.
- 모호한 소유권, 다중 패키지 작업, 승인 게이트를 넘는 병렬 실행은 없다.
