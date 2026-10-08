# 구현 계획: UIComponent 정적 팩토리 제거와 생성 경로 단일화

**Git-flow 유형**: `feature`

**브랜치**: `feature/ui-component-factory-removal`

**날짜**: 2026-09-20 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/039-ui-component-factory-removal/spec.md`의 기능 명세

## 요약

여섯 UIComponent(`ActionButton`, `IconGlassButton`, `TagBadge`, `LabeledCard`,
`ScreenEdgeScrim`, `StyledText`)의 정적 팩토리 30개를 제거하고, 변형 축을 enum 파라미터로 받는
초기화 메서드 하나로 공개 생성 경로를 통일한다. 호출부는 UI 111곳, Feature 117곳으로 합계
228곳이며 App에는 없다.

컴포넌트는 출발 상태가 세 갈래다. 그룹 A(`ActionButton`, `IconGlassButton`, `TagBadge`,
`StyledText`)는 공개 초기화 메서드와 공개 변형 enum을 이미 갖고 있어 제거와 호출부 전환만
필요하다. 그룹 B(`LabeledCard`)는 공개 초기화 메서드가 없고 `Style`이 `private`이라 둘 다
올려야 한다. 그룹 C(`ScreenEdgeScrim`)는 변형 타입 자체가 없어 `Edge`를 신규 정의한다.

팩토리 제거는 View 컨벤션의 생성 경로 규칙과 충돌하므로, 컨벤션 문서 7건(개정 5건 +
`screen-init.md` 문구 정리 1건 + `factory-criteria.md` 삭제 1건)을 같은 기능에 포함한다. 근거와 대안은
[research.md](./research.md), 공개 표면 대조는
[contracts/component-creation-api.md](./contracts/component-creation-api.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 6, iOS 26.0 이상

**주요 의존성**: SwiftUI, DesignSystem(프로젝트 내부 target). UIComponent는
`ComposableArchitecture`에 의존하지 않는다.

**저장소**: N/A — 이 기능은 저장 데이터를 다루지 않는다.

**테스트**: Swift Testing 기본, UI 자동화는 XCTest. 이번 변경은 새 테스트를 추가하지 않고
기존 테스트와 프리뷰의 호출부를 전환 범위에 포함한다.

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: 모바일 앱(Tuist 기반 멀티 패키지)

**성능 목표**: N/A — 표현 불변이 요구사항이며 성능 목표를 바꾸지 않는다.

**제약 조건**: 화면 표현 불변(FR-005). UI 공개 API 제거와 Feature 호출부 수정이 같은 커밋에
들어가야 중간 상태가 compile된다(FR-006).

**규모/범위**: 컴포넌트 6개, 팩토리 30개, 호출부 228곳, 영향 파일 UI 42개·Feature 51개(고유
파일 기준), 컨벤션 문서 7건(개정 5건 + 문구 정리 1건 + 삭제 1건).

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

**브랜치 네임스페이스**: `feature/ui-component-factory-removal`을 `/speckit-specify`가 기준선
`2b994f2`에서 직접 생성했다. 통과.

**허용 수정 경로**: 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
`contracts/**`만 생성했다. 소스·컨벤션 문서는 읽기만 했고 구현 경로는 아래 실행 단위 표에
기록했다. 통과.

**파일 삭제 권한**: 원칙 5는 `/speckit-implement`에 `tasks.md`가 명시한 파일의 **수정**
권한만 부여하고 삭제를 다루지 않는다. 단위 7의 `docs/conventions/view/factory-criteria.md`
삭제는 이 공백에 해당하므로, 구현 시점에 사용자 승인을 받고 PR에 원칙 3 예외로 기록한다
(FR-004a). Constitution 개정은 이 기능의 범위가 아니다.

**세션 지식 기록**: 계획 과정에서 View 컨벤션 충돌을 두 차례 발견해 명세로 되돌렸다. 반복
가능한 사건이므로 Constitution 원칙 9의 문턱을 충족할 수 있으나, 기록 여부는 전용 스킬의
판단에 맡기고 이 계획의 작업으로 만들지 않는다.

**Git 실행 직렬화**: 각 작업 단위는 `git commit`과 pre-commit을 하나씩만 실행한다. 이전 체인의
종료를 확인하기 전에 재시도하지 않는다. 통과.

**커밋 단위 구현**: 아래 "실행 단위"가 컴포넌트 단위 7개를 정의한다. 각 단위는 정확한 파일과
검증을 명시하며 단독으로 되돌릴 수 있다. 통과.

**컨벤션 근거**: 아래 "적용 컨벤션" 표에 기록했다. 팩토리 규칙 충돌은 명세
FR-004a~FR-004d와 FR-004b-1~FR-004b-3으로 해소됐고, 남은 기존 문서 불일치는
[research.md §7](./research.md)에 기록했다. 통과.

**책임 기반 네이밍**: 신규 공개 타입은 `ScreenEdgeScrim.Edge` 하나다. 소유 컴포넌트가 문맥을
제공하므로 이름에 컴포넌트 이름을 반복하지 않았고, 배치 위치라는 책임을 드러낸다. 근거와
기각한 대안은 [research.md §3](./research.md). 통과.

**실행 단위 진행**: 변경 패키지는 UI와 Feature 둘이며 사용 방향은 `Feature → UIComponent`다.
그룹 A 중 `ActionButton`과 그룹 C는 Feature 호출부가 0건이라 단일 패키지 단위이고, 나머지는
불가분한 다중 패키지 integration unit이다. 컨벤션 문서는 패키지에 속하지 않으므로 마지막
단위에 배정했다. 승인 게이트는 단위 7의 파일 삭제 하나뿐이었고(원칙 5가 승인 작업을 허용하는
"파괴적 작업"), 2026-09-20 세션에서 승인을 받아 해소했다. 통과.

### 1단계 설계 후 재점검

설계 산출물은 새 패키지, 새 의존성, 새 추상화 계층을 만들지 않는다. 신규 공개 타입은
`ScreenEdgeScrim.Edge`와 `LabeledCard`의 초기화 메서드뿐이며 둘 다 기존 컴포넌트가 이미
표현하던 변형을 파라미터로 드러내는 것이다. 복잡성 추적에 기록할 위반이 없다. 통과.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/conventions/view.md](../../docs/conventions/view.md) | §3 공개 생성 경로가 이번 변경의 직접 대상이다. §3.2 제목·링크 텍스트, §3.3 절과 링크, §6 체크리스트 2개 항목이 팩토리를 전제하므로 FR-004a에 따라 개정한다. §3 제목과 앵커는 `package-rules/ui.md`·`ui-component.md`·`ui-component/public-contract.md` 세 문서가 참조하므로 유지하고(FR-004b-1), §3.3 삭제 후 §3.4·§3.5는 재번호하지 않는다(FR-004b-3) |
| [docs/conventions/view/component-init.md](../../docs/conventions/view/component-init.md) | 제목과 본문이 생성 경로를 "init과 팩토리 둘"로 규정하고 팩토리 호출을 정본 예시로 제시한다. 제목을 포함해 초기화 메서드 하나로 개정하고, 삭제하는 `factory-criteria.md`의 팩토리 무관 규칙 두 건을 흡수한다 |
| `docs/conventions/view/factory-criteria.md` (삭제 완료, FR-004b-2에 따라 링크를 두지 않음) | "변형이 둘 이상일 때만 팩토리를 정의", "호출부의 기본 선택 수단은 팩토리". 문서 전문이 팩토리 규칙이므로 파일을 삭제하고, `@ViewBuilder` 기본 생성 경로와 기본값 배치 규칙만 `component-init.md`로 옮긴다. 삭제는 사용자 승인 사항이다 |
| [docs/conventions/view-declarations/internal-declarations.md](../../docs/conventions/view-declarations/internal-declarations.md) | 변형 enum을 소유 컴포넌트에 중첩하고 같은 파일에 둔다. 이름에 컴포넌트 이름을 반복하지 않는다 → `ScreenEdgeScrim.Edge` |
| [docs/conventions/view-declarations/style.md](../../docs/conventions/view-declarations/style.md) | 변형별로 갈리는 표현 값은 View의 `switch`가 아니라 변형 enum이 소유한다 → `Edge`가 `GradientToken`을 소유. 마지막 문장이 팩토리를 기본 수단으로 지정하므로 개정 대상 |
| [docs/conventions/view-tokens.md](../../docs/conventions/view-tokens.md) | §2.4와 §3 체크리스트가 Typography 팩토리 사용을 요구한다. 개정 대상 |
| [docs/conventions/view-tokens/typography.md](../../docs/conventions/view-tokens/typography.md) | 같은 규칙의 구체 명시 문서. 개정 대상 |
| [docs/conventions/view/preview.md](../../docs/conventions/view/preview.md) | 컴포넌트 프리뷰가 모든 시각 변형을 포함해야 한다. 프리뷰 호출부를 전환 범위에 포함한다(FR-007) |
| [docs/conventions/file-vocabulary/one-type-per-file.md](../../docs/conventions/file-vocabulary/one-type-per-file.md) | `Edge`는 컴포넌트 중첩 타입이므로 별도 파일로 나누지 않는다 |
| [docs/package-rules/ui.md](../../docs/package-rules/ui.md) | UIComponent는 Feature·Domain·Data·Composition 타입을 참조하지 않는다. 표시 상태 wrapper를 정의하지 않는다. 이번 변경은 이 경계를 바꾸지 않는다 |
| [docs/architecture.md](../../docs/architecture.md) | UI의 내부 패키지 의존은 없음. `Feature → UI` 방향만 사용하며 이번 변경이 의존 방향을 바꾸지 않는다 |
| [docs/conventions/test.md](../../docs/conventions/test.md) | 테스트 파일의 호출부도 전환 범위다. 새 테스트 이름이 필요하면 한국어 동작 문장과 Swift Testing을 따른다 |
| [.github/COMMIT_CONVENTION.md](../../.github/COMMIT_CONVENTION.md) | 공개 API 제거는 `[Remove]`, 구조 개선은 `[Refactor]`, 문서 개정은 `[Docs]`를 사용한다 |

## 프로젝트 구조

### 문서(이 기능)

```text
specs/039-ui-component-factory-removal/
├── plan.md              # 이 파일
├── research.md          # 0단계 산출물
├── data-model.md        # 1단계 산출물
├── quickstart.md        # 1단계 산출물
├── contracts/
│   └── component-creation-api.md
└── tasks.md             # 2단계 산출물(/speckit-tasks)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/UI/Component/
├── Controls/
│   ├── ActionButton.swift          # 팩토리 9개 제거
│   └── IconGlassButton.swift       # 팩토리 3개 제거
├── Displays/
│   ├── TagBadge.swift              # 팩토리 4개 제거
│   ├── LabeledCard.swift           # 팩토리 2개 제거, Style public 승격, init 신규
│   └── StyledText.swift            # 팩토리 10개 제거
└── Overlays/
    └── ScreenEdgeScrim.swift       # 팩토리 2개 제거, Edge 신규, init 신규

sources/Projects/UI/**               # 호출부 111곳 (프리뷰·하니스 포함, 고유 파일 42개)
sources/Projects/Feature/**          # 호출부 117곳 (프리뷰·테스트 포함, 고유 파일 51개)

docs/conventions/
├── view.md                          # §3.2 제목·링크, §3.3 절 삭제, §6 체크리스트
├── view/component-init.md           # 제목 개제, 삭제 문서의 규칙 2건 흡수
├── view/factory-criteria.md         # 파일 삭제
├── view/screen-init.md              # 문구 정리(FR-004d)
├── view-declarations/style.md       # 마지막 문장
├── view-tokens.md                   # §2.4, §3 체크리스트
└── view-tokens/typography.md
```

**구조 결정**: 새 디렉터리나 파일을 만들지 않고, 삭제하는 파일은
`docs/conventions/view/factory-criteria.md` 하나다. `ScreenEdgeScrim.Edge`와 `LabeledCard`의
초기화 메서드는 소유 컴포넌트 파일 안에 둔다. 변경은 기존 파일의 공개 표면과 호출부, 그리고
컨벤션 문서에 한정된다.

## 실행 단위

패키지 사용 방향은 `Feature → UIComponent`다. UI의 공개 API를 제거하면 Feature 호출부가
같은 커밋에서 바뀌어야 compile되므로, Feature 호출부가 있는 컴포넌트는 불가분한 다중 패키지
integration unit으로 계획한다.

순서는 위험이 낮고 범위가 좁은 것부터 둔다. 단위 1~2로 전환 방식을 확정한 뒤 다중 패키지
단위로 넘어가고, 가장 큰 `StyledText`를 마지막 코드 단위로 둔다.

| # | 단위 | 패키지 | 팩토리 | 호출부(UI/Feature) | 성격 | 커밋 태그 |
| --- | --- | --- | ---: | ---: | --- | --- |
| 1 | `ActionButton` | UI | 9 | 15 / 0 | 단일 패키지 | `[Remove]` |
| 2 | `ScreenEdgeScrim` | UI | 2 | 4 / 0 | 단일 패키지, `Edge`·init 신규 | `[Refactor]` |
| 3 | `TagBadge` | UI + Feature | 4 | 9 / 2 | integration unit | `[Remove]` |
| 4 | `LabeledCard` | UI + Feature | 2 | 7 / 3 | integration unit, `Style` 승격·init 신규 | `[Refactor]` |
| 5 | `IconGlassButton` | UI + Feature | 3 | 9 / 11 | integration unit | `[Remove]` |
| 6 | `StyledText` | UI + Feature | 10 | 67 / 101 | integration unit | `[Remove]` |
| 7 | 컨벤션 개정 | 문서 | — | — | 패키지 밖, 문서 7건(개정 5 + 문구 정리 1 + 삭제 1) | `[Docs]` |

**분리 불가 근거**(단위 3~6): UI에서 `public static func`를 지우는 순간 Feature의 해당 호출부가
컴파일되지 않는다. UI 변경과 Feature 호출부 수정을 다른 커밋에 두면 중간 커밋이 단독으로
compile되지 않아 SC-005를 위반한다.

**통합 검증**(단위 3~6): 각 단위 커밋 후 `compile`을 실행해 두 패키지가 함께 빌드되는지
확인한다. 절차는 [quickstart.md](./quickstart.md) §1.

**단위 7의 책임 배정**: `docs/conventions/**`는 어떤 Swift 패키지에도 속하지 않는다. 이 기능이
공개 생성 경로 규칙을 바꾸므로 그 규칙 문서의 개정 책임도 이 기능이 소유한다. 마지막 단위에
둔 근거는 [research.md §6](./research.md)이며, FR-004c가 요구하는 "같은 변경 단위"는 명세
정정으로 브랜치 수준임이 확정됐다. FR-010의 컴포넌트 단위 커밋과 양립하도록 개정을 브랜치의
마지막 커밋에 둔다.

**진행 방식**: 단위 1부터 7까지 반복 승인 없이 연속 진행한다. 유일한 승인 경계였던
`docs/conventions/view/factory-criteria.md` 삭제(Constitution 원칙 5의 삭제 권한 공백)는
2026-09-20 세션에서 사용자 승인을 받았다. 단위 7을 마친 뒤 전체 `build`·`compile`·`test`와
필수 `after_implement` 훅을 실행하고 최종 커밋한다.

## 기준선 실측과 명세 정정

계획 과정에서 명세의 가정 두 건이 실제와 다름을 확인하고 명세를 정정했다. 설계와 명세가 같은
실측값을 쓴다.

| 정정 전 | 정정 후 | 영향 |
| --- | --- | --- |
| `StyledText` 호출 약 110곳, 합계 약 170곳 | `StyledText` 168곳, 합계 228곳 | 단위 6의 작업량이 초기 추정의 1.5배 |
| `StyledText` 166곳, 합계 226곳(계획 단계 실측) | `StyledText` 168곳, 합계 228곳 | 구현 단계에서 줄바꿈 호출 2곳을 추가로 발견([research.md §1](./research.md)) |
| 네 컴포넌트가 이미 변형 enum과 초기화 메서드를 갖는다 | `LabeledCard`는 `public init`이 없고 `Style`이 `private` | 단위 4가 공개 계약 신설 단위(FR-001a 신설) |

근거는 [research.md §1](./research.md)과 [§2](./research.md)에 있다.

## 복잡성 추적

헌법 점검에서 정당화가 필요한 위반이 없다. 새 패키지·추상화 계층·의존성을 만들지 않으며,
신규 공개 타입은 기존 변형을 드러내는 `ScreenEdgeScrim.Edge` 하나다.
