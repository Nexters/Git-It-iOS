# 016-onboarding-login-tutorial-app-integration 문제 해결 기록

**대상 기능**: `016-onboarding-login-tutorial-app-integration`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260825-001: 승인된 Notion 정책 페이지 본문 조회 실패

**기록일**: 2026-08-25
**상태**: 환경 제약
**발생 단계**: `speckit-specify` 요구사항 명확화
**관련 항목**: `specs/016-onboarding-login-tutorial-app-integration/spec.md` FR-006, 승인된 정책 링크

### 증상

사용자가 제공한 개인정보 처리방침과 서비스 이용 약관 Notion URL을 웹 조회 도구로 직접 열었으나 두 요청 모두 `URL ... is not safe to open (non-retryable error)`로 실패했다. 같은 URL 식별자를 도메인 제한 검색으로 조회했지만 검색 결과가 없었다.

### 영향

사용자가 승인한 두 URL과 각 항목의 필수 정책은 명세에 반영할 수 있지만, 이 세션에서는 페이지 본문, 공개 접근성, 최신성을 독립적으로 확인할 수 없다. 이를 제품 URL 자체의 장애나 본문 유효성 검증 성공으로 판단해서는 안 된다.

### 근거

- `web open`: 두 `git-it-service-policy.notion.site` URL 모두 safe URL 검사에서 non-retryable error가 발생했다.
- `web search_query`: 각 페이지 식별자를 `site:git-it-service-policy.notion.site`로 검색한 결과가 비어 있었다.
- `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`: 활성 기능이 `specs/016-onboarding-login-tutorial-app-integration`로 확인되었다.

### 원인

현재 웹 조회 도구가 제공된 Notion URL을 안전한 공개 페이지로 판정하지 못했다. 실제 Notion 페이지의 공개 설정 또는 서비스 상태는 확인하지 못했다.

### 조치

사용자가 승인한 URL과 두 항목의 필수 정책을 명세 계약으로 기록했다. 본문과 공개 접근성은 확인된 것으로 표기하지 않고 계획 또는 구현 검증의 후속 확인 범위로 남겼다.

### 검증

- 사용자 제공값 대조: 두 URL과 `개인정보 처리방침`, `서비스 이용 약관`의 필수 정책이 명세에 동일하게 기록됨을 확인했다.
- 정책 페이지 본문 재조회: 실패. 현재 도구 환경에서는 미검증 상태다.

### 재발 방지

정책 링크를 제품에 연결하기 전에 브라우저 또는 실제 앱 환경에서 비로그인 공개 접근, 최종 redirect URL, 제목과 본문 최신성을 각각 확인한다. 조회 도구 실패만으로 제품 URL 장애를 선언하지 않는다.

### 연결

없음

## TS-20260825-002: Onboarding 화면·테스트 경로 추정 조회 실패

**기록일**: 2026-08-25
**상태**: 해결
**발생 단계**: `speckit-clarify` 큐레이션 뒤로 가기 경계 확인
**관련 항목**: `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`

### 증상

현재 reducer와 화면·테스트 동작을 대조하기 위해 예상한 `OnboardingScreen.swift`와
`Tests/Presentation/Onboarding` 경로를 직접 조회했으나 두 경로가 존재하지 않아
`No such file or directory`로 실패했다.

### 영향

큐레이션 navigation의 현재 구현 근거를 바로 확인하지 못했고, 예상 경로의 부재를 실제
Feature 화면이나 테스트 전체의 부재로 잘못 확대 해석할 수 있었다.

### 근거

- `sed -n '1,280p' sources/Projects/Feature/Presentation/Onboarding/OnboardingScreen.swift`:
  `No such file or directory`가 발생했다.
- `rg ... sources/Projects/Feature/Tests/Presentation/Onboarding`:
  `No such file or directory`가 발생했다.
- `rg --files sources | rg -i 'onboarding|tutorial|curation|career.*screen|position.*screen'`:
  Feature의 Onboarding 구현 경로로
  `sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`를 확인했다.

### 원인

현재 checkout의 파일 목록을 먼저 확인하지 않고 예상한 화면 파일명과 테스트 디렉터리를
직접 명령 인자로 사용했다.

### 조치

`rg --files`로 현재 저장소의 관련 파일을 다시 탐색하고 실제
`OnboardingFeature.swift`를 읽었다. 큐레이션 뒤로 가기 명확화는 존재하지 않는 화면·테스트
파일에 대한 추정이 아니라 현재 reducer 상태와 사용자 답변을 근거로 명세에 반영했다.

### 검증

- `rg --files sources/Projects/Feature | rg -i 'onboarding|presentation.*tests|tests.*presentation'`:
  성공. 현재 Feature 관련 결과가 `OnboardingFeature.swift`임을 확인했다.
- `sed -n '1,260p' sources/Projects/Feature/Presentation/Onboarding/OnboardingFeature.swift`:
  성공. 현재 reducer의 state, action과 effect 경계를 확인했다.

### 재발 방지

현재 checkout에서 화면이나 테스트 파일을 읽기 전 `rg --files`로 실제 경로를 먼저
해결하고, 존재가 확인된 경로만 후속 명령에 사용한다.

### 연결

없음

## TS-20260825-003: Figma design context 생성 실패

**기록일**: 2026-08-25
**상태**: 완화
**발생 단계**: `speckit-plan` 0단계 Career 카드 문구·매핑 조사
**관련 항목**: `specs/016-onboarding-login-tutorial-app-integration/spec.md` FR-013, Figma node `737:10358`, `737:10349`

### 증상

Figma 파일 `mCRt0ejmzI4EFW3UnC9Bzb`의 두 지정 frame에 `get_design_context`를 호출했으나 최초 병렬 요청은 `INVALID_ARGUMENT`, metadata 확인 뒤 재시도는 `An unexpected error occurred`를 반환했다. 하위 `select card list` instance에 대한 축소 재시도도 같은 unexpected error로 실패했다.

### 영향

React/Tailwind 구조 참고, Code Connect, 자산 URL과 design token 세부값은 계획 단계에서 확보하지 못했다. Career 카드의 정확한 문구·순서·선택 상태를 근거 없이 추정하면 안 되며, 구현 자산과 token의 Figma 정합성은 아직 확인되지 않았다.

### 근거

- `get_design_context(fileKey: mCRt0ejmzI4EFW3UnC9Bzb, nodeId: 737:10358|737:10349)`: 최초 두 요청 모두 `INVALID_ARGUMENT`.
- node `737:10358` 재시도: `An unexpected error occurred`, Figma Debug UUID `70254f55-abe8-423a-9c39-6a4560cb4fd6`.
- 하위 node `737:10362` 재시도: `An unexpected error occurred`, Figma Debug UUID `73d0737d-c910-440a-8a15-0d6914462e11`.
- `get_metadata`: 두 지정 node가 각각 360×800 frame이고 Career 선택 카드 4개를 포함함을 확인했다.
- `get_screenshot`: 두 지정 node의 360×800 원본 렌더를 성공적으로 확보했다.

### 원인

Figma 인증 계정은 파일 metadata와 screenshot을 읽을 수 있어 일반 접근 권한 실패는 아니다. 해당 frame 또는 instance의 design-context code generation이 실패한 구체 원인은 확인 중이다.

### 조치

node metadata와 원본 해상도 screenshot을 직접 조회해 화면 질문, 카드 4개의 제목·설명·순서, 미선택과 첫 카드 선택 상태만 확인했다. 이 범위는 `research.md`와 UI 계약에 기록하고, design context가 필요한 자산·token 세부값은 구현 전 재조회 대상으로 남겼다.

### 검증

- Figma `whoami`: 성공. 인증 계정과 접근 가능한 plan 목록을 확인했다.
- node `737:10358`, `737:10349` metadata: 성공. 지정 frame과 카드 list 구조를 확인했다.
- node `737:10358`, `737:10349` screenshot: 성공. `입문`, `주니어`, `미들`, `시니어` 순서와 각 설명, 첫 카드 selected 상태를 시각 확인했다.
- `get_design_context` 재실행: 실패. Code Connect·자산·token 세부값은 미검증이다.

### 재발 방지

구현에서 Figma 자산이나 token을 확정하기 전에 동일 node의 `get_design_context`를 다시 실행한다. 실패하면 Debug UUID와 함께 Figma 연동 상태를 진단하며 screenshot만으로 asset 이름, SF Symbol 또는 token 값을 추정하지 않는다.

### 연결

없음

## TS-20260826-001: backtick이 포함된 검증 검색식의 명령 치환 오류

**기록일**: 2026-08-26
**상태**: 해결
**발생 단계**: `speckit-tasks` 산출물 정합성 검증
**관련 항목**: `CareerLevel.entry`, `specs/016-onboarding-login-tutorial-app-integration/`

### 증상

`beginner`, `student`, `entry`가 남은 위치를 검증하려고 double-quoted `rg` 검색식에
Markdown backtick을 포함해 실행하자 zsh가 backtick 내부 문자열을 명령으로 해석해
`command not found`를 출력했다. 치환된 검색식은 의도보다 넓은 결과를 반환해 해당 출력은
정합성 근거로 사용할 수 없었다.

### 영향

문서 파일은 변경되지 않았지만 첫 검색 결과만 사용하면 `CareerLevel` 이름 정합성을 정확히
판정할 수 없었다. 올바른 인용 방식으로 검증을 다시 실행할 때까지 완료 보고를 중단했다.

### 근거

- double-quoted `rg` 검색식 실행: `zsh:1: command not found: beginner`,
  `zsh:1: command not found: student`, `zsh:1: command not found: junior`가 발생했다.
- 같은 명령의 후속 `task_count`와 체크리스트 출력은 생성됐지만 앞선 이름 검색 결과는
  명령 치환의 영향을 받아 폐기했다.

### 원인

shell 명령 문자열 안의 Markdown backtick이 명령 치환 문법이라는 점을 고려하지 않고
double quote로 감쌌다.

### 조치

Markdown backtick 자체를 검색 조건에서 제거하고 전체 정규식을 single quote로 감싼 별도
`rg` 명령으로 다시 실행했다. 작업 수, 체크리스트와 `git diff --check`도 함께 재검증했다.

### 검증

- `rg -n 'CareerLevel\\.(entry|beginner|student)|CareerLevel.*지원 값|careerLevel.*entry|allCases.*entry' specs/016-onboarding-login-tutorial-app-integration`:
  성공. 활성 매핑과 요구사항·작업은 `entry`이며 `beginner`는 `entry`로 바꾸는 입력 상태 설명에만
  남아 있음을 확인했다.
- `rg -c '^- \\[ \\] T[0-9]{3}' specs/016-onboarding-login-tutorial-app-integration/tasks.md`:
  성공. 작업 수 82개를 확인했다.
- 명세 품질 체크리스트 재검증: 성공. 16/16 항목이 통과 상태다.
- `git diff --check`: 성공. 공백 오류가 없다.

### 재발 방지

shell 검색식에서 Markdown backtick을 직접 포함하지 않는다. 필요한 정규식은 single quote로
감싸고, literal backtick 검색이 필요하면 shell 명령과 분리하거나 안전하게 escape한 뒤 실행한다.

### 연결

없음

## TS-20260826-002: iCloud Desktop 동기화로 인한 Domain 테스트 CodeSign 실패

**기록일**: 2026-08-26
**상태**: 완화
**발생 단계**: `speckit-implement` 작업 패키지 1: Domain 정리와 패키지 검증(T027)
**관련 항목**: `sources/Projects/Domain/`, Domain xcodebuild test scheme

### 증상

`xcodebuild test -workspace GitIt.xcworkspace -scheme Domain -derivedDataPath
DerivedData/PreCommit` 실행이 `CodeSign
.../DomainLearningProject.framework: resource fork, Finder information, or
similar detritus not allowed`로 실패했다. `rm -rf DerivedData/PreCommit` 후
재빌드해도 같은 오류가 재현됐고, 실패한 `.framework` 번들에 직접 `xattr -cr`을
실행해 확장 속성을 제거한 뒤 즉시 재시도해도 다시 재현됐다.

### 영향

Domain 소스 컴파일 자체는 성공했으나(같은 로그에 Swift 컴파일 오류 없음) CodeSign
단계에서 빌드가 중단되어 T001~T026에서 작성한 테스트가 전혀 실행되지 못하는 상태와,
실제 테스트 실패를 구분하지 못하고 검증을 완료로 보고할 위험이 있었다.

### 근거

- `xcodebuild test ... -derivedDataPath DerivedData/PreCommit` (1차): `CodeSign
  ... resource fork, Finder information, or similar detritus not allowed`,
  `** TEST FAILED **`.
- `rm -rf DerivedData/PreCommit` 후 재실행: 동일한 CodeSign 오류로 재현됨.
- `xattr -lr .../DomainLearningProject.framework`: 번들과 하위 파일에
  `com.apple.provenance`, `com.apple.FinderInfo`,
  `com.apple.fileprovider.fpfs#P` 확장 속성이 붙어 있음을 확인했다. 저장소
  경로가 `~/Desktop/Git-It-iOS`로 iCloud Desktop 동기화 대상 아래에 있다.
- `xattr -cr .../DomainLearningProject.framework` 후 즉시 재빌드: 동일한
  CodeSign 오류로 재현됨(File Provider가 빌드 중 속성을 다시 부여하는 것으로
  추정, 근본 원인은 확정 검증하지 못함).
- `xcodebuild test ... CODE_SIGNING_ALLOWED=NO`: `** TEST SUCCEEDED **`,
  `Test run with 44 tests in 21 suites passed`(DomainAuthenticationTests),
  `Test run with 47 tests in 19 suites passed`(DomainLearningProjectTests),
  `Test run with 16 tests in 8 suites passed`(DomainMemberTests).

### 원인

로컬 macOS 환경에서 `sources/DerivedData`가 iCloud Desktop 동기화 대상 경로 아래에
있어 빌드 산출물 `.framework` 번들에 File Provider 관련 확장 속성이 부여되고,
로컬 ad-hoc codesign이 이를 "resource fork, Finder information, or similar
detritus"로 거부하는 것으로 추정한다. File Provider가 확장 속성을 언제 다시
부여하는지 등 완전한 근본 원인은 확인하지 못했다.

### 조치

이번 세션의 T027 검증에 한해 `xcodebuild test`에 `CODE_SIGNING_ALLOWED=NO`를
추가해 로컬 시뮬레이터 테스트 실행에서 codesign 단계를 우회했다. 이 플래그는
프로젝트 설정이나 스킴 파일을 수정하지 않고 이번 명령 호출에만 적용했다.

### 검증

- `xcodebuild test -workspace GitIt.xcworkspace -scheme Domain -destination
  'platform=iOS Simulator,id=580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F'
  -derivedDataPath DerivedData/PreCommit CODE_SIGNING_ALLOWED=NO`: 성공.
  `** TEST SUCCEEDED **`이며 3개 테스트 타깃 107개 테스트 전부 통과(실패 0건)를
  확인했다.
- `git status --short` (tuist generate 실행 전후 비교): 변경 없음. 파생
  workspace/project 재생성이 추적 대상 파일을 바꾸지 않았음을 확인했다.

### 재발 방지

같은 macOS 환경에서 로컬 xcodebuild test/build가 CodeSign 단계에서
"resource fork, Finder information, or similar detritus not allowed"로
실패하면, 저장소 경로의 iCloud Desktop 동기화 여부와 산출물의
`com.apple.FinderInfo`/`com.apple.fileprovider.*` 확장 속성을 먼저 의심한다.
다음 중 하나로 완화한다: (1) 로컬 시뮬레이터 테스트 한정으로
`CODE_SIGNING_ALLOWED=NO`를 명령 인자로만 추가, (2) 시스템 설정에서 해당
저장소 경로의 iCloud Desktop 동기화 제외, (3) `DerivedData`를 iCloud
비동기화 경로로 이동. 이 문제만으로 Domain 소스 코드 결함을 의심하지 않는다.

### 연결

없음

## TS-20260826-003: tasks.md T031·T042·T092의 Project.swift 경로 오류

**기록일**: 2026-08-26
**상태**: 해결
**발생 단계**: `speckit-implement` 작업 패키지 2: Infrastructure 구현 착수(T031)
**관련 항목**: `sources/Projects/Infrastructure/Project.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`,
tasks.md T031·T042·T092

### 증상

T031이 지정한 `sources/Projects/Infrastructure/Project.swift`를 열람하니
`import ProjectDescription` / `import ProjectDescriptionHelpers` /
`let project = ProjectName.Infrastructure.project` 세 줄뿐인 포인터 파일이었고,
target의 `sources`(source 디렉터리) 선언을 담을 수 없었다. 같은 패턴을
`sources/Projects/Data/Project.swift`(T042 대상)와
`sources/Projects/App/Project.swift`(T092 대상)에서도 확인했다 — 두 파일 모두
각각 `ProjectName.Data.project`, `ProjectName.App.project` 한 줄뿐이었다.

### 영향

T031을 문자 그대로 수행하면 `UserDefaultsStore`를 포함하는 신규 `Storage/`,
`Tests/Storage/` 디렉터리가 어떤 target의 `sources` glob에도 포함되지 않아
Tuist 프로젝트 생성은 성공해도 두 파일이 컴파일 대상에서 누락되는 상태로
남을 뻔했다. 같은 오류가 T042(Data)·T092(App)에도 있어 후속 패키지에서 같은
문제가 재발할 위험이 있었다.

### 근거

- `sources/Projects/Infrastructure/Project.swift` 전체 열람: `let project =
  ProjectName.Infrastructure.project` 한 줄만 존재, target 선언 없음.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`
  열람: 실제 `InfrastructureCache` target의 `sources: ["\(sourceDirectory)/**"]`
  선언이 이 파일에 있음을 확인.
- `sources/Projects/Data/Project.swift`, `sources/Projects/App/Project.swift`
  열람: 각각 한 줄짜리 포인터 파일로 동일한 패턴 확인.
- `grep -n "Project.swift" specs/016-onboarding-login-tutorial-app-integration/tasks.md`:
  T031, T042, T092 세 곳에서 같은 패턴의 경로가 사용됨을 확인.

### 원인

tasks.md 생성 시 target source 선언 위치를 `sources/Projects/<패키지>/Project.swift`로
잘못 추정했다. 실제로는 각 패키지의 Tuist target 선언이
`sources/Tuist/ProjectDescriptionHelpers/Projects/<패키지>ModuleName.swift`에
있고, `Project.swift`는 `ProjectName.<패키지>.project`를 참조만 하는
얇은 진입점이다.

### 조치

사용자에게 확장/신규 target 여부를 확인한 뒤(`/speckit-tasks로 작업 목록 먼저
정정` 선택), `/speckit-tasks`를 호출해 T031·T042·T092의 대상 경로를
`sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`·
`DataModuleName.swift`·`AppModuleName.swift`로 정정했다. 체크박스 상태와 작업
설명의 나머지 내용은 그대로 유지했다. 이어서 `InfrastructureModuleName.swift`의
`InfrastructureCache`/`InfrastructureCacheTests` target을 `.module`/`.testModule`
헬퍼 대신 동등한 설정의 `.target(...)` 직접 선언으로 바꾸고 `sources`에
`["Cache/**", "Storage/**"]`(테스트는 `["Tests/Cache/**", "Tests/Storage/**"]`)를
지정해 두 glob을 모두 포함시켰다. `ProjectName.swift`의 Infrastructure 공유
scheme 대상 목록은 이미 `InfrastructureCache`/`InfrastructureCacheTests`
rawValue를 포함하고 있어 추가 변경이 필요 없었다.

### 검증

- `tuist generate --no-open`: 성공. `Generating project Infrastructure`를
  포함해 전체 workspace 생성이 오류 없이 끝남을 확인했다.
- `xcodebuild build-for-testing -scheme Infrastructure ... CODE_SIGNING_ALLOWED=NO`:
  성공. `** TEST BUILD SUCCEEDED **`.
- `xcodebuild test-without-building -scheme Infrastructure ...
  CODE_SIGNING_ALLOWED=NO`: 성공. `UserDefaultsStore 저장과 조회`,
  `UserDefaultsStore 제거와 전체 비우기` 두 suite 포함 `Test run with 18 tests
  in 5 suites passed`(InfrastructureCacheTests)를 확인했다.

### 재발 방지

이 저장소에서 Tuist target의 `sources`/`resources`/`dependencies` 선언을 바꿔야
하는 작업을 생성하거나 수행할 때는 `sources/Projects/<패키지>/Project.swift`가
아니라 `sources/Tuist/ProjectDescriptionHelpers/Projects/<패키지>ModuleName.swift`
(App은 `AppModuleName.swift`, Data는 `DataModuleName.swift` 등)를 실제 대상으로
확인한다. T042(Data)·T092(App) 실행 시점에도 같은 정정이 이미 반영돼 있는지
다시 확인한다.

### 연결

없음

## TS-20260826-004: Infrastructure 패키지 검증에서 CodeSign 오류 재발(TS-20260826-002 재발)

**기록일**: 2026-08-26
**상태**: 완화
**발생 단계**: `speckit-implement` 작업 패키지 2: Infrastructure 정리와 패키지 검증(T032)
**관련 항목**: `sources/Projects/Infrastructure/`, Infrastructure xcodebuild test scheme, [[TS-20260826-002]]

### 증상

`xcodebuild build-for-testing -scheme Infrastructure -derivedDataPath
DerivedData/PreCommit`에서 TS-20260826-002와 동일한
`CodeSign .../InfrastructureCache.framework: resource fork, Finder
information, or similar detritus not allowed`,
`CodeSign .../InfrastructureNetworkClient.framework: resource fork, Finder
information, or similar detritus not allowed` 오류가 발생했다. `xattr -cr`로
산출물의 확장 속성을 지운 뒤 재시도해도, `DerivedData/PreCommit`을 완전히
삭제한 뒤 처음부터 재빌드해도 동일하게 재현됐다.

### 영향

TS-20260826-002와 같은 원인으로 판단되며, `InfrastructureNetworkClient`처럼
이번 세션에서 변경하지 않은 기존 target도 함께 실패해 Infrastructure 신규
코드(`UserDefaultsStore`)의 결함이 아님을 재확인했다.

### 근거

- `xattr -l .../InfrastructureCache.framework`: `com.apple.FinderInfo`,
  `com.apple.fileprovider.fpfs#P`, `com.apple.provenance` 확장 속성 확인.
- `rm -rf sources/DerivedData/PreCommit` 후 재빌드: 동일한 CodeSign 오류로
  재현됨.
- `xcodebuild build-for-testing ... CODE_SIGNING_ALLOWED=NO`: `** TEST BUILD
  SUCCEEDED **`.
- `xcodebuild test-without-building ... CODE_SIGNING_ALLOWED=NO`: 성공.
  Infrastructure 전용 test scheme에서 `Test run with 18 tests in 5 suites
  passed`(InfrastructureCacheTests, `UserDefaultsStore` 6개 신규 시나리오
  포함)와 기존 InfrastructureAuthentication·InfrastructureNetworkClient
  suite 전부 통과를 확인했다.

### 원인

TS-20260826-002와 동일하게 iCloud Desktop 동기화 경로 아래
`sources/DerivedData`의 File Provider 확장 속성이 원인으로 추정된다. 이번
세션에서 새로 확인된 사실은 없다.

### 조치

TS-20260826-002와 같은 완화책을 재적용했다: 이번 T032 검증 호출에 한해
`CODE_SIGNING_ALLOWED=NO`를 명령 인자로만 추가했다. 프로젝트 설정, 스킴 파일,
Tuist manifest는 변경하지 않았다.

### 검증

- `xcodebuild test-without-building -workspace sources/GitIt.xcworkspace
  -scheme Infrastructure -destination "platform=iOS Simulator,name=iPhone 17
  Pro" -derivedDataPath sources/DerivedData/PreCommit
  CODE_SIGNING_ALLOWED=NO`: 성공. `** TEST EXECUTE SUCCEEDED **`.

### 재발 방지

TS-20260826-002의 재발 방지 절차를 그대로 따른다. 이후 패키지(Data·
Composition·UI·Feature·App)의 `[no-write]` 검증에서도 같은 증상이 나오면
새 항목을 추가하지 않고 이 두 항목을 참조해 같은 완화책을 적용한다.

### 연결

[[TS-20260826-002]]

## TS-20260826-005: Data 패키지 검증에서 무관한 DataLearningProjectTests 컴파일 실패로 scheme 전체 test 중단

**기록일**: 2026-08-26
**상태**: 환경 제약
**발생 단계**: speckit-implement, Data 패키지(T033~T043) 정리와 패키지 검증(T043)
**관련 항목**: T033~T043, `sources/Projects/Data/`, Data xcodebuild test scheme,
[[TS-20260826-002]], [[TS-20260826-004]]

### 증상

`xcodebuild test -workspace sources/GitIt.xcworkspace -scheme Data -destination
"platform=iOS Simulator,name=iPhone 17 Pro" CODE_SIGNING_ALLOWED=NO`를 실행하면
`DataLearningProjectTests` 타겟의 `HTTPAnswerRemoteTests.swift`·
`ServerAPIErrorTests.swift` 컴파일이 `Value of type 'RubricResponseDTO' has no
member 'score'` 오류로 실패해 Data 전체 test scheme 빌드가 중단된다. 이 오류는
이번 세션이 손대지 않은 `sources/Projects/Data/LearningProject/DTOs/AnswerDTOs.swift`
등 세션 시작 이전부터 있던 미커밋 변경(LearningProject 관련, 이 기능 범위 밖)에서
비롯됐다.

`-only-testing:DataMemberTests -only-testing:DataLegalConsentTests`와
`-skip-testing:DataLearningProjectTests -skip-testing:DataExternalRepositoryTests
-skip-testing:DataAuthenticationTests`를 함께 줘도 xcodebuild는 scheme에 포함된
모든 test target을 빌드 단계에서 그대로 컴파일했고(실행 대상만 걸러짐), 오류를
회피하지 못했다. `-project Data.xcodeproj -target DataMemberTests -target
DataLegalConsentTests`로 workspace 없이 직접 빌드하면 `Infrastructure` 프로젝트
참조를 해석하지 못해(`unable to resolve module dependency:
'InfrastructureNetworkClient'`/`'InfrastructureCache'`) 별도로 실패했다.

### 영향

T037(`MemberProfileResponseDTO.swift`)·T039~T041(`LegalConsent` 신규 파일)의
정확성을 공식 `Data` xcodebuild test scheme으로 실행해 확인하지 못했다. 프로덕션
빌드 성공과 Xcode 프로젝트 밖 standalone `swift` 스크립트 검증으로 대체했으며, 이
대체 검증은 실제 iOS target·의존성 그래프·Testing 프레임워크 실행 경로를 거치지
않는다는 한계가 있다.

### 근거

- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme Data
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
  CODE_SIGNING_ALLOWED=NO`: `** TEST FAILED **`,
  `SwiftCompile ... HTTPAnswerRemoteTests.swift`에서
  `Value of type 'RubricResponseDTO' has no member 'score'`.
- 같은 명령에 `-only-testing:DataMemberTests -only-testing:DataLegalConsentTests`
  또는 `-skip-testing:DataLearningProjectTests -skip-testing:DataExternalRepositoryTests
  -skip-testing:DataAuthenticationTests`를 추가해도 `DataLearningProjectTests`가
  계속 컴파일되어 동일하게 실패함을 확인했다.
- `xcodebuild build -workspace sources/GitIt.xcworkspace -scheme Data
  -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`:
  `** BUILD SUCCEEDED **`, `grep -c "error:"` 결과 0건.
  (`build` action은 test target을 포함하지 않아 우회됨.)
- `xcodebuild build -project sources/Projects/Data/Data.xcodeproj -target
  DataMemberTests -target DataLegalConsentTests ...`: `unable to resolve
  module dependency: 'InfrastructureNetworkClient'`/`'InfrastructureCache'`로
  실패(workspace 없이는 Infrastructure project reference를 못 찾음).
- Xcode 프로젝트 밖 scratchpad에 `MemberProfileResponseDTO`·`DataMemberError`·
  `LocalPolicyConsentStore`·`PolicyConsentRecordDTO`의 실제 프로덕션 코드를 그대로
  복제한 standalone `swift` 스크립트를 만들어 `swift <script>.swift`로 실행:
  null 조합 보존, 미지원 타입 decoding 실패, 계약된 404 vs 일반 404 vs 5xx 매핑,
  문서별 교체, `UserDefaults` suite 재설정 후 부재까지 모두
  `ALL CHECKS PASSED`로 통과.

### 원인

`RubricResponseDTO.score` 컴파일 오류는 `AnswerDTOs.swift` 등 LearningProject
관련 미커밋 변경이 대응하는 테스트 파일과 아직 맞춰지지 않은 상태로 남아 있기
때문으로 추정된다(이번 세션 범위 밖이라 원인을 더 조사하지 않았다). CodeSign
실패는 [[TS-20260826-002]]/[[TS-20260826-004]]와 동일한 iCloud Desktop 동기화
확장 속성 문제로 추정된다. `xcodebuild`가 `-only-testing`/`-skip-testing`으로도
scheme에 등록된 모든 test target을 빌드하는 것은 이번에 처음 확인한 xcodebuild
자체의 동작이며, 저장소 결함이 아니다.

### 조치

`AnswerDTOs.swift`·`HTTPAnswerRemoteTests.swift`·`ServerAPIErrorTests.swift`는
Data 패키지 tasks.md의 T033~T043 어디에도 명시되지 않아 수정하지 않았다. 대신
`CODE_SIGNING_ALLOWED=NO`로 CodeSign 문제를 우회한 뒤, `build` action(프로덕션
전체 컴파일 확인)과 workspace 밖 standalone `swift` 스크립트(로직 검증)로 대체
검증했다. 프로젝트 설정, 스킴 파일, Tuist manifest는 변경하지 않았다.

### 검증

- `xcodebuild build -workspace sources/GitIt.xcworkspace -scheme Data
  -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`: 성공.
- standalone `swift` 스크립트 2건(`MemberProfileResponseDTO` decode 계약,
  `LocalPolicyConsentStore`/`DataMemberError` 로직): 성공, `ALL CHECKS PASSED`.
- 공식 `xcodebuild test -scheme Data`: 미실행(위 컴파일 오류로 차단).

### 재발 방지

다음 세션에서 LearningProject 관련 미커밋 변경이 해소되면(다른 작업 범위) Data
scheme 전체 test를 다시 시도해 T033~T043 테스트가 실제 Swift Testing 실행
경로에서 통과하는지 재확인한다. 그 전까지 Data 패키지 관련 세션은 이 항목과
[[TS-20260826-002]]/[[TS-20260826-004]]를 참조해 같은 우회를 반복 적용하고,
`-only-testing`/`-skip-testing`으로 무관한 target 컴파일을 건너뛸 수 있다고
가정하지 않는다.

### 연결

[[TS-20260826-002]], [[TS-20260826-004]]

## TS-20260826-006: Composition 패키지 tasks.md에 정책 동의 Tuist 의존성 작업 누락

**기록일**: 2026-08-26
**상태**: 미해결
**발생 단계**: speckit-implement, Composition 패키지(T044~T055) 구현
**관련 항목**: T045, T051, T052, T054, T055,
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`

### 증상

T045(`PolicyConsentRepositoryAdapterTests.swift`)·T051
(`PolicyConsentRepositoryAdapter.swift`)와 T052·T054의 정책 동의 관련 부분을
구현하려면 `CompositionAdapter` target이 `DataLegalConsent`(정책 동의 저장,
Data 패키지 T039~T041에서 신설)와 `InfrastructureCache`(`UserDefaultsStore`가
있는 target, Infrastructure 패키지 T030~T031에서 신설) 의존성을 새로 선언해야
한다. 이 선언은 `sources/Tuist/ProjectDescriptionHelpers/Projects/
CompositionModuleName.swift`에서만 가능하지만, tasks.md의 Composition 패키지
소유 경로(`sources/Projects/Composition/Adapter/`,
`sources/Projects/Composition/Tests/Adapter/`)에는 이 Tuist helper 파일이
포함되지 않고, T044~T055 어떤 작업도 이 파일을 명시하지 않는다.

### 영향

T045·T051과 T052·T054의 정책 동의 관련 부분, T055(패키지 검증)를 이번 세션에서
완료하지 못했다. Composition 패키지가 부분 완료 상태로 남아 다음 패키지(UI)
진행 승인 전에 이 공백을 먼저 해소해야 한다.

### 근거

- `sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`
  읽음: `CompositionAdapter` target의 `dependencies` 배열에
  `.fromData(.DataAuthentication)`·`.fromData(.DataLearningProject)`·
  `.fromData(.DataExternalRepository)`·`.fromData(.DataMember)`·
  `.fromInfrastructure(.InfrastructureNetworkClient)`·
  `.fromInfrastructure(.InfrastructureAuthentication)`만 있고
  `.fromData(.DataLegalConsent)`·`.fromInfrastructure(.InfrastructureCache)`는
  없음을 확인했다.
- `docs/package-rules/composition.md`: "Data가 요구하는 기술 계약의 concrete
  구현은... Composition은 이를 변환하는 별도 Adapter를 두지 않고 그 구현을
  조립 대상으로만 사용한다"·"Infrastructure의 외부 라이브러리 구체 API를 Data
  구현이 아닌 Composition이 직접 사용해서는 안 된다" — Composition이
  Infrastructure를 직접 쓰지 않고 반드시 `DataLegalConsent`를 거쳐야 함을
  확인했다.
- Infrastructure 패키지 T031, Data 패키지 T042는 각 패키지에서 동일한 유형의
  Tuist target 갱신을 명시적으로 작업화했지만, Composition 패키지 T044~T055에는
  대응 작업이 없다.
- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme Composition
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
  CODE_SIGNING_ALLOWED=NO`: 정책 동의 관련 코드를 제외한 나머지 Composition
  변경(T044·T046~T050·T053)에 대해 `Test run with 39 tests in 16 suites
  passed`로 통과함을 확인했다(이 실행에는 `PolicyConsentRepositoryAdapter`
  관련 코드가 아직 없어 정책 부분 검증은 포함되지 않는다).

### 원인

tasks.md 작성 시 Composition 패키지의 "소유 경로"에 Tuist helper 파일이
포함되지 않았고, Infrastructure·Data 패키지에서는 별도 작업(T031, T042)으로
명시했던 것과 달리 Composition 패키지에는 상응하는 Tuist 의존성 갱신 작업이
빠졌다.

### 조치

`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`는
활성 tasks.md의 어떤 작업도 명시하지 않아 수정하지 않았다(speckit-implement
Allowed Write Paths 규칙 준수). 대신 정책 동의와 무관한 나머지 Composition
작업(T044·T046~T050·T053)만 구현·검증하고, T045·T051·T052(정책 부분)·
T054(정책 노출 부분)·T055는 미완료로 남긴 채 사용자에게 이 공백을 보고하고
`/speckit-tasks` 재실행으로 누락된 Tuist 의존성 작업을 tasks.md에 추가하도록
요청했다.

### 검증

- 위 `xcodebuild test -scheme Composition` 실행: 성공(정책 무관 범위만).
- `/speckit-tasks` 재실행 이후 새 작업이 추가되면 그 작업 완료 뒤 T045·T051·
  T052·T054·T055 재시도로 검증 예정(미실행).

### 재발 방지

다음 세션에서 `/speckit-tasks`로 Composition 패키지에
`sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift`
갱신 작업(정확한 경로 명시)이 추가됐는지 먼저 확인한 뒤 T045·T051을 진행한다.
향후 새 패키지 tasks.md를 작성할 때 그 패키지가 다른 패키지의 신규 target을
소비해야 하면, Infrastructure T031·Data T042와 동일하게 그 패키지 자신의 Tuist
helper 갱신 작업을 함께 명시했는지 점검한다.

### 연결

없음

## TS-20260826-007: T055의 AppComposition 공개 표면 확장이 소유권 없는 guard 테스트를 깨뜨림

**기록일**: 2026-08-26
**상태**: 미해결
**발생 단계**: speckit-implement, Composition 패키지(T044~T056) 구현, T055
**관련 항목**: T055, `sources/Projects/Composition/Adapter/AppComposition.swift`,
`sources/Projects/Composition/Tests/Adapter/AppCompositionPublicSurfaceTests.swift`

### 증상

T055에 따라 `AppComposition`에 `public let policyConsent: any PolicyConsentUseCase`
프로퍼티를 추가했다. 이 변경 자체는 컴파일에 성공했지만,
`AppCompositionPublicSurfaceTests.swift`의 `공개 프로퍼티 이름이 UseCase 전체 목록과
정확히 일치한다` 테스트가 `Mirror`로 `AppComposition`의 전체 공개 저장 프로퍼티 이름
집합을 하드코딩된 `expected` Set(22개, `policyConsent` 없음)과 정확히 비교하도록
작성돼 있어, 새 프로퍼티가 추가된 `labels`(23개)와 달라 실패했다.

### 영향

Composition 패키지 검증(T056)을 이번 세션에서 "무결점"으로 완료 보고할 수 없다.
`AppCompositionPublicSurfaceTests.swift`는 활성 tasks.md의 Composition 패키지
소유 경로(T044~T056)에 정확한 경로로 명시되지 않아 speckit-implement Allowed Write
Paths 규칙상 수정할 수 없고, 이 갭이 해소될 때까지 Composition 패키지는 부분 완료
상태로 남는다.

### 근거

- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme Composition
  -destination "platform=iOS Simulator,id=580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F"
  CODE_SIGNING_ALLOWED=NO`: `Test run with 44 tests in 17 suites failed after
  0.102 seconds with 1 issue.` 유일한 실패는
  `AppCompositionPublicSurfaceTests.공개 프로퍼티 이름이 UseCase 전체 목록과 정확히
  일치한다()`이고, T045·T046·T047·T048·T049·T050·T051·T052·T053·T054 관련 나머지
  43개 테스트는 모두 통과했다.
- `sources/Projects/Composition/Tests/Adapter/AppCompositionPublicSurfaceTests.swift`
  읽음: `expected` Set에 `policyConsent`가 없다. 같은 디렉터리의
  `AppCompositionTests.swift`만 T049로 명시돼 있고 이 파일은 tasks.md 어디에도 없다.
- 이 실행 직전 첫 시도에서 `xctest`가 `Test crashed with signal segv while
  preparing to run tests`로 부트스트랩 단계에서 죽었다(exception
  `EXC_BAD_ACCESS`/`SIGSEGV`, `KERN_INVALID_ADDRESS at 0x0bad4007`,
  `computeMetadataBoundsFromSuperclass`/`realizeAllClasses` 프레임). `rm -rf
  ~/Library/Developer/Xcode/DerivedData/GitIt-*` 후 재실행하니 이 크래시는
  재현되지 않고 위 정상적인 1건 실패로 바뀌었다(`-derivedDataPath` 미지정과
  관련한 stale index/module cache로 추정, 근본 원인은 확인하지 못했다).

### 원인

tasks.md 작성 시 T055가 `AppComposition`의 공개 표면을 policy·cleanup까지 확장하도록
요구하면서도, 같은 디렉터리에 이미 존재하던 "공개 표면 정확히 일치" guard 테스트
(`AppCompositionPublicSurfaceTests.swift`)의 `expected` 목록 갱신을 별도 작업으로
명시하지 않았다. TS-20260826-006과 동일한 유형(작업이 요구하는 변경이 소유권 없는
파일에 영향을 줌)이지만 이번에는 대상이 Tuist helper가 아니라 이 guard 테스트다.

### 조치

`AppCompositionPublicSurfaceTests.swift`는 수정하지 않았다(Allowed Write Paths 준수).
`AppComposition.swift`의 `policyConsent` 노출(T055 요구사항)은 그대로 유지했다.
DerivedData 삭제로 크래시를 우회한 것 외에는 프로젝트 설정·스킴 파일을 변경하지
않았다. 사용자에게 이 공백을 보고하고 `/speckit-tasks` 재실행으로
`AppCompositionPublicSurfaceTests.swift`의 `expected` 갱신 작업을 tasks.md에
추가하거나 이 파일을 T055 소유 경로에 포함하도록 요청할 예정이다.

### 검증

- 위 `xcodebuild test -scheme Composition` 실행(DerivedData 삭제 후): 43/44
  통과, 유일한 실패가 이 guard 테스트임을 확인.
- `/speckit-tasks` 재실행 이후 새 작업이 추가되면 그 작업 완료 뒤 재검증 예정
  (미실행).

### 재발 방지

향후 `AppComposition`이나 assembly의 공개 표면을 확장하는 작업을 설계할 때는, 같은
패키지 안에 "공개 표면 정확히 일치" 유형의 guard 테스트가 있는지 먼저 확인하고 그
갱신도 같은 작업 또는 별도 작업으로 명시한다. 또한 Composition 계열 xcodebuild test를
`-derivedDataPath` 없이 재실행해 원인 불명 부트스트랩 크래시가 재현되면, 먼저
`~/Library/Developer/Xcode/DerivedData/GitIt-*` 삭제 후 재시도한다.

### 연결

[[TS-20260826-006]]

## TS-20260826-008: TS-20260826-007 사용자 승인 뒤 guard 테스트 갱신으로 해결

**기록일**: 2026-08-26
**상태**: 해결
**발생 단계**: speckit-implement, Composition 패키지(T044~T056) 구현, T056 검증
**관련 항목**: [[TS-20260826-007]], T055, T056,
`sources/Projects/Composition/Tests/Adapter/AppCompositionPublicSurfaceTests.swift`

### 증상

[[TS-20260826-007]]에서 보고한 대로 `AppCompositionPublicSurfaceTests.swift`가
tasks.md 어떤 작업도 명시하지 않아 Allowed Write Paths 규칙상 수정할 수 없는 채로
남아 있었다.

### 영향

이 공백이 해소되지 않으면 T056(Composition 패키지 test scheme 실행·보고)을 무결점으로
완료할 수 없었다.

### 근거

- 사용자에게 두 가지 방안(이 자리에서 직접 수정 승인 / `/speckit-tasks` 재실행으로 작업
  추가)을 제시했고, 사용자가 "이 자리에서 바로 수정 승인"을 선택했다(이 세션의 사용자
  응답).

### 원인

tasks.md의 사전 정의된 작업 범위 공백(TS-20260826-007과 동일)이며, 사용자의 명시적
직접 승인으로 예외 처리했다.

### 조치

`sources/Projects/Composition/Tests/Adapter/AppCompositionPublicSurfaceTests.swift`의
`expected` Set에 `"policyConsent"`를 추가했다(다른 내용은 변경하지 않음).

### 검증

- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme Composition
  -destination "platform=iOS Simulator,id=580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F"
  CODE_SIGNING_ALLOWED=NO`: `Test run with 44 tests in 17 suites passed after
  0.065 seconds.`, `** TEST SUCCEEDED **`.

### 재발 방지

[[TS-20260826-007]]과 동일.

### 연결

[[TS-20260826-007]]

## TS-20260826-009: T063의 SheetSurface 무조건 ScrollView 래핑이 픽셀 단위 layout contract UI test를 깨뜨림

**기록일**: 2026-08-26
**상태**: 해결
**발생 단계**: speckit-implement, UI 패키지(T057~T065) 구현, T063
**관련 항목**: T063, `sources/Projects/UI/Component/Components/Composite/SheetSurface.swift`,
`sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`,
`sources/Projects/UI/ComponentPreviewApp/LayoutContractCatalog.swift`

### 증상

T063(`SheetSurface`가 Dynamic Type과 작은 화면에서 정책 목록과 CTA에 스크롤 접근을
보장하도록 확장)를 구현하면서 처음에는 `content`를 조건 없이 `ScrollView { content }`로
감쌌다. 이 변경 뒤 `LayoutContractUITests.testSheetSurfaceGrabberAndAreaMatchContract`가
실패했다: 처음에는 grabber 아래 content 시작점이 16pt라는 픽셀 단위 계약이 어긋났고
(`sheet.grabberArea` 대상 `assertDimension` 실패), `.contentMargins(.all, 0, for:
.scrollContent)`·`.scrollBounceBehavior(.basedOnSize)`를 추가한 뒤에는 accessibility
identifier `sheet.surface`가 붙은 element의 타입이 `Other`에서 `ScrollView`로 바뀌면서
`renderedBounds`가 `sheet.surface.background`에 매칭되는 픽셀을 전혀 찾지 못해
(`XCTUnwrap failed ... actual none in 960x60 image`) 여전히 실패했다.

### 영향

수정하지 않았다면 T063 완료와 T065(UI 패키지 test scheme 실행·보고)를 무결점으로
완료할 수 없었고, `SheetSurface`를 사용하는 다른 화면(알림 sheet 등)의 기존 레이아웃도
함께 깨질 위험이 있었다.

### 근거

- `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme UIUITests -destination
  "platform=iOS Simulator,id=580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F"
  CODE_SIGNING_ALLOWED=NO`(무조건 ScrollView 래핑 버전): `LayoutContractUITests` suite
  에서 `testSheetSurfaceGrabberAndAreaMatchContract` 1건만 실패, 나머지 14개는 통과.
- 같은 명령을 `-only-testing:UIComponentPreviewAppUITests/LayoutContractUITests/
  testSheetSurfaceGrabberAndAreaMatchContract`로 재실행(`.contentMargins`·
  `.scrollBounceBehavior` 추가 뒤): `error: ... XCTUnwrap failed: expected non-nil
  value of type "CGRect" - sheet.surface.background: expected matching rendered
  pixels, actual none in 960x60 image`, 로그에서 `Find the "sheet.surface" ScrollView`
  로 element 타입이 바뀐 것을 확인.
- `sources/Projects/UI/ComponentPreviewApp/LayoutContractCatalog.swift`(141~150행)
  읽음: `sheet.surface` accessibility identifier는 `SheetSurface { ... }
  .frame(width:).accessibilityElement(children: .contain)`에 붙어 있어 `SheetSurface`
  내부 구조 변경이 이 identifier가 가리키는 element의 종류·bounds에 직접 영향을 줌을
  확인했다.
- `SheetSurface.ViewModel`에 `isScrollable: Bool = false`(기본값)를 추가해 기존
  호출자(카탈로그 preview 포함)는 `content`를 그대로 렌더링하고 `isScrollable: true`를
  명시한 호출자만 `ScrollView`로 감싸도록 재설계한 뒤 재실행:
  `xcodebuild test -workspace sources/GitIt.xcworkspace -scheme UIUITests -destination
  "platform=iOS Simulator,id=580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F"
  CODE_SIGNING_ALLOWED=NO`: `Executed 16 tests, with 0 failures`,
  `** TEST SUCCEEDED **`. 같은 조건으로 `xcodebuild test -scheme UI -destination
  "platform=iOS Simulator,id=580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F"
  CODE_SIGNING_ALLOWED=NO`도 `Test run with 31 tests in 9 suites passed`·
  `Test run with 38 tests in 11 suites passed`로 재확인했다.

### 원인

`SheetSurface`는 문서화되지 않은 픽셀 단위 layout contract UI test
(`LayoutContractUITests.testSheetSurfaceGrabberAndAreaMatchContract`)의 대상이었는데,
T063 작업 설명(`Dynamic Type과 작은 화면에서 ... 스크롤 접근을 보장하도록 확장한다`)만
으로는 이 컴포넌트의 기본 렌더 경로를 무조건 바꾸면 안 된다는 제약이 명시되지 않았다.
`ScrollView`로 무조건 감싸면 (1) 레이아웃 측정 자체가 달라져 16pt 오프셋 계약이 깨지고,
(2) accessibility identifier가 위치한 element의 UI 타입이 `Other`→`ScrollView`로 바뀌어
스크린샷 기반 픽셀 매칭이 완전히 실패하는 두 가지 다른 방식으로 기존 계약을 깼다.

### 조치

`SheetSurface.ViewModel`에 `isScrollable: Bool = false` 기본값을 가진 옵트인 플래그를
추가해, 기존 호출자(다른 sheet 사용처와 `LayoutContractCatalog`의 `sheet.surface`
preview 포함)는 기존과 동일하게 렌더링하고, `isScrollable: true`를 명시한 호출자만
`ScrollView`(zero content margins, `.scrollBounceBehavior(.basedOnSize)`)로 content를
감싸도록 재설계했다.

### 검증

- 위 근거의 마지막 두 `xcodebuild test` 실행(UIUITests 16/16 통과, UI 스킴 31+38
  테스트 통과)이 최종 근거다.

### 재발 방지

향후 이미 존재하는 공용 UIComponent를 확장하는 작업(특히
`LayoutContractUITests.swift`가 픽셀 단위로 검증하는 컴포넌트)을 설계할 때는, 먼저
`LayoutContractCatalog.swift`에서 해당 컴포넌트의 accessibility identifier와 채택
방식을 확인하고, 구조를 바꿔야 한다면 기본 렌더 경로를 유지하는 옵트인 플래그로
확장하는 편이 안전함을 확인한다.

### 연결

없음

## TS-20260826-010: SettingsFeature.swift가 Domain SignOutResult 계약 변경을 반영하지 못해 Feature scheme 빌드 실패

**기록일**: 2026-08-26
**상태**: 미해결
**발생 단계**: speckit-implement, Feature 패키지(T066~T081) 구현 후 패키지 검증(T081)
**관련 항목**: T021(Domain, `SignOutUseCase` 반환 타입을 `AuthenticationOutcome`에서
`SignOutResult`로 변경, 완료), `sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift`

### 증상

Onboarding 패키지(T066~T080) 구현을 마치고 `xcodebuild -scheme Feature build`를 별도
DerivedData에서 직접 실행하자 다음 오류로 `BUILD FAILED`가 발생했다.

```text
SettingsFeature.swift:144:57: error: cannot convert value of type 'SignOutResult' to
expected argument type 'AuthenticationOutcome'
                    await send(.effect(.signOutFinished(outcome)))
```

### 영향

Feature 패키지의 실제 build/test 실행(T081, `make tuist` 이후 Feature build/test)을
완료하지 못했다. Onboarding 패키지 자체의 정합성은 이 오류 이전 단계에서 별도로
확인되지 않은 상태이며, Feature scheme 전체가 이 파일 하나 때문에 컴파일되지 않아
Onboarding 코드의 실제 컴파일 성공 여부도 아직 독립적으로 검증하지 못했다.

### 근거

- `git status --short sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift`:
  출력 없음 — 이번 세션에서 이 파일을 전혀 수정하지 않았고 커밋된 상태 그대로임을 확인.
- `sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift:85`: `case
  signOutFinished(AuthenticationOutcome)`로 선언되어 있음.
- `sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift:144`: `let outcome
  = await signOut()` 뒤 `.effect(.signOutFinished(outcome))`을 보냄. `signOut`은
  `any SignOutUseCase`이며 T021 완료 후 `callAsFunction()`이 `SignOutResult`를 반환한다.
- `sources/Projects/Feature/Presentation/Settings/SettingsFeature.swift:206-214`: `switch
  outcome { case .unauthenticated: ...; case .authenticated, .recoverableFailure: ... }`로
  옛 `AuthenticationOutcome` 3케이스를 그대로 분기하고 있어 `SignOutResult`의
  `success`/`retryableFailure` 2케이스와 맞지 않는다.
- `grep -rln "AuthenticationOutcome" sources/Projects/Feature/Presentation`: 결과가
  `SettingsFeature.swift` 하나뿐임을 확인 — Feature 안에서 이 계약 불일치의 영향을 받는
  다른 파일은 없다.
- `specs/016-onboarding-login-tutorial-app-integration/tasks.md`의 T001~T102 전체를
  검색해 `SettingsFeature.swift`를 명시한 작업이 없음을 확인. Feature 패키지 소유 경로도
  `sources/Projects/Feature/Presentation/Onboarding/`,
  `sources/Projects/Feature/Tests/Onboarding/`,
  `sources/Tuist/ProjectDescriptionHelpers/Projects/FeatureModuleName.swift`로 한정돼
  Settings 화면을 포함하지 않는다.

### 원인

Domain 패키지 단계(T021, 이미 완료·미커밋)에서 `SignOutUseCase.callAsFunction()`의 반환
타입을 상태 조회 타입 `AuthenticationOutcome`에서 액션 결과 타입 `SignOutResult`로
분리했다. 이 변경의 소비자 정합화는 tasks.md의 Composition 패키지
(`AuthenticationRepositoryAdapter`)와 Feature 패키지의 Onboarding 관련 작업에만
배정됐고, 같은 Domain 계약을 이미 소비하고 있던 기존 `SettingsFeature.swift`(U16
sign-out 흐름)를 갱신하는 작업은 어떤 패키지 단계에도 명시되지 않았다. `speckit-tasks`
재생성 이력(tasks.md 상단 "재생성 사유"·"부분 갱신 사유 1~3")에도 이 파일은 등장하지
않아, Domain 계약 변경의 기존 소비자 전수 조사가 누락된 것으로 보인다(확인 중 —
tasks.md 생성 세션의 실제 조사 범위는 이 세션에서 재확인할 수 없음).

### 조치

미실행. `SettingsFeature.swift`는 Feature 패키지의 현재 승인 범위(Onboarding) 소유
경로 밖이고 어떤 작업도 명시하지 않아 Allowed Write Paths에 따라 이 세션에서 직접
수정하지 않았다. 사용자에게 이 공백을 보고하고 (1) `/speckit-tasks` 재실행으로
`SettingsFeature.swift` 정합화 작업을 tasks.md에 추가하거나 (2) 이 파일을 현재 Feature
패키지 승인 범위에 포함하도록 사용자의 명시적 지시를 받는 방안을 제시할 예정이다.

### 검증

- `xcodebuild -workspace sources/GitIt.xcworkspace -scheme Feature -configuration Debug
  -destination 'generic/platform=iOS Simulator' -disableAutomaticPackageResolution
  -derivedDataPath <세션 전용 임시 경로> build`: `SettingsFeature.swift:144:57` 오류
  하나로 `BUILD FAILED` 재현 확인(2026-08-26).
- Onboarding 패키지 자체 코드가 이 오류와 무관하게 컴파일되는지는 미실행 — 이 오류가
  `SettingsFeature.swift`를 컴파일하는 시점에 발생해 Feature scheme 전체가 여기서
  중단됐다.

### 재발 방지

Domain의 UseCase 반환·인자 타입 계약을 바꾸는 작업을 설계할 때는, `/speckit-tasks`가
새 작업을 배정하기 전에 저장소 전체에서 해당 protocol을 소비하는 기존 production
파일을 `grep -rl "<UseCase 이름>\|<이전 반환 타입>"`으로 먼저 조사하고, 그 결과를 영향
받는 모든 패키지의 작업 목록에 명시적으로 반영한다. 특히 이번 기능(Onboarding)이
직접 건드리지 않는 기존 Feature(Settings, MainShell 등)도 같은 Domain protocol을
공유 소비할 수 있음을 우선순위 없이 전수 확인한다.

### 연결

TS-20260826-006, TS-20260826-009
