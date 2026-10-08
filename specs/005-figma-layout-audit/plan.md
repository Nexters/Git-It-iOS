# 구현 계획: Figma UI 레이아웃 상수 검증

**Git-flow 유형**: `feature`

**브랜치**: `미생성 (예정: feature/figma-layout-audit)`

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/005-figma-layout-audit/spec.md`의 기능 명세

## 요약

Figma `사용한 컴포넌트` 영역과 현재 `UIComponent` 구현의 레이아웃 값을 계약 체크리스트로 대응시킨다. UI 패키지 안에 전용 레이아웃 검증 앱과 XCUITest 타깃을 두고, 테스트를 먼저 실패시킨 뒤 확인된 크기 불일치인 `ActionButton` 크기 변형과 `IconGlassButton` 표면·터치 영역을 교정한다. 나머지 컴포넌트는 근거 수준에 따라 고정값 검증 또는 적응형 동작 검증으로 구분한다.

## 기술 맥락

**언어/버전**: Swift 5 모드, iOS 26.0+

**주요 의존성**: SwiftUI, UIKit, XCTest/XCUITest, Tuist

**저장소**: N/A — 영속 데이터 변경 없음

**테스트**: UI 패키지 전용 XCUITest와 기존 `DesignSystemTests`·`UIComponentTests`

**대상 플랫폼**: iOS Simulator, 기준 기기 `iPhone 17 Pro`

**프로젝트 유형**: Tuist 기반 iOS 멀티 패키지 앱

**성능 목표**: 레이아웃 검증 앱의 각 시나리오가 5초 안에 표시되고 전체 UI 검증이 반복 실행 가능해야 한다.

**제약 조건**: Figma 직접 속성 조회 한도, 기본 수치 허용 오차 `0.5pt`, 최소 터치 영역 `44pt × 44pt`, Dynamic Type과 시스템 컨트롤의 적응형 동작 보존

**규모/범위**: Figma 대응 구현 컴포넌트 12개 계열과 지원 변형, 신규 제품 기능·미구현 Figma 컴포넌트 제외

## 헌법 점검

*게이트: 0단계 조사 전 및 1단계 설계 후 모두 통과.*

- **명시적인 경계**: 변경은 UI 패키지의 재사용 컴포넌트, UI 전용 검증 앱·UI 테스트와 해당 Tuist 선언에만 한정한다. Domain, Data, Infrastructure, Composition, Feature, App은 변경하지 않는다.
- **상태와 데이터 안전성**: 검증 앱은 정적 표본만 사용하며 개인정보·네트워크·영속 상태를 다루지 않는다.
- **검증 가능한 변경**: Figma 목표값마다 자동화 검증을 연결하고, 확인된 불일치는 실패 후 수정·성공 순서를 보존한다.
- **허용 수정 경로**: 계획 단계에서는 이 기능의 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 수정한다. 구현 경로는 `tasks.md`에서 정확히 열거한다.
- **브랜치 네임스페이스**: 생성 훅이 없어 `feature/figma-layout-audit`는 예정 상태이며 실제 생성으로 보고하지 않는다.
- **책임 기반 네이밍**: 크기 변형은 컴포넌트 안의 `Size`로 소유하고 `small`, `large`, `medium`처럼 독립적으로 해석되는 이름을 사용한다. 범용 `LayoutSize` 같은 과도한 공용 타입을 만들지 않는다.
- **패키지 진행**: 적용 대상은 UI 하나뿐이다. Tuist 공용 helper 변경은 UI 테스트 타깃을 최초로 필요로 하는 UI 패키지에 배정한다. 다른 패키지 승인 게이트는 발생하지 않는다.
- **세션 지식 기록**: Figma MCP 호출 한도와 브라우저 대체 확인 과정은 실제 환경 제약이므로 전용 `speckit-troubleshooting` 기록으로 남긴다.
- **Git 실행 직렬화**: 이 계획은 Git index 변경 체인을 실행하지 않는다.

### 설계 후 재점검

UI 전용 harness가 제품 App이나 Feature에 검토 코드를 유입시키지 않으며, 모든 변경 파일이 UI 단계에 단일 배정될 수 있음을 확인했다. 헌법 위반과 예외 정당화가 필요하지 않다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/005-figma-layout-audit/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-layout-constants.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### 소스 코드(저장소 루트)

```text
sources/
├── Projects/UI/
│   ├── UIComponent/Components/
│   │   ├── Leaf/
│   │   └── Composite/
│   ├── UIComponentLayoutHarness/
│   └── UIComponentUITests/
└── Tuist/ProjectDescriptionHelpers/
    ├── Projects/UIModuleName.swift
    └── ProjectName.swift
```

**구조 결정**: 제품 컴포넌트는 기존 `UIComponent`에 유지한다. 레이아웃 검증 진입점과 XCUITest는 UI 프로젝트 내부의 독립 타깃으로 두어 제품 App과 Feature가 검토 전용 코드에 의존하지 않게 한다. UI 테스트 scheme 연결을 위한 Tuist 선언은 UI 패키지 단계가 소유한다.

## 구현 경계와 순서

### UI 패키지

1. `contracts/ui-layout-constants.md`의 확정 항목을 UI 테스트 식별자와 대응시킨다.
2. UI 전용 검증 앱·XCUITest 타깃과 scheme을 선언하고 정적 변형 카탈로그를 구성한다.
3. 일반 버튼과 Liquid Glass 아이콘 버튼의 실패 테스트를 먼저 실행해 현재 불일치를 확인한다.
4. `ActionButton.Size`와 `IconGlassButton.Size` 계약을 추가하고 고정 표면과 44pt 터치 영역을 분리한다.
5. 카드·행·헤더·시트·탭 골격은 확정 근거 수준에 따라 고정값 또는 적응형 불변조건을 검증한다.
6. UI package build/test와 전체 읽기 전용 회귀 검증을 실행하고 결과를 보고한다.

UI가 유일한 적용 대상이므로 다음 패키지 파일 변경을 위한 승인 게이트는 없다. 다만 완료 보고 전 UI 변경 파일과 검증 결과를 명시한다.
