# 구현 계획: UI 패키지 컨벤션 정본화

**Git-flow 유형**: `feature`

**브랜치**: `feature/ui-convention-refactor`

**날짜**: 2026-08-22 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/014-ui-convention-refactor/spec.md`의 기능 명세

## 요약

UIComponent public View 23개 중 component-scoped `ViewModel`을 가진 22개를 직접 presentation value, UI 의미 타입, callback 및 제한된 `Binding` 계약으로 전환한다. production target에 포함된 Review/Preview 전용 타입을 `UIComponentPreview`로 분리하고, 기존 `UIComponentLayoutHarness` app·경로·Tuist 참조를 Preview 책임에 맞게 교체한다. 기존 geometry·접근성·interaction 계약은 전용 unit/UI test가 판정하며 Preview는 결정적 상태 재현만 담당한다.

실제 source 변경 패키지는 `UI` 하나다. 공용 Tuist helper와 UI 정본 문서는 UI target 변경을 최초로 필요로 하는 UI 단계에 배정한다. Feature/App에는 현재 UIComponent 소비 source가 없으므로 수정하지 않고, UI 단계의 마지막 읽기 전용 전체 검증에서 컴파일 전이만 확인한다.

## 기술 맥락

**언어/버전**: Swift (`SWIFT_VERSION = 5.0` Tuist 설정), POSIX sh 검증 진입점

**주요 의존성**: SwiftUI, DesignSystem, Lottie, Tuist, Swift Testing, XCTest/XCUI

**저장소**: 영속 저장소 없음; Preview fixture는 process-local 결정적 값만 사용

**테스트**: Swift Testing unit tests, XCTest UI tests, repository project-build runner, `GIT_IT_SWIFT_FORMAT_RUNNER` lint, 정적 `rg` 경계·consumer 검사

**대상 플랫폼**: iOS 26.0 이상, 기본 `iPhone 17 Pro` Simulator

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 애플리케이션

**성능 목표**: 별도의 런타임 성능 개선 또는 회귀 측정은 범위 밖이다. Preview fixture는 네트워크 없이 process-local 결정적 값으로 생성하며, 기능과 UI 계약의 회귀는 계획에 명시된 build/test gate로 판정한다.

**제약 조건**: UIComponent는 DesignSystem과 승인된 Lottie 렌더링 의존성만 사용; Preview는 UIComponent와 DesignSystem만 프로젝트 target으로 의존; 기존 시각·접근성·geometry 계약 보존; generated project 직접 편집 금지

**규모/범위**: public View 23개, ViewModel 전환 대상 22개, production에서 분리할 Review 타입 3개와 `TabShellPreviewItem`, Preview catalog에 등록할 public component 23개, UI unit test 5개 및 UI test 1개 파일을 기준선으로 확장

## 헌법 점검

*게이트: 0단계 조사 전에 통과했으며 1단계 설계 후 다시 점검했다.*

### 사전 설계 게이트

- **명시적 경계 — 통과**: `UIComponent → DesignSystem`과 승인된 Lottie 의존만 유지하고 Preview/test target은 production dependency가 되지 않는다.
- **상태 안전성 — 통과**: 제품 의미 상태는 상위 계층 소유, component 내부 상태는 재생성해도 손실 없는 시각 상태, Preview 상태는 local fixture로 한정한다.
- **검증 가능한 변경 — 통과**: public API, source inclusion, target graph, geometry, accessibility, interaction과 legacy 이름 제거에 각각 자동 검증 신호가 있다.
- **허용 수정 경로 — 통과**: 계획 단계는 현재 feature의 계획 산출물만 수정한다. 구현 경로는 계약과 향후 `tasks.md`에만 기록한다.
- **한국어 산출물 — 통과**: 자연어 산출물은 한국어로 작성하고 고정 코드 이름만 원문을 유지한다.
- **패키지 진행 — 통과**: 적용 패키지는 `UI` 하나다. Domain, Data, Infrastructure, Composition, Feature, App은 변경 대상에서 제외한다.
- **브랜치 — 통과**: 현재 checkout의 실제 브랜치는 `feature/ui-convention-refactor`이며 `feature/<short-name>`과 lowercase kebab-case 규칙을 충족한다.
- **책임 기반 네이밍 — 통과**: `UIComponentPreview`, `ComponentPreview`, `ComponentPreviewCatalog`는 실제 catalog/host 책임을 나타내며 legacy Harness 이름을 활성 계약에서 제거한다.

### 구현 패키지 경계와 승인 게이트

| 순서 | 패키지 | 변경 여부 | 책임 |
| --- | --- | --- | --- |
| 1 | Domain | 제외 | 비즈니스 모델·정책 변경 없음 |
| 2 | Data | 제외 | DTO·데이터 계약 변경 없음 |
| 3 | Infrastructure | 제외 | 외부 기술 adapter 변경 없음 |
| 4 | Composition | 제외 | dependency 조립 변경 없음 |
| 5 | UI | 적용 | 직접 입력 API, Preview 분리·rename, UI unit/UI test, UI 문서와 UI Tuist graph |
| 6 | Feature | 제외 | 실제 UIComponent 소비 source 0건; 최종 compile boundary만 검증 |
| 7 | App | 제외 | UI 직접 의존과 source 변경 없음; 최종 aggregate build만 검증 |

UI 단계는 구현 → UI 범위 검증 → 변경·결과 보고 → 사용자 승인 순으로 닫는다. UI는 마지막 적용 패키지이므로 승인 뒤에만 전체 읽기 전용 build·compile·test 검증을 수행한다. UI 외 패키지 파일을 새로 변경할 근거가 발견되면 즉시 중단하고 `tasks.md`의 패키지 범위를 다시 정한다. 공용 `UIModuleName.swift`와 `ProjectName.swift`, `docs/package-rules/ui.md`, `docs/conventions/ui-component.md`는 UI target과 컨벤션을 최초이자 유일하게 필요로 하므로 UI 단계에 배정한다.

### 설계 후 재점검

- Preview 전용 source가 UIComponent glob에 포함되지 않도록 물리 경로와 target source glob을 분리했다.
- UI test host rename과 scheme build/run 참조를 같은 UI 단계에 배치해 문서·코드의 과도 상태를 남기지 않는다.
- Review 파일 이동은 같은 UI 패키지 안의 source inclusion 변경이므로 다른 패키지 승인 경계를 넘지 않는다.
- Feature/App는 변경하지 않으며 전체 검증 결과가 실패해 실제 수정이 필요해질 때만 새 적용 패키지로 승격한다.
- 저장소에 실제로 존재하는 활성 UI 정본은 `docs/package-rules/ui.md`와 `docs/conventions/ui-component.md`로 한정하고, 존재하지 않는 기능 문서·component map·traceability·source index를 구현 범위로 만들지 않는다.
- 정당화가 필요한 Constitution 위반은 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/014-ui-convention-refactor/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── ui-component-public-contract.md
│   └── preview-and-validation-contract.md
└── tasks.md              # /speckit-tasks 산출물
```

### 소스 코드(저장소 루트)

```text
sources/Projects/UI/
├── DesignSystem/
├── Component/
│   ├── Components/
│   │   ├── Leaf/
│   │   └── Composite/
│   └── Resources/
├── ComponentPreview/
│   ├── App/
│   ├── Catalog/
│   ├── Fixtures/
│   └── Environment/
├── Tests/
│   ├── DesignSystem/
│   └── Component/
│       ├── Unit/
│       └── UI/
└── Project.swift

sources/Tuist/ProjectDescriptionHelpers/
├── ProjectName.swift
└── Projects/UIModuleName.swift

docs/
├── conventions/ui-component.md
└── package-rules/ui.md
```

**구조 결정**: target 이름은 패키지 문맥을 포함한 `UIComponentPreview`, 패키지 내부 source 폴더는 역할만 나타내는 `ComponentPreview`를 사용한다. `UI`와 `UIUITests` shared scheme 이름은 유지하고 build/run target만 Preview로 교체한다. generated `.xcodeproj`, workspace 및 `Derived/**`는 직접 수정하지 않고 `make tuist` 결과로만 갱신한다.

## 설계 단계

### 0단계 — 조사

1. current production public View와 `ViewModel` 사용을 전수 조사한다.
2. Preview/Review source inclusion, Tuist target·scheme·UI test host 및 활성 legacy 문서 참조를 조사한다.
3. unit/UI test가 현재 판정하는 geometry·interaction·accessibility 계약과 누락 환경을 분류한다.
4. Feature/App 실제 소비 source와 compile dependency만 구분해 적용 패키지를 확정한다.

결과는 [research.md](./research.md)에 기록한다.

### 1단계 — 계약과 검증 설계

1. component 공개 계약, UI 의미 타입, callback/Binding 및 상태 소유 규칙을 [data-model.md](./data-model.md)와 [UIComponent 공개 계약](./contracts/ui-component-public-contract.md)에 정의한다.
2. Preview catalog entry·fixture·environment·test scenario 모델과 target/source inclusion 규칙을 [Preview 및 검증 계약](./contracts/preview-and-validation-contract.md)에 정의한다.
3. Red 계약 확인, lint, consumer 전수 검색, UI 단계 검증과 승인 뒤 전체 compile boundary 확인 절차를 [quickstart.md](./quickstart.md)에 작성한다.
4. 설계 후 Constitution gate를 재검토하고 unresolved `NEEDS CLARIFICATION`이 0건인지 확인한다.

## 복잡성 추적

정당화가 필요한 Constitution 위반이 없다.
