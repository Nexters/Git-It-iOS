# 작업 목록: UI 패키지 디자인 규격 정렬

**입력**: `/specs/024-ui-design-spec-alignment/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 포함한다. 명세가 FR-038·FR-043과 SC-001~SC-004·SC-009·SC-010으로 단위 테스트를
명시적으로 요구한다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안의 `[S#]` 라벨로
추적한다. 적용 패키지의 위상 순서는 `DesignSystem` → `UIComponent` → `Feature`이며 근거는
[아키텍처 문서](../../docs/architecture.md)의 의존성 표와 `UIModuleName.swift`의 target
의존성이다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1(토큰) · S2(반응형 레이아웃) · S3(컴포넌트 신설·상태 계약) ·
  S4(계층 소유 규칙) · S5(접근성)
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 파일 변경 작업은 정확한 저장소 상대 경로와 책임 패키지 또는 integration unit을 갖는다.
- 문서 변경은 `GIT_IT_DOCS_ROOT`(현재 `docs`)를 기준으로 정확한 파일 하나를 지정한다.

## 계획 대비 조정

[plan.md](./plan.md)의 실행 단위 표는 12개였다. 이 tasks.md는 10개 단위로 재구성했고 그 근거를
남긴다. 순서와 소유권은 바꾸지 않았다.

- **계획 단위 1(토큰 값)과 2(적용 확장)를 하나로 합쳤다.** `EffectToken`을 다중 레이어
  구조로 바꾸면 이미 존재하는
  `sources/Projects/UI/DesignSystem/Extensions/View+EffectToken.swift`가 `colorToken`·`offset`·
  `blur`·`spread`를 직접 읽으므로 즉시 컴파일이 깨진다. 두 단위를 나누면 단위 1이 자체
  검증(빌드)을 통과할 수 없다. 두 경로 모두 `DesignSystem` 패키지 소유이므로 단일 패키지
  단위를 유지한다.
- **계획 단위 12(전체 검증과 PR 본문)를 `[no-write]` 전체 완료 검증으로 옮겼다.** 파일 변경
  대상이 없고 화면 변경 목록은 PR 본문에 작성하므로(R-14) 패키지 단위가 아니다.

### 계획이 지정하지 않은 두 지점의 확정

구현 중 판단이 갈리지 않도록 여기서 확정한다. 둘 다 저장소 컨벤션이 요구하는 문서 갱신을
같은 단위에 포함한다.

- **`LayoutMetrics.HeaderStyle`을 `DesignSystem`에 새로 둔다.** 계약의
  `topScrimHeight(headerStyle:)`·`contentBudget(headerStyle:)`은 헤더 종류를 인자로 받는데,
  기존 `ScreenHeader.Style`은 `UIComponent`에 있어 `DesignSystem`이 참조할 수 없다(의존 방향
  역전). `LayoutMetrics.HeaderStyle`을 `DesignSystem`에 정의하고 `ScreenHeader.Style`이 이를
  매핑한다. 기존 `ScreenHeader.Style`의 case 이름 `default`는 규격의 `plain`에 해당하며
  이름을 바꾸지 않는다(Constitution 원칙 10 — rename은 동작 변경과 분리).
- **`SizingMode`는 공개 API 인자가 아니라 문서화된 분류다.** contracts의 신설 컴포넌트 4종
  입력 표에 크기 결정 방식 인자가 없고, 런타임 동작을 바꾸지 않는다. 각 컴포넌트의 doc
  comment에 명시하고 `fixed` 위반은 `fixed-width` 정적 검사가 판정한다(FR-017 "명시").

### 저장소 컨벤션이 요구하는 문서 갱신

[파일·형태 어휘 컨벤션 §3](../../docs/conventions/file-vocabulary.md)은 "표에 없는 형태를
추가하려면 같은 PR에서 이 표를 갱신한다"고 규정한다. 이 기능은 표에 없는 형태 폴더 둘을
만들므로 각각 만드는 단위에서 표를 함께 갱신한다.

| 새 형태 폴더 | 갱신 대상 | 배정 단위 |
| --- | --- | --- |
| `UI/DesignSystem/Layout/` | `docs/conventions/file-vocabulary.md` | 2 |
| `Feature/<기능>/Views/` | `docs/conventions/file-vocabulary.md` | 8 |

또한 [UIComponent 컨벤션 §3.4](../../docs/conventions/ui-component.md)의 "현재 컴포넌트 배치"
표가 컴포넌트 전체 목록을 담고 있어, 신설·이동·삭제가 일어나는 단위마다 갱신한다.

---

## 작업 패키지 1: DesignSystem — 토큰 카탈로그와 적용 확장 ⛔

**목표**: 빈 토큰 3종과 누락 16종을 규격 값으로 채우고, 그 값을 뷰에 적용하는 확장을 맞춘다.
`DesignTokenSet.current.validate()`가 빈 배열을 반환하는 상태를 만든다. `GradientToken`은 값
변경이 없고 `all` 밖의 `gradient4` 제거만 남았으며, 삭제이므로 T009에 승인 게이트가 있다.

**소유 경로**: `sources/Projects/UI/DesignSystem/Tokens/**`,
`sources/Projects/UI/DesignSystem/Extensions/**`

**관련 변경 시나리오**: S1

**독립 검증**: `DesignSystem` target이 빌드되고, 각 카테고리의 `all`이 규격 개수를 반환하며
`validate()`가 빈 배열을 반환한다. 값은 [design-token-catalog.md](./contracts/design-token-catalog.md)와
대조한다.

### 구현

- [X] T001 [S1] `sources/Projects/UI/DesignSystem/Tokens/ColorToken.swift`에 원시 색 5종
      `black25`·`black35`·`black45`·`blue300Alpha10`(rgba 126,148,187,0.10)·
      `blue300Alpha24`(rgba 126,148,187,0.24)를 추가하고 `all`에 등록한다
- [X] T002 [S1] `sources/Projects/UI/DesignSystem/Tokens/SemanticColorToken.swift`에 역할 색
      5종 `tabBarSurface`→`blue300Alpha10` · `tabBarBorder`→`blue300Alpha24` ·
      `selectedSurface`→`white5` · `grabber`→`grey500` · `disabledText`→`white30`을 추가하고
      `all`에 등록한다 (T001 의존)
- [X] T003 [P] [S1] `sources/Projects/UI/DesignSystem/Tokens/LayoutToken.swift`에
      `cardHorizontalPadding` 18 · `cardTopPadding` 14 · `iconSpacing` 6 · `tightSpacing` 4를
      추가하고 `all`에 등록한다
- [X] T004 [P] [S1] `sources/Projects/UI/DesignSystem/Tokens/CornerRadiusToken.swift`에
      `pill` 999를 추가하고 `all`에 등록한다
- [X] T005 [P] [S1] `sources/Projects/UI/DesignSystem/Tokens/ControlSizeToken.swift`에
      `minimumTouch` 44를 추가하고 `all`에 등록한다
- [X] T006 [P] [S1] `sources/Projects/UI/DesignSystem/Tokens/OpacityToken.swift`의 `all`을 빈
      배열에서 규격 6종으로 교체한다 — `subtleSurface` 5 · `tabSurface` 10 · `track` 15 ·
      `border` 24 · `disabled` 30 · `scrim` 70
- [X] T007 [S1] `sources/Projects/UI/DesignSystem/Tokens/BorderToken.swift`의 `all`을 빈
      배열에서 규격 6종으로 교체한다 — `` `default` ``(굵기 1, `grey500`) · `focus`(1,
      `blue100`) · `highlight`(1, `blue200`) · `error`(1, `error`) · `tabBar`(1,
      `blue300Alpha24`) · `loadingTrack`(4, `grey400`). `default`는 Swift 예약어이므로 backtick
      식별자를 쓴다 (T001 의존)
- [X] T008 [S1] `sources/Projects/UI/DesignSystem/Tokens/EffectToken.swift`를 다중 레이어
      구조로 재정의한다 — 기존 `colorToken`·`offset`·`blur`·`spread` 저장 프로퍼티를 중첩
      타입 `Layer`(참조 색 토큰·offset·blur·spread)의 배열 `layers`로 바꾸고, `all`에
      `sheetElevation`(`black45` (0,4) blur 6 → `black35` (0,4) blur 34, 2레이어)과
      `cardElevation`(`black25` (4,4) blur 15 spread 10, 1레이어)을 정의한다. 기존
      `Kind`·`Offset`과 같은 파일에 중첩한다 (T001 의존)
- [X] T009 [S1] ⛔ `sources/Projects/UI/DesignSystem/Tokens/GradientToken.swift`에서
      `gradient4`를 제거한다. `all`은 이미 규격 5종(`gradient1`·`gradient2`·`gradient3`·
      `topEdgeScrim`·`bottomEdgeScrim`)과 일치하므로 값 변경이 없고, `gradient4`만 public이면서
      `all`에 없고 `sources/Projects` 사용처가 0건이다. 삭제는 되돌리기 어려우므로 제거 전에
      승인을 받는다. `private` 방향 상수 `topToBottomStart`·`topToBottomEnd`는 토큰이 아니므로
      그대로 둔다 (FR-008)
- [X] T010 [S1] `sources/Projects/UI/DesignSystem/Tokens/DesignTokenSet.swift`의 `validate()`를
      새 구조에 맞춘다 — `EffectToken` 참조 무결성 검사를 `effect.layers`의 각 레이어에 대해
      수행하도록 바꾸고, data-model의 값 범위 규칙(`BorderToken.width` ≥ 0, 반경·간격 ≥ 0)을
      추가한다 (T007·T008 의존)
- [X] T011 [S1] `sources/Projects/UI/DesignSystem/Extensions/View+EffectToken.swift`를 다중
      레이어 적용으로 바꾼다 — 레이어를 가까운 것부터 순서대로 겹쳐 적용하고, Figma blur를
      SwiftUI radius로 환산(blur ÷ 2)하며 spread를 radius로 흡수한다. 토큰 값 자체는 규격
      원본을 보존한다 (T008 의존)
- [X] T012 [P] [S1] `sources/Projects/UI/DesignSystem/Extensions/View+BorderToken.swift`가 새
      6종을 굵기와 색 토큰 참조로 적용하는지 확인하고 필요한 경우 맞춘다 (T007 의존)
- [X] T013 [P] [S1] `sources/Projects/UI/DesignSystem/Extensions/View+OpacityToken.swift`를
      새로 만들어 `OpacityToken`을 뷰 불투명도로 적용하는 공개 API를 제공한다 (T006 의존)

### 정리와 패키지 검증

- [X] T014 [no-write] [S1] `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`로
      진입점을 읽고 `"$project_build_runner" build`를 실행해 `DesignSystem`을 포함한 공유
      scheme이 빌드되는지 확인한다

**진행 점검**: T001~T014의 변경 파일과 빌드 결과를 보고하고 같은 기능 범위의 다음 실행
단위로 진행한다.

---

## 작업 패키지 2: DesignSystem — 런타임 레이아웃 변수

**목표**: 화면 폭·높이·safe area 넷만 입력으로 받아 파생값을 유도하는 `LayoutMetrics`를
신설한다. SwiftUI에 의존하지 않는 순수 값 타입으로 두어 화면 렌더링 없이 검증 가능하게 한다.

**소유 경로**: `sources/Projects/UI/DesignSystem/Layout/**`,
`docs/conventions/file-vocabulary.md`

**관련 변경 시나리오**: S2

**독립 검증**: `DesignSystem` target이 빌드되고, `LayoutMetrics`가 `SwiftUI`를 import하지
않으며 파생값 계산이 [layout-metrics.md](./contracts/layout-metrics.md)의 계산식과 일치한다.

### 구현

- [X] T015 [S2] `sources/Projects/UI/DesignSystem/Layout/LayoutMetrics.swift`를 새로 만든다 —
      입력 4종(`screenWidth`·`screenHeight`·`safeAreaTop`·`safeAreaBottom`)을 받는
      이니셜라이저와 파생값을 정의한다. 프로퍼티: `contentWidth` =
      `screenWidth − LayoutToken.margin × 2`, `gridColumn2` = `(contentWidth − gutter) / 2`,
      `gridColumn3` = `(contentWidth − gutter × 2) / 3`, `tabBarBottomInset` =
      `max(safeAreaBottom, 24)`, `sheetMaximumHeight` = `screenHeight − safeAreaTop − 16`.
      함수: `topScrimHeight(headerStyle:)` = `safeAreaTop + headerHeight`,
      `bottomScrimHeight(hasTabBar:)` = `safeAreaBottom + (탭바 ? 93 : 0)`,
      `contentBudget(headerStyle:)` =
      `screenHeight − safeAreaTop − safeAreaBottom − headerHeight − tabBarClearance`로 두고
      `tabBarClearance`는 UIUX Guide §7.3의 92로 정의한다. `import SwiftUI`를 쓰지 않는다
      (R-01 · R-02 · R-15)
- [X] T016 [S2] `sources/Projects/UI/DesignSystem/Layout/LayoutMetrics+HeaderStyle.swift`를
      새로 만들어 중첩 타입 `LayoutMetrics.HeaderStyle`을 `extension`으로 선언한다 — case는
      `plain` 50 · `inlineTitle` 64 · `inlineUser` 98 · `largeTitle` 120이며 `height`를
      노출한다. `UIComponent`의 `ScreenHeader.Style`을 참조하지 않는다(의존 방향 유지)
- [X] T017 [S2] `docs/conventions/file-vocabulary.md` §3의 형태 어휘 표에 `UI/DesignSystem/`
      소스 루트의 `Layout/`(런타임 레이아웃 변수) 행을 추가한다. 책임 패키지는 `UI`다

### 정리와 패키지 검증

- [X] T018 [no-write] [S2] `"$project_build_runner" build`로 `DesignSystem`이 빌드되는지
      확인하고, `sources/Projects/UI/DesignSystem/Layout/`에 `import SwiftUI`가 없는지
      `grep`으로 확인한다

**진행 점검**: T015~T018의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 3: DesignSystem + Tuist manifest — 테스트 target 신설 ⚠

**⚠ 불가분한 다중 패키지 integration unit이다.** `DesignSystemTests` target 등록(Tuist 공용
manifest)과 그 target의 테스트 소스는 분리할 수 없다. manifest만 먼저 넣으면 `tuist generate`가
소스 없는 test target을 만들어 scheme이 빌드되지 않고, 소스만 먼저 넣으면 어느 target에도
속하지 않아 컴파일되지 않는다. `AllTestsScheme.swift`도 같은 이유로 함께 바꾼다.

**통합 검증**: `make tuist` 실행 후 전체 테스트 scheme이 새 target을 포함해 통과하는지
확인한다. `make tuist`는 파생 산출물만 갱신하므로 실행 전후 Git 상태를 비교해 추적 파일 diff가
생기지 않았는지 확인한다.

**목표**: 토큰 값과 레이아웃 계산식을 화면 렌더링 없이 검증할 곳을 만든다(R-03).

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`,
`sources/Projects/UI/Tests/DesignSystem/Unit/**`

**관련 변경 시나리오**: S1, S2

**독립 검증**: `AllTests` scheme이 `DesignSystemTests`를 포함하고 전체 테스트가 통과한다.

### 구현

- [X] T019 [S1] [S2] `sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`에
      `case DesignSystemTests`를 추가하고, `sourceDirectory`의 `switch`에 `.DesignSystemTests`
      분기를 더해 `"DesignSystem/Unit"`을 반환하게 한 뒤, `targets`에 `.testModule(name:)`으로
      `productionTarget: .target(name: UIModuleName.DesignSystem.rawValue)` 항목을 추가한다
- [X] T020 [S1] [S2] `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`의
      `allTestTargets`에
      `.project(path: ProjectName.UI.projectPath, target: UIModuleName.DesignSystemTests.rawValue)`를
      추가한다 (T019 의존)
- [X] T021 [P] [S1] `sources/Projects/UI/Tests/DesignSystem/Unit/Tokens/DesignTokenSetValidationTests.swift`를
      새로 만들어 `DesignTokenSet.current.validate()`가 빈 배열을 반환하는지 검증한다
      (SC-001). Swift Testing과 한국어 동작 문장 이름을 쓴다(R-10)
- [X] T022 [P] [S1] `sources/Projects/UI/Tests/DesignSystem/Unit/Tokens/DesignTokenCatalogTests.swift`를
      새로 만들어 카테고리별 개수와 이름 집합을 검증한다 — `BorderToken.all` 6 ·
      `OpacityToken.all` 6 · `EffectToken.all` 2, 빈 배열인 카테고리 0개,
      `EffectToken.sheetElevation.layers` 2개, `design-token-catalog.md`가 나열한 이름 전부
      존재 (SC-002 · SC-003)
- [X] T023 [P] [S2] `sources/Projects/UI/Tests/DesignSystem/Unit/Layout/LayoutMetricsTests.swift`를
      새로 만들어 [quickstart.md](./quickstart.md) §2의 지원 기기 9종 입력 표를 그대로 넣고
      레이아웃 변수 13종이 규격 min–max 범위 안인지 검증한다 — `LayoutMetrics`가 소유하는
      입력 4와 파생 8, 그리고 `LayoutMetrics.HeaderStyle`이 소유하는 `headerHeight` 1이다.
      양 끝을 명시적으로 단정한다 — SE(375×667, 20/0)에서 `contentWidth` 335 ·
      `topScrimHeight(.plain)` 70 · `tabBarBottomInset` 24 · `contentBudget(.plain)` 505 ·
      `contentBudget(.largeTitle)` 435 · `sheetMaximumHeight` 631, 17 Pro Max(440×956,
      62/34)에서 `contentWidth` 400 · `gridColumn2` 194 · `contentBudget(.plain)` 718 ·
      `sheetMaximumHeight` 878, Air(420×912, 68/34)의 `topScrimHeight(.largeTitle)` 188
      (SC-004 · R-15)

### 정리와 패키지 검증

- [X] T024 [no-write] [S1] [S2] `git status --porcelain`을 기록하고 `make tuist`를 실행한 뒤
      다시 비교해 추적 파일 변경이 없는지 확인한다. 추적 파일 diff가 생기면 이 작업을 완료로
      표시하지 않는다
- [X] T025 [no-write] [S1] [S2] `"$project_build_runner" compile`과
      `"$project_build_runner" test`를 순차 실행해 `DesignSystemTests`가 `AllTests`에 포함되어
      통과하는지 확인한다. 두 명령은 `sources/DerivedData/PreCommit`을 공유하므로 병렬
      실행하지 않는다

**진행 점검**: T019~T025의 변경 파일과 통합 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 4: UIComponent — 골격 계층 반응형 정렬

**목표**: 정본 캔버스 고정값에 묶인 골격을 `LayoutMetrics` 계산식으로 바꾼다. 스크림·탭바·
시트·모달이 지원 기기 9종에서 어긋나지 않게 한다.

**소유 경로**: `sources/Projects/UI/Component/Scaffolds/**`,
`sources/Projects/UI/Component/Overlays/**`,
`sources/Projects/UI/Tests/Component/Unit/Scaffolds/**`,
`sources/Projects/UI/Tests/Component/Unit/Overlays/**`

**관련 변경 시나리오**: S2

**독립 검증**: `UIComponentTests`가 통과하고 골격 컴포넌트에 103·154·34·127·53 리터럴이 남지
않는다. 크기·정렬은 [layout-metrics.md](./contracts/layout-metrics.md)의 골격 계층 표와
대조한다.

### 구현

- [X] T026 [S2] `sources/Projects/UI/Component/Scaffolds/ScreenContainer.swift`를 타입 패밀리
      폴더 `sources/Projects/UI/Component/Scaffolds/ScreenContainer/ScreenContainer.swift`로
      옮기고, `GeometryReader`와 safe area에서 화면 폭·높이·safe area 상하를 읽어
      `LayoutMetrics`를 만들어 Environment로 주입하는 유일한 지점으로 만든다. 화면 좌우
      여백(`LayoutToken.margin`)도 여기서 한 번만 붙인다 (FR-027)
- [X] T027 [S2] `sources/Projects/UI/Component/Scaffolds/ScreenContainer/EnvironmentValues+LayoutMetrics.swift`를
      새로 만들어 `LayoutMetrics`의 SwiftUI Environment 키와 접근자를 선언한다. 기본값은 주력
      기기(402 × 874, safe area 62/34)로 둔다 (T026 의존)
- [X] T028 [S2] `sources/Projects/UI/Component/Scaffolds/ScreenHeader/ScreenHeader+Style.swift`에
      `LayoutMetrics.HeaderStyle` 매핑과 높이를 확정한다 — `.default`(규격 plain) 50 ·
      `.inlineTitle` 64 · `.inlineUser` 98 · `.largeTitle` 120. case 이름은 바꾸지 않는다
      (FR-014)
- [X] T029 [S2] `sources/Projects/UI/Component/Scaffolds/ScreenHeader/ScreenHeader.swift`가
      확정된 높이를 사용하고 스크롤과 무관하게 상단 safe area 아래에 고정되게 한다
      (T028 의존)
- [X] T030 [S2] `sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift`가 Environment의
      `LayoutMetrics`를 읽어 상단 높이를 `topScrimHeight(headerStyle:)`로, 하단 높이를
      `bottomScrimHeight(hasTabBar:)`로 계산하게 한다. 헤더 종류와 탭바 유무를 공개 생성
      경로의 값으로 받고, 정본 고정값 103·34·127을 쓰지 않는다 (FR-013 · R-06)
- [X] T031 [S2] `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift`가 알약 폭
      298을 기본값 인자로 갖고 가로 중앙 정렬하며, 하단 여백을 `tabBarBottomInset`
      (`max(safeAreaBottom, 24)`)으로 쓰게 한다. 표면과 테두리는 `tabBarSurface`·`tabBarBorder`
      역할 색과 `BorderToken.tabBar`를 참조한다 (FR-016)
- [X] T032 [S2] `sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift`를
      `ViewThatFits(in: .vertical)`로 재구성한다 — 첫 후보는 콘텐츠 그대로, 둘째 후보는
      `ScrollView { 콘텐츠 }`로 두고 전체에 `.frame(maxHeight:)`로 Environment의
      `sheetMaximumHeight`를 건다. 이로써 `@State private var contentHeight`와
      `ContentHeightPreferenceKey`, `isScrollable` 인자를 모두 제거한다. 비율 detent를 쓰지
      않고 상단 두 모서리만 반경 16을 적용하며 그래버는 `grabber` 역할 색을 쓴다. 같은 파일의
      `.designSystemScreenMargin()` 호출도 함께 제거한다 — 컴포넌트는 화면 좌우 여백을 붙이지
      않고 `ScreenContainer`가 소유한다 (FR-015 · FR-026 · FR-027 · SC-014)
- [X] T033 [S2] `sources/Projects/UI/Component/Overlays/ModalOverlay.swift`가 safe area를
      무시하고 화면 전체를 덮으며 딤을 `OpacityToken.scrim`(70%)으로 표현하게 한다
- [X] T034 [S2] `sources/Projects/UI/Component/Scaffolds/BottomActionBar/BottomActionBar.swift`의
      하단 여백을 `LayoutMetrics`에서 읽어 고정값 대신 계산값을 쓰게 하고,
      `.designSystemScreenMargin()` 호출을 제거한다. 이 파일과 `SheetSurface.swift`가
      `Component/**`의 프로덕션 화면 여백 사용처 2곳이다 (FR-027)
- [X] T035 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Scaffolds/ScreenContainerContractTests.swift`를
      새로 만들어 `ScreenContainer`가 `LayoutMetrics`를 주입하고 화면 여백을 한 번만 붙이는지
      검증한다. 역할 폴더 `Scaffolds`의 첫 테스트다 (SC-010)
- [X] T036 [P] [S2] `sources/Projects/UI/Tests/Component/Unit/Overlays/ScreenEdgeScrimContractTests.swift`를
      갱신해 헤더 종류·탭바 유무별 스크림 높이가 계산값을 따르는지 검증한다 (T030 의존)

### 정리와 패키지 검증

- [X] T037 [no-write] [S2] `"$project_build_runner" compile`과 `"$project_build_runner" test`를
      순차 실행하고, `grep -rn` 으로 `sources/Projects/UI/Component/Scaffolds`와
      `sources/Projects/UI/Component/Overlays`에 정본 고정값 103·154·34·127·53이 남지 않았는지
      확인한다

**진행 점검**: T026~T037의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 5: UIComponent — 규격 컴포넌트 4종 신설

**목표**: 규격이 요구하나 코드에 없는 `Chip`·`PressOverlayStyle`·`BookmarkButton`·
`ChoiceResultRow`를 공개 계약대로 만든다. 넷 모두 표시 상태를 소유하지 않는다.

**소유 경로**: `sources/Projects/UI/Component/Controls/**`,
`sources/Projects/UI/Component/CollectionItems/**`,
`sources/Projects/UI/Tests/Component/Unit/Controls/**`,
`sources/Projects/UI/Tests/Component/Unit/CollectionItems/**`,
`docs/conventions/ui-component.md`

**관련 변경 시나리오**: S3

**독립 검증**: 신설 4종의 공개 생성 경로와 상태별 표현을 검사하는 계약 테스트가 통과하고,
넷 모두 `@State`를 갖지 않는다. 값은
[component-public-api.md](./contracts/component-public-api.md)와 대조한다.

### 구현

- [X] T038 [S3] `sources/Projects/UI/Component/Controls/Chip/Chip.swift`를 새로 만든다 —
      라벨·선택 여부·탭 콜백을 모두 필수 값으로 받고 선택을 보관하지 않는다. 비선택은
      `raisedBackground` 배경 + `blue100` 라벨, 선택은 `brandAccent` 배경 + `grey700` 라벨,
      반경 `CornerRadiusToken.small`(8), 높이 36, 라벨은 Body 2 1줄 고정. 접근성으로 선택
      특성을 노출한다. doc comment에 `SizingMode.hug`를 명시한다 (FR-019 · FR-034)
- [X] T039 [S3] `sources/Projects/UI/Component/Controls/Chip/Chip+Constant.swift`를 새로 만들어
      규격 수치(높이 36 등)를 상수로 모은다 (T038 의존)
- [X] T040 [P] [S3] `sources/Projects/UI/Component/Controls/PressOverlayStyle.swift`를 새로
      만들어 버튼 계열 공용 누름 표현을 제공한다 — 눌림 시 `white30` 오버레이 하나만 적용하고
      배경색을 새로 만들지 않는다 (FR-020)
- [X] T041 [P] [S3] `sources/Projects/UI/Component/Controls/BookmarkButton.swift`를 새로 만든다
      — 저장 여부·접근성 라벨·탭 콜백을 받고 접근성 라벨을 **필수 인자**로 요구한다(생략
      불가). 라벨은 아이콘 이름이 아니라 동작 이름이다. 히트 영역은
      `ControlSizeToken.minimumTouch`(44) 이상 (FR-021 · FR-033)
- [X] T042 [S3] `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow/ChoiceResultRow.swift`를
      새로 만든다 — 정답·오답 축과 접힘·펼침 축을 값으로 받고 본문·해설과 탭 콜백을 받는다.
      펼침 상태를 보관하지 않고 햅틱을 발생시키지 않는다. `cardBackground` 기본, 판정 시
      `correct`/`incorrect` 배경 + `grey100` 본문. 접근성 라벨에 "정답"·"오답"을 접미로 붙인다.
      접힘 높이 59 · 펼침 높이 111을 적용하고 가로는 `SizingMode.fill`로 둔다 — 스펙 카드의
      `320 × 111` 중 320은 정본 캔버스 360에서 좌우 여백 20을 뺀 값이므로 고정 폭으로 옮기지
      않는다 (FR-022 · FR-035 · FR-017 · FR-018)
- [X] T043 [S3] `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow/ChoiceResultRow+Constant.swift`를
      새로 만들어 접힘 높이 59와 펼침 높이 111을 상수로 정의한다. 폭은 상수로 두지 않는다 —
      가로는 채움이다 (T042 의존)
- [X] T044 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/Controls/ChipTests.swift`를 새로
      만들어 선택·비선택 표현과 상태 비보관을 검증한다
- [X] T045 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/Controls/BookmarkButtonTests.swift`를
      새로 만들어 접근성 라벨 필수성과 44pt 히트 영역을 검증한다
- [X] T046 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/CollectionItems/ChoiceResultRowTests.swift`를
      새로 만들어 정답·오답 축과 접힘·펼침 축이 값으로 주입되는지, 접근성 라벨에 판정이
      실리는지 검증한다
- [X] T047 [S3] `docs/conventions/ui-component.md` §3.4 "현재 컴포넌트 배치" 표의 `Controls/`
      행에 `Chip`·`PressOverlayStyle`·`BookmarkButton`을, `CollectionItems/` 행에
      `ChoiceResultRow`를 추가한다. 책임 패키지는 `UI`다

### 정리와 패키지 검증

- [X] T048 [no-write] [S3] `"$project_build_runner" test`로 신설 4종의 계약 테스트가 통과하는지
      확인한다

**진행 점검**: T038~T048의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 6: UIComponent — 상태 매트릭스·재작도·접근성·고정 폭 정리

**목표**: 기존 컴포넌트의 상태별 표현을 UIUX Guide 상태 매트릭스 10행에 맞추고, `TextField`를
규격 값으로 재작도하며, 접근성 계약과 폭 결정 방식을 정렬한다.

**소유 경로**: `sources/Projects/UI/Component/**`,
`sources/Projects/UI/Tests/Component/Unit/**`

**관련 변경 시나리오**: S3, S5

**독립 검증**: `UIComponentTests`가 통과하고, `Component/` 아래 `.frame(width:` 사용처가
종횡비가 의미를 갖는 요소와 `TabShell` 298로만 남는다. 역할 폴더 6종 각각이 최소 1개의
테스트를 갖는다.

### 구현

- [X] T049 [S3] `sources/Projects/UI/Component/Controls/TextField.swift`를 재작도한다 — 높이
      52 · 반경 8 · 내부 좌우 16. Material 잔여 형태(반경 4/4/0/0, 하단 active indicator, 라벨
      축소)를 제거하고 상태별 테두리를 기본 `BorderToken.default` · 활성 `BorderToken.focus` ·
      입력됨 `mutedText` 1pt · 오류 `BorderToken.error`(+ Caption 1 오류문)로 맞춘다 (FR-023)
- [X] T050 [S3] `sources/Projects/UI/Tests/Component/Unit/Controls/TextFieldTests.swift`를
      재작도된 규격 값(높이 52 · 반경 8 · 좌우 16 · 상태별 테두리)에 맞춰 갱신한다 (T049 의존)
- [X] T051 [S3] `sources/Projects/UI/Component/Controls/ActionButton.swift`의 primary·
      secondary·text 세 변형을 상태 매트릭스에 맞추고 눌림 표현을 `PressOverlayStyle`로
      통일한다 (FR-020 · FR-024) (T040 의존)
- [X] T052 [P] [S3] `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift`의 기본은
      `cardBackground` 테두리 없음, 선택은 외곽 `BorderToken.focus`로 맞추고 내부 SwiftUI
      `Button`에 `PressOverlayStyle`을 적용한다 (FR-020) (T040 의존)
- [X] T053 [P] [S3] `sources/Projects/UI/Component/CollectionItems/LearningSetRow/LearningSetRow.swift`와
      `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift`의 기본을
      `screenBackground` + `BorderToken.default`, 선택을 `selectedSurface` 겹침 +
      `BorderToken.focus`로 맞춘다
- [X] T054 [P] [S3] `sources/Projects/UI/Component/Scaffolds/TabShell/TabShellItem.swift`의
      기본을 `mutedText`, 선택을 `brandAccent` 아이콘·라벨로 맞춘다
- [X] T055 [P] [S3] `sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift`가
      규격이 정의한 2종(프로젝트 없음 · 저장 문제 없음)만 표현하는지 확인하고 맞춘다
- [X] T056 [S3] `sources/Projects/UI/Component/Controls/IconPlainButton.swift`와
      `sources/Projects/UI/Component/Controls/IconGlassButton.swift`가 눌림 표현으로
      `PressOverlayStyle`을 쓰게 하고, 아이콘 전용 버튼의 접근성 라벨을 필수 인자로 바꾼다
      (FR-020 · FR-033) (T040 의존)
- [X] T057 [S3] [S5] 아래 정확한 파일의 프로덕션 SwiftUI `Button` 사용처 전부가
      `PressOverlayStyle`을 쓰고, 표면 크기를 유지한 채
      `ControlSizeToken.minimumTouch`(44) 이상의 히트 영역을 갖게 한다
      (FR-020 · FR-032) (T040 의존)

  | 역할 | 정확한 변경 파일 |
  | --- | --- |
  | CollectionItems | `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift` · `sources/Projects/UI/Component/CollectionItems/LearningSetRow/LearningSetRow.swift` · `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift` · `sources/Projects/UI/Component/CollectionItems/SettingRow/SettingRow.swift` · `sources/Projects/UI/Component/CollectionItems/ChoiceResultRow/ChoiceResultRow.swift` |
  | Controls | `sources/Projects/UI/Component/Controls/AccountActionRow/AccountActionRow.swift` · `sources/Projects/UI/Component/Controls/ActionButton.swift` · `sources/Projects/UI/Component/Controls/AppleSignInButton.swift` · `sources/Projects/UI/Component/Controls/BookmarkButton.swift` · `sources/Projects/UI/Component/Controls/Chip/Chip.swift` · `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift` · `sources/Projects/UI/Component/Controls/IconGlassButton.swift` · `sources/Projects/UI/Component/Controls/IconPlainButton.swift` · `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift` · `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift` · `sources/Projects/UI/Component/Controls/SelectableSettingRow/SelectableSettingRow.swift` · `sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList.swift` |
  | Overlays | `sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu.swift` |
- [X] T058 [S5] `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift`·
      `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift`·
      `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift`처럼 여러
      텍스트를 담는 카드가 하나의 접근성 요소로 읽히도록 묶는다 (FR-036)
- [X] T059 [S2] [S3] 아래 표의 정확한 파일에 있는 `.frame(width:` 56곳을 전수 판정한다 —
      버튼·행·카드·텍스트는 채움(`fill`)으로, 2열·3열 배치는 `LayoutMetrics`의
      `gridColumn2`·`gridColumn3`으로, 칩·배지는 내용맞춤(`hug`)으로 바꾸고, 종횡비가 의미를
      갖는 요소(이미지 썸네일 · Lottie 애니메이션 · 가로 스크롤 카드)와 규격이 확정한
      `TabShell` 298만 고정으로 남긴다.
      각 컴포넌트의 doc comment에 `SizingMode`를 명시한다. 같은 훑기에서
      `.frame(maxHeight: .infinity)` 사용처도 확인해 종횡비·웹 콘텐츠 밖의 세로 채움이 없는지
      판정하고, 남기는 지점은 T086의 `allowed-vertical-fill` 입력으로 보고한다
      (FR-017 · FR-018 · R-09)

  | 역할 | 정확한 변경 파일 |
  | --- | --- |
  | CollectionItems | `sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift` · `sources/Projects/UI/Component/CollectionItems/LearningSetRow/LearningSetRow.swift` · `sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift` · `sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift` · `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift` |
  | Controls | `sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift` · `sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput.swift` · `sources/Projects/UI/Component/Controls/IconGlassButton.swift` · `sources/Projects/UI/Component/Controls/IconPlainButton.swift` · `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift` · `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift` · `sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList.swift` · `sources/Projects/UI/Component/Controls/TextField.swift` |
  | Displays | `sources/Projects/UI/Component/Displays/LaunchLogo.swift` · `sources/Projects/UI/Component/Displays/QuestionPrompt.swift` · `sources/Projects/UI/Component/Displays/ResourceAnimation.swift` · `sources/Projects/UI/Component/Displays/ResourceImage.swift` · `sources/Projects/UI/Component/Displays/RubricView/RubricView.swift` · `sources/Projects/UI/Component/Displays/SplashView.swift` · `sources/Projects/UI/Component/Displays/StyledText.swift` |
  | Indicators | `sources/Projects/UI/Component/Indicators/ContinuousProgressBar.swift` · `sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift` · `sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift` · `sources/Projects/UI/Component/Indicators/PageIndicator.swift` · `sources/Projects/UI/Component/Indicators/ProgressSegments.swift` |
  | Overlays | `sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu.swift` · `sources/Projects/UI/Component/Overlays/ModalOverlay.swift` · `sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift` · `sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift` · `sources/Projects/UI/Component/Overlays/WebSheet.swift` |
  | Scaffolds | `sources/Projects/UI/Component/Scaffolds/BottomActionBar/BottomActionBar.swift` · `sources/Projects/UI/Component/Scaffolds/ScreenContainer/ScreenContainer.swift` · `sources/Projects/UI/Component/Scaffolds/ScreenHeader/ScreenHeader.swift` · `sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift` |
- [X] T060 [no-write] [S2] [S3] T059에서 고정으로 남긴 각 지점을 저장소 상대경로와 이유로
      정리해 T086의 입력으로 보고한다. 첫 항목은 Responsive Layout Spec §07이 확정한
      `TabShell` 알약 폭 298이다. 이 작업은 파일을 만들지 않는다 — `tools/design-rules/`는
      작업 패키지 10이 소유한다 (T059 의존)
- [X] T061 [P] [S3] `sources/Projects/UI/Tests/Component/Unit/Displays/TagBadgeContractTests.swift`를
      새로 만들어 `Displays` 역할 폴더의 첫 테스트를 추가한다 — 표현 값과 상태 비보관을
      검증한다 (SC-010)
- [X] T062 [P] [S5] `sources/Projects/UI/Tests/Component/Unit/Controls/AccessibilityContractTests.swift`를
      새로 만들어 아이콘 전용 버튼의 접근성 라벨 필수성, 조작 컴포넌트의 44pt 히트 영역,
      선택 특성 노출을 검증한다 (SC-009). Dynamic Type API 부재는 소스 정적 계약이므로
      T084의 `dynamic-type` 규칙과 T087 fixture가 검증한다 (FR-037)

### 정리와 패키지 검증

- [X] T063 [no-write] [S3] [S5] `"$project_build_runner" test`를 실행하고, 역할 폴더 6종
      (`Scaffolds`·`Overlays`·`Controls`·`CollectionItems`·`Indicators`·`Displays`) 각각에
      최소 1개의 테스트 파일이 있는지 `sources/Projects/UI/Tests/Component/Unit/` 아래에서
      확인한다 (SC-010). 이어서 규격 컴포넌트 인덱스의 UI 소관 30항목이 지정된 역할 폴더에
      존재하는지 대조한다 — 착수 시점 결손은 `Chip`·`BookmarkButton`·`ChoiceResultRow`
      3건뿐이고 배치 불일치는 0건이므로, 작업 패키지 5 완료 후 결손 0을 확인하면 통과다
      (SC-007 · FR-025). 마지막으로 상태 매트릭스 10행이 각각 담당 작업을 갖는지 확인한다 —
      `ActionButton` 3행 T051 · `TextField` T049 · `Chip` T038 · `ChoiceAnswerOption` T052 ·
      `ChoiceResultRow` T042 · `LearningSetRow`·`SelectionCard` T053 · `TabShell.Item` T054 ·
      `EmptyState` T055 (FR-024). 이어서 `Component/` 프로덕션 SwiftUI `Button` 사용 파일
      집합이 T057 표와 일치하고 모두 `PressOverlayStyle`을 적용했는지 확인한다 (FR-020)

**진행 점검**: T049~T063의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 7: UIComponent — 규격 밖 15종 판정 ⛔

**⛔ 진행 중 승인이 필요할 수 있는 단위다.** 삭제로 판정한 항목이 나오면 지우기 전에 대상과
근거를 제시하고 사용자 승인을 받는다. 유지·이동 판정은 승인 없이 진행한다(Constitution
원칙 7 · R-13).

**목표**: 규격 인덱스에 없는 기존 컴포넌트 15종을 사용처 조사로 유지·이동·삭제 중 하나로
판정하고, 유지 대상이 Component 공통 계약을 지키게 한다.

**소유 경로**: `sources/Projects/UI/Component/**`, `docs/conventions/ui-component.md`

**관련 변경 시나리오**: S4

**독립 검증**: 15종 전부가 판정과 근거를 갖고, `Component/` 아래에 `@State`를 선언하는 타입이
남지 않는다.

### 구현

- [X] T064 [no-write] [S4] 아래 15개 파일 집합의 `sources/Projects` 전체 사용처를 조사해
      각각 유지·이동·삭제로 판정하고, 판정과 근거를 PR 본문 기록 대상으로 정리한다. 기본값은
      유지이며 삭제는 사용처가 0건인 경우로 한정한다. 이 목록이 T065~T067의 변경 대상
      전체이며 이 밖의 파일을 이 단위에서 만들거나 지우지 않는다 (FR-029 · SC-008)

  | 컴포넌트 | 현재 경로 |
  | --- | --- |
  | `SelectionCardStyle` | `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCardStyle.swift` |
  | `AccountActionRow` | `sources/Projects/UI/Component/Controls/AccountActionRow/AccountActionRow.swift` · `AccountActionRow+Constant.swift` |
  | `LabeledTextField` | `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift` |
  | `SelectableSettingRow` | `sources/Projects/UI/Component/Controls/SelectableSettingRow/SelectableSettingRow.swift` · `SelectableSettingRow+Constant.swift` |
  | `LaunchLogo` | `sources/Projects/UI/Component/Displays/LaunchLogo.swift` |
  | `OnboardingMockup` | `sources/Projects/UI/Component/Displays/OnboardingMockup/OnboardingMockup.swift` · `OnboardingMockup+Constant.swift` |
  | `RubricView` | `sources/Projects/UI/Component/Displays/RubricView/RubricView.swift` · `RubricView+Constant.swift` |
  | `SplashView` | `sources/Projects/UI/Component/Displays/SplashView.swift` |
  | `WebContentView` | `sources/Projects/UI/Component/Displays/WebContentView.swift` |
  | `WebSheet` | `sources/Projects/UI/Component/Overlays/WebSheet.swift` |
  | `TabShellPreviewItem` | `sources/Projects/UI/Component/Scaffolds/TabShell/TabShellPreviewItem.swift` |
  | `ScreenContainer` | `sources/Projects/UI/Component/Scaffolds/ScreenContainer/ScreenContainer.swift` (T026이 옮긴 뒤 경로) |
  | `StyledText` | `sources/Projects/UI/Component/Displays/StyledText.swift` |
  | `EmptyState` | `sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift` · `EmptyState+Constant.swift` |
  | `PolicyAgreementRow` | `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift` · `PolicyAgreementRow+Constant.swift` |
- [X] T065 [S4] 유지 판정한 컴포넌트가 Component 공통 계약을 지키게 정렬한다 — 특히
      `sources/Projects/UI/Component/Displays/LaunchLogo.swift`의 `@State private var isVisible`과
      `sources/Projects/UI/Component/Displays/SplashView.swift`의 `@State` 5개는 표시 상태
      보관 금지(FR-026)에 걸리므로 상위로 올리고 값과 콜백으로만 받게 바꾼다 (T064 의존)
- [X] T066 [no-write] [S4] T064 표의 15종을
      [UIComponent 컨벤션 §3.2](../../docs/conventions/ui-component.md)의 판정 순서와 다시
      대조해, 계획 시점 조사와 같이 역할 폴더 이동 대상이 0건인지 확인한다. 이동 필요 항목이
      발견되면 placeholder 경로로 옮기지 않고 이 작업을 미완료로 두며, `/speckit-tasks`로
      정확한 출발·도착 파일 경로 작업을 추가한 뒤 재개한다 (T064 의존)
- [X] T067 [S4] 삭제 판정한 컴포넌트가 있으면 대상·사용처 조사 결과·근거를 제시하고 사용자
      승인을 받은 뒤에만 파일을 삭제한다. 삭제 가능한 파일은 T064 표의 경로로 한정한다. 승인
      전에는 지우지 않으며, 삭제 대상이 없으면 이 작업은 변경 없이 완료한다 ⛔ (T064 의존)
- [X] T068 [S4] `docs/conventions/ui-component.md` §3.4 "현재 컴포넌트 배치" 표를 T065~T067의
      결과에 맞춰 갱신한다. 책임 패키지는 `UI`다

### 정리와 패키지 검증

- [X] T069 [no-write] [S4] `"$project_build_runner" build`와 `"$project_build_runner" test`를
      순차 실행하고, `grep -rn '@State' sources/Projects/UI/Component`가 `#Preview` 밖에서
      결과를 내지 않는지 확인한다 (SC-014)

**진행 점검**: T064~T069의 판정 결과, 변경 파일과 검증 결과를 보고하고 다음 실행 단위로
진행한다. 삭제 판정이 나오면 T067 전에 중단하고 승인을 요청한다.

---

## 작업 패키지 8: UIComponent + Feature — Sub View 2종 이관 ⚠

**⚠ 불가분한 다중 패키지 integration unit이다.** 하나의 목적(타입 이동)이며 UI에서의 삭제와
Feature에서의 추가를 나누면 두 타입이 어디에도 없는 중간 커밋이 생긴다. 그 커밋은 되돌리기
단위로 적절하지 않다. 두 타입은 UI 패키지 밖 사용처가 0건이라 호출부 수정을 유발하지
않는다(R-07).

**통합 검증**: 두 패키지를 포함한 전체 빌드가 성공하고, `Component/` 계층에 상태를 소유하는
타입이 남지 않는다.

**목표**: 규격이 Sub View로 분류한 `QuestionPrompt`·`EssayAnswerInput`을 Feature로 옮겨
Component 계층의 소유 규칙을 회복한다.

**소유 경로**: `sources/Projects/UI/Component/Displays/QuestionPrompt.swift`,
`sources/Projects/UI/Component/Controls/EssayAnswerInput/**`,
`sources/Projects/Feature/Quiz/Views/**`, `docs/conventions/file-vocabulary.md`,
`docs/conventions/ui-component.md`

**관련 변경 시나리오**: S4

**독립 검증**: 전체 빌드가 성공하고 두 타입이 `Feature/Quiz/Views/`에만 존재한다.

### 구현

- [X] T070 [S4] `sources/Projects/Feature/Quiz/Views/QuestionPrompt.swift`를 새로 만들어
      기존 `sources/Projects/UI/Component/Displays/QuestionPrompt.swift`의 구현을 Sub View로
      옮긴다. 이 저장소의 디렉터리·파일 컨벤션에 맞춰 다시 작성하고 참조 구현을 그대로 복사해
      넣지 않는다 (FR-030)
- [X] T071 [S4] `sources/Projects/Feature/Quiz/Views/AnswerEditor.swift`를 새로 만들어 기존
      `sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput.swift`의 구현을
      규격의 Sub View 이름 `AnswerEditor`로 옮긴다. 자기 영역의 상태(`text`·포커스)를 Sub View가
      소유한다 (FR-030)
- [X] T072 [no-write] [S4]
      `sources/Projects/UI/Component/Displays/QuestionPrompt.swift`와
      `sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput.swift`를
      재확인한다. 계획 시점 조사에서 별도 추출할 무상태 조각은 0건이고,
      `sources/Projects/UI/Component/Indicators/ProgressSegments.swift`는 이미 독립
      컴포넌트이므로 새 UI 파일을 만들지 않는다는 결과를 보고한다 (FR-031)
      (T070·T071 의존)
- [X] T073 [S4] `sources/Projects/UI/Component/Displays/QuestionPrompt.swift`를 삭제한다
      (T070·T072 의존)
- [X] T074 [S4] `sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput.swift`와
      `sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput+Constant.swift`를
      삭제한다 (T071·T072 의존)
- [X] T075 [S4] `docs/conventions/file-vocabulary.md` §3의 형태 어휘 표 `Feature/<기능>/` 행에
      `Views/`(Screen을 구성하는 Sub View) 항목을 추가한다. 책임 패키지는 `Feature`다
- [X] T076 [S4] `docs/conventions/ui-component.md` §3.4 표의 `Controls/` 행에서
      `EssayAnswerInput`을, `Displays/` 행에서 `QuestionPrompt`를 제거한다. 책임 패키지는
      `UI`다

### 정리와 패키지 검증

- [X] T077 [no-write] [S4] `"$project_build_runner" build`로 UI와 Feature를 포함한 전체 빌드가
      성공하는지 확인하고, `Component/` 계층에 상태를 소유하는 타입이 남지 않았는지
      확인한다

**진행 점검**: T070~T077의 변경 파일과 통합 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 9: Feature — 공개 API 변경에 따른 호출부 복구

**목표**: UI 공개 API 변경으로 깨진 Feature 호출부를 복구한다. 호출 형태만 맞추고 화면 동작·
흐름·상태 전이는 바꾸지 않는다(FR-040).

**소유 경로**: `sources/Projects/Feature/**`

**관련 변경 시나리오**: S4

**독립 검증**: Feature 패키지를 포함한 전체 빌드와 기존 `FeatureTests`가 통과하고, 화면 흐름
관련 테스트의 기대값이 바뀌지 않는다.

### 구현

- [X] T078 [no-write] [S4] `rg`로 `sources/Projects/Feature`의 `EffectToken` 직접 참조를
      다시 확인해 계획 시점과 같이 0건인지 보고한다. `GradientToken`은 값과 `all`이 그대로이고
      T009의 `gradient4` 사용처도 0건이므로 Feature 호출부 복구 대상이 아니다
- [X] T079 [no-write] [S4] `rg`로 `sources/Projects/Feature`의 UIComponent `TextField`·
      `IconPlainButton`·`IconGlassButton` 직접 호출을 다시 확인해 계획 시점과 같이 0건인지
      보고한다. 결과가 생기면 이 작업을 완료하지 않고 `/speckit-tasks`로 정확한 소비 파일
      경로를 추가한다
- [X] T080 [S4] `ScreenContainer`가 화면 좌우 여백을 소유하게 되었으므로(T026) 여백을 중복
      적용하는 화면에서 제거한다 — `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`,
      `sources/Projects/Feature/Onboarding/Screens/PositionSelectionScreen.swift`,
      `sources/Projects/Feature/Onboarding/Screens/CareerSelectionScreen.swift`,
      `sources/Projects/Feature/Onboarding/Screens/TutorialScreen.swift` (FR-027)
- [X] T081 [S4] 골격 컴포넌트 공개 계약 변경(T030~T034)으로 깨진 아래 정확한 소비 파일을
      새 인자 형태에 맞춘다 — `sources/Projects/Feature/MainShell/Screens/MainShellScreen.swift`,
      `sources/Projects/Feature/Onboarding/Screens/CareerSelectionScreen.swift`,
      `sources/Projects/Feature/Onboarding/Screens/LegalAgreementScreen.swift`,
      `sources/Projects/Feature/Onboarding/Screens/PositionSelectionScreen.swift`,
      `sources/Projects/Feature/ProjectRegistration/Screens/GenerationReminderSheet.swift`

### 정리와 패키지 검증

- [X] T082 [no-write] [S4] `"$project_build_runner" build`와 `"$project_build_runner" test`를
      순차 실행해 앱 전체가 컴파일되고 기존 테스트가 통과하는지 확인한다 (SC-012)

**진행 점검**: T078~T082의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 진행한다.

---

## 작업 패키지 10: 패키지 밖(tools) — 금지 패턴 정적 검사 도구

**목표**: "…하는 곳이 0곳" 성공 기준 5개를 실행 가능한 판정 수단으로 고정한다. 대상 코드가
정렬된 뒤에 규칙을 고정해 규칙이 현재 상태를 기술하게 한다(plan 순서 근거).

**소유 경로**: `tools/design-rules/**`, `tools/repository-paths/repository-paths.json`,
`tools/repository-paths/bin/repository-paths.sh`,
`tools/repository-paths/tests/test-no-hardcoded-paths.sh`, `tools/script-tests/core/tests.sh`,
`tools/githooks/pre-commit`, `tools/githooks/pre-commit.d/design-rules.sh`,
`tools/githooks/pre-commit.d/enabled`, `tools/githooks/hook-management/tests/test-pre-commit.sh`

**관련 변경 시나리오**: S1, S2, S3, S4

**독립 검증**: 검사기가 현재 저장소에서 종료 코드 0을 반환하고, 위반 fixture에서 실패한다.
`tools/script-tests/bin/run.sh`와 `tools/script-verification/bin/run.sh`가 통과한다.

**작성 기준**: [write-project-scripts 스킬](../../.agents/skills/write-project-scripts)의
아키텍처·컨벤션과 `tools/script-verification/tests/test-architecture-boundaries.sh`의 선례를
따른다(R-04). 검사에는 `rg`를 사용한다.

### 구현

- [ ] T083 `tools/design-rules/bin/run.sh`를 새로 만들어 공개 진입점을 제공한다 — 인자 없이
      실행하면 전체 규칙을 검사하고, 위반이 없으면 종료 코드 0, 있으면 0이 아닌 코드와 함께
      위반 파일·행·규칙 이름을 출력한다. 추적 대상 소스·문서와 Git index를 변경하지 않는다
- [ ] T084 `tools/design-rules/core/rules.sh`를 새로 만들어 규칙 8종을 정의한다 —
      `fixed-width`(`sources/Projects/UI/Component/**`의 `.frame(width:`, 허용 목록 예외) ·
      `canvas-constant`(`sources/Projects/UI/Component/**` 프로덕션 코드에서
      103·154·34·127·53을 폭·높이·safe area 차원으로 쓰는 문맥, `#Preview` 제외,
      승인된 154 고정 폭은 `allowed-fixed-width` 예외) ·
      `hardcoded-metric`(`sources/Projects/UI/Component/**`의 토큰 대체 가능 수치 리터럴,
      `*+Constant.swift` 예외) · `component-state`(`@State` 선언, 예외 없음) ·
      `component-margin`(`LayoutToken.margin` 또는 `designSystemScreenMargin(` 사용,
      `Scaffolds/ScreenContainer` 예외) ·
      `component-haptic`(햅틱 호출, 예외 없음) ·
      `vertical-fill`(`sources/Projects/UI/Component/**`의 `.frame(maxHeight: .infinity)`,
      `config/allowed-vertical-fill` 예외) ·
      `dynamic-type`(`sources/Projects/UI/**`의 `dynamicTypeSize`·`ScaledMetric`·`relativeTo:`·
      `UIFontMetrics`, 예외 없음). `component-margin`과 `component-state`는
      `#Preview` 블록 안의 사용을 위반으로 잡지 않는다 — 현재 저장소의 `LayoutToken.margin`
      사용처 대부분이 프리뷰 스캐폴딩이다 (T083 의존)
- [ ] T085 `tools/design-rules/core/run.sh`를 새로 만들어 규칙 실행과 결과 집계·보고를
      담당하는 내부 계층을 둔다 (T084 의존)
- [ ] T086 `tools/design-rules/config/allowed-fixed-width`와
      `tools/design-rules/config/allowed-vertical-fill`을 새로 만들어 허용 목록을 저장소
      상대경로와 이유로 한 줄씩 기록한다. 전자는 T060이 정리한 고정 폭 목록이며 첫 항목은
      `TabShell` 알약 폭 298이고, 후자는 T059가 보고한 세로 채움 목록이며 첫 항목은
      `sources/Projects/UI/Component/Overlays/WebSheet.swift`(웹 콘텐츠는 채움이 정당)다
      (T059·T060 의존)
- [ ] T087 `tools/design-rules/tests/test-design-rules.sh`를 새로 만들어 회귀 테스트를 둔다 —
      위반이 있는 fixture에서 실패하고 없는 fixture에서 통과하는지 규칙 8종 각각에 대해
      검사해 규칙이 조용히 무력화되는 것을 막는다. `canvas-constant` fixture는
      `.frame(height: 34)` 같은 레이아웃 사용은 실패하고 `EffectToken` blur 34와
      `safeAreaBottom` 34 테스트 입력은 통과함을 함께 단정한다. 파일 이름이
      `tools/script-tests/core/tests.sh`의 수집 패턴(`*/tests/test-*.sh`)에 맞아야 자동
      수집된다 (T084 의존)
- [ ] T088 `tools/repository-paths/repository-paths.json`에
      `"GIT_IT_DESIGN_RULE_RUNNER": "tools/design-rules/bin/run.sh"` 항목을 추가한다
      (T083 의존)
- [ ] T089 `tools/repository-paths/bin/repository-paths.sh`의 허용 키 목록에
      `GIT_IT_DESIGN_RULE_RUNNER`를 추가한다 (T088 의존)
- [ ] T090 `tools/repository-paths/tests/test-no-hardcoded-paths.sh`의 키 열거 목록에
      `GIT_IT_DESIGN_RULE_RUNNER`를 추가한다 (T089 의존)
- [ ] T091 `tools/script-tests/core/tests.sh`의 `unset` 목록에 `GIT_IT_DESIGN_RULE_RUNNER`를
      추가해 CI의 중앙 경로 환경변수가 fixture를 덮어쓰지 않게 한다 (T088 의존)
- [ ] T092 `tools/githooks/pre-commit.d/design-rules.sh`를 새로 만들어 pre-commit 단계
      스크립트를 추가한다. `GIT_IT_DESIGN_RULE_RUNNER`로 진입점을 읽어 실행한다 (T089 의존)
- [ ] T093 `tools/githooks/pre-commit`의 알려진 단계 이름 목록(약 52행의 `case` 분기)과 고정
      실행 순서(약 65행의 `for` 목록)에 `design-rules`를 추가한다. 실행 순서는
      `script-tests` → `swift-format` → `design-rules` → `build` → `compile`로 둔다 — 포맷
      결과가 검사 대상 파일을 바꾸므로 `swift-format` 뒤에 놓는다 (T092 의존)
- [ ] T094 `tools/githooks/pre-commit.d/enabled`의 단계 설명 주석과 순서 안내에
      `design-rules`(디자인 규격 금지 패턴 검사)를 추가한다. **주석 처리된 활성화 목록은 바꾸지
      않는다** — pre-commit 활성화는 이 기능의 범위 밖 협업 결정이다(R-05 · SC-013) (T093 의존)
- [ ] T095 `tools/githooks/hook-management/tests/test-pre-commit.sh`의 단계 열거(약 26·111행의
      `for step in ...`)와 기대 실행 순서 단정(약 49·78행의 `expected`)에 `design-rules`를
      반영한다 (T093 의존)

### 정리와 패키지 검증

- [ ] T096 [no-write] `design_rule_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_DESIGN_RULE_RUNNER)`로
      진입점을 읽고 `"$design_rule_runner"`를 실행해 종료 코드 0을 확인한다. 위반이 남으면
      해당 규칙이 가리키는 작업 패키지로 돌아가 정렬한다 (SC-005 · SC-006 · SC-011 · SC-014)
- [ ] T097 [no-write] `./tools/script-tests/bin/run.sh`와
      `./tools/script-verification/bin/run.sh`를 순차 실행해 새 도구의 회귀 테스트와 셸 정적
      검사가 통과하는지 확인한다. 최초 실행이면
      `./tools/script-verification/bin/prepare-tools.sh`를 먼저 실행한다

**진행 점검**: T083~T097의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 10의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할
마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 작업 패키지 10의 마지막 커밋 단위에 배정한다. 모든
검증과 필수 `after_implement` hook(`speckit.swift-format.run`)을 마친 뒤 그 단위를 최종
commit한다. 이미 파일 변경 단위가 모두 commit된 단순 재개에서는 `tasks.md` 완료 표시를 위한
별도 최종 검증 단위를 둔다. 읽기 전용 전체 검증은 반복 승인 없이 같은 실행에서 이어서
수행한다.

- [ ] T098 [no-write] `git status --porcelain`을 기록하고 `make tuist`를 실행한 뒤 다시 비교해
      추적 파일 변경이 없는지 확인한다. 파생 workspace·project·심볼릭 링크·cache 갱신만
      허용하며, 추적 파일 diff가 생기면 이 작업을 완료로 표시하지 않는다
- [ ] T099 [no-write] `"$project_build_runner" build` → `compile` → `test`를 순차 실행하고
      결과를 기록한다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 병렬 실행하지
      않는다 (SC-012)
- [ ] T100 [no-write] `"$design_rule_runner"`를 다시 실행해 최종 상태에서 규칙 8종 전부가
      종료 코드 0을 내는지 확인한다 (SC-005 · SC-006 · SC-011 · SC-014 · FR-018 · FR-037)
- [ ] T101 [no-write] 변경 시나리오별 독립 수용 기준을 검증한다 — S1은
      `DesignTokenSet.current.validate()` 빈 배열과 토큰 이름 100% 존재, S2는 지원 기기 9종의
      레이아웃 변수 범위와 종횡비·웹 콘텐츠 밖의 세로 채움 0곳(FR-018), S3은 신설 4종 계약 테스트와 상태 매트릭스 및 규격 인덱스 30항목의
      역할 폴더 배치(SC-007), S4는 `Component/`에 상태
      보관·화면 여백·햅틱 0곳, S5는 44pt 히트 영역과 접근성 라벨 계약 및 고정 pt 유지·
      Dynamic Type 연동 API 0곳(FR-037). 판정 절차는
      [quickstart.md](./quickstart.md)를 따른다
- [ ] T102 [no-write] PR 본문에 넣을 두 표를 확정한다 — (1) 규격 적용으로 표시가 달라진 항목의
      화면·값·변경 전후 표. 최소 `TextField` 높이 56→52, 홈 2열 카드 154→`gridColumn2`, 상단
      스크림 103→`topScrimHeight` 세 건을 포함한다(SC-015). (2) 규격 밖 15종의 유지·이동·삭제
      판정과 근거(SC-008). 저장소에 새 문서 파일을 만들지 않는다(FR-041 · R-14)
- [ ] T103 [no-write] PR 본문의 미검증 범위에 다음 세 건을 남긴다 — pre-commit 단계는 등록만
      하고 활성화하지 않았다(SC-013 판정 기준 축소, R-05), 타이포·폰트의 규격 위반 2건은
      "알려진 차이"로 남겼다(R-12), 기존 테스트 함수의 영문 이름은 바꾸지 않았다(R-10).
      Constitution 원칙 3에 따른 기록이다

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

채택한 순서와 근거:

| # | 단위 | 패키지 | 근거 |
| --- | --- | --- | --- |
| 1 | 토큰 카탈로그와 적용 확장 ⛔ | DesignSystem | 값이 없으면 그 위의 모든 작업이 하드코딩으로 시작한다 |
| 2 | 런타임 레이아웃 변수 | DesignSystem | `LayoutMetrics`가 `LayoutToken`을 입력으로 쓴다 |
| 3 | 테스트 target 신설 ⚠ | DesignSystem + Tuist manifest | 골격을 바꾸기 전에 검증 수단을 확보한다 |
| 4 | 골격 반응형 정렬 | UIComponent | 골격은 20개 화면 전부가 공유해 파급이 가장 크다 |
| 5 | 컴포넌트 신설 4종 | UIComponent | 없는 컴포넌트가 화면 구현의 병목이다 |
| 6 | 상태·접근성·고정 폭 정렬 | UIComponent | 기존 컴포넌트 정리라 되돌리기 쉽다 |
| 7 | 규격 밖 15종 판정 ⛔ | UIComponent | 앞 단위가 끝나야 대상과 계약이 확정된다 |
| 8 | Sub View 2종 이관 ⚠ | UIComponent + Feature | Component 계층의 상태 소유를 마지막으로 없앤다 |
| 9 | Feature 호출부 복구 | Feature | UI 공개 계약이 확정된 뒤에야 호출 형태를 맞출 수 있다 |
| 10 | 정적 검사 도구 | 패키지 밖 (tools) | 정렬이 끝난 뒤 규칙을 고정해야 규칙이 현재 상태를 기술한다 |

⚠ = 불가분한 다중 패키지 integration unit · ⛔ = 진행 중 승인이 필요할 수 있는 단위

- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지
  않는다. 확정된 기능 범위의 후속 단위와 읽기 전용 전체 검증은 연속 진행한다.
- **승인이 필요한 지점은 둘이다.** 둘 다 삭제이며 Constitution 원칙 7의 명시적 승인 대상이다.
  - 작업 패키지 1의 **T009** — `gradient4` 제거. `all` 밖이고 사용처가 0건이지만 삭제이므로
    지우기 전에 승인을 받는다.
  - 작업 패키지 7의 **T067** — 규격 밖 15종 중 삭제로 판정한 항목. 대상과 근거를 제시하고
    승인을 받는다. 유지·이동 판정은 승인 없이 진행한다.

### 변경 시나리오 추적성

| 시나리오 | 작업 |
| --- | --- |
| S1 — 디자인 토큰 정본 완성 | T001~T014, T019~T022, T025 |
| S2 — 반응형 레이아웃 변수와 골격 정렬 | T015~T020, T023~T025, T026~T037, T059, T060 |
| S3 — 규격 컴포넌트 신설과 상태 계약 | T038~T063, T059, T060 |
| S4 — 계층 소유 규칙 정합 | T064~T082 |
| S5 — 접근성 계약 준수 | T057, T058, T062, T063 |

변경 시나리오는 관련된 모든 패키지가 완료된 뒤 T101에서 독립 수용 기준으로 검증한다.

### 실행 단위 내부 실행

- 테스트를 포함하면 같은 패키지 구현 전에 작성하고 예상한 이유로 실패하는지 확인한다. 단,
  작업 패키지 3은 검증 수단 자체를 만드는 단위이므로 T019·T020(target 등록) 뒤에 테스트를
  작성한다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용한다.
- 같은 파일을 변경하는 작업과 Red → Green 의존 작업은 순차 실행한다.
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 단위의 미완료 작업을 하나의 목적과
  독립적인 rollback 경계를 갖는 순서화된 커밋 단위로 묶는다. 구현과 직접 관련된 테스트는 같은
  단위에 둘 수 있지만 기능, 구조 정리, rename과 자동 포맷은 목적이 다르면 분리한다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 단위의
  검증과 `[X]` 표시를 완료한 뒤 해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을
  확인하기 전에는 다음 단위를 시작하지 않는다.
- 단위를 시작할 때 작업 ID와 파일 경로를 snapshot하며 checkbox가 `[X]`가 된 뒤에도 해당
  단위가 commit되거나 중단될 때까지 같은 범위를 유지한다. Commit 성공 뒤 단위 경로와
  tasks.md에 staged·unstaged·untracked 잔여가 없어야 다음 단위로 진행할 수 있다.
- 작업 패키지 10의 마지막 단위는 전체 완료 검증과 필수 `after_implement`
  hook(`speckit.swift-format.run`)이 끝날 때까지 commit하지 않는다. Hook이 현재 단위 파일에
  만든 허용된 포맷 결과를 재검증해 같은 최종 commit에 포함하며, commit 성공 뒤 hook을 다시
  실행하지 않는다.

### 병렬 실행 예시

같은 실행 단위 안에서만 사용한다.

- **작업 패키지 1**: T003 · T004 · T005 · T006을 동시에 진행한다(서로 다른 토큰 파일, T001에
  의존하지 않음). 이어서 T012 · T013을 동시에 진행한다.
- **작업 패키지 3**: T021 · T022 · T023을 동시에 진행한다(서로 다른 테스트 파일, T019·T020
  완료 후).
- **작업 패키지 4**: T035 · T036을 동시에 진행한다(서로 다른 테스트 파일).
- **작업 패키지 5**: T040 · T041을 동시에 진행하고, 이어서 T044 · T045 · T046을 동시에
  진행한다.
- **작업 패키지 6**: T052 · T053 · T054 · T055를 동시에 진행하고, 이어서 T061 · T062를 동시에
  진행한다.

작업 패키지 1의 T001→T002, T007, T008과 T010→T011처럼 참조 의존이 있는 작업은 병렬로 실행하지
않는다. 서로 다른 작업 패키지의 작업은 어떤 경우에도 병렬 실행하지 않는다.

## 구현 전략

1. 먼저 중단 단위와 tasks.md 전체 diff를 분류하고 blob hash와 diff를 기준선으로 고정한다.
   재개 단위가 없으면 작업 패키지 1의 T001부터 시작한다.
2. 그 실행 단위의 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다. 단,
   작업 패키지 10의 마지막 단위는 전체 완료 검증과 필수 hook까지 열린 상태로 유지한다.
4. 실행 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 다음 단위로
   이어간다.
5. 작업 패키지 7의 T067에서 삭제 판정이 나오면 파일을 지우기 전에 중단하고 명시적 승인을
   요청한다. 그 밖의 경계에서 새 권한이 필요해지면 변경을 시작하기 전에 중단한다.
6. 작업 패키지 10에서 전체 읽기 전용 검증(T098~T103)과 필수 `after_implement` hook을 실행하고
   결과를 재검증한 뒤 마지막 단위를 최종 commit한다.

## 최소 가치 범위

**작업 패키지 1(시나리오 1 — 디자인 토큰 정본 완성)**이 최소 가치 범위다. 빈 토큰 3종과 누락
16종을 채우면 Feature 개발자가 테두리·불투명도·그림자 값을 하드코딩할 이유가 사라진다. 단독
검증은 `DesignSystem` 빌드로 성립하며, 검증 테스트까지 포함하려면 작업 패키지 3을 함께 마친다.

새 권한이 필요하지 않으므로 여기서 멈추지 않고 확정된 기능 범위 안에서 연속 진행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다. `docs/` 디렉터리나 glob은 구현 권한이 아니다.
- 변경 시나리오의 독립성은 유지하되 구현 단위는 논리적 실행 단위다.
- 커밋 단위는 단일 패키지가 기본이며 작업 패키지 3과 8만 다중 패키지를 포함한다.
- 문제 해결과 암묵지 기록(`docs/spec-kit/024-ui-design-spec-alignment/trouble-shooting.md`,
  `tacit-knowledge.md`)은 구현 작업 ID로 만들지 않는다. 기록 조건이 충족되면 각 전용 기록
  스킬이 별도로 처리한다.
