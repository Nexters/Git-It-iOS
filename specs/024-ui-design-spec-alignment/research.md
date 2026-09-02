# 조사: UI 패키지 디자인 규격 정렬

**기능 브랜치**: `feature/ui-design-spec-alignment`

**날짜**: 2026-09-02

**명세**: [spec.md](./spec.md)

명세의 기술 맥락에서 확정되지 않은 항목과, 계획 중 저장소를 조사해 새로 드러난 제약을
정리한다. 각 항목은 결정·근거·검토한 대안 순으로 기록한다.

## R-01. 레이아웃 변수의 전달 방식

**결정**: 값 타입 `LayoutMetrics`를 `DesignSystem` target에 두고, 화면 폭·높이·safe area
상하 네 값을 받는 이니셜라이저와 파생값 계산 프로퍼티를 갖게 한다. 뷰 계층 전달은 SwiftUI
Environment 키 하나로 하고, 주입은 `ScreenContainer`가 `GeometryReader`와 safe area에서 읽어
한 번 수행한다.

**근거**: 파생값 계산은 순수 함수라 SwiftUI 없이 단위 테스트로 검증할 수 있어야 한다
(FR-043, SC-004). 값 타입으로 분리하면 지원 기기 9종의 입력을 표로 넣어 min–max 범위를
검사할 수 있다. 전달을 Environment로 하는 이유는 `ScreenEdgeScrim`·`TabShell`·`SheetSurface`가
화면 골격 안쪽 깊이에 놓여 모든 중간 뷰에 인자를 관통시키면 컴포넌트 공개 계약이 화면 구조에
오염되기 때문이다. 참조 구현이 이미 `@Environment(\.safeAreaInsetTop)`으로 같은 방향을
택했다(`reference-swift/Component/Overlays/ScreenEdgeScrim.swift`).

**검토한 대안**:
- 모든 골격 컴포넌트에 명시 파라미터로 전달 — 계약이 명시적이지만 호출부마다 같은 값을
  반복 전달해야 하고, 중간 컴포넌트가 자기가 쓰지 않는 값을 받아 넘기게 된다.
- `UIScreen.main`이나 전역 싱글턴에서 직접 읽기 — 테스트에서 값을 주입할 수 없고 iOS 26에서
  권장되지 않는다. 명세의 "화면 렌더링 없이 검증"(FR-043)과 충돌한다.
- 개별 safe area 값만 Environment로 넘기고 파생값은 각 컴포넌트가 계산 — 같은 계산식이
  여러 컴포넌트에 흩어져 SC-005(정본 고정값 0곳)를 판정하기 어려워진다.

## R-02. `LayoutMetrics`가 속할 target

**결정**: `DesignSystem` target에 둔다. Environment 키와 주입 지점은 `UIComponent`의
`ScreenContainer`가 소유한다.

**근거**: `LayoutMetrics`의 계산식은 `LayoutToken.margin`·`gutter`를 입력으로 쓴다. 토큰과
같은 target에 있어야 의존 방향(`DesignSystem` ← `UIComponent`)을 거스르지 않는다. 값 자체는
SwiftUI에 의존하지 않으므로 참조 구현의 "Tokens는 SwiftUI를 import하지 않는다" 원칙을
지킬 수 있고, Environment 키만 SwiftUI 확장으로 분리한다.

**검토한 대안**: `UIComponent`에 두기 — 토큰 상수를 역참조하게 되고, 토큰만 검증하는
테스트에서 레이아웃 계산을 함께 다룰 수 없다.

## R-03. 토큰을 검증할 테스트 target 부재

**결정**: `DesignSystemTests` target을 새로 만든다. Tuist manifest
(`sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`)와
`AllTestsScheme.swift`에 함께 등록한다.

**근거**: 현재 UI 프로젝트의 target은 `DesignSystem`·`UIComponent`·`UIComponentTests` 셋뿐이고,
`DesignSystem`에는 테스트 target이 없다. SC-001~SC-004는 토큰 값과 레이아웃 계산식을
검증해야 하는데 이들은 `DesignSystem`에 있다. `UIComponentTests`에서 `import DesignSystem`으로
접근할 수는 있으나, 컴포넌트 테스트 target이 토큰 검증까지 떠안으면 실패 원인의 소재가
흐려지고 `AllTestsScheme`의 구성도 실제 책임과 어긋난다.

**검토한 대안**: `UIComponentTests`에 토큰 테스트를 함께 두기 — target 추가 없이 즉시
가능하지만 위 이유로 기각. 다만 target 신설이 부담이면 되돌릴 수 있는 선택지로 남겨 둔다.

## R-04. 금지 패턴 정적 검사의 위치와 형태

**결정**: `tools/design-rules/`에 저장소 셸 도구 관례(`bin`·`core`·`tests`·`config` 계층)로
새로 만든다. 검사 대상은 `sources/Projects/UI`와 `sources/Projects/Feature`의 Swift 소스이며
`rg`(ripgrep)로 금지 패턴을 찾는다. 허용 예외는 `config/`의 목록 파일로 관리한다.

**근거**: 저장소에 이미 같은 형태의 선례가 있다.
`tools/script-verification/tests/test-architecture-boundaries.sh`가 `rg`로 금지된 의존을
검사하고 실패 시 종료 코드를 반환한다. `tools/repository-paths`가 도구 진입점을
`GIT_IT_*_RUNNER` 키로 노출하는 관례도 이미 있으므로 같은 방식으로 등록한다.
`tools/swift-style`는 외부 저장소를 벤더링한 Swift 패키지라 프로젝트 고유 규칙을 넣기에
적절하지 않다.

**검토한 대안**:
- SwiftLint 커스텀 규칙으로 추가 — `tools/swift-style`가 외부 저장소라 저장소 고유 규칙을
  섞으면 이후 갱신에서 충돌한다.
- 단위 테스트로 소스 문자열을 읽어 검사 — 테스트 target이 자기 소스를 파일로 읽는 구조가
  되어 빌드 산출물 경로에 의존하게 되고, Swift 파일이 아닌 대상으로 확장할 수 없다.

## R-05. pre-commit 검증 경로가 현재 비활성

**결정**: 새 검사를 `tools/githooks/pre-commit.d/`의 단계로 등록하되, `enabled` 목록의
활성화 여부는 바꾸지 않는다. SC-013은 "등록되어 있어 활성화 시 실행된다"로 판정한다.

**근거**: `tools/githooks/pre-commit.d/enabled`의 네 단계(`script-tests`·`swift-format`·
`build`·`compile`)가 모두 주석 처리되어 있고 파일에 "현재는 커밋 검증을 비활성화한
상태입니다"라고 적혀 있다. 이 상태를 이 기능에서 바꾸는 것은 명세 범위 밖의 개발 환경
결정이며, 되돌리기 어려운 협업 영향(모든 커밋이 느려짐)을 만든다.

**영향**: SC-013의 문구가 "실행된다"이므로 계획 단계에서 판정 기준을 위와 같이 좁힌다.
활성화 여부는 사용자 결정 사항으로 남긴다.

## R-06. 참조 구현과 Responsive Layout Spec의 불일치

**결정**: 두 입력이 충돌하면 Responsive Layout Spec을 따른다. 참조 구현은 값의 출처일 뿐
최종 계약이 아니다.

**근거**: 확인된 불일치가 있다. `reference-swift`의 `ScreenEdgeScrim`은 하단 높이를
`Constant.bottomWithTabBar = 127` / `bottomWithoutTabBar = 34`로 고정하는데, Responsive
Layout Spec은 `safeAreaBottom + (탭바 ? 93 : 0)`으로 계산하고 정본 고정값 34·127을 명시적으로
금지한다(SC-005). 참조 구현은 상단만 safe area를 반영하고 하단은 정본 값을 남겨 두었다.

**영향**: 참조 구현을 그대로 옮기면 SC-005를 위반한다. 컴포넌트별로 두 문서를 대조해야 하며,
특히 골격 계층 8종은 Responsive Layout Spec의 표를 정본으로 삼는다.

**근거 우선순위**: 규격 문서 → Figma 정본 원본(`private/넥터 Git-it (MCP).fig`) → 참조 구현
순으로 신뢰한다. 참조 구현은 값의 출처를 보여줄 뿐 계약이 아니다. 원본은 저장소에 커밋하지
않으므로, 원본에서만 확인 가능한 값을 쓸 때는 그 값과 노드 근거를 산출물에 함께 적는다.

## R-07. `QuestionPrompt`·`EssayAnswerInput`의 이동 대상과 위험

**결정**: `sources/Projects/Feature/Quiz/Views/`로 옮긴다.

**근거**: 두 타입은 UI 패키지 밖에서 **사용처가 하나도 없다**(`sources/Projects`에서 UI
패키지 자신을 제외한 참조 0건). `Feature/Quiz`에는 현재 `Reducers/QuizFeature.swift` 하나뿐이고
화면이 아직 없다. 따라서 이동은 호출부 수정을 유발하지 않으며 위험이 낮다. 규격의 Sub View
카탈로그가 두 타입을 각각 객관식·서술형 화면의 구성 단위로 지정하므로 `Quiz` 아래가 맞다.

**검토한 대안**: 사용처가 없으므로 삭제 — 규격이 Sub View로 존재를 명시하고 있고, 화면 구현
기능에서 다시 만들어야 하므로 폐기가 아니라 이관이 맞다.

## R-08. 적용 패키지와 구현 순서

**결정**: `DesignSystem`(UI) → `UIComponent`(UI) → `Feature` 순으로 구현한다. 패키지에 속하지
않는 Tuist manifest와 검증 도구는 아래 표대로 책임 단위에 배정한다.

**근거**: [아키텍처 문서](../../docs/architecture.md)의 의존성 표에서 `Feature`는 `UI`에
의존하고 `UI`는 어디에도 의존하지 않는다. UI 프로젝트 내부에서는 `UIComponent`가
`DesignSystem`을 target 의존성으로 참조한다(`UIModuleName.swift`). 따라서 토큰이 먼저 서야
컴포넌트가 그것을 참조할 수 있고, 컴포넌트 공개 계약이 확정돼야 Feature 호출부를 맞출 수 있다.

| 패키지 밖 파일 | 배정 단위 | 이유 |
| --- | --- | --- |
| `sources/Tuist/.../UIModuleName.swift` · `AllTestsScheme.swift` | DesignSystem 테스트 target 신설 단위 | manifest와 테스트 소스가 함께 있어야 target이 생성·빌드된다 |
| `tools/design-rules/**` | 검증 도구 단위 | 검사 대상 코드가 정렬된 뒤에 규칙을 고정해야 규칙이 현재 상태를 기술한다 |
| `tools/repository-paths/repository-paths.json` | 검증 도구 단위 | 새 도구 진입점 등록이 도구 추가와 분리되면 진입점이 없는 경로 키가 남는다 |
| `tools/githooks/pre-commit.d/design-rules.sh` | 검증 도구 단위 | 같은 이유 |

## R-09. 고정 폭 허용 예외의 판정 기준

**결정**: Responsive Layout Spec 원칙 P4를 기본 판정 기준으로 쓴다. 허용 대상은 종횡비가
깨지면 안 되는 요소, 곧 이미지 썸네일·Lottie 애니메이션·가로 스크롤 카드와 §07이 직접
확정한 `TabShell` 298이다. 그 밖의 `.frame(width:)`는 정적 검사가 실패로 판정하며, 예외는
`tools/design-rules/config/`의 허용 목록에 파일·이유와 함께 등록해야 통과한다.

**근거**: 현재 `Component/` 아래 `.frame(width:` 사용처가 56곳이라 전수 판단이 필요하다.
목록을 코드 밖 설정으로 두면 예외가 늘어나는 것이 diff에 드러나 리뷰에서 잡힌다.
`TabShell` 알약 폭 298은 Responsive Layout Spec이 §07에서 명시적으로 고정으로 확정했으므로
허용 목록의 첫 항목이 된다.

## R-10. 테스트 함수 이름 규칙

**결정**: 새로 추가하는 테스트 함수 이름은 [테스트 컨벤션](../../docs/conventions/test.md)에
따라 한국어 동작 문장으로 쓰고, Swift Testing을 사용한다. 기존 테스트의 영문 이름은 이
기능에서 일괄 변경하지 않는다.

**근거**: 컨벤션은 한국어 동작 문장을 요구하는데 기존
`Tests/Component/Unit/Controls/LayoutConstantContractTests.swift` 등은
`` `action button sizes match figma`() `` 형태의 영문이다. 이름만 바꾸는 변경은 Constitution
원칙 10에 따라 동작 변경과 분리해야 하므로 이 기능에 섞지 않는다.

**영향**: 이 기능이 끝난 뒤에도 기존 테스트 이름의 컨벤션 위반이 남는다. 별도 기능으로
분리할 후보다.

## R-11. `GradientToken`의 규격 밖 항목

**결정**: `gradient4`만 제거하고 방향 상수는 그대로 둔다. 삭제이므로 실행 전에 확인을
받는다(FR-008).

**근거**: 사용처 조사를 이 조사 단계에서 이미 끝냈다. `GradientToken.all`은 규격 5종
(`gradient1`·`gradient2`·`gradient3`·`topEdgeScrim`·`bottomEdgeScrim`)과 이미 일치하고
값 변경이 없다. `gradient4`는 public이지만 `all`에 없고 `reference-swift/GradientToken.swift`
에도 없으며 `sources/Projects` 전체 사용처가 0건이라 제거 대상이다.

방향 상수는 양쪽 모두 `private static let UnitPointRatio`이며 값도 같다 — 구현의
`topToBottomStart`(x 0.5, y 0)·`topToBottomEnd`(x 0.5, y 1)와 `reference-swift`의
`topStart`·`bottomEnd`가 같은 값의 다른 이름이다. `private`이라 공개 계약이 아니고 렌더링
결과가 같으므로 이름을 맞추지 않는다. 규격 토큰 목록에는 두 이름 모두 없다.

## R-12. 타이포 적용과 폰트 설정의 범위 제외

**결정**: 타이포 적용 규칙과 폰트 설정은 현행 구현을 유지한다. `TextStyleToken` 13종의 값,
`FontFamilyToken` 구성, 문자 단위 폰트 선택 로직, 행간 환산, 번들 폰트 자산을 모두 바꾸지
않는다.

**근거**: 사용자 결정이다(spec 명확화 세션 2차). 조사 중 규격 위반 두 건을 확인했으나 이
기능에서 해소하지 않기로 했다.

- `TextStyleResolver.font(for:style:)`가 유니코드 `0x41–0x5A`·`0x61–0x7A`만 라틴 폰트로
  보낸다. 숫자 `0x30–0x39`는 이 범위 밖이라 Noto Sans KR로 렌더된다. UIUX Guide는 "숫자는
  항상 라틴"을 요구하며 이유로 자폭 차이에 따른 정렬 흔들림을 든다.
- `DesignSystem/Resources/Fonts/`에 Light·SemiBold·Italic과 VariableFont 파일이 남아 있다.
  가이드는 Regular·Medium·Bold 3종만 번들하라고 한다. 다만 `UIModuleName.swift`의 리소스
  glob이 이미 3종만 지정하므로 앱 번들에는 포함되지 않고 저장소에만 남는다.

**영향**: 두 항목은 성공 기준에서 제외한다. 실행 단위에 타이포 관련 작업이 없다. 정적 검사의
`hardcoded-metric` 규칙이 `TextStyleResolver`의 유니코드 범위 상수를 위반으로 잡지 않도록
검사 대상에서 제외해야 한다.

**검토한 대안**: 규격 우선 원칙에 따라 숫자 폰트만이라도 고치기 — 사용자가 현행 유지를
명시적으로 지시했으므로 기각. "알려진 차이"로 기록해 후속 기능의 후보로 남긴다.

## R-13. 규격 밖 15종의 판정 시점과 삭제 승인

**결정**: 판정은 구현 중 각 컴포넌트의 사용처를 조사해 수행하고 근거를 PR 본문에 기록한다.
삭제로 판정한 항목은 실행 전에 사용자 승인을 받는다.

**근거**: 사용자 결정이다(spec 명확화 세션 2차). 15종 중 상당수는 사용처 조사로 기계적으로
갈린다 — `WebContentView`·`WebSheet`는 Figma 정본 범위 밖의 웹뷰이고 `TabShellPreviewItem`은
프리뷰 전용이다. 조사 없이 명세에 결과를 고정하면 구현 중 뒤집힐 가능성이 크다. 삭제만
승인 대상으로 두는 이유는 Constitution 원칙 7이 되돌리기 어려운 작업에 명시적 승인을
요구하기 때문이다.

**영향**: 실행 단위 7이 조사와 판정을 함께 수행한다. 삭제 판정이 나오면 그 시점에 중단하고
승인을 받으므로, 이 단위는 승인 없이 끝까지 진행된다고 가정할 수 없다.

## R-14. 화면 변경 목록의 산출물 위치

**결정**: PR 본문에 표로 기록한다. 저장소에 새 문서 파일을 만들지 않는다.

**근거**: 사용자 결정이다(spec 명확화 세션 2차). 규격 정렬로 화면이 왜 달라졌는지는 리뷰
시점에 필요한 정보이고, 저장소에는 PR 템플릿(`.github/PULL_REQUEST_TEMPLATE.md`)이라는 자리가
이미 있다. 문서 파일을 만들면 병합 후 갱신되지 않는 산출물이 하나 늘어난다.

**영향**: `tasks.md`에 변경 목록을 위한 파일 경로가 필요 없다. 마지막 실행 단위가 목록 작성을
지시하되 파일 수정 작업으로 만들지 않는다. Constitution 원칙 4의 "정확히 명시된 파일" 제약과
충돌하지 않는다.

## R-15. `contentBudget` 산식과 검증 범위

**결정**: `contentBudget(headerStyle:)`은
`screenHeight − safeAreaTop − safeAreaBottom − headerHeight − tabBarClearance(92)`로
계산한다. `sheetMaximumHeight`의 지원 기기 범위는 631–878로 검증한다.

**근거**: Responsive Layout Spec의 `METRICS` 행은 `− tabBarClearance(92)`를 문자식에서
누락했지만 같은 행의 예시 435·505·718은 모두 92를 뺀 결과다. UIUX Guide §7.3은
"탭바 92"를 포함한 전체 산식과 세 예시를 직접 적고 있어 의도가 명확하다.
`sheetMaximumHeight = screenHeight − safeAreaTop − 16`을 quickstart의 9개 입력에 적용하면
최솟값은 SE의 631, 최댓값은 17 Pro Max의 878이다.

**검토한 대안**: Responsive Layout Spec의 누락된 문자식만 따라 범위를 527–810으로 바꾸는
안은 동일 문서의 예시와 UIUX Guide의 명시적 산식을 모두 깨뜨리므로 기각했다.
