# 조사: 패키지 의존성 기계 검증과 CompositionAdapter 도메인 축 분할

기준 커밋 `a9021ec`. 수치는 프로토타입 스크립트로 실측했다.

## 1. 의존성 규칙 설정 파일의 형식과 위치

- **결정**: `tools/package-dependencies/config/allowed-dependencies`에 한 줄에 패키지 하나를
  `<패키지>: <허용 패키지 공백 구분>` 형식으로 둔다. 허용 의존성이 없으면 콜론 뒤를 비운다.
  `#` 주석과 빈 줄은 무시한다. 7개 패키지가 정확히 한 번씩 있어야 하며, 누락·중복·알 수 없는
  이름·자기 자신 허용은 설정 오류로 실패한다.

  ```text
  App: Feature Composition Domain
  Composition: Domain Data Infrastructure
  Feature: Domain UI
  Domain:
  Data: Infrastructure
  Infrastructure:
  UI:
  ```

- **대응 검사(FR-002)**: `GIT_IT_ARCHITECTURE_PATH`가 가리키는 문서에서
  `### 3.1 프로젝트 내부 패키지 의존성` 제목 다음에 처음 나오는 마크다운 표를 읽는다.
  `| 패키지 | 허용 의존성 |` 머리행과 구분행 뒤 각 행을 `이름: 쉼표 분리 목록`으로 정규화하고
  `—`는 빈 목록으로 바꾼다. 양쪽을 패키지 이름순, 허용 목록 이름순으로 정렬해 비교한다.
  제목이 없거나 머리행이 다르거나 표 행이 0개면 `table-unreadable`로 실패한다. 내용이 다르면
  행 단위 차이를 `table-mismatch`로 보고한다.
- **근거**: 기존 도구(`tools/design-rules/config/`)가 줄 단위 평문 설정을 쓴다. 셸에서 JSON을
  파싱하려면 `repository-paths.sh`처럼 전용 판독기가 필요하고, 이 표는 7행으로 고정적이다.
  표를 설정의 원천으로 직접 쓰지 않는 이유는 FR-001이 기계용 설정 파일을 요구하고, 문서
  서식 변경이 검사 규칙을 조용히 바꾸지 않게 두 원천의 일치를 검사하는 편이 안전하기
  때문이다.
- **검토한 대안**: (a) 아키텍처 표만 읽고 설정 파일을 두지 않는다 — FR-001 위반. (b) 설정을
  `repository-paths.json`에 넣는다 — 경로 레지스트리의 책임이 아니다. (c) YAML — 셸 파싱
  의존성이 생긴다.

## 2. manifest의 target별 선언과 모듈→패키지 소속 읽기

manifest는 두 형식이 섞여 있다.

| 형식 | 패키지 | target 블록 시작 표식 |
| --- | --- | --- |
| switch | App, Composition, Feature, Domain, Data | `var target: Target {` 뒤의 `case .<모듈>:` |
| 배열 | Infrastructure, UI | `.module(` 또는 `.testModule(`의 `name: <패키지>ModuleName.<모듈>.rawValue` |

- **결정**: `sources/Tuist/ProjectDescriptionHelpers/Projects/<패키지>ModuleName.swift`
  7개를 설정의 패키지 이름으로 찾는다. 파일이 없으면 실패한다.
  1. **모듈 목록**: `enum <패키지>ModuleName` 선언부터 첫 열의 `}`까지에서 `case <이름>` 줄을
     모은다. 모듈의 소속 패키지는 선언한 파일이다(명세 가정). 두 파일이 같은 이름을
     선언하면 `module-duplicate`로 실패한다.
  2. **target 블록**: 위 두 표식 중 하나가 나온 줄부터 다음 표식 전까지를 한 target 블록으로
     본다. 표식은 `awk`가 줄 번호와 함께 기록한다.
  3. **선언 수집**: 블록 안에서 다음을 줄 번호와 함께 수집한다.
     - `.from<패키지>(.<모듈>)` → 패키지 간 선언
     - `.target(name: <패키지>ModuleName.<모듈>.rawValue)` → 같은 패키지 선언
     - `productionTarget:` 뒤 첫 선언 → production target 표시
     - `.external(…)`, `.sdk(…)` → 무시
  4. **자기 일관성**: 모든 모듈이 target 블록을 정확히 하나 가져야 한다(`target-missing`,
     `target-duplicate`). `.from<P>(.M)`의 `M`이 실제로 `P`가 선언한 모듈이 아니면
     `declaration-mismatch`로 실패한다. 이 검사가 manifest 형식 변경으로 파서가 조용히
     빈 결과를 내는 것을 막는다.
- **실측**: 모듈 41개, target 블록 41개, 누락 0. `.from` 선언의 패키지 조합 위반 0.
- **근거**: Tuist manifest를 실제 평가(`tuist graph`)하면 빌드 도구 설치와 수 초~수십 초가
  필요해 FR-013(정적, 5초)을 지키기 어렵고 CI를 `ubuntu-latest`에서 돌릴 수 없다. manifest가
  이미 두 형식으로 정형화돼 있어 줄 단위 파싱으로 충분하며, 자기 일관성 검사가 파서의
  누락을 실패로 바꾼다.
- **검토한 대안**: (a) `tuist graph --format json` — macOS·Tuist 의존, 느림. (b) 모듈 이름
  접두어로 패키지 판별 — `GitIt`, `ShareExtension`, `DesignSystem`에서 틀린다.
  (c) Swift로 manifest helper를 import하는 검사 실행 파일 — 빌드가 필요하다.
- **UI 폰트 이름**: `notoSansKR`, `plusJakartaSans`는 `UIModuleName` enum이 아닌 폰트 enum의
  case다. enum 범위로 수집하므로 모듈로 잡히지 않는다.

## 3. Swift 파일을 target에 대응시키는 방법

- **결정**: `tools/package-dependencies/config/source-roots`에 `<target> <루트>` 한 줄씩
  둔다. 루트는 `GIT_IT_PROJECTS_ROOT` 기준 상대 경로다. 파일은 경로 접두어가 일치하는 루트
  중 가장 긴 것에 속한다.

  ```text
  GitIt App/GitIt
  GitItTests App/Tests/GitIt
  ShareExtension App/ShareExtension
  Feature Feature
  FeatureTests Feature/Tests
  UIComponent UI/Component
  UIComponentTests UI/Tests/Component/Unit
  …
  ```

- **스캔 대상**: `GIT_IT_PROJECTS_ROOT` 아래 `*.swift` 중 경로 구성요소가 `Derived`,
  `DerivedData`, `build`, `*.xcodeproj`인 것과 각 패키지 루트의 `Project.swift`를 제외한다.
- **자기 일관성**: manifest target과 설정 행이 1:1이어야 하고(`source-root-missing`,
  `source-root-unknown`), 각 루트 디렉터리가 존재해야 하며(`source-root-absent`), 대상 Swift
  파일은 모두 어느 루트에 속해야 한다(`source-unmapped`). 루트가 target 소속 패키지 디렉터리
  밖이면 `source-root-package`로 실패한다.
- **실측**: 41개 루트 모두 존재, 대상 파일 전부 대응.
- **근거**: `sourceDirectory` 계산은 패키지마다 다르다(`droppingPrefix`, `droppingSuffix`,
  Feature의 `"."`, UI 테스트의 `/Unit`, App 테스트의 `Tests/GitIt`, `testModule`의
  `Tests/` 접두). Swift 문자열 연산을 셸에서 재현하면 manifest가 바뀔 때 조용히 틀린다. 명시
  표와 양방향 일관성 검사는 틀리면 항상 실패한다. target 추가 시 한 줄을 추가해야 하는 비용은
  검사가 즉시 알려준다.
- **검토한 대안**: (a) `sourceDirectory` 규칙 재구현 — 위 이유. (b) 생성된 `.xcodeproj`
  읽기 — `tuist generate`가 필요하고 CI에서 불가. (c) 폴더 이름 추측 — Feature·UI에서 틀린다.

## 4. import 추출과 판정

- **추출**: 한 번의 `awk` 실행으로 모든 대상 파일을 읽는다.
  - `/* … */` 블록 주석(중첩 포함)과 `"""` 여러 줄 문자열 안의 줄은 건너뛴다.
  - `//` 뒤는 지운다.
  - 줄 머리에서 `@testable`, `@_exported`, `@preconcurrency`, `@_implementationOnly`,
    `@_spi(…)` 속성을 0개 이상 허용하고 `import`, 선택적 종류 키워드(`struct`, `class`,
    `enum`, `protocol`, `typealias`, `func`, `let`, `var`), 모듈 이름을 읽는다. `import A.B`는
    `A`를 모듈로 본다.
  - `#if` 안의 import도 같은 규칙으로 수집한다(명세 경계 사례).
  - 모듈 목록(2절)에 없는 이름은 버린다(외부 라이브러리·시스템 프레임워크).
- **판정 순서**: 파일의 target `T`, 소속 패키지 `P`, import 모듈 `M`, 그 패키지 `Q`.
  1. `P ≠ Q`이고 `Q`가 `P`의 허용 목록에 없으면 `import-package` 위반(FR-004).
  2. 아니면 `M`이 `T`의 선언 집합에 없을 때 `import-undeclared` 위반(FR-005).
     - 선언 집합 = `T` 자신 ∪ `T`의 `.from`·`.target` 선언 ∪ (test target이면 production
       target과 그 target의 `.from`·`.target` 선언)
  3. manifest 선언은 `P ≠ Q`이고 허용 목록에 없으면 `manifest-package` 위반(FR-003).
- **test target 상속 결정 근거**: Tuist test target은 production target에 링크되고 테스트
  대상은 그 target의 공개·`@testable` 표면이다. 상속 없이 판정하면 위반 173건
  (`FeatureTests → DomainLearningProject` 42건 등)이 나오고, 해소하려면 test manifest에
  production 선언을 그대로 반복해야 한다. 반복은 동기화 누락을 새로 만들 뿐 전이 의존
  위험을 줄이지 않는다. 패키지 조합 규칙은 test target도 그대로 적용하므로 명세의 "허용
  목록을 완화하지 않는다"를 지킨다.
- **실측(상속 적용)**: 6건. `GitIt → DomainMember` 3(`GitItApp.swift`, `AppRootView.swift`,
  `AppRootFeature.swift`), `GitIt → DomainLearningProject` 2(`AppRootView.swift`,
  `AppRootFeature.swift`), `CompositionApp → DataMember` 1(`AppComposition.swift`, 사용처 없음).
- **검토한 대안**: (a) 상속 없음 — 위 이유. (b) test target이 production target의 전이 의존
  전체를 상속 — 전이 의존 검사가 무력해진다. (c) `swiftc -emit-imported-modules` — 빌드
  설정과 SDK가 필요하다.

## 5. 도구 구조와 보고 형식

- **결정**: [셸 스크립트 아키텍처](../../.agents/skills/write-project-scripts/references/architecture.md)를
  따른다.
  - `bin/run.sh`: 인자 없음. `repository-paths.sh --absolute`로 `GIT_IT_PROJECTS_ROOT`,
    `GIT_IT_TUIST_ROOT`, `GIT_IT_ARCHITECTURE_PATH`를 읽고 임시 작업 디렉터리를 만들어
    유스케이스에 넘긴다.
  - `core/rules-policy.sh`: argv만 받는 순수 정책. 패키지 조합 허용 여부와 위반 종류별
    설명·조치 문장을 반환한다.
  - `core/architecture-table.sh`, `core/manifest.sh`, `core/imports.sh`: 파일을 읽어 탭 구분
    레코드를 작업 디렉터리에 쓰는 adapter.
  - `core/run.sh`: 설정 검증 → 표 대응 → manifest 수집·일관성 → source root 일관성 →
    import 수집 → 판정 → 정렬 보고.
- **보고**: 위반마다 한 줄 `<경로>:<줄>: [<규칙>] <설명>`을 stderr에 쓰고 마지막에
  `오류[package-dependencies.violated]: 위반 N건` 과 조치를 쓴 뒤 종료 코드 1. 설정·파싱
  오류는 `오류[package-dependencies.<종류>]`와 종료 코드 2. 위반이 없으면
  `패키지 의존성 검사 완료: target=N 파일=M 위반=0`을 stdout에 쓰고 0.
  메시지는 FR-006의 target 또는 파일, 선언 위치(경로:줄), 이유(`Feature는 Data에 의존할 수
  없음: 허용 Domain, UI` 또는 `GitIt manifest가 DomainMember를 선언하지 않음`)를 담는다.
- **근거**: `tools/design-rules`와 같은 모양이라 리뷰어가 구조를 새로 익힐 필요가 없다.
- **검토한 대안**: 단일 파일 스크립트 — FR-007이 구조를 지정한다.

## 6. 회귀 테스트

- **결정**: `tests/test-package-dependencies.sh`가 `mktemp -d`에 최소 fixture 저장소를 만든다.
  fixture는 아키텍처 문서, `ModuleName.swift` 7개(switch·배열 형식 혼합), Swift 소스 몇 개와
  `repository-paths.json`을 담고 `GIT_IT_PATHS_FILE`로 fixture 경로를 주입해 `bin/run.sh`를
  실행한다. 경우는 다음과 같다.
  1. 정상 fixture → 종료 0
  2. 허용되지 않는 `.from` 선언 → 1, `manifest-package`
  3. 허용되지 않는 패키지 import → 1, `import-package`
  4. 미선언 내부 import → 1, `import-undeclared`
  5. 표와 설정 불일치 → 1, `table-mismatch`
  6. 표 형식 파손 → 2, `table-unreadable`
  7. 설정 파일 없음 → 2
  8. 주석·블록 주석·여러 줄 문자열 안의 `import` → 0
  9. `#if` 안의 위반 import → 1
  10. 접두어 없는 모듈(`GitIt`)을 import하는 위반 → 1
  11. test target의 production 선언 상속 → 0, 상속 밖 모듈 → 1
  12. source root에 속하지 않는 Swift 파일 → 2, `source-unmapped`
- **근거**: FR-009가 요구하는 3종(2·3·5)을 포함하고 명세 경계 사례를 모두 고정한다.
  설정 파일은 도구 자신의 `config/`를 쓰지 않도록 `bin/run.sh`가 설정 디렉터리를
  `PACKAGE_DEPENDENCIES_CONFIG_DIR` 환경변수로 덮어쓸 수 있게 한다. 테스트 전용 입력이며
  기본값은 도구의 `config/`다.
- **검토한 대안**: 실제 저장소를 복사해 변형 — 느리고 fixture 의도가 흐려진다.

## 7. pre-commit 진입점 허용 목록과 CI 게이트 등록 지점

- **pre-commit**: 허용 목록은 `tools/githooks/pre-commit`의 `case "$pre_commit_name" in`
  분기와 고정 순서 `for pre_commit_stage in …` 두 곳이다. `package-dependencies`를
  `design-rules` 다음, `build` 앞에 넣는다. 정적 검사라 빌드보다 먼저 실패하는 편이 빠르고,
  포맷 결과와 무관하므로 `swift-format` 뒤 어디든 되지만 기존 정적 검사 옆에 둔다.
  - `tools/githooks/pre-commit.d/package-dependencies.sh`: `design-rules.sh`와 같은 모양으로
    `GIT_IT_PACKAGE_DEPENDENCY_RUNNER`를 실행한다.
  - `tools/githooks/pre-commit.d/enabled`: 설명 주석의 순서와 단계 목록에 이름을 추가하고
    주석 처리 상태로 둔다(명세 범위 밖: 활성화 결정).
  - `tools/githooks/hook-management/tests/test-pre-commit.sh`: stub 단계 목록과 기대 순서에
    추가한다.
- **CI**: `.github/workflows/ci.yml`에 `package-dependencies` job을 추가한다.
  `needs: changes`, `if: vars.GIT_IT_CI_VALIDATION_ENABLED == 'true'`, `runs-on:
  ubuntu-latest`, `timeout-minutes: 5`. 단계는 checkout → `repository-paths.sh >>
  "$GITHUB_ENV"` → `"$GIT_IT_PACKAGE_DEPENDENCY_RUNNER"`. 변경 분류 조건을 두지 않는다.
  아키텍처 문서만 바뀐 문서 전용 PR에서도 표 대응 검사가 돌아야 하고, 실행 시간이 짧다.
  `gate` job의 `needs`와 `gate-evaluate.sh` 인자에 이 job 결과를 추가한다.
  `gate-evaluate.sh`는 가변 인자이므로 수정하지 않는다.
  - `tools/ci/tests/test-gate-evaluate.sh`: workflow가 `needs.package-dependencies.result`를
    evaluator에 넘기는지 고정하는 검사를 추가한다.
- **공개 경로**: `repository-paths.json`에 `GIT_IT_PACKAGE_DEPENDENCY_RUNNER:
  tools/package-dependencies/bin/run.sh`를 추가한다. 판독기의 키 목록(`repository-paths.sh`),
  하드코딩 검사 키 목록(`test-no-hardcoded-paths.sh`), 셸 회귀 환경 격리 목록
  (`script-tests/core/tests.sh`)에도 추가한다. 정적 검사 대상
  `VERIFICATION_SCRIPT_TARGETS`(`verification.conf`)에 `tools/package-dependencies`를
  추가한다(FR-010).
- **셸 회귀 등록(FR-009)**: `script-tests/core/tests.sh`는 `tools/**/tests/test-*.sh`를
  자동 수집하므로 파일 위치만으로 등록된다.
- **근거**: 기존 `design-rules`가 같은 등록 지점을 쓴다. CI에 `design-rules`는 없지만 FR-012가
  CI 게이트를 요구한다.
- **검토한 대안**: (a) `script-quality` job의 단계로 추가 — 스크립트 변경이 없는 PR에서
  실행되지 않는다. (b) `swift-lint` job에 추가 — Swift 변경이 없는 문서 PR에서 빠진다.

## 8. CompositionAdapter 분할 배치

### 8.1 판단 기준

- Adapter와 조립은 **구현하는 Domain 계약의 모듈**로 축을 정한다.
- 여러 축이 쓰는 요소 중 Domain·Data 모듈을 import하지 않는 것만 공용 target에 둔다.
- 각 target의 다른 패키지 모듈 의존 수는 파일 import의 합집합이다.

### 8.2 ExternalRepository와 생성 리마인드의 소속

- **결정**: 둘 다 `CompositionLearningProject`에 둔다.
- **근거**: `ExternalRepositoryLookupAdapter`, `ExternalRepositoryURLParserAdapter`,
  `ExternalRepositoryAssembly`가 구현·공개하는 계약(`FetchExternalRepositoryUseCase`,
  `ExternalRepositoryURLParser`)은 `DomainLearningProject` 소속이다. 생성 리마인드
  (`GenerationReminderSchedulerAdapter`, `NotificationAuthorizationGatewayAdapter`,
  `PendingGenerationReminderStoreAdapter`, `GenerationReminderAssembly`)도
  `DomainLearningProject` 계약이며 `TrackGenerationUseCase`를 입력으로 받는다. 별도 축으로
  떼면 리뷰 문서가 지정한 세 축 밖에 네 번째·다섯 번째 축이 생긴다. 합쳐도
  `DomainLearningProject`, `DataLearningProject`, `DataExternalRepository`,
  `InfrastructureNetworkClient`, `InfrastructureStorage`, `InfrastructureLocalNotification`
  6개로 제약 안이다.
- **검토한 대안**: `CompositionExternalRepository`·`CompositionGenerationReminder` 분리 —
  의존 수는 더 줄지만 축이 명세 밖으로 늘어나고 `CompositionShareExtension`이 참조할 target이
  3개가 된다.

### 8.3 공용 target

- **결정**: `CompositionShared`(`sources/Projects/Composition/Shared/`)에
  `Factories/HTTPClientFactory.swift`만 둔다. 의존은 `InfrastructureNetworkClient` 1개.
  `makeHTTPClient`를 `public`으로 올린다.
- **근거**: 세 축의 조립(`AuthenticationAssembly`, `LearningProjectAssembly`,
  `MemberAssembly`, `ExternalRepositoryAssembly`)이 같은 HTTP 클라이언트 구성을 쓴다. 이
  파일은 Domain·Data를 import하지 않아 FR-017을 충족한다. `SessionRecordCoding`은
  `DataAuthentication`·`DomainAuthentication`을 쓰고 Authentication 축에서만 쓰이므로 공용이
  아니다.
- **이름**: `Shared`는 "여러 도메인 조립이 공유하는 요소"라는 책임을 드러낸다. 내용이 지금은
  HTTP 클라이언트 구성 하나지만 target의 존재 이유는 공유이지 네트워크가 아니다.
- **검토한 대안**: (a) 함수를 세 target에 복제 — 구성 변경이 세 곳으로 흩어진다.
  (b) `InfrastructureNetworkClient`로 이동 — Composition의 조립 선택(`StandardJSONBodyCoding`
  기본값)을 Infrastructure에 넣게 된다.

### 8.4 조립 루트의 의존 축소

분할만으로는 `CompositionApp` 9, `CompositionShareExtension` 8이 남는다. 두 루트가 Data와
Storage 타입을 직접 만들기 때문이다.

| 루트 | 직접 쓰는 타입 | 옮길 곳 |
| --- | --- | --- |
| `CompositionApp` | `SessionKeychainMigration`, `AppGroupKeychainStore.makeLegacy()` | `AuthenticationAssembly.migrateSessionKeychain(sharedKeychainStore:)` |
| `CompositionApp` | `SharedSessionStateMarkerCoding`, `AppGroupUserDefaults.makeShared()` | `AuthenticationAssembly.recordSharedSessionState` |
| `CompositionApp` | `DeviceIdentifierRepositoryAdapter`, `RegisterCurrentDevice`, `member.repository` | `MemberAssembly.makeRegisterCurrentDevice(keychainStore:appVersion:osVersion:deviceTokenProvider:)` |
| `CompositionApp` | `import DataExternalRepository`, `import DataMember` | 사용처 없음. 제거 |
| `CompositionShareExtension` | `SharedSessionStateMarkerCoding`, `SharedSessionMarkerRepositoryAdapter`, `StoredSessionRepositoryAdapter`, `ResolveSessionAvailability` | `SessionAvailabilityAssembly`(`CompositionAuthentication`) |
| `CompositionShareExtension` | `PendingGenerationReminderCoding` | `GenerationReminderAssembly.makePendingReminderEnqueue(sharedDefaults:)` |

- **결과**: `CompositionApp`은 `DomainAuthentication`, `DomainLearningProject`, `DomainMember`,
  `InfrastructureAuthentication`(`KeychainStore` 기본값), `InfrastructureNetworkClient`
  (`HTTPTransport`), `InfrastructurePushMessaging` 6개. `CompositionShareExtension`은
  `DomainAuthentication`, `DomainLearningProject`, `InfrastructureAuthentication`,
  `InfrastructureLocalNotification`, `InfrastructureNetworkClient`, `InfrastructureStorage`
  (`sharedDefaults` 기본값) 6개.
- **근거**: 두 루트의 공개 `live(…)` 서명과 기본값은 그대로 두고, 루트 안에서 Data 타입을 만드는
  코드만 해당 축 조립으로 옮긴다. 호출 순서(키체인 마이그레이션이 인증 조립보다 먼저)는
  루트에서 static 함수를 먼저 호출하는 형태로 유지한다.
- **검토한 대안**: (a) `live(…)`의 `KeychainStore`·`HTTPTransport` 기본 인자를 없애 Infrastructure
  의존을 줄인다 — App과 테스트의 호출 서명이 바뀐다. (b) 루트를 6 초과로 두고 FR-016을
  Adapter target에만 적용 — SC-006과 명세 문장에 어긋난다.

## 9. 테스트 target 분할

- **결정**: `CompositionAdapterTests`를 축별 3개로 나눈다. `CompositionShared`에는 테스트
  target을 만들지 않는다(현재 테스트 파일이 없다).
  - `CompositionAuthenticationTests`: `AuthenticationRepositoryAdapterTests`,
    `LoginSessionRepositoryAdapterTests`, `PolicyConsentRepositoryAdapterTests`,
    `AuthenticationAssemblyTests`, `RefreshSessionReleaseBlockerTests`,
    `TestDoubles/RecordingHTTPTransport`
  - `CompositionLearningProjectTests`: `AnswerRepositoryAdapterTests`,
    `BookmarkRepositoryAdapterTests`, `ExternalRepositoryLookupAdapterTests`,
    `GenerationOutcomeRepositoryAdapterTests`, `LearningProjectRepositoryAdapterTests`,
    `LearningSetRepositoryAdapterTests`, `ExternalRepositoryAssemblyTests`,
    `LearningProjectAssemblyTests`, `TestDoubles/RecordingHTTPTransport`
  - `CompositionMemberTests`: `MemberRepositoryAdapterTests`,
    `TestDoubles/RecordingHTTPTransport`
- **근거**: 테스트 파일 하나는 한 축의 production 타입만 쓴다. test double은 target마다
  둔다(기존 `Tests/App/TestDoubles/RecordingHTTPTransport.swift`와 같은 관행). 테스트 수는
  나뉠 뿐 변하지 않는다.
- `CompositionAppTests`와 `CompositionShareExtensionTests`는 `CompositionAdapter` 대신 쓰는
  분할 target과 fixture에 필요한 Data 모듈(`DataAuthentication`, `DataLearningProject`)을
  추가 선언한다. U6 뒤 production 선언에서 빠지는 모듈을 테스트가 계속 import하기 때문이다.

## 10. 예상 결과

| 항목 | 현재 | 목표 | 예상 |
| --- | --- | --- | --- |
| 미선언 import(상속 적용) | 6 | 0 | 0 |
| `CompositionAdapter` 의존 | 12 | 제거 | 제거 |
| `CompositionAuthentication` | — | ≤6 | 6 |
| `CompositionLearningProject` | — | ≤6 | 6 |
| `CompositionMember` | — | ≤6 | 5 |
| `CompositionShared` | — | ≤6, Domain·Data 0 | 1, Domain·Data 0 |
| `CompositionApp` | 9 | ≤6 | 6 |
| `CompositionShareExtension` | 8 | ≤6 | 6 |
| Composition test target 최대 추가 선언 | 3 | ≤6 | 2 |
| `Composition/Adapter` 아래 Swift 파일 | 26 | 0 | 0 |
| 도구 실행 시간 | — | ≤5초 | 1초 안팎 |
