# 작업 목록: 최종 UXUI 화면 구현 기반

**입력**: `/specs/006-final-uxui-screens/`의 `spec.md`, `plan.md`, `research.md`,
`data-model.md`, `contracts/**`, `quickstart.md`

**테스트**: 명세 FR-008, FR-022와 SC-003~SC-022가 자동 검증을 요구하므로 각 패키지에서
테스트를 먼저 작성하고 예상한 이유로 실패하는지 확인한 뒤 구현한다.

**적용 패키지**: `Domain → Composition → UI → Feature → App`. Data와 Infrastructure는
실제 Use Case 구현과 서버·저장 연동이 범위 밖이므로 제외한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능하며 서로 다른 파일을 변경한다.
- **[S1]**: 화면 목록과 참조 화면 계약 확정
- **[S2]**: 참조 화면 하나로 구현 방식 실증
- **[S3]**: 여백·간격의 Figma 일치
- **[S4]**: 색의 Figma 일치
- **[S5]**: 후속 기능 다섯 개의 독립 착수 기반
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행·수동 검증·결과 보고·승인 대기

모든 파일 변경 작업은 정확한 저장소 상대 경로 하나와 이 문서의 패키지 단계 하나에만
속한다. 다른 패키지 단계의 작업은 승인 게이트를 넘어 병렬 실행하지 않는다.

---

## 작업 패키지 1: Domain

**목표**: 프로젝트 목록의 비즈니스 모델과 조회·삭제 Use Case Protocol을 기술·실행
환경과 무관한 Domain 경계로 제공한다. 테스트 Mock은 Domain에 두지 않는다.

**소유 경로**: `sources/Projects/Domain/LearningProject/**`,
`sources/Projects/Domain/LearningProjectTests/**`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 변경 시나리오**: S2, S5

**독립 검증**: `DomainLearningProject`가 다른 프로젝트 패키지에 의존하지 않고 빌드되며,
모델 불변조건과 두 Protocol의 공개 시그니처를 `DomainLearningProjectTests`와 컴파일로
검증한다. Domain source·test target에는 Feature 상태 검증용 Mock이 없어야 한다.

### 준비와 target 선언

- [X] T001 `sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`에 source directory가 각각 `LearningProject`, `LearningProjectTests`인 `DomainLearningProject`, `DomainLearningProjectTests` target과 test→production 의존성을 선언한다
- [X] T002 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Domain scheme 목록에 `DomainLearningProject`와 `DomainLearningProjectTests`를 연결하고 기존 인증 scheme 구획은 보존한다

### 테스트 — Red

- [X] T003 [P] [S2] `sources/Projects/Domain/LearningProjectTests/Models/LearningProjectValueTests.swift`에 빈 식별자 거부, 진행률 0...1 고정, 세트 순서 1 이상 불변조건 테스트를 작성한다
- [X] T004 [P] [S2] `sources/Projects/Domain/LearningProjectTests/Models/LearningProjectCollectionTests.swift`에 요약 모델의 식별 가능성·값 보존과 페이지의 항목·다음 페이지 상태 테스트를 작성한다
- [X] T005 [no-write] `make tuist` 후 project build runner로 `DomainLearningProject` 테스트를 실행해 T003~T004가 누락된 모델 때문에 예상대로 실패하고, 실패 원인이 환경이 아닌 계약 부재인지 확인한다

### 구현 — Green

- [X] T006 [P] [S2] `sources/Projects/Domain/LearningProject/Models/LearningProjectID.swift`에 공백 제거 후 빈 원시값을 거부하고 원래 식별값을 보존하는 `Sendable`, `Hashable`, `Identifiable` 값 객체를 구현한다
- [X] T007 [P] [S2] `sources/Projects/Domain/LearningProject/Models/LearningProgress.swift`에 `completedRatio`를 0...1로 고정하는 `Sendable`, `Equatable` 값 객체를 구현한다
- [X] T008 [P] [S2] `sources/Projects/Domain/LearningProject/Models/LearningSetMark.swift`에 1 이상의 `order`와 `title`을 보존하는 `Sendable`, `Equatable` 값 객체를 구현한다
- [ ] T009 [P] [S2] `sources/Projects/Domain/LearningProject/Models/LearningProjectError.swift`에 `temporarilyUnavailable`, `projectUnavailable`만 표현하는 기술 중립 오류를 구현한다
- [X] T010 [S2] `sources/Projects/Domain/LearningProject/Models/LearningProjectSummary.swift`에 식별자, 이름, 기술 목록, 진행 정보와 다음 세트 표시 정보를 가진 `Identifiable`, `Sendable`, `Equatable` 모델을 구현한다
- [X] T011 [S2] `sources/Projects/Domain/LearningProject/Models/LearningProjectPage.swift`에 프로젝트 요약 배열과 `hasNextPage`를 가진 `Sendable`, `Equatable` 모델을 구현한다
- [ ] T012 [P] [S2] `sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjects.swift`에 `callAsFunction(page:size:) async throws -> LearningProjectPage`를 선언하는 `Sendable` Protocol을 구현한다
- [ ] T013 [P] [S2] `sources/Projects/Domain/LearningProject/UseCases/DeleteLearningProject.swift`에 `callAsFunction(_:) async throws`를 선언하는 `Sendable` Protocol을 구현한다

### 패키지 검증과 승인

- [ ] T014 [no-write] `make tuist` 후 project build runner로 `DomainLearningProject`를 build·test하고 금지된 프로젝트 의존성 0건, 모델 테스트 통과, Domain source·test target의 `FetchLearningProjectsMock`·`DeleteLearningProjectMock` 정의 0건을 확인한다
- [ ] T015 [no-write] T001~T014의 Domain 변경 파일과 실제 검증 결과를 보고한 뒤 중단하고 Composition 진행에 대한 명시적 사용자 승인을 기다린다

**승인 게이트**: T015 승인 전에는 Composition, UI, Feature, App 파일을 생성·수정·삭제하지
않는다.

---

## 작업 패키지 2: Composition

**목표**: Domain Protocol을 만족하는 프로세스 수명 표본 구현과 실제 구현 선택 지점 한
곳을 제공하되 비즈니스 규칙·네트워크·영속 저장을 포함하지 않는다.

**소유 경로**: `sources/Projects/Composition/Composition/LearningProject/**`,
`sources/Projects/Composition/Composition/AppComposition.swift`,
`sources/Projects/Composition/CompositionTests/LearningProject/**`,
`sources/Projects/Composition/Composition/Placeholder.swift`,
`sources/Projects/Composition/CompositionTests/Placeholder.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`

**관련 변경 시나리오**: S2, S5

**독립 검증**: Composition 테스트가 표본 목록 조회·삭제와 `AppComposition`의 Protocol
적합성을 검증한다. `AppComposition.live()`의 구현 선택은
`sources/Projects/Composition/Composition/AppComposition.swift` 한 파일에만 있어야 한다.

### 준비와 target 선언

- [ ] T016 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`의 Composition production·test target에 `DomainLearningProject` 의존성만 추가하고 Mock 전용 target이나 FeatureTests 의존성은 추가하지 않는다

### 테스트 — Red

- [ ] T017 [P] [S2] `sources/Projects/Composition/CompositionTests/LearningProject/SampleFetchLearningProjectsTests.swift`에 초기 표본 페이지 반환, page·size 경계 전달과 삭제 뒤 조회 결과 반영 테스트를 작성한다
- [ ] T018 [P] [S2] `sources/Projects/Composition/CompositionTests/LearningProject/SampleDeleteLearningProjectTests.swift`에 기존 식별자 삭제, 없는 식별자의 `projectUnavailable`과 프로세스 수명 상태 테스트를 작성한다
- [ ] T019 [P] [S5] `sources/Projects/Composition/CompositionTests/LearningProject/AppCompositionTests.swift`에 `live()`와 `sample(fetch:)`의 `projects`·`failure`·`pending` 표본 동작이 두 Domain Protocol 실행 객체를 제공하고 대체 가능한지 검증한다
- [ ] T020 [no-write] project build runner로 `Composition` 테스트를 실행해 T017~T019가 누락된 표본 저장소·Use Case 구현·조립 타입 때문에 예상대로 실패하는지 확인한다

### 구현 — Green

- [ ] T021 [S2] `sources/Projects/Composition/Composition/LearningProject/SampleLearningProjectStore.swift`에 표본 목록의 프로세스 수명과 동시 접근을 소유하는 actor를 구현한다
- [ ] T022 [P] [S2] `sources/Projects/Composition/Composition/LearningProject/SampleFetchLearningProjects.swift`에 저장소 값을 그대로 페이지로 반환하고 정렬·필터·재시도 정책을 갖지 않는 Protocol 구현을 추가한다
- [ ] T023 [P] [S2] `sources/Projects/Composition/Composition/LearningProject/SampleDeleteLearningProject.swift`에 식별자 삭제와 `projectUnavailable`만 처리하는 Protocol 구현을 추가한다
- [ ] T024 [S5] `sources/Projects/Composition/Composition/AppComposition.swift`에 두 Use Case 실행 객체를 노출하고 `live()`의 실행 구현 선택과 harness용 `sample(fetch:)`의 `projects`·`failure`·`pending` 표본 동작을 정의하되 Mock 명칭·FeatureTests 의존 없이 실제 구현 교체 지점을 이 파일 한 곳으로 유지한다
- [ ] T025 `sources/Projects/Composition/Composition/Placeholder.swift`를 실제 Composition 소스가 생긴 뒤 삭제한다
- [ ] T026 `sources/Projects/Composition/CompositionTests/Placeholder.swift`를 실제 Composition 테스트가 생긴 뒤 삭제한다

### 패키지 검증과 승인

- [ ] T027 [no-write] `make tuist` 후 project build runner로 `Composition`을 build·test하고 표본 조회·삭제·조립 테스트, production Mock 정의·참조 0건과 `live()` 구현 선택 지점 한 파일을 확인한다
- [ ] T028 [no-write] T016~T027의 Composition 변경 파일과 실제 검증 결과를 보고한 뒤 중단하고 UI 진행에 대한 명시적 사용자 승인을 기다린다

**승인 게이트**: T028 승인 전에는 UI, Feature, App 파일을 생성·수정·삭제하지 않는다.

---

## 작업 패키지 3: UI

**목표**: Figma 색·간격·edge dim 계약을 DesignSystem 토큰으로 제공하고, 근거가 갱신된
공용 컴포넌트 기준선 4개를 교정하며 참조 화면에 필요한 화면 독립 표현 컴포넌트를 구현한다.

**소유 경로**: `sources/Projects/UI/DesignSystem/**`,
`sources/Projects/UI/DesignSystemTests/**`, `sources/Projects/UI/UIComponent/**`,
`sources/Projects/UI/UIComponentTests/**`, `sources/Projects/UI/UIComponentLayoutHarness/**`,
`sources/Projects/UI/UIComponentUITests/**`, `sources/docs/ui-component-checklist.md`

**관련 변경 시나리오**: S1, S2, S3, S4, S5

**독립 검증**: UI package만으로 색 변수 25개 정합, 토큰 무결성, 컴포넌트 고정값
`±0.5pt`, edge dim 방향·정지점, 44pt 터치 영역과 접근성 계약을 검증한다. `TagBadge`의
8pt 반경은 변경 없이 회귀 검증하고, 참조 화면이 쓰지 않는 텍스트 스타일 불일치는 이번
기능에서 값을 바꾸지 않는다.

### 테스트 — Red

- [ ] T029 [P] [S3] `sources/Projects/UI/DesignSystemTests/LayoutTokenTests.swift`에 기존 20pt·12pt와 반복 간격 `compactSpacing` 8pt 및 토큰 총 개수 계약을 작성한다
- [ ] T030 [P] [S4] `sources/Projects/UI/DesignSystemTests/SemanticColorTokenTests.swift`에 `progressTrack → grey500`, `progressFill → blue200` 참조 무결성 테스트를 작성한다
- [ ] T031 [P] [S4] `sources/Projects/UI/DesignSystemTests/GradientTokenTests.swift`에 stop 불투명도, 상단 아래→위 0/0.25·alpha 0/0.5, 하단 위→아래 0.7/1·alpha 0.6/0 계약과 기존 3종 회귀를 작성한다
- [ ] T032 [P] [S4] `sources/Projects/UI/DesignSystemTests/ColorTokenTests.swift`에 Figma 변수 25개의 이름·hex·opacity 전량 대조와 근거가 있는 저장소 전용 토큰 분리 검증을 추가한다
- [ ] T033 [P] [S3] `sources/Projects/UI/UIComponentTests/ActionButtonSizeContractTests.swift`에 공개 `ActionButton.Size`의 LG 54·MD 40·SM 36pt 표면 계단과 모든 크기의 최소 44pt 터치 영역 구성 계약을 작성하고, `SheetSurface`·`ProjectRow`의 private 레이아웃 수치는 이 단위 테스트에 노출하지 않는다
- [ ] T034 [P] [S2] `sources/Projects/UI/UIComponentTests/ContinuousProgressBarContractTests.swift`에 높이 6pt, 진행률 경계와 track·fill 의미 토큰 사용 계약을 작성한다
- [ ] T035 [P] [S2] `sources/Projects/UI/UIComponentTests/ActionMenuContractTests.swift`에 메뉴 181×126pt, 내부 여백, 불변 ViewModel·선택 콜백 분리와 항목 VoiceOver 의미 계약을 작성한다
- [ ] T036 [P] [S2] `sources/Projects/UI/UIComponentTests/ScreenEdgeScrimContractTests.swift`에 top·bottom 변형이 대응 GradientToken만 사용하고 사용자 상호작용을 가로채지 않는 계약을 작성한다
- [ ] T037 [S2] `sources/Projects/UI/UIComponentLayoutHarness/LayoutContractCatalog.swift`에 ActionButton 3크기, ProjectRow 기본·삭제, SheetSurface, ContinuousProgressBar, ActionMenu, ScreenEdgeScrim 시나리오와 실제 렌더 frame·padding을 읽을 고유 accessibility identifier를 추가한다
- [ ] T038 [S3] `sources/Projects/UI/UIComponentUITests/LayoutContractUITests.swift`에 `SheetSurface` grabber 58×4pt·위 5pt·영역 16pt, `ProjectRow` 방향별 inset·기본 150pt·삭제 94pt, ActionButton 크기 계단, `tag.radius` 8pt 보존, 44×44pt 터치 영역, 계약 ID 진단과 최대 Dynamic Type 적응 검증을 추가한다
- [ ] T039 [no-write] `DesignSystem`, `UIComponent`, `UIComponentLayout` 테스트를 실행해 T029~T038이 신규 토큰·컴포넌트와 기준선 불일치 때문에 예상대로 실패하는지 확인한다

### DesignSystem 구현 — Green

- [ ] T040 [P] [S3] `sources/Projects/UI/DesignSystem/Token/LayoutToken.swift`에 역할이 이름에서 드러나는 `compactSpacing` 8pt 토큰을 추가하고 `all`에 등록한다
- [ ] T041 [P] [S4] `sources/Projects/UI/DesignSystem/Token/SemanticColorToken.swift`에 `progressTrack`과 `progressFill`을 각각 `grey500`, `blue200` 참조로 추가하고 `all`에 등록한다
- [ ] T042 [S4] `sources/Projects/UI/DesignSystem/Token/GradientToken.swift`의 `Stop`에 기본값 1인 opacity를 추가하고 `topEdgeScrim`을 아래→위, `bottomEdgeScrim`을 위→아래 방향과 Figma 실측 정지점으로 정의한다
- [ ] T043 [S4] `sources/Projects/UI/DesignSystem/Application/View+GradientToken.swift`가 각 `GradientToken.Stop.opacity`를 SwiftUI `Color`에 적용하도록 확장한다

### UIComponent 구현 — Green

- [ ] T044 [P] [S2] `sources/Projects/UI/UIComponent/Components/Leaf/ContinuousProgressBar.swift`에 0...1 진행률, 6pt 표면과 `progressTrack`·`progressFill`을 가진 화면 독립 말단 컴포넌트를 구현한다
- [ ] T045 [P] [S2] `sources/Projects/UI/UIComponent/Components/Composite/ActionMenu.swift`에 불변 항목 ViewModel과 별도 선택 콜백, 181×126pt 메뉴 계약과 VoiceOver 라벨을 구현한다
- [ ] T046 [P] [S2] `sources/Projects/UI/UIComponent/Components/Leaf/ScreenEdgeScrim.swift`에 `topEdgeScrim`·`bottomEdgeScrim` 시각 변형과 hit testing 제외를 구현한다
- [ ] T047 [P] [S3] `sources/Projects/UI/UIComponent/Components/Leaf/ActionButton.swift`의 `Size`를 LG 54·MD 40·SM 36pt 표면과 최소 44pt 터치 영역으로 교정하고 기존 생성 경로를 보존한다
- [ ] T048 [P] [S3] `sources/Projects/UI/UIComponent/Components/Composite/SheetSurface.swift`의 grabber를 58×4pt, 위 5pt, grabber 영역 총 16pt로 교정하고 Figma 미확정값은 기존 근거 수준으로 유지한다
- [ ] T049 [S2] `sources/Projects/UI/UIComponent/Components/Composite/ProjectRow.swift`가 위 16·좌우 18·아래 18pt inset, 기본 150pt·삭제 94pt 최소 높이, 8pt 세부 간격과 `ContinuousProgressBar`를 사용하도록 교정한다
- [ ] T050 [S1] `sources/docs/ui-component-checklist.md`의 `ProjectRow` 대응을 Figma `ProjectList`로 정정하고 `학습세트 List-item`은 별도 미구현 컴포넌트로 유지하며 신규 컴포넌트 상태를 반영한다
- [ ] T051 `sources/Projects/UI/UIComponentTests/Placeholder.swift`를 실제 UIComponent 테스트가 추가된 뒤 삭제한다

### 패키지 검증과 승인

- [ ] T052 [no-write] `make tuist` 후 project build runner로 `DesignSystem`, `UIComponent`, `UIComponentLayout`을 build·test하고 색 변수 25개, 그라데이션 방향·정지점, 기준선 갱신 4개, `tag.radius` 8pt 보존, 44pt 터치 영역과 최대 Dynamic Type을 확인한다
- [ ] T053 [no-write] `rg`와 diff 검토로 UI production 코드의 색 리터럴, `body` 직접 여백 수치, 둘 이상의 View에 복제된 로컬 여백 상수가 각각 0건이고 한 View 전용 `private enum Constant`만 허용되는지 확인한다
- [ ] T054 [no-write] T029~T053의 UI 변경 파일과 실제 검증 결과를 보고한 뒤 중단하고 Feature 진행에 대한 명시적 사용자 승인을 기다린다

**승인 게이트**: T054 승인 전에는 Feature와 App 파일을 생성·수정·삭제하지 않는다.

---

## 작업 패키지 4: Feature

**목표**: 두 Domain Use Case Protocol을 initializer로 주입받는 TCA 상태 흐름과 프로젝트
목록 화면을 구현하고, 각 Mock을 `FeatureTests` 안의 최소 로컬 테스트 자산으로 격리한다.

**소유 경로**: `sources/Projects/Feature/Presentation/**`,
`sources/Projects/Feature/FeatureTests/LearningProjectList/**`,
`sources/Projects/Feature/Feature/Feature.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 변경 시나리오**: S2, S5

**독립 검증**: `FeatureTests`의 로컬 Mock만으로 idle·loading·loaded·empty·failed, 메뉴,
삭제 모드, 확인, 삭제 성공·실패와 delegate를 실행 환경 없이 검증한다. Feature production
source는 Mock·Composition·Service Locator를 정의하거나 참조하지 않는다.

### 준비와 target 선언

- [ ] T055 `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`에 source directory `Presentation`인 Feature target의 TCA·DomainLearningProject·DesignSystem·UIComponent 의존성과 source directory `FeatureTests`인 FeatureTests target의 Feature·DomainLearningProject·TCA test 의존성을 선언하고 공유 Mock target 의존성은 만들지 않는다
- [ ] T056 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Feature scheme에 `FeatureTests` test action만 연결하고 다른 패키지 scheme 구획은 변경하지 않는다

### 테스트 자산과 테스트 — Red

- [ ] T057 [P] [S5] `sources/Projects/Feature/FeatureTests/LearningProjectList/Mocks/FetchLearningProjectsMock.swift`에 제어 가능한 비동기 결과와 thread-safe page·size·호출 횟수 기록을 제공하는 로컬 Mock을 구현한다
- [ ] T058 [P] [S5] `sources/Projects/Feature/FeatureTests/LearningProjectList/Mocks/DeleteLearningProjectMock.swift`에 제어 가능한 비동기 결과와 thread-safe 프로젝트 식별자·호출 횟수 기록을 제공하는 로컬 Mock을 구현한다
- [ ] T059 [P] [S2] `sources/Projects/Feature/FeatureTests/LearningProjectList/Tests/LearningProjectListLoadingTests.swift`에 최초 1회 조회, loading, loaded, empty, failed, failed 재시도의 loading 전이·재호출과 page·size 입력 검증을 작성한다
- [ ] T060 [P] [S2] `sources/Projects/Feature/FeatureTests/LearningProjectList/Tests/LearningProjectListInteractionTests.swift`에 메뉴 열기·닫기, 삭제 모드 진입·종료, 확인·취소, 삭제 성공·실패와 학습 시작 delegate 전이를 작성한다
- [ ] T061 [P] [S5] `sources/Projects/Feature/FeatureTests/LearningProjectList/Tests/LearningProjectListDependencyIsolationTests.swift`에 두 로컬 Mock을 다른 Protocol 구현으로 교체해도 Reducer·View 수정 없이 상태 전이와 호출 검증이 유지되는지 작성한다
- [ ] T062 [no-write] `make tuist` 후 project build runner로 `Feature` 테스트를 실행해 T059~T061이 누락된 Reducer·화면 상태 때문에 예상대로 실패하는지 확인한다

### 구현 — Green

- [ ] T063 [S2] `sources/Projects/Feature/Presentation/Screens/LearningProjectList/LearningProjectListFeature.swift`에 상태·Action·취소 가능한 Effect·delegate와 두 Protocol의 명시적 initializer 주입을 구현한다
- [ ] T064 [S2] `sources/Projects/Feature/Presentation/Screens/LearningProjectList/LearningProjectListView.swift`에 loaded·empty·loading·failed·menu·deleting·confirmingDeletion 상태 분기와 공용 UIComponent ViewModel 변환을 구현한다
- [ ] T065 `sources/Projects/Feature/Feature/Feature.swift`를 `Presentation` source directory 전환과 실제 화면 구현 완료 뒤 삭제한다

### 패키지 검증과 승인

- [ ] T066 [no-write] project build runner로 `Feature`를 build·test하고 모든 상태 전이, Effect 취소·오류 경로, 로컬 Mock 호출, 다른 테스트 target 의존성 0건과 production의 Mock·`@Dependency`·Service Locator·Composition 참조 0건을 확인한다
- [ ] T067 [no-write] T055~T066의 Feature 변경 파일과 실제 검증 결과를 보고한 뒤 중단하고 App 진행에 대한 명시적 사용자 승인을 기다린다

**승인 게이트**: T067 승인 전에는 App 파일을 생성·수정·삭제하지 않는다.

---

## 작업 패키지 5: App

**목표**: `AppComposition.live()`의 실행 객체를 Feature initializer에 연결해 앱 실행 중
참조 화면에 도달하게 하고, 상태별 레이아웃·색·상호작용·접근성을 검증하는 App 소유
harness를 제공한다.

**소유 경로**: `sources/Projects/App/Sources/**`, `sources/Projects/App/Tests/**`,
`sources/Projects/App/ScreenLayoutHarness/**`,
`sources/Projects/App/ScreenLayoutUITests/**`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

**관련 변경 시나리오**: S1, S2, S3, S4, S5

**독립 검증**: 제품 앱과 `ScreenLayoutHarness`에서 프로젝트 목록에 도달하고, UI 테스트가
각 상태의 확정 레이아웃·sRGB 색·edge dim·상호작용·터치 영역·Dynamic Type을 나머지
화면 없이 판정한다. App은 구체 표본 구현 타입을 알지 않고 `AppComposition` 값만 연결한다.

### 준비와 target 선언

- [ ] T068 `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`에 GitIt·GitItTests의 Composition·Feature·DomainLearningProject 의존성, `ScreenLayoutHarness`, `ScreenLayoutUITests`, 공유 `ScreenLayout` scheme을 선언하되 FeatureTests나 Mock 전용 target을 어떤 App target에도 추가하지 않는다

### 테스트 — Red

- [ ] T069 [P] [S2] `sources/Projects/App/Tests/ReferenceScreenAssemblyTests.swift`에 App이 `AppComposition`의 두 Protocol 실행 객체를 타입 분기 없이 Feature initializer에 전달하고 대체 `AppComposition`도 같은 경로로 조립되는 계약을 작성한다
- [ ] T070 [P] [S3] `sources/Projects/App/ScreenLayoutUITests/ReferenceScreenLayoutTests.swift`에 360pt 기준 목록·행·메뉴·시트·상하단 dim의 확정값 `±0.5pt` 검증과 production 수정 없이 assertion helper에 계약 20pt 대신 측정 21pt를 입력해 계약 ID·기대값·실제값 진단을 확인하는 짝 테스트를 작성한다
- [ ] T071 [P] [S4] `sources/Projects/App/ScreenLayoutUITests/ReferenceScreenColorTests.swift`에 PNG를 sRGB 8-bit로 정규화하고 안정된 3×3pt 중앙값을 사용해 단색 `±1/255`, 반투명 합성 `±2/255`로 화면·행·진행 바·시트·scrim을 판정하며 production 수정 없이 assertion helper에 잘못된 RGBA와 올바른 RGBA를 주입하는 짝 테스트를 작성한다
- [ ] T072 [P] [S2] `sources/Projects/App/ScreenLayoutUITests/ReferenceScreenInteractionTests.swift`에 메뉴, 삭제 모드, 확인 시트, 취소와 삭제 후 목록·빈 상태 전환을 작성한다
- [ ] T073 [P] [S2] `sources/Projects/App/ScreenLayoutUITests/ReferenceScreenAccessibilityTests.swift`에 모든 조작 요소 44×44pt, 의미 있는 VoiceOver 라벨과 최대 Dynamic Type 비겹침·비잘림을 작성한다
- [ ] T074 [no-write] GitItTests와 ScreenLayout UI 테스트를 실행해 T069~T073이 앱 조립·harness·참조 화면·판정 helper 누락 때문에 예상대로 실패하는지 확인한다

### 제품 App 조립 — Green

- [ ] T075 [S2] `sources/Projects/App/Sources/ContentView.swift`가 주입받은 `AppComposition`의 두 실행 객체로 `LearningProjectListFeature` Store를 만들고 참조 화면을 루트로 표시하도록 기존 Hello World 화면을 교체한다
- [ ] T076 [S2] `sources/Projects/App/Sources/GitItApp.swift`가 프로세스 수명 `AppComposition.live()`를 한 번 생성해 `ContentView`에 전달하도록 앱 진입점을 조립한다

### 화면 검증 harness — Green

- [ ] T077 [P] [S2] `sources/Projects/App/ScreenLayoutHarness/ReferenceScreenScenario.swift`에 launch argument별 Figma 디자인 상태 loaded·empty·menu·deleting·confirmingDeletion과 운영 상태 loading·failed를 정의하고 `AppComposition.sample(fetch:)`의 `projects`·`pending`·`failure` 표본 동작에 연결한다
- [ ] T078 [S2] `sources/Projects/App/ScreenLayoutHarness/ScreenLayoutHarnessApp.swift`에 선택한 시나리오를 `LearningProjectListFeature`와 조립하는 독립 앱 진입점을 구현한다
- [ ] T079 [P] [S3] `sources/Projects/App/ScreenLayoutUITests/Support/ScreenContractAssertion.swift`에 production 값과 분리된 기대값·측정값 입력, 레이아웃 허용 오차, sRGB RGBA 정규화·source-over 합성·3×3 중앙값과 계약 ID·기대값·실제값 진단 helper를 구현한다

### 패키지 검증과 승인

- [ ] T080 [no-write] `make tuist` 후 project build runner로 `GitIt`, `GitItTests`, `ScreenLayout`을 build·test하고 앱 도달성, 디자인 상태 5개 정밀 렌더, 운영 상태 2개 최소 렌더·failed 재시도, 레이아웃·색·edge dim, 상호작용, 44pt 터치 영역과 최대 Dynamic Type을 확인한다
- [ ] T081 [no-write] target graph·production source·링크 산출물을 검사해 `FetchLearningProjectsMock`, `DeleteLearningProjectMock`, FeatureTests와 테스트 bundle이 제품 GitIt·ScreenLayoutHarness에 정의·참조·링크된 건수가 0인지 확인한다
- [ ] T082 [no-write] App source가 `AppComposition.live()`와 Protocol 값만 사용하고 표본 구체 타입을 참조하지 않으며, production에서 `SampleFetchLearningProjects`·`SampleDeleteLearningProject`를 선택하는 파일이 `sources/Projects/Composition/Composition/AppComposition.swift` 한 곳인지 확인한다
- [ ] T083 [no-write] T068~T082의 App 변경 파일과 실제 검증 결과를 보고한 뒤 중단하고 전체 완료 검증 진행에 대한 명시적 사용자 승인을 기다린다

**승인 게이트**: T083 승인 전에는 전체 build·compile·test와 최종 수용 판정을 실행하지 않는다.

---

## 전체 완료 검증

**선행 조건**: App 패키지의 구현·검증·결과 보고가 완료되고 사용자가 전체 검증 진행을
명시적으로 승인해야 한다. 아래 작업은 추적 파일을 수정하지 않는다.

- [ ] T084 [no-write] [S1] `specs/006-final-uxui-screens/contracts/screen-inventory.md`에서 프레임 65개가 G1~G5 또는 제외에 정확히 한 번 배정되고 `내용 미대조` 항목마다 담당 후속 기능이 있으며, 각 그룹의 시작 화면·연결 지점·공용 컴포넌트 단일 소유자가 존재하고 기록된 전환 100%가 `확정` 또는 `추정` 근거 수준을 가지며 추정 전환을 확정으로 기록한 건수가 0인지 검증한다(SC-022)
- [ ] T085 [no-write] [S2] `specs/006-final-uxui-screens/contracts/reference-screen-layout.md`에 구현 위치·현재 구현 상태·상태별 근거 수준이 있고, loaded·empty·menu·deleting·confirmingDeletion 5개 launch scenario의 Figma 정밀 판정과 loading·failed 2개 launch scenario의 최소 렌더·failed 재시도를 앱에서 독립 실행하며 자리표시자·미구현 표시 0건을 확인한다
- [ ] T086 [no-write] [S3] `ScreenLayout`을 360pt 기준과 최대 Dynamic Type에서 실행해 확정 여백·간격 100%가 `±0.5pt`이고 색 리터럴·`body` 직접 여백 수치·복제된 로컬 여백 상수와 텍스트 잘림·겹침이 각각 0건인지 확인한다
- [ ] T087 [no-write] [S4] `DesignSystem`과 `ScreenLayout`으로 Figma 색 변수 25개, 상단 아래→위·하단 위→아래 edge dim, sRGB 판정 허용치와 production 수정 없이 주입한 잘못된·올바른 측정값의 항목별 실패·통과 진단을 확인한다
- [ ] T088 [no-write] [S5] `sources/Projects/Feature/FeatureTests/LearningProjectList/Mocks/**`만으로 Feature 상태 전이를 재실행해 Mock 정의 100%가 해당 테스트 target 안에 있는지 확인하고, `specs/006-final-uxui-screens/contracts/screen-inventory.md`의 G1~G5 모두에 Feature별 로컬 Mock 규칙이 적용되는지 검증한다
- [ ] T089 [no-write] project build runner의 전체 `build`, `compile`, `test`를 순서대로 실행하고 기준선 갱신 4항목을 제외한 기존 자동 검증이 동일하게 통과하는지 기록한다
- [ ] T090 [no-write] `git diff --check`와 `git status --short`로 후행 공백, 의도적 불일치 잔여물, tasks.md에 없는 변경, 생성 프로젝트·DerivedData의 추적 변경이 0건인지 확인한다

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

```text
Domain (T001~T015)
  → 사용자 승인
Composition (T016~T028)
  → 사용자 승인
UI (T029~T054)
  → 사용자 승인
Feature (T055~T067)
  → 사용자 승인
App (T068~T083)
  → 사용자 승인
전체 읽기 전용 검증 (T084~T090)
```

- 한 번에 첫 미완료 패키지만 구현한다. 현재 패키지의 모든 구현·검증·결과 보고가 끝나기
  전에는 다음 패키지 파일을 변경하지 않는다.
- 승인 전에는 다음 패키지 영향 분석만 허용한다.
- 후속 패키지에서 선행 패키지 수정이 필요하면 구현을 중단하고 `/speckit-tasks`로 소유권과
  순서를 다시 조정한다.
- `ProjectName.swift`는 Domain과 Feature 단계가 각자의 scheme 구획만 독립 작업으로
  변경한다. 다른 패키지 구획을 함께 수정하지 않는다.

### 변경 시나리오 완료 순서

```text
S1 화면·상수 계약 ─┬─→ S3 레이아웃 일치 ─┐
                    ├─→ S4 색 일치 ────────┼─→ S2 참조 화면 실증 ─→ S5 후속 기능 착수 기반 확인
                    └────────────────────────┘
```

- **S1**은 계획 산출물로 계약을 먼저 제공하며 T050, T084에서 구현 대응과 전량 배정을
  확인한다.
- **S3·S4**는 UI 토큰·컴포넌트 구현 이후 App harness로 독립 판정할 수 있다.
- **S2**는 Domain부터 App까지의 주입·표현 경계가 모두 완료돼야 독립 수용 검증이 가능하다.
- **S5**는 S2의 본보기, Feature별 로컬 Mock과 검증 수단을 후속 기능이 재현할 수 있을 때
  완료된다.

### 패키지 내부 병렬 실행 예시

- Domain 승인 범위: T003~T004 테스트와 T006~T009 값 타입, T012~T013 Protocol은 각 묶음의
  선행 조건을 만족한 뒤 병렬 실행할 수 있다.
- Composition 승인 범위: T017~T019 테스트는 병렬 작성할 수 있고, T021 완료 뒤
  T022~T023을 병렬 구현할 수 있다.
- UI 승인 범위: T029~T036 테스트 파일, T040~T041 토큰 파일과 T044~T048 컴포넌트 파일은
  각자의 Red와 선행 토큰이 준비된 범위에서 병렬 실행할 수 있다.
- Feature 승인 범위: T057~T061은 서로 다른 테스트 파일에서 병렬 작성할 수 있다. Reducer
  구현 뒤 View를 순차 구현한다.
- App 승인 범위: T069~T073 테스트 파일은 병렬 작성할 수 있고 T077과 T079는 선행 계약이
  준비된 뒤 서로 다른 파일에서 병렬 구현할 수 있다.
- 서로 다른 패키지는 어떤 경우에도 병렬 실행하지 않는다.

## 변경 시나리오별 독립 검증 기준

| 시나리오 | 독립 검증 기준 |
| --- | --- |
| S1 | 화면 프레임 65개가 고유 식별자·그룹 또는 제외 사유·분류 상태를 갖고, `내용 미대조` 항목마다 담당 후속 기능이 있으며, 참조 화면은 구현 위치·현재 구현 상태·상세 계약의 항목별 근거 수준을 가진다. 그룹별 시작 화면·연결 지점·공용 컴포넌트 단일 소유자와 SC-022의 전환 근거 판정도 존재한다. |
| S2 | 앱에서 프로젝트 목록의 5개 디자인 상태와 2개 운영 상태에 독립적으로 도달하고, 디자인 상태는 Figma 정밀 판정, 운영 상태는 최소 렌더·failed 재시도를 통과하며, 대체 `AppComposition`을 주입해도 Feature·화면 코드는 바뀌지 않는다. |
| S3 | 참조 화면과 공용 컴포넌트의 모든 확정 여백·간격이 360pt 기준 `±0.5pt`이고, 금지된 production 여백 리터럴·복제 상수가 없으며 최대 Dynamic Type에서 잘림·겹침이 없다. |
| S4 | Figma 색 변수 25개와 edge dim 방향·정지점이 토큰과 일치하고 화면·컴포넌트에 색 리터럴이 없으며, 잘못된 측정값을 계약 ID·기대값·실제값으로 검출한다. |
| S5 | 다섯 그룹의 계약이 완결되고 후속 Feature가 공유 Mock target이나 다른 FeatureTests 의존 없이 자기 테스트 target의 로컬 Mock과 기존 harness 패턴으로 시작할 수 있다. |

## 구현 전략과 최소 가치 범위

1. 첫 미완료 패키지의 Red 테스트만 먼저 작성해 계약 부재로 실패하는지 확인한다.
2. 같은 패키지의 Green 구현과 회귀 검증을 마치고 파일·결과를 보고한 뒤 승인 대기한다.
3. 승인 후 다음 패키지에서 같은 절차를 반복한다.
4. App 승인 뒤에만 T084~T090 전체 검증을 실행한다.

S1 계약 문서만으로도 참조 화면 외 프레임의 담당 범위와 분할을 검토할 수 있다. 실제 코드의 최소 가치
범위는 **S1 계약 + S2 참조 화면 실증**이며, 이를 위해서도 Domain → Composition → UI →
Feature → App 승인 게이트를 모두 유지한다. S3·S4의 확정값 검증은 S2의 완료 조건에
포함하고, S5는 같은 기반의 후속 재현 가능성을 최종 확인한다.

## 참고

- `trouble-shooting.md`와 `tacit-knowledge.md`는 구현 작업에 포함하지 않는다.
- Lottie 의존성, 실제 Data·Infrastructure Use Case 구현, 라이트 테마, 참조 화면이 사용하지
  않는 텍스트 스타일 불일치와 나머지 화면의 상세 상수·상태 계약 및 구현은 이 작업 목록의
  범위 밖이다.
- 이 기능은 별도 시간·프레임률 SLA를 정의하지 않으며 성능 수치는 후속 명세 없이는 완료
  기준으로 사용하지 않는다.
- Figma `top dim`(`1216:16439`, 내부 `1216:16441`)과 `bottom dim`(`1216:16402`, 내부
  `1216:16399`)의 방향·정지점은 2026-08-19 읽기 전용 조회값을 정본으로 사용한다.
