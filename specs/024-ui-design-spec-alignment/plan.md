# 구현 계획: UI 패키지 디자인 규격 정렬

**Git-flow 유형**: `feature`

**브랜치**: `feature/ui-design-spec-alignment`

**날짜**: 2026-09-02 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/024-ui-design-spec-alignment/spec.md`의 기능 명세

## 요약

네 규격 문서를 정본으로 삼아 UI 패키지를 정렬한다. 핵심은 세 가지다.

1. **토큰을 채운다.** `BorderToken`·`OpacityToken`·`EffectToken`이 선언만 있고 값이 빈
   배열이라 이 세 종류를 쓰려면 하드코딩이 강제된다. 여기에 누락 16종을 더한다.
2. **레이아웃을 계산식으로 바꾼다.** 정본 캔버스 360 × 800의 고정값(스크림 103, 2열 카드
   154)이 실기기 어디와도 맞지 않는다. 화면 폭·높이·safe area 넷만 입력으로 받아 파생값을
   유도하는 `LayoutMetrics`를 새로 만들고 골격 컴포넌트가 이를 읽게 한다.
3. **계약을 규격에 맞춘다.** 컴포넌트 4종을 신설하고, 상태를 소유해 Component 정의를
   위반하는 2종을 Feature로 옮기며, "0곳" 성공 기준을 실행 가능한 정적 검사로 고정한다.

조사에서 드러난 제약 두 가지가 계획을 바꿨다. `DesignSystem`에 테스트 target이 없어 토큰
검증을 담을 곳이 없고(R-03), pre-commit 단계가 전부 비활성이라 SC-013의 판정 기준을 좁혀야
한다(R-05). 또 참조 구현이 Responsive Layout Spec과 어긋나는 곳이 있어 그대로 옮기면
SC-005를 위반한다(R-06). 세로 예산은 UIUX Guide §7.3의 산식에 따라 누락된
`tabBarClearance` 92를 복원한다(R-15).

**타이포와 폰트는 범위 밖이다.** 명확화 2차에서 현행 유지로 확정했다. `TextStyleToken`과
`FontFamilyToken`의 값·구성, 문자 단위 폰트 선택, 행간 환산, 번들 자산을 바꾸지 않는다.
조사에서 확인한 규격 위반 두 건(숫자가 라틴 폰트로 렌더되지 않음, 미번들 폰트 자산 잔존)은
명세의 "알려진 차이"에 기록만 하고 성공 기준에서 제외한다(R-12).

## 기술 맥락

**언어/버전**: Swift 6, iOS 26.0 이상

**주요 의존성**: SwiftUI. `UIComponent`는 Lottie를 target 의존성으로 갖는다. `DesignSystem`은
번들 폰트(Noto Sans KR · Plus Jakarta Sans, Regular·Medium·Bold) 외 외부 의존성이 없다.
폰트 자산과 등록 방식은 이 기능에서 바꾸지 않는다.

**저장소**: N/A — 이 기능의 값 모델은 전부 인메모리이며 영속성이 없다.

**테스트**: Swift Testing. 기존 `UIComponentTests`에 더해 `DesignSystemTests` target을
신설한다(R-03). 셸 도구는 `tools/script-tests`와 `tools/script-verification`이 검증한다.

**대상 플랫폼**: iOS 26.0+, 지원 기기 폭 375 – 440 · 높이 667 – 956. 주력 402 × 874.

**프로젝트 유형**: 모바일 앱(iOS)의 UI 패키지. Tuist 기반 멀티 패키지 구조.

**성능 목표**: 해당 없음. 이 기능은 값 정의와 계약 정렬이며 런타임 성능 목표를 바꾸지 않는다.
`LayoutMetrics`의 파생값은 순수 산술이라 화면당 한 번 계산한다.

**제약 조건**: 단일 다크 테마 유지. Dynamic Type 미지원, 고정 pt 사용. 정본 캔버스
360 × 800을 크기 기준으로 쓰지 않는다. 공개 API 변경 시 deprecated 별칭을 남기지 않고
Feature 호출부를 같은 단위에서 복구한다.

**규모/범위**: UI 패키지 Swift 파일 108개(컴포넌트 41 · 토큰 12 · 적용 확장 9 · 테스트 12).
토큰 항목 약 100개 중 변경 대상은 9개 카테고리이며 `TextStyleToken`·`FontFamilyToken`은
제외한다. 컴포넌트 45개(신설 4 · 이동 2 · 판정 15). 고정 폭 사용처 56곳.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

### 0단계 전 점검 — 통과

| 원칙 | 점검 | 결과 |
| --- | --- | --- |
| 1. 명시적인 경계 | UI는 어디에도 의존하지 않고 Feature가 UI에 의존한다. 이 계획은 그 방향을 바꾸지 않는다 | 통과 |
| 2. 상태와 데이터 안전성 | 컴포넌트에서 상태 소유를 제거하는 방향이라 소유자가 명확해진다 | 통과 |
| 3. 검증 가능한 변경 | 동작 변경에 빌드·테스트 결과를 남긴다. quickstart가 절차를 정의 | 통과 |
| 4. 스킬별 수정 경로 | 이 계획은 `plan.md`·`research.md`·`data-model.md`·`quickstart.md`·`contracts/**`만 작성했다 | 통과 |
| 5. Spec-Kit 범위 | 구현 파일 경로는 기록만 하고 수정하지 않았다 | 통과 |
| 6. 한국어 산출물 | 모든 산출물을 한국어로 작성. 식별자·명령어·경로는 원문 유지 | 통과 |
| 7. 위험 기반 실행 단위 | 아래 실행 단위 표 참조. 다중 패키지 단위 2개에 분리 불가 근거 기록 | 통과 |
| 8. Git-flow 네임스페이스 | `feature/ui-design-spec-alignment`. `/speckit-specify`가 생성·검증 | 통과 |
| 9. 세션 지식 기록 | 현재 기록 조건 미충족. 계획 산출물로 만들지 않음 | 해당 없음 |
| 10. 책임 기반 네이밍 | 토큰·컴포넌트 이름은 규격이 확정한 외부 고정 명칭이라 원문 보존. 아래 주석 참조 | 통과 |

**원칙 10 관련 주석**: 규격 문서가 확정한 토큰·컴포넌트 이름(`brandAccent`, `ChoiceResultRow`
등)은 디자인 시스템의 고정 명칭이므로 보존한다. 다만 `gradient1`~`gradient3`처럼 책임을
드러내지 않는 이름이 규격에 남아 있다. 이 기능은 규격 정렬이 목적이므로 이름을 임의로 바꾸지
않고, 개선이 필요하면 규격 문서 갱신과 함께 별도로 다룬다. 기존 테스트 함수의 영문 이름도
같은 이유로 이 기능에서 바꾸지 않는다(R-10).

**브랜치 네임스페이스**: `feature/`를 사용하며 `/speckit-specify`가 명세 산출물 생성 전에
현재 HEAD에서 직접 생성하고 검증했다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정했다. 구현 파일은 아래에 경로만 기록한다.

**Git 실행 직렬화**: 검증 명령 세 개(`build`·`compile`·`test`)는
`sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다. quickstart에 명시했다.

**커밋 단위 구현**: 아래 실행 단위 표가 순서와 경계를 정의한다. 각 단위는 하나의 목적과
되돌릴 수 있는 결과를 갖는다.

### 명확화 2차 반영 후 재점검 — 통과

명세의 2차 명확화(타이포·폰트 현행 유지, 변경 목록은 PR 본문, 규격 밖 컴포넌트 판정은 구현 중)를
반영한 뒤 다시 확인했다. 새 위반은 없다. 세 가지를 기록한다.

- **원칙 7(위험 기반 실행 단위)**: 단위 7의 삭제 판정과 단위 1의 `gradient4` 제거에만 승인이 필요하다.
  "승인이 필요한 지점"에 명시했다. 그 밖의 단위는 반복 승인 없이 진행한다.
- **원칙 4(스킬별 수정 경로)**: 화면 변경 목록이 PR 본문으로 확정되어 `tasks.md`에 배정할
  파일이 없어졌다. 저장소 파일을 만들지 않으므로 수정 경로 문제가 사라졌다.
- **원칙 3(검증 가능한 변경)**: 타이포·폰트를 범위에서 제외하면서 확인된 규격 위반 2건이
  남는다. 명세의 "알려진 차이"에 근거와 함께 기록했고, 원칙 3에 따라 PR에 미검증 범위로
  남긴다.

### 1단계 후 재점검 — 통과

설계 산출물을 만든 뒤 다시 확인했다. 새 위반은 없다. 다만 두 가지를 기록한다.

- **`DesignSystemTests` target 신설**이 Tuist 공용 manifest를 건드린다. 원칙 7이 요구하는
  대로 분리 불가 근거와 통합 검증을 실행 단위 표에 명시했다.
- **SC-013의 판정 기준을 좁혔다.** pre-commit이 비활성이므로 "등록되어 있어 활성화 시
  실행된다"로 판정한다. 활성화 자체는 협업 영향이 있는 별도 결정이라 이 기능에서 하지
  않는다(R-05). 이는 명세를 약화하는 것이 아니라 실행 가능한 형태로 확정한 것이며, 원칙 3에
  따라 PR에 미검증 범위로 남긴다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/024-ui-design-spec-alignment/
├── spec.md                  # 기능 명세(/speckit-specify, /speckit-clarify)
├── plan.md                  # 이 파일(/speckit-plan 산출물)
├── research.md              # 0단계 산출물 — 조사 항목 15건 해소
├── data-model.md            # 1단계 산출물 — 값 모델 8종
├── quickstart.md            # 1단계 산출물 — 검증 실행 가이드
├── contracts/               # 1단계 산출물
│   ├── design-token-catalog.md
│   ├── layout-metrics.md
│   ├── component-public-api.md
│   └── design-rule-checks.md
├── checklists/requirements.md
├── design-specs/            # 규격 문서 4종(입력)
├── reference-swift/         # 참조 구현 41개 파일(입력)
└── tasks.md                 # 2단계 산출물(/speckit-tasks가 생성)
```

입력 중 Figma 정본 원본 `private/넥터 Git-it (MCP).fig`는 `.gitignore` 대상이라 저장소에
포함하지 않는다. 규격 문서에 없는 값을 원본에서 확인했다면 그 값과 노드 근거를 산출물에
옮겨 적어, 원본이 없는 환경에서도 검증이 성립하게 한다.

### 소스 코드(저장소 루트)

```text
sources/Projects/UI/
├── DesignSystem/
│   ├── Tokens/                      # BorderToken · OpacityToken · EffectToken 값 채움
│   │                                # ColorToken · SemanticColorToken · LayoutToken
│   │                                # CornerRadiusToken · ControlSizeToken 항목 추가
│   │                                # GradientToken: all은 규격과 일치, gradient4만 제거
│   │                                # TextStyleToken · FontFamilyToken 변경 없음
│   ├── Layout/                       # 신설 — LayoutMetrics
│   ├── Extensions/                   # 신설 확장 — 테두리·불투명도·그림자 적용
│   │                                 # TextStyleResolver·FontRegistration 변경 없음
│   └── Resources/Fonts/              # 변경 없음
├── Component/
│   ├── Scaffolds/                    # ScreenContainer(LayoutMetrics 주입) · ScreenHeader
│   │                                 # TabShell · BottomActionBar
│   ├── Overlays/                     # ScreenEdgeScrim · SheetSurface · ModalOverlay
│   ├── Controls/                     # 신설 Chip · PressOverlayStyle · BookmarkButton
│   │                                 # TextField 재작도 · EssayAnswerInput 제거
│   ├── CollectionItems/              # 신설 ChoiceResultRow
│   ├── Indicators/
│   └── Displays/                     # QuestionPrompt 제거
└── Tests/
    ├── DesignSystem/Unit/            # 신설 — 토큰·레이아웃 변수 검증
    └── Component/Unit/               # Scaffolds · Displays 테스트 추가

sources/Projects/Feature/
└── Quiz/Views/                       # 신설 — QuestionPrompt · AnswerEditor 이관

sources/Tuist/ProjectDescriptionHelpers/
├── Projects/UIModuleName.swift       # DesignSystemTests target 등록
└── AllTestsScheme.swift              # 같은 target을 전체 테스트 scheme에 연결

tools/
├── design-rules/                     # 신설 — bin · core · tests · config
├── repository-paths/repository-paths.json  # GIT_IT_DESIGN_RULE_RUNNER 등록
└── githooks/pre-commit.d/design-rules.sh   # 단계 등록(활성화는 하지 않음)
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 그대로 쓴다. UI 프로젝트는 `DesignSystem`과
`UIComponent` 두 target을 유지하고 여기에 `DesignSystemTests`를 더한다. `LayoutMetrics`는
`LayoutToken`을 입력으로 쓰므로 `DesignSystem`에 두고, SwiftUI Environment 키와 주입은
`UIComponent`의 `ScreenContainer`가 소유한다(R-01·R-02). 검증 도구는 패키지가 아니라
`tools/` 아래 독립 셸 도구로 두어 기존 도구 계층 관례를 따른다(R-04).

## 실행 단위

적용 패키지의 의존성 위상 순서는 `DesignSystem` → `UIComponent` → `Feature`다. 근거는
[아키텍처 문서](../../docs/architecture.md)의 의존성 표(`Feature`는 `UI`에 의존, `UI`는 무의존)와
`UIModuleName.swift`의 target 의존성(`UIComponent`가 `DesignSystem` 참조)이다.

| # | 단위 | 패키지 | 목적 | 주요 경로 | 검증 |
| --- | --- | --- | --- | --- | --- |
| 1 | 토큰 카탈로그와 적용 확장 ⛔ | DesignSystem | 빈 토큰 3종과 누락 16종 해소, 뷰 적용 확장 정렬, `gradient4` 제거 | `DesignSystem/Tokens/**` · `DesignSystem/Extensions/**` | 빌드 |
| 2 | 런타임 레이아웃 변수 | DesignSystem | `LayoutMetrics` 신설 | `DesignSystem/Layout/**` · `docs/conventions/file-vocabulary.md` | 빌드 |
| 3 | **테스트 target 신설** ⚠ | DesignSystem + Tuist manifest | 토큰·레이아웃 검증을 담을 곳 | `Tuist/.../UIModuleName.swift` · `AllTestsScheme.swift` · `UI/Tests/DesignSystem/Unit/**` | `make tuist` 후 test |
| 4 | 골격 반응형 정렬 | UIComponent | 스크림·탭바·시트를 계산식으로 | `Component/Scaffolds/**` · `Component/Overlays/**` | 빌드·test |
| 5 | 컴포넌트 신설 4종 | UIComponent | `Chip`·`PressOverlayStyle`·`BookmarkButton`·`ChoiceResultRow` | `Component/Controls/**` · `Component/CollectionItems/**` · `docs/conventions/ui-component.md` | test |
| 6 | 상태·접근성·고정 폭 정렬 | UIComponent | 상태 매트릭스 10행, 44pt, 고정 폭 제거, `TextField` 재작도 | `Component/**` · `Tests/Component/Unit/**` | test |
| 7 | 규격 밖 15종 판정 ⛔ | UIComponent | 사용처 조사 후 유지·이동·삭제 결정 | `Component/**` · `docs/conventions/ui-component.md` | 빌드·test |
| 8 | **Sub View 2종 이관** ⚠ | UIComponent + Feature | 상태 소유 타입을 Component 계층에서 제거 | `UI/Component/Displays/QuestionPrompt*` · `UI/Component/Controls/EssayAnswerInput*` · `Feature/Quiz/Views/**` · `docs/conventions/**` | 전체 빌드 |
| 9 | Feature 호출부 복구 | Feature | 공개 API 변경으로 깨진 호출 정정 | `Feature/**` | 전체 빌드 |
| 10 | 정적 검사 도구 | 패키지 밖 (tools) | "0곳" 기준을 실행 가능하게 | `tools/design-rules/**` · `repository-paths.json` · `pre-commit.d/design-rules.sh` | 셸 테스트 |

그 뒤에 파일 변경이 없는 `[no-write]` 전체 완료 검증을 둔다. 변경 목록은 PR 본문에 쓴다.

**계획 초안 12단위에서 10단위로 재구성한 근거**

- 초안 단위 1(토큰 값 채움)과 2(토큰 적용 확장)를 병합했다. `EffectToken`을 다중 레이어
  구조로 바꾸면 기존 `View+EffectToken.swift`가 `colorToken`·`offset`·`blur`·`spread`를 직접
  읽으므로 즉시 컴파일이 깨져, 단위 1이 자체 빌드 검증을 통과할 수 없다. 두 경로 모두
  DesignSystem 소유라 단일 패키지 단위는 유지된다.
- 초안 단위 12(전체 검증과 PR 본문)는 파일 변경 대상이 없고 변경 목록을 PR 본문에
  작성하므로(R-14) 패키지 단위가 아니라 `[no-write]` 전체 완료 검증으로 옮겼다.
- 이 재구성은 `tasks.md`가 확정한 구조이며 T001~T103의 단위 경계와 일치한다.

⚠ = 불가분한 다중 패키지 단위 · ⛔ = 진행 중 승인이 필요할 수 있는 단위

### 승인이 필요한 지점

Constitution 원칙 7에 따라 확정된 기능 범위의 후속 단위는 반복 승인 없이 진행한다. 이
계획에서 승인이 필요한 지점은 두 곳이다.

**단위 7에서 삭제 판정이 나올 때.** 규격 밖 15종 중 사용처가 없어 삭제가 타당한 항목이
나오면, 지우기 전에 대상과 근거를 제시하고 승인을 받는다. 유지·이동 판정은 승인 없이
진행한다.

**단위 1의 `gradient4` 제거.** `GradientToken.all`은 이미 규격 5종과 일치하고, `all`에
포함되지 않으면서 사용처가 0건인 `gradient4`만 제거 대상이다. 삭제이므로 실행 전에 확인을
받는다(spec FR-008).

두 지점 모두 삭제가 되돌리기 어려운 작업이라 원칙 7의 명시적 승인 대상이기 때문이다. 그
밖의 단위는 승인 게이트를 두지 않으며, 전체 읽기 전용 검증도 같은 실행에서 이어서 수행한다.

### 다중 패키지 단위의 분리 불가 근거

**단위 3 — 테스트 target 신설**: Tuist manifest에 target을 등록하는 변경과 그 target의 테스트
소스는 분리할 수 없다. manifest만 먼저 넣으면 `tuist generate`가 소스 없는 test target을
만들어 scheme이 빌드되지 않고, 소스만 먼저 넣으면 어느 target에도 속하지 않아 컴파일되지
않는다. `AllTestsScheme.swift`도 같은 이유로 함께 바꾼다. **통합 검증**: `make tuist` 실행 후
전체 테스트 scheme이 새 target을 포함해 통과하는지 확인한다. `make tuist`는 파생 산출물만
갱신하므로 실행 전후 Git 상태를 비교해 추적 파일 diff가 생기지 않았는지 확인한다.

**정확한 경로**:
`sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`,
`sources/Projects/UI/Tests/DesignSystem/Unit/Tokens/DesignTokenSetValidationTests.swift`,
`sources/Projects/UI/Tests/DesignSystem/Unit/Tokens/DesignTokenCatalogTests.swift`,
`sources/Projects/UI/Tests/DesignSystem/Unit/Layout/LayoutMetricsTests.swift`.

**단위 8 — Sub View 2종 이관**: 하나의 목적(타입 이동)이며 UI에서의 삭제와 Feature에서의
추가를 나누면 두 타입이 어디에도 없는 중간 커밋이 생긴다. 그 커밋은 되돌리기 단위로
적절하지 않다. 두 타입은 UI 패키지 밖 사용처가 0건이라 호출부 수정은 유발하지 않는다(R-07).
**통합 검증**: 두 패키지를 포함한 전체 빌드가 성공하고, 정적 검사의 `component-state` 규칙이
위반 0을 보고한다.

**정확한 경로**:
`sources/Projects/Feature/Quiz/Views/QuestionPrompt.swift`,
`sources/Projects/Feature/Quiz/Views/AnswerEditor.swift`,
`sources/Projects/UI/Component/Displays/QuestionPrompt.swift`,
`sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput.swift`,
`sources/Projects/UI/Component/Controls/EssayAnswerInput/EssayAnswerInput+Constant.swift`,
`docs/conventions/file-vocabulary.md`, `docs/conventions/ui-component.md`.

### 패키지에 속하지 않는 파일의 배정

| 파일 | 배정 단위 | 근거 |
| --- | --- | --- |
| `sources/Tuist/.../UIModuleName.swift` | 3 | target 정의와 그 소스는 함께 있어야 생성·빌드된다 |
| `sources/Tuist/.../AllTestsScheme.swift` | 3 | 같은 이유. 새 target이 전체 테스트에 연결돼야 검증이 성립 |
| `tools/design-rules/**` | 10 | 대상 코드가 정렬된 뒤 규칙을 고정해야 규칙이 현재 상태를 기술한다 |
| `tools/repository-paths/repository-paths.json` | 10 | 진입점 등록이 도구 추가와 분리되면 대상 없는 경로 키가 남는다 |
| `tools/githooks/pre-commit.d/design-rules.sh` | 10 | 같은 이유 |

화면 변경 목록(FR-041 · SC-015)은 PR 본문에 작성하므로 저장소 파일이 아니다(R-14).
`tasks.md`에 경로를 배정할 대상이 없고, 전체 완료 검증 T102가 작성을 지시하되 파일 수정
작업으로 만들지 않는다.

### 순서 근거

- 1 → 2는 값·적용 → 파생의 단방향 의존이다. 토큰이 없으면 적용 확장이 참조할 대상이
  없고, `LayoutMetrics`는 `LayoutToken`을 입력으로 쓴다.
- 3을 4보다 앞에 두는 이유는 골격을 바꾸기 전에 검증 수단을 확보하기 위해서다. 스크림·탭바
  계산이 기기별로 맞는지는 테스트 없이 확인하기 어렵다.
- 5 → 6은 공용 `PressOverlayStyle`을 먼저 만든 뒤 기존 버튼 계열에 적용하는 의존이다.
  신설 컴포넌트가 화면 구현을 막는 병목이므로 5를 먼저 두고, 6과 7의 기존 컴포넌트 정리를
  이어서 수행한다.
- 10을 9 다음에 두는 이유는 검사기를 먼저 만들면 정렬이 끝나지 않은 코드에서 즉시 실패해
  개발 중 신호가 무의미해지기 때문이다.
- 타이포·폰트 관련 단위는 없다. 범위에서 제외했다(R-12).

## 복잡성 추적

> 헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다.

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 새 테스트 target `DesignSystemTests` 추가 | 토큰과 레이아웃 변수는 `DesignSystem`에 있는데 이 target에 테스트가 없다. SC-001~SC-004를 검증할 곳이 없다 | `UIComponentTests`에 얹으면 target 추가는 피하지만 컴포넌트 테스트가 토큰 검증까지 떠안아 실패 소재가 흐려지고 `AllTestsScheme` 구성이 실제 책임과 어긋난다 |
| 새 셸 도구 `tools/design-rules` 추가 | "…하는 곳이 0곳" 성공 기준 5개가 실행 가능한 판정 수단 없이는 검증 불가능한 문구로 남는다 | SwiftLint 커스텀 규칙은 `tools/swift-style`가 외부 벤더링 저장소라 갱신 시 충돌한다. 단위 테스트로 소스를 문자열로 읽으면 빌드 산출물 경로에 의존하게 된다 |
