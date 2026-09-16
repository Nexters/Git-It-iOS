# 작업 목록: 패키지 의존성 기계 검증과 CompositionAdapter 도메인 축 분할

**입력**: `/specs/034-package-dependency-enforcement/`의 설계 문서

**선행 조건**: [plan.md](./plan.md)(필수), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/README.md](./contracts/README.md), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 실행 기준선으로 고정한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 필요한 경우에만 만든다.

**테스트**: FR-009가 도구 회귀 테스트를 요구하므로 도구 테스트 작업을 구현 앞에 둔다. 분할은 공개 동작을 바꾸지 않으므로 새 Swift 테스트를 만들지 않고 기존 Composition 테스트를 축별 target으로 옮겨 회귀를 확인한다.

**구성**: [plan.md](./plan.md)의 실행 단위 U1, I2, U3, U4, I5, U6, U7을 최상위 구조로 사용하고, 변경 시나리오는 각 단위 안에서 `[S1]`~`[S4]` 라벨로 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- `[P]` — 같은 실행 단위 안에서 서로 다른 파일을 다루고 미완료 작업에 의존하지 않는 작업
- `[S1]` 허용되지 않는 의존 차단 / `[S2]` 설정과 아키텍처 표 대응 / `[S3]` 훅과 무관한 실행 / `[S4]` CompositionAdapter 분할
- `[no-write]` — 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `tuist generate`의 파생 workspace·project와 빌드 산출물 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다. 빌드가 FormatSwift 플러그인으로 현재 단위 파일을 정규화하면 그 결과는 현재 단위에 포함한다

## 실행 단위 소유권 규칙

- 검사 도구(FR-001~FR-014, U1~U4)를 분할(FR-015~FR-019, I5·U6)보다 먼저 둔다. 분할 단위는 도구가 위반 0을 유지하는지로 회귀를 확인한다.
- 패키지에 속하지 않는 파일의 책임: `tools/package-dependencies/**`는 U1(단, `config/source-roots`의 분할 반영은 I5), 경로·셸 검증 등록 파일은 U3, 훅·CI 파일은 U4, `docs/package-rules/composition.md`는 U7.
- I2와 I5는 다중 패키지 단위다. 근거는 [plan.md](./plan.md)의 "I2를 App과 Composition 묶음으로 두는 근거"와 "I5를 다중 패키지 단위로 두는 근거"에 있다.
- 작업 트리의 사용자 소유 변경(`.agents/`, `.gitignore`, `AGENTS.md`, `Makefile`, `docs/registry/`, `tools/**`의 기존 수정, UI `Chip.swift`, Feature `ShareRegistrationTestSupport.swift`)과 이 명세가 다루지 않는 파일의 포맷 변경은 stage하지 않는다.

---

## 작업 단위 1 (U1): 도구 — 검사 도구 본체와 회귀 테스트

**목표**: 아키텍처 3.1 표를 기계가 검증하는 독립 도구를 만든다.

**관련 변경 시나리오**: S1, S2

**독립 테스트**: 회귀 테스트가 통과하고, 저장소 전체 실행이 [research.md](./research.md) 4절의 미선언 import 6건을 정확히 보고한다.

### 준비

- [X] T001 [no-write] 적용 전 지표를 측정해 이 파일의 "기준선 기록" 절에 적는다 — Composition target별 의존 수([quickstart.md](./quickstart.md) 4.1 명령), `sources/Projects/Composition/Adapter` 아래 Swift 파일 수, `tools/githooks/pre-commit.d/enabled`의 활성 단계 수

### 테스트

- [X] T002 [S1] [S2] `tools/package-dependencies/tests/test-package-dependencies.sh`를 만든다. `mktemp -d`에 fixture 저장소(아키텍처 문서, switch·배열 형식이 섞인 `<패키지>ModuleName.swift` 7개, `repository-paths.json`, Swift 소스)를 만들고 `GIT_IT_PATHS_FILE`과 `PACKAGE_DEPENDENCIES_CONFIG_DIR`로 주입해 `bin/run.sh`를 실행한다. [research.md](./research.md) 6절의 12개 경우를 종료 코드와 규칙 이름으로 확인한다. 실행 권한을 준다

### 구현

- [X] T003 [P] [S2] `tools/package-dependencies/config/allowed-dependencies`를 [research.md](./research.md) 1절 형식으로 만든다. 값은 아키텍처 3.1 표와 같다
- [X] T004 [P] [S1] `tools/package-dependencies/config/source-roots`를 만든다. 현재 target 41개 각각의 `<target> <GIT_IT_PROJECTS_ROOT 기준 루트>` 한 줄 (예: `GitItTests App/Tests/GitIt`, `Feature Feature`, `FeatureTests Feature/Tests`, `UIComponentTests UI/Tests/Component/Unit`)
- [X] T005 [P] [S1] `tools/package-dependencies/core/rules-policy.sh`에 argv만 받는 순수 정책을 만든다 — 패키지 조합 허용 판정, 규칙·오류 종류별 이유와 조치 문장([contracts/README.md](./contracts/README.md) 2절)
- [X] T006 [P] [S2] `tools/package-dependencies/core/architecture-table.sh`에 3.1 표를 읽어 `패키지<TAB>정렬된 허용 목록` 레코드를 쓰는 adapter를 만든다. 제목·머리행·행이 없으면 `table-unreadable`
- [X] T007 [P] [S1] `tools/package-dependencies/core/manifest.sh`에 모듈 목록, target 블록(switch·배열 형식), `.from`·`.target`·`productionTarget` 선언을 줄 번호와 함께 레코드로 쓰는 adapter를 만든다([research.md](./research.md) 2절)
- [X] T008 [P] [S1] `tools/package-dependencies/core/imports.sh`에 대상 Swift 파일을 한 번의 `find … -exec awk … {} +`로 읽어 내부 import 후보를 `경로<TAB>줄<TAB>모듈`로 쓰는 adapter를 만든다. 블록 주석(중첩)·여러 줄 문자열·줄 주석을 건너뛰고 속성·종류 키워드를 허용한다([research.md](./research.md) 4절)
- [X] T009 [S1] [S2] `tools/package-dependencies/core/run.sh`에 유스케이스를 만든다 — 설정 검증 → 표 대응 → manifest 일관성 → source root 일관성 → import 판정 → 정렬 보고([data-model.md](./data-model.md) 1.8·1.9절)
- [X] T010 [S1] `tools/package-dependencies/bin/run.sh`에 공개 진입점을 만든다 — 인자 검증, `repository-paths.sh --absolute`로 경로 키 3개 해석, `PACKAGE_DEPENDENCIES_CONFIG_DIR` 기본값, 임시 디렉터리와 trap, core source. 실행 권한을 준다

### 단위 검증

- [X] T011 [no-write] [S1] [S2] `tools/package-dependencies/tests/test-package-dependencies.sh`가 종료 0인지 확인한다
- [X] T012 [no-write] [S1] `tools/package-dependencies/bin/run.sh`를 저장소에서 실행해 종료 1과 `[import-undeclared]` 6건(research 4절 목록)만 보고되는지, 실행 시간이 5초 이하인지 확인한다
- [X] T013 [no-write] `tools/script-verification/.build`의 ShellCheck·shfmt를 `tools/script-verification/config/verification.conf`의 옵션으로 `tools/package-dependencies`에 직접 실행해 통과를 확인한다. 도구가 없으면 `tools/script-verification/bin/prepare-tools.sh`를 먼저 실행한다

**진행 점검**: T001~T013의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 2 (I2): App + Composition — 현행 미선언 import 해소

**분리 불가 근거**: FR-014의 위반 0은 두 패키지 변경이 모두 끝나야 성립한다. 각 변경은 한 줄 수준이다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`

**관련 변경 시나리오**: S1

**독립 테스트**: 도구가 위반 0으로 종료한다.

**통합 검증**: `tuist generate` 후 `App`·`Composition` scheme 빌드.

### 구현

- [X] T014 [P] [S1] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `GitIt` target 의존성에 `.fromDomain(.DomainLearningProject)`와 `.fromDomain(.DomainMember)`를 추가한다
- [X] T015 [P] [S1] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에서 쓰이지 않는 `import DataMember`를 지운다

### 단위 검증

- [X] T016 [no-write] [S1] `tools/package-dependencies/bin/run.sh`가 종료 0과 `위반=0`을 출력하는지 확인한다
- [X] T017 [no-write] `sources`에서 `tuist generate --no-open` 후 `App`·`Composition` scheme을 iPhone 17 Pro 시뮬레이터 대상으로 빌드해 성공을 확인한다

**진행 점검**: T014~T017의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 3 (U3): 도구 등록 — 공개 경로와 셸 검증 대상

**목표**: 도구를 공개 경로 레지스트리와 셸 정적 검사 대상에 등록한다(FR-008·FR-010). 회귀 테스트는 위치만으로 자동 수집된다(FR-009).

**관련 변경 시나리오**: S3

**독립 테스트**: `repository-paths.sh GIT_IT_PACKAGE_DEPENDENCY_RUNNER`가 도구 경로를 출력하고, 셸 회귀와 정적 검사가 통과한다.

### 승인

- [X] T018 [no-write] **승인 필요**: 아래 T019~T023의 다섯 파일에 사용자 미커밋 변경이 있음을 보고하고 "승인이 필요한 지점"의 선택지 중 하나를 확인받는다. 확인 전에는 다섯 파일을 수정하지 않는다

### 구현

- [X] T019 [S3] `tools/repository-paths/repository-paths.json`에 `"GIT_IT_PACKAGE_DEPENDENCY_RUNNER": "tools/package-dependencies/bin/run.sh"`를 추가한다
- [X] T020 [S3] `tools/repository-paths/bin/repository-paths.sh`의 `repository_paths_keys` 목록에 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER`를 추가한다
- [X] T021 [S3] `tools/repository-paths/tests/test-no-hardcoded-paths.sh`의 검사 키 목록에 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER`를 추가한다
- [X] T022 [S3] `tools/script-tests/core/tests.sh`의 환경 격리 `unset` 목록에 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER`를 추가한다
- [X] T023 [S3] `tools/script-verification/config/verification.conf`의 `VERIFICATION_SCRIPT_TARGETS`에 `tools/package-dependencies`를 추가한다

### 단위 검증

- [X] T024 [no-write] [S3] `./tools/repository-paths/bin/repository-paths.sh GIT_IT_PACKAGE_DEPENDENCY_RUNNER`, `./tools/script-tests/bin/run.sh`, `./tools/script-verification/bin/run.sh`가 모두 성공하는지 확인한다

**진행 점검**: T018~T024의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 4 (U4): 훅·CI — pre-commit 단계와 CI 게이트

**목표**: 검사를 pre-commit 단계로 등록하고(FR-011), 훅 활성화와 무관하게 CI 게이트에서 실행한다(FR-012).

**관련 변경 시나리오**: S3

**독립 테스트**: 훅 회귀 테스트가 새 고정 순서를 확인하고, CI gate 테스트가 새 job 결과 전달을 확인한다.

### 테스트

- [X] T025 [P] [S3] `tools/githooks/hook-management/tests/test-pre-commit.sh`의 stub 단계 목록과 기대 실행 순서에 `package-dependencies`를 `design-rules`와 `build` 사이에 추가한다
- [X] T026 [P] [S3] `tools/ci/tests/test-gate-evaluate.sh`에 workflow가 `needs.package-dependencies.result`를 evaluator에 전달하는지 확인하는 검사를 추가한다

### 구현

- [X] T027 [P] [S3] `tools/githooks/pre-commit.d/package-dependencies.sh`를 `tools/githooks/pre-commit.d/design-rules.sh`와 같은 모양으로 만들어 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER`를 실행한다. 실행 권한을 준다
- [X] T028 [S3] `tools/githooks/pre-commit`의 단계 이름 허용 `case`와 고정 순서 `for` 목록에 `package-dependencies`를 `design-rules` 다음에 추가하고 순서 설명 주석을 갱신한다
- [X] T029 [P] [S3] `tools/githooks/pre-commit.d/enabled`의 순서 설명과 단계 설명에 `package-dependencies`를 추가하고 목록에는 주석 처리된 `# package-dependencies`로 둔다
- [X] T030 [P] [S3] `.github/workflows/ci.yml`에 `package-dependencies` job(`needs: changes`, 검증 변수 조건만, `ubuntu-latest`, 경로 로드 후 `"$GIT_IT_PACKAGE_DEPENDENCY_RUNNER"` 실행)을 추가하고 `gate` job의 `needs`와 `gate-evaluate.sh` 인자에 결과를 추가한다

### 단위 검증

- [X] T031 [no-write] [S3] `tools/githooks/hook-management/tests/test-pre-commit.sh`, `tools/ci/tests/test-gate-evaluate.sh`, `./tools/script-verification/bin/run.sh`가 성공하는지 확인한다

**진행 점검**: T025~T031의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 5 (I5): Composition + App + Tuist + 도구 설정 — CompositionAdapter 분할

**분리 불가 근거**: `CompositionAdapter` 모듈이 사라지는 순간 그것을 import하는 조립 루트, 테스트 target, App `ShareExtension` target, `ProjectName`·`AllTestsScheme`, 도구의 `source-roots`가 함께 깨진다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/{ProjectName.swift,AllTestsScheme.swift,Projects/CompositionModuleName.swift,Projects/AppModuleName.swift}`, `sources/Projects/App/ShareExtension/ShareViewController.swift`, `sources/Projects/Composition/{Adapter,Shared,Authentication,LearningProject,Member}/**`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`, `sources/Projects/Composition/Tests/**`, `tools/package-dependencies/config/source-roots`

**관련 변경 시나리오**: S4

**독립 테스트**: `CompositionAdapter` 참조가 저장소에서 사라지고, 분할 target 4개의 의존 수가 [data-model.md](./data-model.md) 2절과 같다.

**통합 검증**: 도구 위반 0, `tuist generate`, `App`·`Composition` scheme 빌드, `Composition` scheme 테스트 수가 분할 전과 같음.

### 구현 — Tuist

- [X] T032 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 `CompositionAdapter`·`CompositionAdapterTests`를 `CompositionShared`, `CompositionAuthentication`, `CompositionAuthenticationTests`, `CompositionLearningProject`, `CompositionLearningProjectTests`, `CompositionMember`, `CompositionMemberTests`로 바꾼다. 의존은 [data-model.md](./data-model.md) 2.1~2.4절, `CompositionApp`은 `CompositionAdapter` 대신 세 축 target, `CompositionShareExtension`은 Authentication·LearningProject target을 참조하고 나머지 선언은 유지한다. `CompositionAppTests`와 `CompositionShareExtensionTests`의 추가 의존에서 `CompositionAdapter`를 빼고 필요한 축 target을 넣는다
- [X] T033 [P] [S4] `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 Composition `buildTargets`·`testTargets`를 분할 target 목록으로 바꾼다
- [X] T034 [P] [S4] `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`의 `CompositionAdapterTests` 항목을 `CompositionAuthenticationTests`, `CompositionLearningProjectTests`, `CompositionMemberTests` 세 항목으로 바꾼다
- [X] T035 [P] [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 `ShareExtension` target에서 `.fromComposition(.CompositionAdapter)`를 지운다
- [X] T036 [P] [S4] `sources/Projects/App/ShareExtension/ShareViewController.swift`에서 쓰이지 않는 `import CompositionAdapter`를 지운다

### 구현 — Composition production

- [X] T037 [S4] `sources/Projects/Composition/Adapter/Factories/HTTPClientFactory.swift`를 `sources/Projects/Composition/Shared/Factories/HTTPClientFactory.swift`로 `git mv`하고 `makeHTTPClient`를 `public`으로 바꾼다
- [X] T038 [S4] Authentication 축 7개 파일을 `git mv`한다 — `sources/Projects/Composition/Adapter/Adapters/{AuthenticationRepositoryAdapter,LoginSessionRepositoryAdapter,PolicyConsentRepositoryAdapter,SharedSessionMarkerRepositoryAdapter,StoredSessionRepositoryAdapter}.swift` → `sources/Projects/Composition/Authentication/Adapters/`, `sources/Projects/Composition/Adapter/Assemblies/AuthenticationAssembly.swift` → `sources/Projects/Composition/Authentication/Assemblies/`, `sources/Projects/Composition/Adapter/Codings/SessionRecordCoding.swift` → `sources/Projects/Composition/Authentication/Codings/`. `AuthenticationAssembly.swift`에 `import CompositionShared`를 추가한다
- [X] T039 [S4] LearningProject 축 14개 파일을 `git mv`한다 — `sources/Projects/Composition/Adapter/Adapters/{AnswerRepositoryAdapter,BookmarkRepositoryAdapter,ExternalRepositoryLookupAdapter,ExternalRepositoryURLParserAdapter,GenerationOutcomeRepositoryAdapter,GenerationReminderSchedulerAdapter,GenerationStateRepositoryAdapter,LearningProjectRepositoryAdapter,LearningSetRepositoryAdapter,NotificationAuthorizationGatewayAdapter,PendingGenerationReminderStoreAdapter}.swift` → `sources/Projects/Composition/LearningProject/Adapters/`, `sources/Projects/Composition/Adapter/Assemblies/{ExternalRepositoryAssembly,GenerationReminderAssembly,LearningProjectAssembly}.swift` → `sources/Projects/Composition/LearningProject/Assemblies/`. `ExternalRepositoryAssembly.swift`와 `LearningProjectAssembly.swift`에 `import CompositionShared`를 추가한다
- [X] T040 [S4] Member 축 4개 파일을 `git mv`한다 — `sources/Projects/Composition/Adapter/Adapters/{CurationRepositoryAdapter,DeviceIdentifierRepositoryAdapter,MemberRepositoryAdapter}.swift` → `sources/Projects/Composition/Member/Adapters/`, `sources/Projects/Composition/Adapter/Assemblies/MemberAssembly.swift` → `sources/Projects/Composition/Member/Assemblies/`. `MemberAssembly.swift`에 `import CompositionShared`를 추가한다
- [X] T041 [P] [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `import CompositionAdapter`를 `import CompositionAuthentication`, `import CompositionLearningProject`, `import CompositionMember`로 바꾼다
- [X] T042 [P] [S4] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`의 `import CompositionAdapter`를 `import CompositionAuthentication`, `import CompositionLearningProject`로 바꾼다

### 구현 — Composition 테스트

- [X] T043 [S4] Authentication 테스트를 `git mv`하고 `@testable import CompositionAdapter`를 `@testable import CompositionAuthentication`으로 바꾼다 — `sources/Projects/Composition/Tests/Adapter/Adapters/{AuthenticationRepositoryAdapterTests,LoginSessionRepositoryAdapterTests,PolicyConsentRepositoryAdapterTests}.swift` → `sources/Projects/Composition/Tests/Authentication/Adapters/`, `sources/Projects/Composition/Tests/Adapter/Assemblies/AuthenticationAssemblyTests.swift` → `sources/Projects/Composition/Tests/Authentication/Assemblies/`, `sources/Projects/Composition/Tests/Adapter/RefreshSessionReleaseBlockerTests.swift` → `sources/Projects/Composition/Tests/Authentication/`, `sources/Projects/Composition/Tests/Adapter/TestDoubles/RecordingHTTPTransport.swift` → `sources/Projects/Composition/Tests/Authentication/TestDoubles/`
- [X] T044 [S4] LearningProject 테스트를 `git mv`하고 import를 `CompositionLearningProject`로 바꾼다 — `sources/Projects/Composition/Tests/Adapter/Adapters/{AnswerRepositoryAdapterTests,BookmarkRepositoryAdapterTests,ExternalRepositoryLookupAdapterTests,GenerationOutcomeRepositoryAdapterTests,LearningProjectRepositoryAdapterTests,LearningSetRepositoryAdapterTests}.swift` → `sources/Projects/Composition/Tests/LearningProject/Adapters/`, `sources/Projects/Composition/Tests/Adapter/Assemblies/{ExternalRepositoryAssemblyTests,LearningProjectAssemblyTests}.swift` → `sources/Projects/Composition/Tests/LearningProject/Assemblies/`. `sources/Projects/Composition/Tests/LearningProject/TestDoubles/RecordingHTTPTransport.swift`를 T043의 test double과 같은 내용으로 만든다
- [X] T045 [S4] Member 테스트를 `git mv`하고 import를 `CompositionMember`로 바꾼다 — `sources/Projects/Composition/Tests/Adapter/Adapters/MemberRepositoryAdapterTests.swift` → `sources/Projects/Composition/Tests/Member/Adapters/`. `sources/Projects/Composition/Tests/Member/TestDoubles/RecordingHTTPTransport.swift`를 같은 내용으로 만든다
- [X] T046 [S4] App·ShareExtension 조립 테스트의 `@testable import CompositionAdapter`를 실제로 쓰는 축 target import로 바꾼다 — `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`, `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionSharedLifetimeTests.swift`, `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`, `sources/Projects/Composition/Tests/App/SharedLifetimeTests.swift`, `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`

### 구현 — 도구 설정

- [X] T047 [S4] `tools/package-dependencies/config/source-roots`에서 `CompositionAdapter`·`CompositionAdapterTests` 행을 지우고 분할 target 7개 행(`CompositionShared Composition/Shared` 등)을 추가한다

### 단위 검증

- [X] T048 [no-write] [S4] `tools/package-dependencies/bin/run.sh`가 위반 0인지, [quickstart.md](./quickstart.md) 4.2 명령이 `CompositionAdapter` 참조 0과 `Adapter` 아래 Swift 파일 0을 보이는지 확인한다
- [X] T049 [no-write] [S4] `sources`에서 `tuist generate --no-open` 후 `App`·`Composition` scheme 빌드와 `Composition` scheme 테스트를 실행해 빌드 성공과 테스트 합계가 분할 전과 같은지 확인하고, 이 파일의 "기준선 기록"에 테스트 수를 적는다

**진행 점검**: T032~T049의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 6 (U6): Composition + App manifest — 조립 루트 의존 축소

**목표**: `CompositionApp` 9 → 6, `CompositionShareExtension` 8 → 6(FR-016·FR-018).

**관련 변경 시나리오**: S4

**독립 테스트**: [quickstart.md](./quickstart.md) 4.1의 의존 수가 모든 Composition target에서 6 이하이고 `CompositionShared`의 Domain·Data 선언이 0이다.

### 구현 — 축 조립

- [X] T050 [P] [S4] `sources/Projects/Composition/Authentication/Assemblies/AuthenticationAssembly.swift`에 `static func migrateSessionKeychain(sharedKeychainStore:)`와 `init`의 `sharedDefaults: UserDefaults? = AppGroupUserDefaults.makeShared()` 인자, 공개 `recordSharedSessionState`를 추가한다([data-model.md](./data-model.md) 3절)
- [X] T051 [P] [S4] `sources/Projects/Composition/Authentication/Assemblies/SessionAvailabilityAssembly.swift`를 만든다 — `init(keychainStore:sharedDefaults:)`, `resolveSessionAvailability`, `accessTokenProvider`. 동작은 현재 `ShareExtensionComposition.live`의 두 closure와 같다
- [X] T052 [P] [S4] `sources/Projects/Composition/Member/Assemblies/MemberAssembly.swift`에 `makeRegisterCurrentDevice(keychainStore:appVersion:osVersion:deviceTokenProvider:)`를 추가하고 공개 `repository`를 내부 저장으로 바꾼다
- [X] T053 [P] [S4] `sources/Projects/Composition/LearningProject/Assemblies/GenerationReminderAssembly.swift`에 `static func makePendingReminderEnqueue(sharedDefaults:)`를 추가한다

### 구현 — 조립 루트

- [X] T054 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`가 T050·T052 API를 쓰도록 바꾸고 `import DataAuthentication`, `import DataExternalRepository`, `import InfrastructureStorage`를 지운다. 키체인 마이그레이션은 `live` 첫 호출로 유지한다
- [X] T055 [S4] `sources/Projects/Composition/ShareExtension/Assemblies/ShareExtensionComposition.swift`가 T051·T053 API를 쓰도록 바꾸고 `import DataAuthentication`, `import DataLearningProject`를 지운다. `live(…)` 서명은 유지한다
- [X] T056 [S4] `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`에서 `CompositionApp`의 `DataAuthentication`, `DataExternalRepository`, `InfrastructureStorage` 선언과 `CompositionShareExtension`의 `DataAuthentication`, `DataLearningProject` 선언을 지우고, `CompositionAppTests`에 `.fromData(.DataAuthentication)`, `CompositionShareExtensionTests`에 `.fromData(.DataAuthentication)`·`.fromData(.DataLearningProject)`를 추가 선언한다

### 구현 — 테스트

- [X] T057 [S4] 루트 API 변경으로 compile되지 않는 테스트만 고친다. 대상은 `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`, `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`, `sources/Projects/Composition/Tests/ShareExtension/ShareExtensionCompositionTests.swift`로 한정하고, 검증 의도와 기대값은 바꾸지 않는다

### 단위 검증

- [X] T058 [no-write] [S4] [quickstart.md](./quickstart.md) 4.1 명령으로 모든 Composition target 의존 수 6 이하와 `CompositionShared`의 Domain·Data 선언 0을 확인하고, 도구 위반 0을 확인한다
- [X] T059 [no-write] [S4] `sources`에서 `tuist generate --no-open` 후 `App`·`Composition` scheme 빌드와 `Composition` scheme 테스트를 실행해 T049와 같은 테스트 합계가 통과하는지 확인한다

**진행 점검**: T050~T059의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 7 (U7): 문서 — Composition target 구성 기록

**목표**: 분할 결과와 유지 규칙을 패키지 규칙 문서에 남긴다.

**관련 변경 시나리오**: S4

**독립 테스트**: 문서의 target 표가 manifest와 같고 검사 도구 링크가 동작한다.

### 구현

- [ ] T060 [S4] `docs/package-rules/composition.md`에 "Target 구성" 절을 추가한다 — production target 5개와 축, 소속 판단 기준(구현하는 Domain 계약의 모듈), 공용 target의 Domain·Data 의존 금지, target별 다른 패키지 모듈 의존 6개 이하 규칙, `tools/package-dependencies`가 표를 강제한다는 안내

### 단위 검증

- [ ] T061 [no-write] [S4] T060의 target 표를 `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`와 대조하고 문서 링크가 존재하는 경로를 가리키는지 확인한다

**진행 점검**: T060~T061의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 계속한다.

---

## 전체 완료 검증

- [ ] T062 [no-write] `time tools/package-dependencies/bin/run.sh`가 5초 이하, 위반 0인지 확인한다(SC-001·SC-004)
- [ ] T063 [no-write] `./tools/script-tests/bin/run.sh`와 `./tools/script-verification/bin/run.sh`가 성공하는지 확인한다
- [ ] T064 [no-write] `sources`에서 `tuist generate --no-open` 후 `GIT_IT_PROJECT_BUILD_RUNNER build`로 전체 공유 scheme Debug 빌드 성공과 `AllTests` scheme의 분할 target 목록을 확인한다(SC-008)
- [ ] T065 [no-write] `AppTests`와 `Composition` scheme 테스트의 성공·실패 목록이 명세 시작 전과 같은지 확인한다(SC-009). `AppTests`의 기존 실패 `AppRootFeature root 전환` 19건은 기준선이다
- [ ] T066 [no-write] "기준선 기록"의 지표를 다시 재고 [research.md](./research.md) 10절 예상값과 대조한다

---

## 기준선 기록

| 지표 | 적용 전 | 적용 후 |
| --- | --- | --- |
| `CompositionAdapter` 의존 | 12 | |
| `CompositionApp` 의존 | 9 | |
| `CompositionShareExtension` 의존 | 8 | |
| Composition target 의존 최댓값 | 12 | |
| `Composition/Adapter` 아래 Swift 파일 | 26 | |
| 도구 위반 수 | 6 (U1 도입 직후) | |
| 활성 pre-commit 단계 | 0 | |
| `Composition` scheme 테스트 합계 | 61 (정적 `@Test` 51+5+5) | 61 (I5 뒤 15+28+8+5+5) |

## 범위 보정 기록

구현 중 tasks.md에 없던 파일을 고쳐야 했다면 작업 ID 아래에 경로와 이유를 적는다.

- **T005·T009**: 판정 로직을 `tools/package-dependencies/core/judge.sh`로 분리했다. 판정은 수집 레코드 파일 여러 개를 읽으므로 argv만 받는 순수 정책(`rules-policy.sh`)에 둘 수 없고, 유스케이스(`run.sh`)에 두면 수집 순서와 판정이 섞인다. `rules-policy.sh`는 패키지 목록, 허용 판정, 조치 문장만 소유한다. 허용 의존성 설정 판독은 표 판독과 같은 레코드를 만들므로 `architecture-table.sh`에 함께 두었다.
- **T002**: 회귀 경우를 research 6절의 12개에서 14개로 늘렸다(source root 누락, 인자 거부 추가).
- **T012**: 실측 위반 6건, 저장소 전체 실행 0.3초 안팎.
- **T018**: 사용자가 doc-registry 관련 미커밋 변경을 직접 스태시했고, 남은 `tools/script-tests/core/tests.sh`·`tools/script-verification/config/verification.conf`의 같은 변경도 스태시하라고 지시했다(`stash@{0}` "doc-registry 등록 잔여"). 다섯 파일이 HEAD와 같아진 뒤 이 명세의 줄만 추가했다.
- **T024**: `repository-paths.sh GIT_IT_PACKAGE_DEPENDENCY_RUNNER`와 `script-verification/bin/run.sh`는 성공. `script-tests/bin/run.sh`는 `tools/repository-paths/tests/test-no-hardcoded-paths.sh` 하나가 실패한다. 원인은 `d9e7517`에서 커밋된 `.agents/skills/fix-project-swift-lint/agents/openai.yaml`의 `sources/Projects` 문구이며 이 명세의 변경과 무관한 기존 실패다. 나머지 셸 회귀는 통과했다.
- **T030**: CI job을 `ubuntu-latest`가 아니라 `macos-26`에서 실행한다. 공개 경로 판독기 `repository-paths.sh`가 `/usr/bin/plutil`을 쓰므로 경로 적재 단계가 macOS를 요구한다([research.md](./research.md) 7절의 러너 결정 보정). 도구 본체는 여전히 `rg` 없이 POSIX 도구만 쓴다. 새 job은 기존 `test_job` 범위 검사와 겹치지 않도록 `script-quality`와 `swift-lint` 사이에 두었다.
- **T029**: `enabled`의 주석 처리된 단계 목록에 `# package-dependencies`를 `# swift-format` 다음에 추가했다.
- **T046**: `AppCompositionPublicSurfaceTests.swift`는 축 target 타입을 쓰지 않아 `CompositionAdapter` import를 지우기만 했고, 나머지 네 파일은 `SessionRecordCoding`·Authentication Adapter만 쓰므로 `CompositionAuthentication`으로 바꿨다. 이동·수정한 테스트 파일에 이전 빌드의 FormatSwift 정규화 결과(import 정렬, 한 줄 `if` 전개)가 있어 plan의 기준선 규칙대로 이 단위에 포함했다. 비어 남은 `Composition/Adapter/`의 추적되지 않는 `.DS_Store`는 디렉터리와 함께 지웠다.
- **I5 커밋 분리 사고**: staging 명령이 이동 전 경로 때문에 실패했는데 뒤이은 `git commit`이 실행돼, `4212760`에는 `git mv`로 미리 stage된 순수 이름 변경 41개만 들어갔다. 이 커밋은 단독으로 빌드되지 않는다. amend·reset을 쓰지 않는 규칙에 따라 manifest, import, 접근 수준, 새 test double, `source-roots`, 이 기록을 바로 다음 커밋에 담았다. 두 커밋을 합친 상태에서 T048·T049 검증을 통과했다.
- **T056**: `CompositionShareExtensionTests`의 추가 선언에서 production이 이미 선언한 `DomainAuthentication`을 빼고 `DataAuthentication`·`DataLearningProject`를 넣었다. 추가 선언 수는 2다.
- **T057**: 루트 공개 API(`live(…)` 서명, 공개 프로퍼티)가 바뀌지 않아 테스트 수정이 필요 없었다. `Composition` scheme 61개가 그대로 통과했다.
- **T002 재수정**: U3에서 `test-no-hardcoded-paths.sh`의 검사 키에 이 도구가 들어가자, 회귀 fixture가 쓰던 `docs/architecture.md`·`sources/Projects`·`sources/Tuist` 경로 문자열이 중앙 JSON 값의 복제로 판정됐다. fixture 디렉터리 이름을 `architecture-rules.md`·`packages`·`manifest-root`로 바꿨다. 이 검사의 남은 실패는 `openai.yaml` 기존 실패뿐이다.

---

## 의존성과 실행 순서

1. U1 → I2: I2의 완료 판정이 도구 실행이다.
2. I2 → U3: 위반 0 상태에서 등록해야 CI·훅이 처음부터 통과한다.
3. U3 → U4: 훅 단계와 CI job이 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER` 키를 쓴다.
4. U4 → I5: 사용자 지시에 따라 도구를 분할보다 먼저 완성한다. U3이 보류되면 U4도 보류하고 I5로 진행한다.
5. I5 → U6: U6은 분할된 축 조립에 API를 추가한다.
6. U6 → U7: 문서가 최종 의존 수를 기록한다.

시나리오 완료 순서: S2(U1) → S1(U1·I2) → S3(U3·U4) → S4(I5·U6·U7).

## 병렬 실행 기회

- U1: T003~T008은 서로 다른 파일이다.
- I2: T014·T015.
- U4: T025·T026·T027·T029·T030. T028은 T025의 기대 순서와 맞춰 확인한다.
- I5: T033~T036, T041·T042. 파일 이동 T037~T040·T043~T045는 `git mv`가 index를 바꾸므로 직렬로 실행한다.
- U6: T050~T053.

## 승인이 필요한 지점

- **T018 (U3)**: T019~T023의 `tools/repository-paths/repository-paths.json`, `tools/repository-paths/bin/repository-paths.sh`, `tools/repository-paths/tests/test-no-hardcoded-paths.sh`, `tools/script-tests/core/tests.sh`, `tools/script-verification/config/verification.conf`에는 사용자 미커밋 변경(doc-registry 등록 등)이 있다. 파일 단위 stage는 그 변경을 함께 커밋한다. `/speckit-implement`는 T018에서 멈추고 다음 중 하나를 확인받는다.
  1. 이 명세가 추가하는 줄만 index에 적용한다. HEAD 기준 패치를 만들어 `git apply --cached`로 적용하고, 작업 트리에는 사용자 변경과 이 명세의 변경이 함께 남는다.
  2. 사용자 변경을 포함해 다섯 파일 전체를 stage한다.
  3. U3·U4를 보류하고 I5부터 진행한다. FR-008~FR-012가 미완료로 남는다.
- 그 밖의 단위는 확정된 기능 범위 안이므로 반복 승인 없이 진행한다.
