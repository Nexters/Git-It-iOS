# 계약: 금지 패턴 정적 검사

**소유**: `tools/design-rules` · **진입점**: `GIT_IT_DESIGN_RULE_RUNNER`

명세의 "…하는 곳이 0곳" 성공 기준을 사람 판단이 아니라 실행 가능한 검사로 고정한다.
저장소 셸 도구 관례(`bin` · `core` · `tests` · `config` 계층)를 따른다.

## 실행 계약

- 인자 없이 실행하면 전체 규칙을 검사한다.
- 위반이 없으면 종료 코드 0, 있으면 0이 아닌 코드와 함께 위반 파일·행·규칙 이름을 출력한다.
- 저장소가 추적하는 소스·문서와 Git index를 변경하지 않는다(읽기 전용).
- `tools/githooks/pre-commit.d/design-rules.sh` 단계로 등록한다. `enabled` 목록의 활성화
  여부는 이 기능에서 바꾸지 않는다(research R-05).

## 규칙

| 이름 | 대상 | 금지 | 허용 예외 |
| --- | --- | --- | --- |
| `fixed-width` | `sources/Projects/UI/Component/**` | `.frame(width:` | `config/allowed-fixed-width`에 파일·이유와 함께 등록된 곳 |
| `canvas-constant` | `sources/Projects/UI/Component/**` 프로덕션 레이아웃 | 103 · 154 · 34 · 127 · 53을 폭·높이·safe area 차원으로 사용 | `#Preview` 제외, 승인된 154 고정 폭은 `allowed-fixed-width` 적용 |
| `hardcoded-metric` | `sources/Projects/UI/Component/**` | 토큰으로 대체 가능한 수치 리터럴 | `*+Constant.swift` |
| `component-state` | `sources/Projects/UI/Component/**` | `@State` 선언 | 없음 |
| `component-margin` | `sources/Projects/UI/Component/**` | `LayoutToken.margin` 또는 `designSystemScreenMargin(` 사용 | `Scaffolds/ScreenContainer` |
| `component-haptic` | `sources/Projects/UI/Component/**` | 햅틱 호출 | 없음 |
| `vertical-fill` | `sources/Projects/UI/Component/**` | `.frame(maxHeight: .infinity)` | `config/allowed-vertical-fill`에 파일·이유와 함께 등록된 곳 |
| `dynamic-type` | `sources/Projects/UI/**` | `dynamicTypeSize` · `ScaledMetric` · `relativeTo:` · `UIFontMetrics` | 없음 |

`hardcoded-metric`의 대상이 `Component/**`이므로 `DesignSystem/Extensions/TextStyleResolver.swift`의
유니코드 범위 상수는 대상 밖이다. 타이포는 이 기능의 범위가 아니다(research R-12).

`canvas-constant`는 숫자 문자열 자체가 아니라 레이아웃 의미를 판정한다. 따라서
`EffectToken.sheetElevation`의 blur 34, 지원 기기 fixture의 `safeAreaBottom` 34와 같은
DesignSystem 값·테스트 입력은 대상 밖이다. `RepositoryCard`처럼 규격이 고정 폭 154를
허용한 가로 스크롤 카드는 `allowed-fixed-width` 등록을 함께 확인한다.

`component-margin`이 두 패턴을 모두 잡아야 하는 이유는 프로덕션 코드가 `LayoutToken.margin`을
직접 쓰지 않기 때문이다. `DesignSystem/Extensions/View+LayoutToken.swift`의
`designSystemScreenMargin()`이 `padding(.horizontal, LayoutToken.margin)`을 감싸고 있고,
`Component/**`의 프로덕션 사용처는 `LayoutToken.margin` 직접 사용 0곳 · `designSystemScreenMargin()`
2곳(`Overlays/SheetSurface/SheetSurface.swift`, `Scaffolds/BottomActionBar/BottomActionBar.swift`)이다.
직접 사용만 검사하면 규칙이 통과하면서 실제 FR-027 위반 2건을 놓친다. `LayoutToken.margin`
문자열은 `Component/**`에 20여 곳 더 있으나 전부 `#Preview` 안이라 프리뷰 제외 규칙이 걸러낸다.

`vertical-fill`은 FR-018(세로 간격과 컴포넌트 높이를 화면 높이와 무관하게 유지)의 판정 수단이다.
실측 결과 `Component/**`의 프로덕션 `.frame(maxHeight: .infinity)`는 `Overlays/WebSheet.swift`
2곳뿐이고 웹 콘텐츠는 채움이 정당하므로 허용 목록의 첫 항목이 된다.

`dynamic-type`은 FR-037의 회귀 방지 기준이며 현재 위반 0건이다. 접근성 작업 중 Dynamic Type
대응을 새로 넣지 않는지 검사한다. `.font(.system(size:))`는 고정 pt이므로 위반이 아니다.

## 허용 목록 계약

예외는 코드 주석이 아니라 `config/` 아래 목록 파일로 관리한다. 한 줄에 저장소 상대경로와
이유를 적는다. 목록이 늘어나는 것이 diff에 드러나야 리뷰에서 잡을 수 있기 때문이다.

`config/allowed-fixed-width`의 첫 등록 항목은 `TabShell` 알약 폭 298이다. Responsive Layout
Spec §07이 고정으로 확정했다. `config/allowed-vertical-fill`도 같은 형식으로 관리하며 첫
항목은 `Overlays/WebSheet.swift`다.

## 검사 도구

기존 선례와 같이 `rg`(ripgrep)를 사용한다.
`tools/script-verification/tests/test-architecture-boundaries.sh`가 같은 방식으로 금지된
의존을 검사한다.

## 자기 검증

`tools/design-rules/tests/`에 회귀 테스트를 둔다. 위반이 있는 fixture에서 실패하고 없는
fixture에서 통과하는지 검사해, 규칙이 조용히 무력화되는 것을 막는다.
`tools/script-tests/bin/run.sh`가 이를 실행한다.
