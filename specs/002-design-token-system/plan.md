# Implementation Plan: 디자인 토큰 시스템

**Git-flow 유형**: `feature`

**브랜치**: `feature/002-design-token-system` (생성됨)

**날짜**: 2026-08-12 | **명세**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-design-token-system/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

UI 프레임워크에 의존하지 않는 순수 Swift 디자인 토큰 값 모델(색상 24종, 그라데이션
3종, 텍스트 스타일 10종, 글꼴 패밀리 2종, 레이아웃 2종)을 정의하고, 그 위에 SwiftUI
View Modifier 계층을 얹어 화면 구현자가 토큰 이름만으로 스타일을 적용할 수 있게 한다.
값 모델과 적용 수단은 같은 `DesignSystem` 타겟 내부에서 폴더로 분리(`Token/` vs
`Application/`)해 의존 방향을 강제하고, 값 존재·정확성은 신규 `DesignSystemTests`
타겟에서 시뮬레이터 렌더링 없이 검증한다(research.md, data-model.md 참고).

## Technical Context

**Language/Version**: Swift(tools-version 6.0, 타겟 언어 모드 5.0) — `sources/Tuist/Package.swift`, `Target+Module.swift` 기존 설정을 따름(research.md §1)

**Primary Dependencies**: SwiftUI, Foundation(플랫폼 프레임워크만). 외부 SPM 패키지 의존성 없음 — UI 패키지는 다른 내부 패키지에 의존할 수 없음(package-rules/ui.md)

**Storage**: N/A(정적 인메모리 값, `DesignTokenSet.current` 상수 하나)

**Testing**: Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`) — 프로젝트 기존 관례(`GitItCompilationTests.swift`)를 따름(research.md §1)

**Target Platform**: iOS 26.0+

**Project Type**: mobile-app(Tuist 다중 모듈). 이 기능은 `UI` 패키지의 `DesignSystem` 타겟(+ 신규 `DesignSystemTests`)만 변경한다

**Performance Goals**: N/A — 정적 조회와 상수 시간 산술(행간 변환)만 존재, 성능 목표를 별도로 정의할 필요 없음

**Constraints**: 토큰 값 모델(`Token/`)은 `SwiftUI`/`UIKit` import 금지(FR-001, FR-017). 활성 토큰 집합은 항상 하나이며 런타임 다중 선택 금지(FR-020, FR-022)

**Scale/Scope**: 원시 토큰 41개(색상 24 + 그라데이션 3 + 글꼴 패밀리 2 + 텍스트 스타일 10 + 레이아웃 2), 신규 Swift 파일 약 12개 내외(Token 6, Application 4~5, Tests 다수)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **브랜치 네임스페이스(원칙 8)**: 현재 브랜치 `feature/002-design-token-system`는 이미
  `feature/` 네임스페이스로 생성되어 있다. PASS.
- **허용 수정 경로(원칙 4·5)**: 이 명령은 `specs/002-design-token-system/`의 `plan.md`,
  `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정했다. 소스
  파일(`sources/Projects/UI/**`, Tuist 설정)은 아래 "프로젝트 구조"에 경로만 기록하고
  `tasks.md`에서 실제로 변경한다. PASS.
- **패키지 단위 구현 진행(원칙 7)**: 이 명세가 변경하는 패키지는 `UI` 하나뿐이다(spec.md
  가정: "이 기능은 여러 기능 화면이 공유하는 시각 언어를 제공하며, 아키텍처 문서의 UI
  경계 책임에 해당"). `Domain → Data → Core → Composition → UI → Feature → App` 순서
  에서 UI 이전 패키지는 모두 건너뛰고, UI 단계 하나만 존재한다. UI 단계 완료·검증·사용자
  승인 없이는 다음 적용 대상 패키지가 없으므로 순서 위반 가능성 자체가 없다. PASS.
- **명시적 경계(원칙 1)**: `DesignSystem` 타겟은 프로젝트 내부 다른 패키지에 의존하지
  않고(package-rules/ui.md), Tuist 의존성 선언도 추가하지 않는다. PASS.
- **한국어 산출물(원칙 6)**: 이 문서를 포함한 모든 계획 산출물을 한국어로 작성했다. 코드
  식별자(Swift 타입/케이스 이름)만 영문을 유지한다. PASS.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**패키지 진행**: 적용 대상 패키지는 `UI` 하나이며, `Domain → Data → Core → Composition →
UI → Feature → App` 순서에서 UI 앞뒤 패키지는 모두 이 기능의 변경 대상이 아니므로
건너뛴다. `tasks.md`는 UI 단계 하나만 정의하고, 그 단계 끝에 검증·보고·승인 게이트를
둔다.

*post-design 재확인*: Phase 1 설계(data-model.md, contracts/design-token-api.md)를
반영해도 위 다섯 게이트는 그대로 PASS다. 새로 추가한 `DesignSystemTests` 타겟도 `UI`
패키지 내부 산출물이라 패키지 경계를 넘지 않는다.

## Project Structure

### Documentation (this feature)

```text
specs/002-design-token-system/
├── plan.md              # 이 파일
├── research.md          # Phase 0 산출물
├── data-model.md         # Phase 1 산출물
├── quickstart.md         # Phase 1 산출물
├── contracts/
│   └── design-token-api.md   # Phase 1 산출물
└── tasks.md              # Phase 2 산출물 (/speckit-tasks, 이 명령은 생성하지 않음)
```

### Source Code (repository root)

이 기능은 `UI` 패키지 안 기존 `DesignSystem` 타겟(현재 플레이스홀더만 존재)을 실제
구현으로 채우고, 검증용 신규 타겟 `DesignSystemTests`를 추가한다. 아래 경로는 실제
구현 시 `tasks.md`가 배정할 대상이며, 계획 단계에서는 생성·수정하지 않는다.

```text
sources/Projects/UI/
├── Project.swift                       # 기존 파일, 변경 없음(UIModuleName.targets 참조)
├── DesignSystem/
│   ├── Token/                          # 값 모델 — Foundation만 import (FR-001, FR-017)
│   │   ├── RGBAComponents.swift
│   │   ├── ColorToken.swift
│   │   ├── GradientToken.swift
│   │   ├── FontFamilyToken.swift
│   │   ├── TextStyleToken.swift
│   │   ├── LayoutToken.swift
│   │   └── DesignTokenSet.swift
│   └── Application/                    # 적용 수단 — SwiftUI import 허용 (FR-014~017)
│       ├── View+TokenColor.swift
│       ├── View+TokenTextStyle.swift
│       ├── View+TokenGradient.swift
│       ├── View+TokenLayout.swift
│       ├── LineHeightConverging.swift  # research.md §4
│       └── ScriptClassifying.swift     # research.md §7
└── DesignSystemTests/                  # 신규 unitTests 타겟 (research.md §1)
    ├── ColorTokenTests.swift
    ├── GradientTokenTests.swift
    ├── TextStyleTokenTests.swift
    └── LayoutTokenTests.swift
```

Tuist 설정 변경 대상(구현 단계에서 `tasks.md`가 배정):

```text
sources/Tuist/ProjectDescriptionHelpers/Projects/UIModuleName.swift
  - DesignSystemTests target 추가 (product: .unitTests, dependencies: [DesignSystem])
  - UI 프로젝트의 자동 공유 스킴을 유지해 생성된 DesignSystem 스킴이
    DesignSystemTests의 TestableReference를 포함하도록 함
    → tools/githooks/project-build가 TestableReference 존재로 test 여부를 자동 판별
  - `Noto Sans KR`·`Plus Jakarta Sans`의 `Regular`·`Medium`·`Bold` 6개 정적 폰트를
    `ResourceFileElements`로 코드 기반 선언해 DesignSystem 번들에만 포함
```

**Structure Decision**: 신규 패키지·모듈을 만들지 않고 기존 `UI` 패키지의 `DesignSystem`
타겟 내부에서 `Token/`(값 모델)과 `Application/`(SwiftUI 적용 수단)을 폴더로 분리한다.
검증은 같은 타겟에 테스트를 추가하는 대신 신규 `DesignSystemTests` 타겟을 신설해, 값
모델 검증이 `UIComponent` 등 다른 UI 타겟의 뷰 테스트와 섞이지 않도록 한다(research.md
§1). 이 구조는 `Option 1/2/3` 어느 것에도 해당하지 않는 프로젝트 고유의 Tuist 다중
모듈 레이아웃이므로 위 플레이스홀더 옵션 대신 실제 경로로 대체했다.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

해당 없음 — Constitution Check의 모든 게이트가 위반 없이 통과했다.
