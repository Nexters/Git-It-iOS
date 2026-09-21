---

description: "기능·상태 단위 Feature 분해와 화면 Feature 합성 작업 목록"
---

# 작업 목록: 기능·상태 단위 Feature 분해와 화면 Feature 합성

**입력**: `specs/041-feature-composition-refactor/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/feature-composition-contracts.md](./contracts/feature-composition-contracts.md),
[quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세가 요구한다. FR-009는 기능 Feature 단독 테스트를, FR-010·SC-011은 합성 지점 검증과
단언 이관을 요구한다. 그래서 각 단위에 테스트 작업을 둔다. 새 기능 Feature 테스트는 구현 전에 작성하고
컴파일 실패(타입 없음)를 확인한 뒤 구현한다.

**구성**: 실행 단위를 최상위 구조로 쓰고, 변경 시나리오는 각 단위 안의 라벨로 추적한다. 변경
패키지는 `Feature`다. `App`은 U3에서만 Feature 상태 경로 변경과 불가분이므로 integration unit으로
묶는다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행할 수 있다(서로 다른 파일, 미완료 의존성 없음).
- **[S1]~[S4]**: 명세의 시나리오 1~4.
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 바꾸지 않는 명령 실행이나 수동 검증이다.
  `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용한다. 단, 실행 전후
  `git status --porcelain`을 비교해 추적 파일 변경이 생기면 완료로 처리하지 않는다.
- 빌드 실행기: `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`.
  `build`·`compile`·`test`는 `sources/DerivedData/PreCommit`을 공유하므로 순차로만 실행한다.
- 파일 이동은 같은 모듈 안의 경로 변경이다. 타입 이름과 접근 수준을 바꾸지 않는 순수 이동으로 하며,
  같은 작업에서 내용 변경을 섞지 않는다.
- 모든 새 Reducer는 [contracts](./contracts/feature-composition-contracts.md)의 생성자·input·view·delegate와
  [data-model.md](./data-model.md) §2의 State를 따른다. 의존성은 `@Sendable` 클로저 initializer로
  받아 `private let`으로 보존하고 기본값을 두지 않는다.
- Swift 소스에는 `// MARK:` 외 주석을 쓰지 않는다. 테스트 함수 이름은 한국어 동작 문장이다(Swift Testing,
  `TestStore`).
- 각 단위의 "이관 대응표" 작업은 [research.md §6](./research.md#6-단언-이관-대응표-sc-011)에 이관 전 `@Test`
  하나마다 한 행 이상을 추가한다. 이 파일은 명세 산출물이며 이 기능의 책임 패키지인 Feature 단위가
  갱신한다.

## 실행 단위 소유권 규칙

- `sources/Projects/Feature/**`의 소스·테스트는 해당 Feature 실행 단위가 소유한다.
- `sources/Projects/App/**`는 U3·U8 integration unit만 수정한다.
- `docs/conventions/**` 변경은 이 기능의 Feature 단위가 소유하며, 아래 작업에 적힌 파일 하나씩만 수정한다.
- `specs/041-feature-composition-refactor/research.md`의 §6 대응표 갱신은 각 Feature 단위가 소유한다.
- `docs/spec-kit/<feature>/trouble-shooting.md`와 `tacit-knowledge.md`는 작업으로 만들지 않는다.

---

## 실행 단위 0: 식별 결과 확인 (단일 패키지: Feature, 읽기 전용)

**목표**: 시나리오 1의 산출물(분해 기준과 전수 식별 결과)이 이후 단위의 입력으로 유효한지 확인한다.

**소유 경로**: 없음(읽기 전용)

**관련 변경 시나리오**: S1

**독립 검증**: 제3자가 [research.md](./research.md) §1 기준만으로 §3.7의 분류에 도달할 수 있다.

- [X] T001 [no-write] [S1] `specs/041-feature-composition-refactor/research.md` §3.1의 모수 29개가 현재 HEAD와 같은지 `grep -rn '^@Reducer' --include='*.swift' sources/Projects/Feature | grep -v '/Tests/' | grep -v '/Derived/' | wc -l`로 확인한다. 다르면 중단하고 research를 갱신하도록 보고한다.

**진행 점검**: 결과를 보고하고 실행 단위 1로 진행한다.

---

## 실행 단위 1: 공용 경로 정리 (단일 패키지: Feature)

**목표**: FR-022 위반 경로 P1~P3을 공용 디렉터리로 순수 이동하고, 새 형태 폴더 `Reducers/`를 컨벤션 문서에 등록한다.

**소유 경로**: `sources/Projects/Feature/Shared/**`(새 파일), 아래에 적은 이동 전 경로, `docs/conventions/file-vocabulary/shape-vocabulary.md`, `docs/conventions/directory-file/feature-layout.md`

**관련 변경 시나리오**: S2

**독립 검증**: 이동한 타입의 참조가 모두 compile되고, 이동한 테스트가 그대로 통과한다.

### 구현

- [X] T002 [P] [S2] `sources/Projects/Feature/MainShell/Router/MainShellAccess.swift`를 `sources/Projects/Feature/Shared/Models/MainShellAccess.swift`로 순수 이동한다(P1)
- [X] T003 [P] [S2] `sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift`를 `sources/Projects/Feature/Shared/Reducers/SingleQuestionEntryFeature.swift`로 순수 이동하고, 빈 `ProjectDetail/SingleQuestionEntry/` 디렉터리를 남기지 않는다(P2)
- [X] T004 [P] [S2] `sources/Projects/Feature/Onboarding/LegalAgreement/LegalAgreementFeature.swift`를 `sources/Projects/Feature/Shared/Reducers/LegalAgreementFeature.swift`로 순수 이동한다. `LegalAgreementScreen`과 그 SubViews·Previews는 제자리에 둔다(P3)
- [X] T005 [P] [S2] `sources/Projects/Feature/Tests/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeatureTests.swift`를 `sources/Projects/Feature/Tests/Shared/Reducers/SingleQuestionEntryFeatureTests.swift`로 순수 이동한다
- [X] T006 [P] [S2] `sources/Projects/Feature/Tests/Onboarding/LegalAgreement/LegalAgreementFeatureTests.swift`를 `sources/Projects/Feature/Tests/Shared/Reducers/LegalAgreementFeatureTests.swift`로 순수 이동한다
- [X] T007 [P] [S2] `docs/conventions/file-vocabulary/shape-vocabulary.md`의 형태 어휘 표에 `Feature/Shared/` 행(`Views/`, `Models/`, `Reducers/` — 둘 이상 흐름이 쓰는 View·값 타입·기능 Feature)과 `Feature/<흐름>/Shared/`의 `Reducers/` 행(같은 흐름의 둘 이상 화면이 합성하는 기능 Feature)을 추가한다
- [X] T008 [P] [S2] `docs/conventions/directory-file/feature-layout.md`에 기능 Feature 배치 규칙을 추가한다. 규칙: 한 화면만 쓰면 화면 폴더, 한 전환 계층만 쓰면 `Router/`, 같은 흐름 여러 화면이면 `<흐름>/Shared/Reducers/`, 둘 이상 흐름이면 `Feature/Shared/Reducers/`. `Feature/Shared/**`는 흐름 디렉터리를 참조하지 않는다는 규칙도 추가한다. 또 화면 폴더의 Screen이 공용 기능 Feature를 직접 관찰할 수 있다는 규칙을 추가한다. 이때 그 화면 폴더에는 Feature 파일이 없을 수 있다(예: `Onboarding/LegalAgreement/`). 근거는 research §2다

### 정리와 단위 검증

- [X] T009 [no-write] `make tuist` 후 `"$project_build_runner" compile`과 `"$project_build_runner" test`를 순서대로 실행한다. 이동한 두 테스트 파일의 `@Test`가 모두 통과하는지 확인한다

**진행 점검**: T002~T009의 변경 파일과 검증 결과를 보고하고 실행 단위 2로 진행한다.

---

## 실행 단위 2: 사용자 프로필 조회 추출 (단일 패키지: Feature)

**목표**: I1 `UserProfileLoadFeature`를 추출한다. Home·Profile·Settings를 합성으로 전환하고, SettingsRouter의 자식 필드 직접 쓰기(R3)를 `replace` input으로 바꾼다. 단위 완료 시점에 프로필 조회 상태 선언이 한 벌만 남는다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S2

**독립 검증**: `UserProfileLoadFeatureTests`가 화면 없이 계약의 모든 행을 검증한다. 화면 테스트는 위임과 후속 동작만 단언한다.

### 테스트

- [ ] T010 [S2] `sources/Projects/Feature/Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift`를 작성한다. 검증 범위는 계약의 `load`·`reload`·`replace` 전이, request identity로 늦은 응답 거부, `loaded` 중 `reload` 실패 무시, `load` 실패 시 `.failed`, 비`UserInfoError`를 `.temporarilyUnavailable`로 변환하는 것이다. Test Double은 클로저로 주입한다

### 구현

- [ ] T011 [S2] `sources/Projects/Feature/Shared/Reducers/UserProfileLoadFeature.swift`에 `UserProfileLoadFeature`를 구현한다. State는 `load: Load`, `requestID`, computed `profile`이다. 입력은 `input.load/reload/replace(UserProfile)`, 생성자는 `profile:`다. `Load` 중첩 타입이 파일을 나눌 만큼 크면 `UserProfileLoadFeature+Load.swift`로 분할해 타입 패밀리 폴더 `Shared/Reducers/UserProfileLoadFeature/`에 둔다
- [ ] T012 [S2] `sources/Projects/Feature/Home/HomeFeature.swift`에서 `profileLoad`·`profileRequestID`·프로필 Effect를 제거한다. `profile: UserProfileLoadFeature.State`를 `Scope`로 합성하고, 기존 시작·재시도 조건(research §4 I1)을 input 전송으로 옮긴다. 생성자 시그니처는 유지한다
- [ ] T013 [P] [S2] `sources/Projects/Feature/Home/ViewModels/HomeProfileDisplay.swift`가 `UserProfileLoadFeature.State.Load`(또는 그 State)를 입력으로 받게 바꾼다. 표시 결과는 바꾸지 않는다
- [ ] T014 [S2] `sources/Projects/Feature/Home/HomeScreen.swift`, `sources/Projects/Feature/Home/SubViews/HomeScreen+ProfileHeaderView.swift`, `sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift`의 프로필 상태 참조를 새 경로로 바꾼다. 레이아웃·컴포넌트·토큰은 바꾸지 않는다(FR-023)
- [ ] T015 [S2] `sources/Projects/Feature/Settings/Profile/ProfileFeature.swift`를 `UserProfileLoadFeature`를 합성하는 화면 합성 Feature로 바꾼다. `task`는 `idle/failed → load`, `loaded → reload`, `retryTapped`는 `failed`일 때 `load`를 보낸다. `settingsTapped` delegate는 유지한다
- [ ] T016 [P] [S2] `sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift`가 새 상태 타입을 입력으로 받게 바꾼다. 표시 결과는 바꾸지 않는다
- [ ] T017 [S2] `sources/Projects/Feature/Settings/Profile/ProfileScreen.swift`와 `sources/Projects/Feature/Settings/Profile/Previews/ProfileScreenPreviews.swift`의 상태 참조를 새 경로로 바꾼다
- [ ] T018 [S2] `sources/Projects/Feature/Settings/Settings/SettingsFeature.swift`에서 `profile`·`profileLoad` 저장 필드와 프로필 Effect를 제거한다. `UserProfileLoadFeature`를 합성하고 `task`에서 `load`를 보낸다. 직군·연차 변경 성공 시 `profile.replacing(...)` 결과를 `replace`로 전달한다. 외부 전달용 `input.profileProvided(UserProfile)`를 추가해 자식 `replace`로 넘긴다
- [ ] T019 [S2] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`와 `sources/Projects/Feature/Settings/Settings/Previews/SettingsScreenPreviews.swift`의 프로필 참조를 새 경로로 바꾼다
- [ ] T020 [S2] `sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift`의 `settings.profile`·`settings.profileLoad`·`profile.profileLoad` 직접 쓰기를 제거한다. 화면 이동 시 조회 완료된 프로필을 상대 화면에 input(`settings.input.profileProvided`, `profile.profile.input.replace`)으로 전달한다(R3)

### 테스트 이관

- [ ] T021 [S2] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureLoadTests.swift`, `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGuestAccessTests.swift`, `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationProgressTests.swift`, `sources/Projects/Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`에서 프로필 내부 전이 단언을 제거하고, `profile` 자식으로의 위임과 화면 고유 결과만 단언하게 바꾼다
- [ ] T022 [P] [S2] `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProfileDisplayTests.swift`의 입력 구성을 새 상태 타입으로 바꾼다
- [ ] T023 [S2] `sources/Projects/Feature/Tests/Settings/Profile/ProfileFeatureTests.swift`를 합성 지점 검증으로 바꾼다. 검증 범위는 `task` 분기에 따른 input 전송과 `settingsRequested`다. 옮겨진 전이 단언은 T010에 대응시킨다
- [ ] T024 [P] [S2] `sources/Projects/Feature/Tests/Settings/Profile/ViewModels/ProfileDisplayTests.swift`의 입력 구성을 새 상태 타입으로 바꾼다
- [ ] T025 [S2] `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureTests.swift`, `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift`, `sources/Projects/Feature/Tests/Settings/TestDoubles/SettingsTestFixture.swift`의 프로필 상태 참조와 단언을 새 경로로 바꾼다. 변경 성공 뒤 `replace` 전달도 단언한다
- [ ] T026 [S2] `sources/Projects/Feature/Tests/Settings/Router/SettingsRouterFeatureTests.swift`가 input 전달로 프로필을 동기화하는지 단언하게 바꾼다
- [ ] T027 [S2] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`의 `home.profileLoad` 참조를 새 경로로 바꾼다
- [ ] T028 [S2] `specs/041-feature-composition-refactor/research.md` §6에 U2 이관 대응표를 추가한다. 대상은 T021~T027에서 바꾸거나 제거한 모든 `@Test`다

### 정리와 단위 검증

- [ ] T029 [no-write] [S2] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다. `grep -rn 'ProfileLoad\b\|profileRequestID' sources/Projects/Feature --include='*.swift' | grep -v '/Derived/'`로 `UserProfileLoadFeature` 밖에 선언이 남지 않았는지 확인한다(FR-003)

**진행 점검**: T010~T029의 변경 파일과 검증 결과를 보고하고 실행 단위 3으로 진행한다.

---

## 실행 단위 3: 프로젝트 요약 목록 추출 (integration unit: Feature, App)

**목표**: I2 `ProjectSummaryListFeature`를 추출하고 Home·ProjectList를 합성으로 전환한다.

**분리 불가 근거**: `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`(`loadedProject`)와 `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`가 `state.mainShell.home.projectLoad`를 직접 읽고 쓴다. Feature에서 이 필드가 사라지면 App이 compile되지 않는다. 또 T035에서 `projectList.projects`가 읽기 전용 computed가 되면 App 테스트의 직접 설정(`state.mainShell.projectList.projects = …`)도 compile되지 않는다. 그래서 두 패키지 변경을 한 단위로 묶는다. plan.md의 "App 호출부 변경 없음" 판단은 생성자 시그니처 기준이었다. 이 상태 경로 의존은 tasks 단계에서 새로 확인했다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S2

**통합 검증**: Feature와 App test를 포함한 `compile`·`test`가 함께 통과한다.

### 테스트

- [ ] T030 [S2] `sources/Projects/Feature/Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift`를 작성한다. 검증 범위는 `start`(관찰+새로고침), `refresh`의 로딩 표시 조건(`loaded`가 아닐 때만), `list.isLoaded` 필터, `loaded` 뒤 새로고침 실패 무시, request identity, `projectRemoved`, `listUpdated` delegate 방출, 오류 변환(`.unexpected`)이다

### 구현

- [ ] T031 [S2] `sources/Projects/Feature/Shared/Reducers/ProjectSummaryListFeature.swift`에 `ProjectSummaryListFeature`를 구현한다(State `load`, `requestID`; 생성자 `projects:`, `refreshProjects:`)
- [ ] T032 [S2] `sources/Projects/Feature/Home/HomeFeature.swift`에서 `projectLoad`·`projectRequestID`·관찰·새로고침 Effect를 제거한다. `projectSummaries: ProjectSummaryListFeature.State`를 합성하고, 회원 조건·재시도 조건을 input 전송으로 옮긴다. 학습 탭 조회는 자식 State에서 읽는다
- [ ] T033 [P] [S2] `sources/Projects/Feature/Home/ViewModels/HomeProjectSectionState.swift`가 자식 상태를 입력으로 받게 바꾼다. 표시 결과는 바꾸지 않는다
- [ ] T034 [S2] `sources/Projects/Feature/Home/HomeScreen.swift`, `sources/Projects/Feature/Home/SubViews/HomeScreen+ProjectSection.swift`, `sources/Projects/Feature/Home/Previews/HomeScreenPreviews.swift`의 목록 상태 참조를 새 경로로 바꾼다
- [ ] T035 [S2] `sources/Projects/Feature/ProjectList/ProjectListFeature.swift`에서 `projects`·`hasNextPage`·`initialLoad`·`requestID` 저장 필드와 관찰·새로고침 Effect를 제거하고 `projectSummaries`를 합성한다. `projects`·`hasNextPage`는 computed로 제공한다. `listUpdated`를 받으면 페이지네이션 재설정과 빈 목록의 삭제 모드 종료를 수행하고, 새로고침 시작 시 진행 중 다음 페이지 요청을 취소한다. 페이지네이션 상태는 이 단위에서 화면에 남긴다(U7에서 분리)
- [ ] T036 [S2] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`와 `sources/Projects/Feature/ProjectList/Previews/ProjectListScreenPreviews.swift`의 상태 참조를 새 경로로 바꾼다
- [ ] T037 [S2] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`의 `loadedProject`가 `state.mainShell.home.projectSummaries`에서 조회 완료 목록을 읽게 바꾼다(App)

### 테스트 이관

- [ ] T038 [S2] `sources/Projects/Feature/Tests/Home/Home/HomeFeatureLoadTests.swift`, `sources/Projects/Feature/Tests/Home/Home/HomeFeatureNavigationTests.swift`, `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationProgressTests.swift`, `sources/Projects/Feature/Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift`, `sources/Projects/Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`에서 목록 내부 전이 단언을 제거하고 위임과 화면 고유 결과만 단언하게 바꾼다
- [ ] T039 [P] [S2] `sources/Projects/Feature/Tests/Home/Home/ViewModels/HomeProjectSectionStateTests.swift`의 입력 구성을 새 상태 타입으로 바꾼다
- [ ] T040 [S2] `sources/Projects/Feature/Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift`에서 관찰·새로고침 전이 단언을 T030으로 옮기고 합성 지점 검증으로 바꾼다. 빈 목록 새로고침 동작 차이(research §4 I2-1)를 고정하는 테스트를 T030에 둔다
- [ ] T041 [S2] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`의 `home.projectLoad`·`projectList` 목록 상태 참조를 새 경로로 바꾼다
- [ ] T042 [S2] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`의 `home.projectLoad` 설정·단언과 `mainShell.projectList.projects` 직접 설정을 `projectSummaries` 상태 구성으로 바꾼다(App)
- [ ] T043 [S2] `specs/041-feature-composition-refactor/research.md` §6에 U3 이관 대응표를 추가한다

### 정리와 단위 검증

- [ ] T044 [no-write] [S2] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다. Feature·App test가 모두 통과하고, `projectLoad`·`initialLoad` 선언이 `ProjectSummaryListFeature` 밖에 남지 않았는지 grep으로 확인한다

**진행 점검**: T030~T044의 변경 파일과 검증 결과를 보고하고 실행 단위 4로 진행한다.

---

## 실행 단위 4: 프로젝트 삭제 추출 (단일 패키지: Feature)

**목표**: I3 `ProjectDeletionFeature`를 추출하고 ProjectList·ProjectDetail을 합성으로 전환한다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S2

**독립 검증**: `ProjectDeletionFeatureTests`가 정본 규칙과 동작 차이 I3-1·I3-2를 고정한다.

### 테스트

- [ ] T045 [S2] `sources/Projects/Feature/Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift`를 작성한다. 검증 범위는 `request`(`idle`·`failed`에서만), `cancel`(`confirming`·`failed`에서만), `confirm`(`confirming`에서만), 성공·`.notFound` 시 `deleted` delegate, 기타 오류 시 `.failed(id, error)`, `committing` 중 입력 무시다

### 구현

- [ ] T046 [S2] `sources/Projects/Feature/Shared/Reducers/ProjectDeletionFeature.swift`에 `ProjectDeletionFeature`를 구현한다(생성자 `deleteProject:`)
- [ ] T047 [S2] `sources/Projects/Feature/ProjectList/ProjectListFeature.swift`에서 `deletion`과 삭제 Effect를 제거하고 `deletion: ProjectDeletionFeature.State`를 합성한다. `mode == .deleting`일 때만 `request`를 보낸다. `deleted`를 받으면 `projectSummaries`에 `projectRemoved`를 보내고 `projectDeleted` delegate를 보낸다
- [ ] T048 [S2] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`와 `sources/Projects/Feature/ProjectList/Previews/ProjectListScreenPreviews.swift`의 삭제 상태 참조와 확인 UI 액션 연결을 자식 store 스코핑으로 바꾼다
- [ ] T049 [S2] `sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift`에서 `deletion`과 삭제 Effect를 제거하고 `ProjectDeletionFeature`를 합성한다. `deleteTapped`는 메뉴를 닫고 `request(projectID)`를 보내며, `deleted`를 `projectDeleted(projectID:)`로 올린다
- [ ] T050 [S2] `sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift`와 `sources/Projects/Feature/ProjectDetail/Previews/ProjectDetailScreenPreviews.swift`의 삭제 상태 참조를 자식 store 스코핑으로 바꾼다

### 테스트 이관

- [ ] T051 [S2] `sources/Projects/Feature/Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift`의 삭제 전이 단언을 T045로 옮기고 합성 지점(모드 조건, `projectRemoved`·`projectDeleted` 전달)만 남긴다
- [ ] T052 [S2] `sources/Projects/Feature/Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift`의 삭제 전이 단언을 T045로 옮기고 합성 지점(메뉴 닫힘, `projectDeleted` 전달)만 남긴다
- [ ] T053 [S2] `specs/041-feature-composition-refactor/research.md` §6에 U4 이관 대응표를 추가하고, research §4 I3의 동작 차이를 고정한 테스트 이름을 함께 적는다

### 정리와 단위 검증

- [ ] T054 [no-write] [S2] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행하고, 삭제 상태 enum 선언이 `ProjectDeletionFeature` 밖에 남지 않았는지 grep으로 확인한다

**진행 점검**: T045~T054의 변경 파일과 검증 결과를 보고하고 실행 단위 5로 진행한다.

---

## 실행 단위 5: 로그인 추출 (단일 패키지: Feature)

**목표**: I4 `SignInFeature`를 추출한다. `GuestSignInFeature`를 제거하고 MainShell·Tutorial·OnboardingRouter를 합성으로 전환한다. 동의 화면은 `SignInFeature`가 소유하는 오버레이로 옮긴다(R4 일부).

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S2

**독립 검증**: `SignInFeatureTests`가 두 흐름의 공통 전이를 화면 없이 검증한다. 화면·전환 계층 테스트는 시작 신호와 delegate 해석만 단언한다.

### 테스트

- [ ] T055 [S2] `sources/Projects/Feature/Tests/Shared/Reducers/SignInFeatureTests.swift`를 작성한다. 검증 범위는 `prepareConsent`, `start`(`idle`·`cancelled`·`failed`에서만), 동의 미적재 시 적재 대기 후 판단(차이 I4-1), 동의 유효 시 즉시 로그인, 동의 필요 시 `.agreeingToPolicies`, `consentCompleted` → 로그인, `cancelled` → `consentCancelled`, 결과별 `signedIn`·`.cancelled`+`signInCancelled`·`.failed`, `failureDismissed`, requestID와 `phase == .signingIn` 동시 검증이다

### 구현

- [ ] T056 [S2] `sources/Projects/Feature/Shared/Reducers/SignInFeature/SignInFeature+Phase.swift`에 `SignInFeature.Phase`(`idle`, `checkingConsent`, `agreeingToPolicies`, `signingIn`, `cancelled`, `failed`)를 선언한다
- [ ] T057 [S2] `sources/Projects/Feature/Shared/Reducers/SignInFeature/SignInFeature.swift`에 `SignInFeature`를 구현한다. `legalAgreement` 자식을 항상 보유하고, 생성자는 `signIn:`, `policyConsentStatus:`, `consent:`다
- [ ] T058 [S2] `sources/Projects/Feature/MainShell/Router/GuestSignInFeature.swift`와 `sources/Projects/Feature/MainShell/Router/GuestSignInFeature+Phase.swift`를 삭제한다
- [ ] T059 [S2] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`의 `guestSignIn`을 `signIn: SignInFeature.State` 합성으로 바꾼다. 비회원 `signInTapped`·Home `signInRequested` → `start`, `signedIn` → `signInSucceeded(needsCuration:)`로 연결한다. 생성자 시그니처는 유지한다
- [ ] T060 [S2] `sources/Projects/Feature/MainShell/Router/MainShellRouter.swift`의 동의 오버레이·WebSheet·실패 alert가 `signIn` 자식 store를 관찰하게 바꾼다. 표현은 유지한다
- [ ] T061 [S2] `sources/Projects/Feature/Onboarding/Tutorial/TutorialFeature.swift`에서 `authentication`·`requestID`·로그인 Effect를 제거하고 `SignInFeature`를 합성한다. 옮기는 동작은 다음과 같다. 표시 시 `prepareConsent`, `appleSignInTapped` → `page = 3`과 `start`, `consentCancelled` → 마지막 페이지. 개발용 계정 재설정은 `withdraw` 후 `start`하는 후속 동작으로 옮기고 `accountReset` 진행 상태를 둔다. `signedIn` → `signInSucceeded`. `signInRequested`·`input.startSignIn`·`input.returnToLastPage` 중 쓰이지 않게 된 Action은 제거한다
- [ ] T062 [S2] `sources/Projects/Feature/Onboarding/Tutorial/TutorialScreen.swift`, `sources/Projects/Feature/Onboarding/Tutorial/SubViews/TutorialScreen+SignInSection.swift`, `sources/Projects/Feature/Onboarding/Tutorial/Previews/TutorialScreenPreviews.swift`의 인라인 오류·진행 표시가 `signIn` 자식 상태(`cancelled`·`failed`·`signingIn`)와 `accountReset`을 관찰하게 바꾼다
- [ ] T063 [S2] `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift`에서 `legalAgreement` 자식과 `ActiveScreen.Guide.legalAgreement` case, 동의 분기, `legalAgreementDismissed`·`legalDocumentSheetDismissed` view action을 제거한다. `tutorial.delegate.signInSucceeded` 해석은 유지한다. 생성자 시그니처는 유지하고 로그인 의존성은 Tutorial에 전달한다
- [ ] T064 [S2] `sources/Projects/Feature/Onboarding/Router/OnboardingRouter.swift`와 `sources/Projects/Feature/Onboarding/Router/Previews/OnboardingRouterPreviews.swift`의 동의 오버레이가 `tutorial.signIn` 자식 store를 관찰하게 바꾼다

### 테스트 이관

- [ ] T065 [S2] `sources/Projects/Feature/Tests/MainShell/Router/GuestSignInFeatureTests.swift`의 각 `@Test`를 T055에 대응시킨 뒤 파일을 삭제한다
- [ ] T066 [S2] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift`와 `sources/Projects/Feature/Tests/MainShell/TestDoubles/MainShellAccountUseCaseStub.swift`를 `signIn` 자식으로의 시작 신호와 `signInSucceeded` 전달 검증으로 바꾼다
- [ ] T067 [S2] `sources/Projects/Feature/Tests/Onboarding/Tutorial/TutorialFeatureTests.swift`와 `sources/Projects/Feature/Tests/Onboarding/Tutorial/TutorialAccessibilityTests.swift`를 합성 지점과 화면 고유 후속 동작(페이지, 계정 재설정) 검증으로 바꾼다
- [ ] T068 [S2] `sources/Projects/Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift`와 `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestSupport.swift`에서 동의 화면 전환과 이동 이벤트 단언을 제거하고(차이 I4-2), 로그인 성공 delegate 해석만 남긴다
- [ ] T069 [S2] `specs/041-feature-composition-refactor/research.md` §6에 U5 이관 대응표를 추가한다

### 정리와 단위 검증

- [ ] T070 [no-write] [S2] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다. App test(`AppRootFeatureGuestAccessTests`)도 통과하는지, `GuestSignIn` 문자열이 소스에 남지 않았는지 grep으로 확인한다

**진행 점검**: T055~T070의 변경 파일과 검증 결과를 보고하고 실행 단위 6으로 진행한다.

---

## 실행 단위 6: Settings 화면 정리 (단일 패키지: Feature)

**목표**: `SettingsFeature`의 화면 고유 관심사 S1~S3을 기능 Feature로 분리한다(SC-008).

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S3

**독립 검증**: 분리한 세 Feature가 각자 테스트를 가진다. `SettingsFeatureTests`는 합성 지점만 단언한다.

### 테스트

- [ ] T071 [P] [S3] `sources/Projects/Feature/Tests/Settings/Settings/CurationUpdateFeatureTests.swift`를 작성한다. 검증 범위는 직군·연차 각각의 `committing` 중 무시, 성공 시 `positionUpdated`·`careerLevelUpdated`, 실패 시 `.failed`다
- [ ] T072 [P] [S3] `sources/Projects/Feature/Tests/Settings/Settings/AccountActionFeatureTests.swift`를 작성한다. `SettingsFeatureAccountActionTests.swift`의 계정 동작 전이를 옮겨 온다
- [ ] T073 [P] [S3] `sources/Projects/Feature/Tests/Settings/Settings/NotificationPermissionFeatureTests.swift`를 작성한다. 검증 범위는 `refresh`와 `rowTapped`의 권한별 분기다

### 구현

- [ ] T074 [P] [S3] `sources/Projects/Feature/Settings/Settings/CurationUpdateFeature.swift`에 `CurationUpdateFeature`를 구현한다(생성자 `updatePosition:`, `updateCareerLevel:`)
- [ ] T075 [P] [S3] `sources/Projects/Feature/Settings/Settings/AccountActionFeature.swift`에 `AccountActionFeature`를 구현한다(생성자 `signOut:`, `withdraw:`)
- [ ] T076 [P] [S3] `sources/Projects/Feature/Settings/Settings/NotificationPermissionFeature.swift`에 `NotificationPermissionFeature`를 구현한다(생성자 `notificationAuthorization:`, `requestNotificationAuthorization:`, `openNotificationSettings:`)
- [ ] T077 [S3] `sources/Projects/Feature/Settings/Settings/SettingsFeature.swift`에서 `positionMutation`·`careerLevelMutation`·`accountAction`·`notificationStatus`와 관련 Effect를 제거하고 세 Feature를 합성한다. 자식 delegate를 기존 delegate로 바꿔 올리고, `CurationUpdateFeature`의 결과를 프로필 `replace`로 연결한다. 생성자 시그니처는 유지한다
- [ ] T078 [S3] `sources/Projects/Feature/Settings/Settings/SettingsScreen.swift`, `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+AccountDeletionView.swift`, `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+PositionSelectionView.swift`, `sources/Projects/Feature/Settings/Settings/SubViews/SettingsScreen+CareerLevelSelectionView.swift`, `sources/Projects/Feature/Settings/Settings/Previews/SettingsScreenPreviews.swift`의 상태 참조와 액션 연결을 자식 store 스코핑으로 바꾼다

### 테스트 이관

- [ ] T079 [S3] `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureTests.swift`와 `sources/Projects/Feature/Tests/Settings/TestDoubles/SettingsTestFixture.swift`를 합성 지점(자식 위임, delegate 전달, 프로필 `replace` 연결) 검증으로 바꾼다
- [ ] T080 [S3] `sources/Projects/Feature/Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift`의 각 `@Test`를 T072 또는 T079에 대응시킨 뒤 파일을 삭제한다
- [ ] T081 [S3] `sources/Projects/Feature/Tests/Settings/Router/SettingsRouterFeatureTests.swift`의 계정 동작 상태 참조를 새 경로로 바꾼다
- [ ] T082 [S3] `specs/041-feature-composition-refactor/research.md` §6에 U6 이관 대응표를 추가한다

### 정리와 단위 검증

- [ ] T083 [no-write] [S3] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다

**진행 점검**: T071~T083의 변경 파일과 검증 결과를 보고하고 실행 단위 7로 진행한다.

---

## 실행 단위 7: ProjectList 화면 정리 (단일 패키지: Feature)

**목표**: I2′ `ProjectListPaginationFeature`를 분리한다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S3

**독립 검증**: 페이지네이션 전이가 화면 없이 검증된다.

- [ ] T084 [S3] `sources/Projects/Feature/Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift`를 작성한다. 검증 범위는 `nextPageRequested`(`idle`만), `retry`(`failed`만), `listReplaced(hasNextPage:)`, `refreshStarted` 취소, 결과별 `idle`·`exhausted`·`failed`다
- [ ] T085 [S3] `sources/Projects/Feature/ProjectList/ProjectListPaginationFeature.swift`에 `ProjectListPaginationFeature`를 구현한다(생성자 `requestNextPage:`)
- [ ] T086 [S3] `sources/Projects/Feature/ProjectList/ProjectListFeature.swift`에서 `pagination`과 다음 페이지 Effect를 제거하고 합성한다. 목록 조건(`loaded`, `hasNextPage`)은 부모가 판정한 뒤 `nextPageRequested`를 보낸다
- [ ] T087 [S3] `sources/Projects/Feature/ProjectList/ProjectListScreen.swift`, `sources/Projects/Feature/ProjectList/SubViews/ProjectListScreen+NextPageFooter.swift`, `sources/Projects/Feature/ProjectList/Previews/ProjectListScreenPreviews.swift`의 페이지네이션 참조를 자식 store 스코핑으로 바꾼다
- [ ] T088 [S3] `sources/Projects/Feature/Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift`의 페이지네이션 전이 단언을 T084로 옮기고 합성 지점만 남긴다
- [ ] T089 [S3] `specs/041-feature-composition-refactor/research.md` §6에 U7 이관 대응표를 추가한다
- [ ] T090 [no-write] [S3] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다

**진행 점검**: T084~T090의 변경 파일과 검증 결과를 보고하고 실행 단위 8로 진행한다.

---

## 실행 단위 8: ProjectDetail 화면 정리 (integration unit: Feature, App)

**목표**: S4 `ProjectDetailLoadFeature`를 분리한다.

**분리 불가 근거**: `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`가 `projectDetail.projectDetail.loadStatus`를 직접 단언한다. Feature에서 이 필드가 `ProjectDetailLoadFeature`로 옮겨지면 App 테스트가 compile되지 않으므로 두 패키지 변경을 한 단위로 묶는다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S3

**통합 검증**: 상세 조회 전이가 화면 없이 검증되고, Feature와 App test를 포함한 `compile`·`test`가 함께 통과한다.

- [ ] T091 [S3] `sources/Projects/Feature/Tests/ProjectDetail/ProjectDetail/ProjectDetailLoadFeatureTests.swift`를 작성한다. 검증 범위는 `load`(무조건 `.loading`), request identity, 성공·실패, 파생값 `firstIncompleteSet`·`isResumeEnabled`·`isEmpty`다
- [ ] T092 [S3] `sources/Projects/Feature/ProjectDetail/ProjectDetailLoadFeature.swift`에 `ProjectDetailLoadFeature`를 구현한다(생성자 `projectDetail:`)
- [ ] T093 [S3] `sources/Projects/Feature/ProjectDetail/ProjectDetailFeature.swift`에서 `detail`·`loadStatus`·`requestID`와 조회 Effect를 제거하고 합성한다. `task`·`retryTapped`·`refreshRequested`는 `load`를 보낸다. 생성자 시그니처는 유지한다
- [ ] T094 [S3] `sources/Projects/Feature/ProjectDetail/ProjectDetailScreen.swift`, `sources/Projects/Feature/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift`, `sources/Projects/Feature/ProjectDetail/Previews/ProjectDetailScreenPreviews.swift`의 참조를 자식 store 스코핑으로 바꾼다
- [ ] T095 [S3] `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift`와 `sources/Projects/Feature/ProjectDetail/Router/Previews/ProjectDetailRouterPreviews.swift`의 `projectDetail.detail` 등 상태 참조를 새 경로로 바꾼다
- [ ] T096 [S3] `sources/Projects/Feature/Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift`의 조회 전이 단언을 T091로 옮기고 합성 지점만 남긴다. `sources/Projects/Feature/Tests/ProjectDetail/Router/ProjectDetailRouterFeatureTests.swift`와 `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`(App)의 `projectDetail.loadStatus` 참조를 새 경로로 바꾼다
- [ ] T097 [S3] `specs/041-feature-composition-refactor/research.md` §6에 U8 이관 대응표를 추가한다
- [ ] T098 [no-write] [S3] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다(App test 포함)

**진행 점검**: T091~T098의 변경 파일과 검증 결과를 보고하고 실행 단위 9로 진행한다.

---

## 실행 단위 9: 전환 계층 input 전환 (단일 패키지: Feature)

**목표**: R4(잔여)·R5에 해당하는 전환 계층의 자식 필드 직접 쓰기를 input으로 바꾼다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S3

**독립 검증**: 각 자식의 새 input이 자식 테스트로 검증되고, Router 테스트는 input 전송을 단언한다.

- [ ] T099 [P] [S3] `sources/Projects/Feature/Onboarding/CareerSelection/CareerSelectionFeature.swift`에 `input.positionProvided(MemberPosition)`을 추가하고 `position`의 외부 setter를 제거한다. 테스트는 `sources/Projects/Feature/Tests/Onboarding/CareerSelection/CareerSelectionFeatureTests.swift`에 추가한다
- [ ] T100 [P] [S3] `sources/Projects/Feature/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift`에 `input.repositoryProvided(ExternalRepository)`와 `input.cleared`를 추가한다. 테스트는 `sources/Projects/Feature/Tests/ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeatureTests.swift`로 새로 작성한다
- [ ] T101 [P] [S3] `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift`에 `input.validationReset`을 추가한다. 테스트는 `sources/Projects/Feature/Tests/ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeatureTests.swift`에 추가한다
- [ ] T102 [S3] `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift`의 `careerSelection.position = p`를 `positionProvided` input 전송으로 바꾼다
- [ ] T103 [S3] `sources/Projects/Feature/ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift`의 `repositoryConfirmation.repository`·`repositoryLinkInput.validation` 직접 쓰기를 T100·T101의 input 전송으로 바꾼다. `sources/Projects/Feature/ProjectRegistration/Router/Previews/ProjectRegistrationRouterPreviews.swift`와 `sources/Projects/Feature/ProjectRegistration/RepositoryLinkInput/Previews/RepositoryLinkInputScreenPreviews.swift`는 compile에 필요한 경우에만 State 구성을 맞춘다
- [ ] T104 [S3] `sources/Projects/Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift`와 `sources/Projects/Feature/Tests/ProjectRegistration/Router/ProjectRegistrationRouterFeatureTests.swift`가 input 전송 결과를 단언하게 바꾼다
- [ ] T105 [S3] `specs/041-feature-composition-refactor/research.md` §6에 U9 이관 대응표를 추가한다
- [ ] T106 [no-write] [S3] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다

**진행 점검**: T099~T106의 변경 파일과 검증 결과를 보고하고 실행 단위 10으로 진행한다.

---

## 실행 단위 10: Quiz 학습 세션 분리 (단일 패키지: Feature)

**목표**: R1 `LearningSessionFeature`를 분리해 `QuizRouterFeature`에 전환 상태만 남긴다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S3

**독립 검증**: 세션 진행 규칙이 Router 없이 검증된다.

- [ ] T107 [S3] `sources/Projects/Feature/Tests/Quiz/Router/LearningSessionFeatureTests.swift`를 작성한다. 검증 범위는 `started`(시작 인덱스·범위 밖이면 `emptySetDetected`), `answerRecorded` 누적, `advanced`(다음 문항 `questionReady`·마지막이면 `completed`와 정답 수 합산), 이미 시작한 세션의 재시작 처리다
- [ ] T108 [S3] `sources/Projects/Feature/Quiz/Router/LearningSessionFeature.swift`에 `LearningSessionFeature`를 구현한다(의존성 없음)
- [ ] T109 [S3] `sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift`에서 `learningSet`·`currentQuestionIndex`·`resumption`·`sessionCorrectChoiceCount`·`bookmarkedQuestionIDs`를 제거하고 `session`을 합성한다. 세션 delegate로 `QuestionSolvingFeature.State` 생성, `learningCompletion` 구성, 화면 전환을 수행한다. 생성자 시그니처는 유지한다
- [ ] T110 [S3] `sources/Projects/Feature/Quiz/Router/Previews/QuizRouterPreviews.swift`의 State 구성을 새 구조에 맞춘다
- [ ] T111 [S3] `sources/Projects/Feature/Tests/Quiz/Router/QuizRouterFeatureTests.swift`의 세션 진행 단언을 T107로 옮기고 전환·이동 이벤트 검증만 남긴다
- [ ] T112 [S3] `specs/041-feature-composition-refactor/research.md` §6에 U10 이관 대응표를 추가한다
- [ ] T113 [no-write] [S3] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행한다

**진행 점검**: T107~T113의 변경 파일과 검증 결과를 보고하고 실행 단위 11로 진행한다.

---

## 실행 단위 11: 공유 등록 분리 (단일 패키지: Feature)

**목표**: R2 `SharedRepositoryRegistrationFeature`를 분리해 `ShareRegistrationFeature`에 단계 전환만 남긴다. 타입 이름·파일 위치·App 호출부는 유지한다.

**소유 경로**: 아래 작업의 파일

**관련 변경 시나리오**: S3

**독립 검증**: 검증·등록 전이와 진단 기록이 전환 계층 없이 검증된다. `App/ShareExtension/ShareViewController.swift`는 수정 없이 compile된다.

- [ ] T114 [S3] `sources/Projects/Feature/Tests/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift`를 작성한다. 기존 Validation·Submission·Failure·Diagnostics 테스트의 검증·등록 전이와 진단 이벤트 단언을 옮겨 온다
- [ ] T115 [S3] `sources/Projects/Feature/ShareRegistration/SharedRepositoryRegistrationFeature.swift`에 `SharedRepositoryRegistrationFeature`를 구현한다(생성자 `parseRepositoryLink:`, `externalRepository:`, `projectGeneration:`, `signInAvailability:`, `recordDiagnostic:`)
- [ ] T116 [S3] `sources/Projects/Feature/ShareRegistration/ShareRegistrationFeature.swift`의 `status`를 `step`(단계 3개)과 `registration` 자식 합성으로 바꾼다. `repositoryResolved` → 확인 단계와 `repositoryConfirmation.input.repositoryProvided`, 생성 확인 `submitRequested` → `registration.input.submit`로 연결한다. `canDismiss`·`canRetry`는 자식에서 파생하고 `dismiss`는 유지한다. 생성자 시그니처와 `State()` 초기화는 유지한다
- [ ] T117 [S3] `sources/Projects/Feature/ShareRegistration/ShareRegistrationScreen.swift`, `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift`, `sources/Projects/Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift`, `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift`, `sources/Projects/Feature/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift`의 상태 참조를 새 구조로 바꾼다. 표현은 유지한다
- [ ] T118 [S3] `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureValidationTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureStepTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureSubmissionTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationFeatureFailureTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/ShareRegistrationDiagnosticsTests.swift`, `sources/Projects/Feature/Tests/ShareRegistration/TestDoubles/ShareRegistrationTestSupport.swift`를 단계 전환과 자식 위임 검증으로 바꾼다. 옮긴 단언은 T114에 대응시킨다. 내용이 모두 옮겨진 파일은 삭제한다
- [ ] T119 [S3] `specs/041-feature-composition-refactor/research.md` §6에 U11 이관 대응표를 추가한다
- [ ] T120 [no-write] [S3] `"$project_build_runner" compile` 후 `"$project_build_runner" test`를 실행하고, `git diff --stat -- sources/Projects/App`에 변경이 없는지 확인한다

**진행 점검**: T114~T120의 변경 파일과 검증 결과를 보고하고 실행 단위 12로 진행한다.

---

## 실행 단위 12: 컨벤션 문서화 (단일 패키지: Feature)

**목표**: 분해 기준과 최종 분류·제외 사유·동작 차이를 컨벤션 문서에 확정한다(FR-020, 시나리오 4).

**소유 경로**: `docs/conventions/tca/feature.md`, `docs/conventions/tca/feature/classification.md`

**관련 변경 시나리오**: S4

**독립 검증**: 문서만 읽고 임의 Feature의 분류와 기준 준수 여부를 판정할 수 있다(SC-009).

- [ ] T121 [S4] `docs/conventions/tca/feature/classification.md`를 새로 작성한다. 내용은 세 분류와 판정 규칙(research §1), 공용 경계 배치(research §2 요약), 리팩토링 완료 시점의 전체 분류표(실제 코드 기준으로 research §3.7 확정), 제외 사유 E1~E8, 동작 차이 확정 목록(research §4, 각 항목을 고정하는 테스트 이름 포함)이다. 문서 형식은 `docs/conventions/common/document-structure.md`의 구체 명시 문서 형식을 따른다
- [ ] T122 [S4] `docs/conventions/tca/feature.md`의 §2에 세 분류 판정 원칙을 추가하고 `###` 아래에 `feature/classification.md` 링크를 둔다. §6 검토 체크리스트에 "화면 합성 Feature가 관심사 상태를 직접 선언하지 않는가", "공용 기능 Feature가 흐름을 참조하지 않는가" 항목을 추가하고 최종 수정일을 갱신한다

**진행 점검**: T121~T122의 변경 파일을 보고하고 전체 완료 검증으로 진행한다. 이 단위는 마지막 적용 패키지의 마지막 커밋 단위이므로, 아래 전체 검증과 `after_implement` 훅까지 마친 뒤 commit한다.

---

## 전체 완료 검증

**선행 조건**: 실행 단위 12의 파일 변경을 마쳤고, 마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 실행 단위 12의 커밋 단위에 배정한다. 모든 검증과 필수
`after_implement` hook(`speckit.swift-format.run`)을 마친 뒤 그 단위를 최종 commit한다. 파일 변경
단위가 모두 이미 commit된 단순 재개라면 `tasks.md` 완료 표시만을 위한 별도 최종 검증 단위를 둔다.

- [ ] T123 [no-write] `make tuist` 후 `"$project_build_runner" build`, `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 실행하고 각 결과를 구분해 기록한다(SC-005)
- [ ] T124 [no-write] [S2] `specs/041-feature-composition-refactor/quickstart.md` §2의 세 grep을 실행해 출력이 없는지 확인한다(SC-010, SC-015, FR-012, FR-026)
- [ ] T125 [no-write] [S2] 통합 관심사 I1~I4마다 상태 유형 선언이 정확히 한 파일에만 있는지 grep으로 확인한다(SC-001, SC-003)
- [ ] T126 [no-write] [S3] 비테스트 `@Reducer`가 39개이고 모두 `docs/conventions/tca/feature/classification.md`의 분류표에 한 번씩 나타나는지 대조한다. 화면 합성 Feature의 State에 관심사 상태 필드가 없는지 확인한다(SC-007, SC-008)
- [ ] T127 [no-write] [S2] `specs/041-feature-composition-refactor/research.md` §6에 U2~U11의 대응표가 모두 있고 "이관 뒤 위치"가 빈 행이 없는지 확인한다(SC-011)
- [ ] T128 [no-write] [S3] `git diff --stat develop...HEAD -- sources/Projects/Feature` 기준으로 View 파일 변경이 store 스코핑·자식 View 분리·상태 참조 경로 변경에 한정되는지, 레이아웃 값·컴포넌트·토큰 변경이 없는지 diff를 검토한다(SC-012)
- [ ] T129 [no-write] [S4] `docs/conventions/tca/feature.md`에서 분류 문서로 가는 링크가 유효하고, 분류 문서만으로 research §1의 판정을 재현할 수 있는지 검토한다(SC-009)
- [ ] T130 [no-write] [S3] 참조 방향을 검토한다(SC-010). 각 화면 폴더의 Swift 파일이 다른 화면 폴더의 타입이나 전환 계층(`Router/`, `MainShell/Router/`, `ShareRegistrationFeature`) 타입을 참조하지 않는지 확인한다. `Feature/Shared/**`가 전환 계층 타입을 참조하지 않는지도 확인한다. 분류표 기준으로 `grep -rn` 결과를 대조한다
- [ ] T131 [no-write] [S2] 새 기능 Feature 11개와 이동한 2개의 생성자 파라미터를 검토한다. 각 상위 Feature가 전달하는 인자와 대조해, 상위가 자식을 위해 받은 의존성이 빠짐없이 그대로 전달되고 구현 교체·새 생성이 없는지 확인한다(FR-004, FR-024, SC-013). 기능 Feature 안에 합성한 화면이나 상위를 식별해 분기하는 코드가 없는지도 확인한다(FR-005, SC-006)

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 변경 패키지는 Feature이고 App은 Feature에 의존한다([아키텍처 문서](../../docs/architecture.md)의
  의존 표). App을 포함하는 U3·U8은 Feature 변경과 같은 단위에서 Feature → App 순서로 수정한다.
- 채택한 순서는 U0 → U1 → U2 → U3 → U4 → U5 → U6 → U7 → U8 → U9 → U10 → U11 → U12다. 근거는 다음과 같다.
  - U2→U3: 둘 다 `HomeFeature.swift`를 수정한다.
  - U3→U4→U7: `ProjectListFeature.swift`를 이어서 수정한다.
  - U4→U8: `ProjectDetailFeature.swift`를 이어서 수정한다.
  - U2→U6: `SettingsFeature.swift`를 이어서 수정한다.
  - U5→U9: `OnboardingRouterFeature.swift`를 이어서 수정한다.
  - U9→U11: U11이 U9의 `RepositoryConfirmationFeature.input.repositoryProvided`를 사용한다.
  - U10은 다른 단위와 파일이 겹치지 않지만 순서 고정을 위해 U9 뒤에 둔다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 새 범위, 파괴적 작업, remote·외부 상태 변경, 사용자 소유 변경 소비 또는 새로운 제품 결정이
  필요할 때만 중단하고 승인을 요청한다. 예를 들어 research §4에 없는 사용자 관찰 동작 변경이
  필요해지거나, App의 다른 파일 수정이 필요해지는 경우다.

### 변경 시나리오 추적성

| 시나리오 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| S1 기준 확립과 전수 식별 | T001(산출물은 plan 단계의 research.md) | research §1만으로 §3.7 분류를 재현할 수 있다 |
| S2 관심사 추출 | T002~T070, T124, T125, T127, T131 | 관심사마다 선언이 한 벌이고, 기능 Feature 테스트가 존재하며, 이관 대응표가 완결된다 |
| S3 화면 합성 정리 | T071~T120, T126, T128, T130 | 화면 합성 Feature와 전환 계층이 관심사 상태를 선언하지 않고, View 변경이 최소 범위다 |
| S4 컨벤션 문서화 | T121, T122, T129 | 문서만으로 분류·기준 이탈을 판정할 수 있다 |

### 실행 단위 내부 실행

- 새 기능 Feature 테스트(각 단위의 첫 테스트 작업)는 구현 전에 작성하고, 타입 부재로 compile에
  실패하는 것을 확인한 뒤 구현한다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 쓴다. 병렬 예시는 다음과 같다.
  - U1: T002~T008을 동시에 진행할 수 있다.
  - U2: T013·T016·T022·T024는 각자 다른 파일이다.
  - U6: 세 Feature 테스트 T071~T073과 구현 T074~T076은 서로 독립이다.
  - U9: 자식 input 추가 T099~T101은 서로 독립이다.
- 같은 파일을 변경하는 작업과 Red → Green 의존 작업은 순차로 실행한다.
- 서로 다른 실행 단위를 병렬로 실행하지 않는다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 단위의 미완료 작업을 하나의 목적과 독립 rollback
  경계를 갖는 커밋 단위로 묶는다. U1의 순수 이동(T002~T006)과 문서 갱신(T007~T008)은 목적이
  다르면 커밋을 나눌 수 있다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 검증과 `[X]`
  표시 뒤 해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을 확인하기 전에는 다음 단위를
  시작하지 않는다.
- 마지막 단위(U12)는 전체 완료 검증과 필수 `after_implement` hook까지 마친 뒤 commit한다.

## 구현 전략

1. 이 tasks.md의 blob hash와 전체 diff를 기준선으로 고정하고 첫 미완료 실행 단위(U0)를 선택한다.
2. U0~U5로 중복 관심사 제거(시나리오 2)를 먼저 끝낸다. 최소 가치 범위이며, U5까지 마치면 FR-003이
   달성된다.
3. U6~U11로 화면 합성 정리(시나리오 3)를 진행한다.
4. U12에서 문서를 확정하고 전체 검증과 포맷 hook을 실행한 뒤 최종 commit한다.
5. research §4에 없는 동작 변경이나 계획 밖 App 수정이 필요해지면 변경 전에 중단하고 보고한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 삭제(T058, T065, T080, T118의 일부)는 같은 단위에서 대응표로 대체 테스트를 입증한 뒤 수행한다.
- 문제 해결 기록과 암묵지 기록은 작업 ID로 만들지 않는다.
