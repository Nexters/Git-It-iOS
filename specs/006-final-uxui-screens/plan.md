# 구현 계획: 최종 UXUI 화면 구현 기반

**Git-flow 유형**: `feature`

**브랜치**: `feature/final-uxui-screens`

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/006-final-uxui-screens/spec.md`의 기능 명세

## 요약

Figma `최종 UXUI` 섹션의 기기 화면 프레임 65개를 목록화해 다섯 후속 흐름 그룹과 제외
항목에 배정한다. 이름만으로 상태 변형을 확정할 수 없는 항목은 `내용 미대조`와 담당 그룹을
기록하고 상세 대조를 후속 기능에 맡긴다. Figma 색 변수 25개와 저장소 토큰의 정합을
확정하고, 참조 화면과 함께 교정하는 공용 컴포넌트에서 반복되는 레이아웃 값과 `C`
기준선을 직접 실측값으로 승격·교정한다.

기반의 실제 동작은 `프로젝트` 목록 계열(`screen.project.list`)을 참조 화면으로 구현해
증명한다. Domain은 조회·삭제 Use Case Protocol을 소유하고, Composition의 표본 구현을
Feature에 생성자 주입한다. 각 `FeatureTests`는 필요한 최소 Mock을 로컬 테스트 자산으로
소유하며 공유 Mock target은 만들지 않는다. UI는 토큰·컴포넌트를, Feature는 TCA 상태
전이와 화면을, App은 조립과 검증용 실행 진입점을 소유한다. 나머지 화면의 상세 상수·상태
계약과 구현은 목록·그룹 정의와 참조 화면의 검증 방식을 이어받는 후속 기능 다섯 개가
담당한다.

## 기술 맥락

**언어/버전**: Swift 5 모드, iOS 26.0+

**주요 의존성**: SwiftUI, TCA 1.26.0+, XCTest/XCUITest, Tuist

**저장소**: N/A — Composition의 프로세스 수명 표본 데이터만 사용하고 영속화하지 않음

**테스트**: Swift Testing, XCTest/XCUITest, `DesignSystemTests`, `UIComponentTests`,
`UIComponentUITests`, 신규 Domain·Composition·Feature·App 검증 target

**대상 플랫폼**: iOS Simulator, 기준 기기 `iPhone 17 Pro`, 360pt Figma 기준 화면

**프로젝트 유형**: Tuist 기반 SwiftUI 멀티 패키지 iOS 앱

**성능 목표**: 이 기능에는 시간·프레임률 SLA를 새로 두지 않는다. 검증 가능성 목표는
참조 화면 상태 시나리오가 나머지 64개 화면 없이 독립적으로 반복 실행되는 것이다. 시간·
프레임률 기준이 필요하면 측정 환경과 허용치를 별도 후속 명세에서 확정한다.

**제약 조건**: 고정값 허용 오차 `±0.5pt`, 최소 터치 영역 44×44pt, 최대 Dynamic Type,
색 리터럴·`body`의 직접 여백 수치·여러 View에 복제된 로컬 여백 상수 금지, 생성자 주입,
Mock의 production target·배포 산출물 제외, 시스템 안전 영역 고정 금지

**규모/범위**: Figma 프레임 65개 목록·그룹 계약과 5개 후속 그룹, 참조 화면 1개와 Figma
디자인 상태 5개·운영 상태 2개, Use Case Protocol 2개, `FeatureTests` 로컬 Mock 2개, 색
변수 25개, 공용 컴포넌트 기준선 갱신 4항목과 `TagBadge` 8pt 값 보존 회귀 검증 1항목

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계**: Domain은 비즈니스 모델·Use Case Protocol, Composition은 표본 구현과
  객체 조립, UI는 토큰·공용 컴포넌트, Feature는 TCA 상태와 화면, App은 실행 진입점과
  Feature↔Composition 연결만 소유한다. Data와 Infrastructure는 변경하지 않는다.
- **상태와 데이터 안전성**: 모든 비동기 Effect는 성공·실패·취소 경로를 갖고, 표본 데이터는
  프로세스 수명 안에서만 유지한다. 개인정보·네트워크·영속 저장을 다루지 않는다.
- **검증 가능한 변경**: Figma 근거가 있는 계약 ID마다 자동 검증을 연결하고, production
  값을 바꾸지 않은 채 assertion helper에 잘못된 측정값을 주입해 검출력을 확인한다.
  기준선 갱신 항목은 이전값·새 값·Figma 노드를 기록한다.

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. 생성 훅이 실행되지 않았다면 실제 브랜치가
생성된 것처럼 기록하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 실제 문제가 발생하면 `/speckit-troubleshooting`, 여러 세션의 독립
근거에서 암묵적인 판단 기준을 해석하면 `/speckit-tacit-knowledge`가 각 전용 파일에
append-only로 기록한다. 두 파일은 계획 산출물이나 구현 작업이 아니며 조건을 충족하지
않으면 빈 파일을 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다. `sources/docs/naming.md`가 없으면
Constitution 원칙 10을 직접 적용하고, 문서가 작성된 뒤에는 세부 기준과 예외를 함께 참조한다.

**패키지 진행**: 현재 명세가 변경하는 패키지를 식별하고 `Domain → Data → Infrastructure →
Composition → UI → Feature → App` 순서로 구현 경계를 계획한다. 적용되지 않는 패키지는
건너뛰며, 각 적용 대상 패키지는 구현·검증·결과 보고·사용자 승인 후에만 다음 패키지로
진행한다. 공용 구성 파일이 여러 패키지 선언을 바꿔야 하면 패키지별 작업으로 분리하고 각
변경을 해당 패키지 단계에 배치한다. 패키지에 속하지 않는 파일 변경은 그 변경을 최초로
필요로 하는 책임 패키지에 명시적으로 배정하며, 배정할 수 없으면 계획을 중단하고 경계를
명확히 한다.

### 설계 후 재점검

- 공유 Mock target을 신설하지 않는다. `FeatureTests`가 Domain 계약을 구현하는 최소 Mock을
  로컬로 소유하고 다른 Feature 테스트 target과 공유하지 않으므로 production 의존 방향과
  Domain 내부 target 정책을 변경하지 않는다.
- 화면 렌더 harness는 Feature와 Composition을 함께 조립하므로 App 프로젝트가 소유한다.
  UI→Feature 역방향 의존을 만들지 않는다.
- `ProjectRow`와 `학습세트 List-item`을 외형이 아닌 표현 책임으로 분리해 UI 재사용 규칙과
  책임 기반 네이밍을 만족한다.
- `SheetSurface`와 `ProjectRow`의 레이아웃 수치는 컴포넌트의 `private enum Constant`에
  유지하고 테스트 전용 internal 측정 API를 추가하지 않는다. 정확한 수치는
  `UIComponentLayoutHarness`와 `UIComponentUITests`가 실제 렌더 결과로 검증한다.
- 모든 계획 산출물이 이 스킬의 허용 경로 안에 있고, 구현 경로는 아래 패키지 단계에만
  기록했다. 정당화가 필요한 헌법 위반은 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/006-final-uxui-screens/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/
│   ├── screen-inventory.md
│   ├── design-token-alignment.md
│   ├── component-correction.md
│   ├── reference-screen-layout.md
│   └── use-case-contracts.md
├── tasks.md             # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
├── trouble-shooting.md  # 문제 발생 시 /speckit-troubleshooting이 생성·추가
└── tacit-knowledge.md   # 암묵지 해석 시 /speckit-tacit-knowledge가 생성·추가
```

### 소스 코드(저장소 루트)
```text
sources/
├── Projects/
│   ├── Domain/
│   │   ├── LearningProject/{Models,UseCases}/
│   │   └── LearningProjectTests/
│   ├── Composition/
│   │   ├── Composition/LearningProject/
│   │   └── CompositionTests/LearningProject/
│   ├── UI/
│   │   ├── DesignSystem/{Token,Application}/
│   │   ├── DesignSystemTests/
│   │   ├── UIComponent/Components/{Leaf,Composite}/
│   │   ├── UIComponentTests/
│   │   ├── UIComponentLayoutHarness/
│   │   └── UIComponentUITests/
│   ├── Feature/
│   │   ├── Presentation/Screens/LearningProjectList/
│   │   └── FeatureTests/LearningProjectList/{Mocks,Tests}/
│   └── App/
│       ├── Sources/
│       ├── Tests/
│       ├── ScreenLayoutHarness/
│       └── ScreenLayoutUITests/
├── Tuist/ProjectDescriptionHelpers/Projects/
└── docs/
    └── ui-component-checklist.md
```

**구조 결정**: 기존 패키지 구조와 허용 의존 방향을 유지한다. 새 target의 source·test 폴더는
패키지 접두어를 반복하지 않고 역할 이름을 사용하며 `sourceDirectory`를 명시한다. Feature의
자리표시자 소스 경로는 View 컨벤션의 정본 경로인 `Presentation/`으로 옮긴다. 검증용 앱은
Feature와 Composition을 합법적으로 조립할 수 있는 App 프로젝트에 둔다.

## 구현 경계와 승인 순서

적용 순서는 `Domain → Composition → UI → Feature → App`이다. Data와 Infrastructure는
서버·저장·플랫폼 구현이 범위 밖이므로 건너뛴다. 각 단계는 구현, 해당 단계 검증, 변경·결과
보고, 사용자의 명시적 승인을 모두 마친 뒤에만 다음 단계 파일을 변경한다.

### 1. Domain

- `DomainLearningProject` target과 역할 폴더 `LearningProject/`에 목록 모델과
  `FetchLearningProjects`, `DeleteLearningProject` Protocol을 정의한다.
- `DomainModuleName.swift`의 target·scheme 변경은 Domain 단계가 소유한다.
- 모델 불변조건과 Protocol 계약을 검증하고 결과 승인을 받는다.

### 2. Composition

- 성공 목록·빈 목록·실패·대기 조회를 재현하는 두 Use Case 임시 구현과 조립 지점 하나를
  추가한다. `AppComposition.sample(fetch:)`는 harness가 운영 상태를 재현할 수 있는 표본
  동작만 선택하며 production 구현 교체 책임을 분산하지 않는다.
- `CompositionModuleName.swift`의 Domain target 의존성 변경은 Composition 단계가 소유한다.
- 표본 조회·삭제를 검증한다. 실제 구현 선택은
  `sources/Projects/Composition/Composition/AppComposition.swift` 한 파일이 소유하며,
  교체 시 App·Feature 파일이 바뀌지 않음을 검증하고 결과 승인을 받는다.

### 3. UI

- 색·텍스트·레이아웃 토큰 정합을 검증하고 반복 8pt 토큰과 진행 표시 의미 색을 추가한다.
  참조 화면이 사용하지 않는 텍스트 스타일 불일치 2건은 값 변경 없이 후속 명세 대상으로
  기록한다.
- [컴포넌트 교정 계약](./contracts/component-correction.md)의 기준선 4개를 갱신해
  `ProjectRow`, `SheetSurface`, `ActionButton`을 교정한다. 이미 Figma 값 8pt를 사용하는
  `TagBadge`는 회귀 검증으로 값 보존과 근거 승격만 확인한다.
- `SheetSurface`와 `ProjectRow`의 private 레이아웃 상수를 노출하지 않는다. 단위 테스트는
  공개 구성·상태 계약만 다루고, 정확한 padding·크기 판정은 렌더 harness/UI 테스트가
  전담한다.
- 참조 화면에 필요한 `ActionMenu`, edge scrim 표현을 UIComponent가 소유한다. `top dim`은
  아래→위, `bottom dim`은 위→아래 방향과 실측 정지점을 자동 일치 판정에 포함한다.
- `sources/docs/ui-component-checklist.md`의 `ProjectRow` 대응 정정은 UI 단계가 소유한다.
- `UIModuleName.swift` 변경은 UI target 선언 변경과 함께 UI 단계가 소유한다.
- DesignSystem·UIComponent 단위·렌더 검증과 기존 회귀 결과를 보고하고 승인을 받는다.

### 4. Feature

- Feature target의 source directory를 `Presentation/`으로 맞추고 TCA·Domain·UI 의존성을
  선언한다. `FeatureModuleName.swift` 변경은 Feature 단계가 소유한다.
- `LearningProjectListFeature`가 상태·Action·Effect를 소유하고 두 Use Case Protocol을
  initializer로 받는다.
- `LearningProjectListView`는 Feature State를 공용 컴포넌트 `ViewModel`로 변환하며 화면
  파일 안에 재사용 컴포넌트를 새로 정의하지 않는다.
- `FeatureTests/LearningProjectList/Mocks/`에 두 Use Case Protocol의 최소 로컬 Mock을 두고,
  상태 전이와 입력·호출 횟수를 검증한다. 다른 테스트 target이나 공유 Mock target에
  의존하지 않는다.
- Feature 빌드·테스트 결과를 보고하고 승인을 받는다.

### 5. App

- App의 조립 지점에서 Composition 실행 객체를 Feature initializer에 주입하고 앱 실행 후
  참조 화면에 도달하게 한다.
- `ScreenLayoutHarness`와 `ScreenLayoutUITests`를 App 프로젝트에 추가해 화면 상태별
  레이아웃·색·상호작용·Dynamic Type을 검증한다. Figma 디자인 상태 5개는 각각 launch
  scenario와 정밀 레이아웃·색 판정을 가지며, `loading`·`failed` 운영 상태 2개는 별도
  launch scenario의 최소 렌더링과 `failed` 재시도만 판정한다.
- `AppModuleName.swift`의 target·scheme 변경은 App 단계가 소유한다.
- 제품 App과 검증 앱의 production 의존성·배포 산출물에 Mock 정의나 참조가 없음을
  확인한다.
- 전체 build·compile·test와 의도적 불일치 검출력 확인 결과를 보고하고 최종 승인을 받는다.

## 공용 구성 파일 배정

`sources/Tuist/ProjectDescriptionHelpers/Projects/*.swift`는 각 패키지 단계에서 그 패키지
선언 파일만 수정한다. `ProjectName.swift`처럼 여러 패키지 scheme을 함께 나열하는 파일이
필요하면 패키지별 독립 작업으로 나누고, 최초로 필요한 Domain 단계부터 해당 패키지 관련
구획만 변경한다. `sources/Tuist/Package.swift`는 TCA가 이미 선언되어 있어 변경하지 않는다.

패키지 밖 문서 `sources/docs/ui-component-checklist.md`는 잘못된 UI 컴포넌트 대응을 처음
교정하는 UI 단계에 배정한다. 이 밖에 어느 패키지에도 배정할 수 없는 구현 파일이 발견되면
계획을 중단하고 책임 경계를 다시 확정한다.
