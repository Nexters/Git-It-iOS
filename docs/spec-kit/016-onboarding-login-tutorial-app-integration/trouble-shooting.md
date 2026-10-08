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

## TS-20260826-011: App target에서 커스텀 init을 가진 @Reducer 타입이 circular reference로 컴파일 실패

**기록일**: 2026-08-26
**상태**: 완화
**발생 단계**: speckit-implement, App 패키지(T082~T094) 구현, T089
**관련 항목**: T089, `sources/Projects/App/Sources/AppRootFeature.swift`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

### 증상

`sources/Projects/App/Sources/AppRootFeature.swift`에 `@Reducer struct AppRootFeature:
Sendable { ... }`을 선언하면(커스텀 `init`과 `private let` 저장 프로퍼티가 있는 형태)
App(GitIt) target에서만 다음 컴파일 오류가 발생했다.

```text
@__swiftmacro_5GitIt14AppRootFeature7ReducerfMe_.swift:1:1: error: circular reference
extension AppRootFeature: ComposableArchitecture.Reducer {
```

Feature 패키지의 `MainShellFeature`·`OnboardingFeature`처럼 동일한 `@Reducer` + 커스텀
`init` + 여러 `private let any Protocol` 저장 프로퍼티 패턴을 쓰는 기존 Reducer는 문제없이
컴파일된다.

### 영향

App root 연결(T089)의 최초 구현이 App target에서 전혀 컴파일되지 않아 T090~T094 어느
것도 진행할 수 없는 상태였다.

### 근거

- `xcodebuild -scheme App -destination 'generic/platform=iOS Simulator'
  -derivedDataPath /tmp/gitit-isolated-dd2 build`: 최소 재현 코드
  (`@Reducer struct AppRootFeature: Sendable { init(count: Int) { self.count = count };
  private let count: Int; ... var body: some ReducerOf<Self> { Reduce { _, _ in .none } } }`)
  로도 동일한 circular reference가 재현됨을 확인했다.
- 같은 파일에서 저장 프로퍼티와 커스텀 `init`을 모두 제거한 버전(`State`에 `var route:
  Int = 0`만 있고 `Action`도 `case task` 하나뿐인 버전)은 circular reference 없이
  컴파일됨을 확인했다 — 즉 타입 이름이나 `Scope`/`switch` 본문 복잡도가 아니라 "커스텀
  init + 저장 프로퍼티 존재"가 재현 조건이었다.
- 타입 이름을 `AppRootFeature` → `RenamedRootFeature` → `RootFeature`로 바꿔가며 같은
  최소 재현 코드를 반복 실행해, 처음에는 이름 문제로 오인했으나 이후 전체 필드가 있는
  버전을 `RootFeature`라는 이름으로 다시 컴파일하자 동일하게 circular reference가
  재현되어 이름은 원인이 아님을 재확인했다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 GitIt target
  `settings`에만 `"SWIFT_APPROACHABLE_CONCURRENCY": "YES"`,
  `"SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor"`가 있고 Feature/Composition 등 다른
  패키지에는 없음을 `grep`으로 확인했다. 이 두 설정을 GitIt target에서만 제거하고 같은
  최소 재현 코드를 다시 컴파일했으나 circular reference가 계속 재현되어, 이 두 설정
  단독이 원인이라는 가설은 이 세션에서 확정하지 못했다(다른 세팅과의 조합이거나 App
  target 특유의 다른 요인일 수 있다).
- `struct AppRootFeature: Sendable { ... }`를 `nonisolated struct AppRootFeature: Sendable
  { ... }`로 바꾼 뒤 전체 필드가 있는 원래 코드(Scope 2개, 13개 UseCase 저장 프로퍼티,
  전체 switch 분기 포함)를 다시 컴파일: circular reference 없이 성공.

### 원인

App target에서만 재현되고 `nonisolated`로 타입 전체의 격리를 명시하면 사라지는 것으로
보아 App target의 actor-isolation 관련 컴파일러 설정과 `@Reducer` 매크로가 합성하는
`Reducer` 준수부(커스텀 init이 있는 타입 한정)가 상호작용해 발생하는 것으로 추정하지만,
`SWIFT_DEFAULT_ACTOR_ISOLATION`/`SWIFT_APPROACHABLE_CONCURRENCY` 제거만으로는 재현이
계속돼 정확한 단일 원인은 확인하지 못했다.

### 조치

`sources/Projects/App/Sources/AppRootFeature.swift`의 타입 선언을 `@Reducer nonisolated
struct AppRootFeature: Sendable { ... }`로 바꿔 우회했다. Tuist 설정
(`AppModuleName.swift`의 actor-isolation 관련 설정, Firebase 의존성)은 진단 목적으로
일시적으로 제거해봤을 뿐 최종적으로 원래대로 복원했고, 실제로 유지한 변경은
`nonisolated` 키워드 추가뿐이다.

### 검증

- `xcodebuild -workspace sources/GitIt.xcworkspace -scheme App -configuration Debug
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/gitit-final-dd
  build`: `** BUILD SUCCEEDED **`.
- `project_build_runner build`(전체 9개 공유 scheme, `iPhone 17 Pro` destination):
  `프로젝트 요약: 작업=build 시도=9 성공=9 실패=0`.

### 재발 방지

이 저장소에서 App(GitIt) target에 새 `@Reducer` 타입을 추가할 때 커스텀 `init`과 저장
프로퍼티가 하나라도 있으면 `circular reference` 컴파일 오류가 날 수 있음을 먼저 가정하고,
`@Reducer` 다음 줄의 타입 선언에 `nonisolated`를 붙인 뒤 컴파일해본다. 근본 원인이
확인되지 않았으므로, Swift/Xcode 도구 버전이 바뀌면 이 우회가 여전히 필요한지 다시
확인한다.

### 연결

[[TS-20260826-012]]

## TS-20260826-012: GitItTests가 GitIt.app을 처음 host로 사용하며 xctest 부트스트랩 SIGSEGV로 test 단계 차단

**기록일**: 2026-08-26
**상태**: 미해결
**발생 단계**: speckit-implement, App 패키지(T082~T094) 구현, T094
**관련 항목**: T082, T094, `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`,
AppTests xcodebuild test scheme, [[TS-20260826-007]], [[TS-20260826-011]]

### 증상

T082에서 `GitItTests`(unit test target)의 `dependencies`에
`.target(name: AppModuleName.GitIt.rawValue)`를 처음 추가해 `GitIt.app`을 host
application으로 쓰게 됐다. 이후 `xcodebuild test -scheme AppTests`(또는
`project_build_runner test`가 실행하는 동일 scheme)를 실행하면 특정 테스트가 실패하는
것이 아니라 host 앱 자체가 테스트 준비 단계에서 크래시해 다음과 같이 실패한다.

```text
Testing failed:
	GitIt (nnnnn) encountered an error (Early unexpected exit, operation never finished
	bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with
	signal segv while preparing to run tests.))
```

### 영향

T094(App build/test 검증)의 `build`·`compile`(build-for-testing)은 성공하지만 `test`
단계에서 `AppTests`만 실행이 막혀, 이 세션에서 `AppRootFeatureTests`·`PolicyManifestTests`·
`GitItCompositionLifetimeTests`·`GitItCompilationTests`가 실제로 통과하는지 확정 검증하지
못했다.

### 근거

- `~/Library/Logs/DiagnosticReports/GitIt-2026-08-26-193338.ips`(및 이후 재현마다 생성된
  동일 패턴 `.ips`): crashed thread가 `+[XCTestCase(RuntimeUtilities) allSubclasses]` →
  `objc_copyClassList` → `realizeAllClasses()` → `swift_getSingletonMetadata` →
  `_swift_relocateClassMetadata` → `computeMetadataBoundsFromSuperclass`이고 exception은
  `EXC_BAD_ACCESS`/`SIGSEGV`, `KERN_INVALID_ADDRESS at 0x0000000000bad4007`다. 즉 특정
  테스트 코드 실행 전, XCTest가 프로세스 내 모든 Objective-C 클래스를 강제로 realize하는
  시점에 크래시한다.
- `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`의 GitIt target
  `dependencies`에서 `.external(.FirebaseAnalytics)`·`.external(.FirebaseCrashlytics)`를
  일시 제거하고 `tuist generate` 후 재실행: 동일한 crashed thread로 재현됨(Firebase가
  원인이 아님을 확인).
- 같은 파일에서 GitIt target의 `"SWIFT_APPROACHABLE_CONCURRENCY"`·
  `"SWIFT_DEFAULT_ACTOR_ISOLATION"` 설정도 함께 제거하고 재실행: 동일하게 재현됨.
- `xcrun simctl erase 580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F` 후 재실행: 동일하게
  재현됨(시뮬레이터 상태 손상 문제가 아님).
- `rm -rf sources/DerivedData/PreCommit ~/Library/Developer/Xcode/DerivedData/GitIt-*` 후
  `-derivedDataPath sources/DerivedData/PreCommit`로 재실행: 동일하게 재현됨 —
  [[TS-20260826-007]]이 유사한 크래시 시그니처를 DerivedData 삭제로 완화했던 사례와 달리
  이번에는 DerivedData 삭제가 효과가 없었다.
- `project_build_runner test`(9개 공유 scheme 순차 실행) 실행 중 App과 무관한 기존
  `Feature` scheme도 한 번은 `xctest (68984) encountered an error ... crashed while
  preparing to run tests`로 동일 패턴에 실패했다(같은 세션의 개별 재시도들에서는
  Feature가 통과한 이력도 있다) — App 관련 코드 변경과 무관하게 이 실행 환경에서
  산발적으로 나타나는 문제일 가능성을 시사한다.
- 같은 세션에서 `UIUITests`(다른 host app인 `UIComponentPreviewApp` 사용)는
  `Executed 16 tests, with 0 failures`로 정상 통과했다.
- `project_build_runner build`(9/9)와 `project_build_runner compile`(8/8, AppTests
  build-for-testing 포함)은 모두 성공해, 프로덕션·테스트 컴파일 자체는 정상이다.

### 원인

XCTest가 host 프로세스의 Objective-C 클래스를 전부 realize하는 시점에 Swift 런타임의
제네릭 클래스 metadata 계산(`computeMetadataBoundsFromSuperclass` 등)이 SIGSEGV로
죽는다. Firebase 의존성, App target의 actor-isolation 설정, 시뮬레이터 상태,
DerivedData 캐시를 각각 제거·초기화해도 재현이 계속돼 이 세션에서는 확정 원인을 좁히지
못했다. `Feature` scheme도 한 번 동일 패턴으로 실패한 사실은 GitIt.app host 자체의
결함이 아니라 이 Xcode 26 / iOS 26.5 Simulator 실행 환경의 산발적(flaky) 문제일 가능성을
시사하지만, 확정하지는 못했다.

### 조치

미해결. `GitItTests`가 `GitIt.app`을 host로 쓰는 구조(T082의 요구사항이며
`@testable import GitIt`로 App 내부 타입에 접근하려면 필수)는 그대로 유지했다. 이
크래시를 우회하는 프로젝트 설정 변경은 적용하지 않았다(Firebase·actor-isolation 제거는
진단 목적으로 임시 적용했다가 모두 원상 복구했다).

### 검증

- `project_build_runner build`: 성공(9/9).
- `project_build_runner compile`: 성공(8/8, AppTests build-for-testing 포함).
- `project_build_runner test`: 실패(AppTests가 이 크래시로 차단, 그 밖에 Data scheme은
  이 기능과 무관한 기존 실패 4건이 별도로 있었다).
- `AppRootFeatureTests`·`PolicyManifestTests`·`GitItCompositionLifetimeTests`·
  `GitItCompilationTests`의 실제 실행 결과: 미검증(이 크래시로 차단됨).

### 재발 방지

다음 세션에서 AppTests를 다시 시도할 때는 (1) 이 항목과 [[TS-20260826-007]]을 먼저
참조하고, (2) `Feature` 등 App과 무관한 scheme도 같은 세션에서 함께 여러 번 재시도해
산발성 여부를 다시 확인하고, (3) 여전히 재현되면 별도의 macOS/Xcode 환경이나 물리
기기에서 같은 scheme을 실행해 이 환경 특유의 문제인지 좁힌다. `test` 단계 실패만으로
`AppRootFeature`·`PolicyManifestLoader`의 로직 결함을 단정하지 않는다.

### 연결

[[TS-20260826-007]], [[TS-20260826-011]]

## TS-20260827-001: Feature scheme test 실행도 TS-20260826-012와 동일한 xctest 부트스트랩 SIGSEGV로 재현됨

**기록일**: 2026-08-27
**상태**: 환경 제약
**발생 단계**: speckit-implement, Feature 패키지(T081~T082) 구현, T082
**관련 항목**: T082, T070(`OnboardingAccessibilityTests.swift`, 이 세션에서 `.midLevel`→`.middle` 오타 수정 완료), [[TS-20260826-010]], [[TS-20260826-012]]

### 증상

T081 검증(`SettingsFeature.swift`가 이미 `SignOutResult` 계약과 정합함을 확인) 완료 후
T082(Feature build/test)를 위해 격리된 DerivedData에서 `xcodebuild -workspace
sources/GitIt.xcworkspace -scheme Feature -destination 'platform=iOS
Simulator,name=iPhone 17 Pro' test`를 실행했다. 빌드와 테스트 컴파일은 모두 성공했지만
테스트 실행 직전 host 프로세스가 죽어 다음과 같이 실패했다.

```text
Testing failed:
	xctest (28638) encountered an error (Early unexpected exit, operation never finished
	bootstrapping - no restart will be attempted. (Underlying Error: The test runner
	crashed while preparing to run tests: xctest at <external symbol>))
```

`test-without-building`으로 재시도해도 동일하게 재현됐다(`xctest (28727)`).

### 영향

T082(Feature 패키지 `[no-write]` build/test 검증)의 `build`는 성공했지만 `test` 단계가
차단되어, `OnboardingRestoreTests`·`OnboardingLegalAndSignInTests`·
`OnboardingCurationTests`·`OnboardingAccessibilityTests`의 실제 통과 여부를 이 세션에서
확정하지 못했다. Feature 패키지 승인 게이트를 위한 검증 결과 보고가 이 부분만
"미실행/환경 차단"으로 남는다.

### 근거

- `xcodebuild ... -scheme Feature ... build`: `** BUILD SUCCEEDED **`(프로덕션 코드
  컴파일 성공, 이 세션에서 T081 확인과 T070의 `.midLevel`→`.middle` 오타 수정 이후).
- `xcodebuild ... -scheme Feature ... test`: 테스트 대상 4개 파일(`OnboardingAccessibilityTests.swift`,
  `OnboardingRestoreTests.swift`, `OnboardingCurationTests.swift`,
  `OnboardingLegalAndSignInTests.swift`) 모두 컴파일 성공(`Ld ... FeatureTests` 성공) 후
  `xctest` 프로세스가 부트스트랩 중 종료됨을 확인.
- `xcodebuild ... -scheme Feature ... test-without-building`: 동일한 오류로 재현
  확인(`xctest (28727)`).
- `~/Library/Logs/DiagnosticReports/xctest-2026-08-27-172502.ips`를 파싱한 결과,
  crashed thread가 `+[XCTestCase(RuntimeUtilities) allSubclasses]` →
  `objc_copyClassList` → `realizeAllClasses()` → `swift_getSingletonMetadata` →
  `_swift_relocateClassMetadata` → `computeMetadataBoundsFromSuperclass`이고 exception은
  `EXC_BAD_ACCESS`/`SIGSEGV`, `KERN_INVALID_ADDRESS at 0x0000000000bad4007`다. 이는
  [[TS-20260826-012]]가 기록한 crash signature와 프레임 단위로 동일하다.
- `xcrun simctl list devices`: 대상 시뮬레이터 `iPhone 17 Pro
  (580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F)`가 `Booted` 상태였음을 확인(TS-012가 이미
  `simctl erase` 시도로도 재현이 계속됐다고 기록한 것과 같은 시뮬레이터).
- [[TS-20260826-012]]는 "같은 세션에서 App과 무관한 기존 `Feature` scheme도 한 번은
  동일 패턴으로 실패했다"고 이미 기록했다. 이번 관찰은 그 재발 방지 절차가 요청한
  "Feature 등 App과 무관한 scheme도 재시도해 산발성 여부를 확인"을 다른 세션에서 수행한
  결과이며, `GitIt.app`을 host로 쓰는 `GitItTests`뿐 아니라 `FeatureTests`(별도의 경량
  host)에서도 같은 crash가 재현되어, 원인이 `GitIt.app` host 구조([[TS-20260826-012]]가
  검토했던 가설)가 아니라 이 Xcode 26.5 / iOS 26.5 Simulator 실행 환경 자체의 문제일
  가능성을 강화한다.

### 원인

[[TS-20260826-012]]와 동일하게 XCTest가 host 프로세스의 Objective-C 클래스를 전부
realize하는 시점에 Swift 런타임의 제네릭 클래스 metadata 계산이 SIGSEGV로 죽는다.
`FeatureTests`는 `GitIt.app`을 host로 쓰지 않는 별도의 경량 xctest bundle인데도 동일한
crash가 발생해, 원인이 특정 target 구성이 아니라 이 세션의 Xcode/Simulator 실행 환경
자체에 있을 가능성이 더 커졌다. 확정 원인은 여전히 미확인이다.

### 조치

미실행. 이 crash를 우회하는 프로젝트 설정 변경은 시도하지 않았다. T070의
`.midLevel`→`.middle` 오타는 이 crash와 무관한 별개의 실제 컴파일 결함이었으며 이미
수정했다(별도 커밋 대상, 이 기록과 별개로 tasks.md T070 범위 안에서 처리).

### 검증

- `xcodebuild -scheme Feature build`: 성공.
- `xcodebuild -scheme Feature test`: 컴파일 성공, 실행 단계에서 SIGSEGV로 차단.
- `xcodebuild -scheme Feature test-without-building`: 동일하게 차단.
- `OnboardingRestoreTests`·`OnboardingLegalAndSignInTests`·`OnboardingCurationTests`·
  `OnboardingAccessibilityTests`의 실제 실행 결과: 미검증(이 crash로 차단됨).

### 재발 방지

다음 세션에서 Feature 또는 App 패키지 test 검증을 재시도할 때는 (1) 이 항목과
[[TS-20260826-012]]를 먼저 참조하고, (2) 별도의 macOS/Xcode 환경이나 물리 기기에서 같은
scheme을 실행해 이 세션 환경 특유의 문제인지 좁히며, (3) `test` 단계 실패만으로
`OnboardingFeature`·`SettingsFeature` 등 production reducer의 로직 결함을 단정하지
않는다. 두 scheme(App, Feature) 모두에서 동일 signature가 재현된 이상, 세 번째 무관
scheme(예: `Domain`, `UI`)에서도 재현되는지 확인하면 "GitIt.app host 특유" 가설을 완전히
배제하고 "이 환경 전역" 결론으로 좁힐 수 있다.

### 연결

[[TS-20260826-010]], [[TS-20260826-012]]

## TS-20260827-002: SIGSEGV는 전체 환경이 아니라 ComposableArchitecture를 import하는 scheme(Feature·App)에서만 재현됨

**기록일**: 2026-08-27
**상태**: 환경 제약
**발생 단계**: speckit-implement, Feature 패키지(T082) 검증 중 사용자 요청에 따른 교차 확인
**관련 항목**: T082, [[TS-20260826-012]], [[TS-20260827-001]]

### 증상

[[TS-20260827-001]]이 기록한 "이 환경 전역 문제일 가능성" 가설을 좁히기 위해 사용자
요청으로 App·Feature와 무관한 scheme에서 같은 crash가 재현되는지 확인했다. 같은
격리된 DerivedData 방식(`xcodebuild -workspace sources/GitIt.xcworkspace -scheme
<S> -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`)으로 `Domain`,
`UI`, `Composition` 세 scheme을 순서대로 실행한 결과 셋 다 SIGSEGV 없이 정상
종료됐다. 같은 시뮬레이터(`iPhone 17 Pro`,
`580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F`, 세 실행 내내 재부팅 없이 `Booted` 유지)에서
Feature·App만 크래시가 재현되므로, 이 문제는 "이 세션의 Xcode/Simulator 환경 전역"이
아니라 특정 scheme 집합에 국한된다.

### 영향

[[TS-20260827-001]]의 "환경 전역 문제일 가능성" 결론을 좁힌다. Feature·App
패키지의 `[no-write]` test 검증(T082, T095)이 이 crash로 계속 차단될 가능성이 높은
반면, Domain·Infrastructure·Data·Composition·UI 패키지의 test 검증은 이 crash의
영향을 받지 않을 것으로 예상할 수 있는 근거가 생겼다(단, Infrastructure·Data는 이
세션에서 직접 재실행하지 않아 확인 중).

### 근거

- `xcodebuild -scheme Domain ... test`: `Test run with 16 tests in 8 suites passed`,
  `** TEST SUCCEEDED **`.
- `xcodebuild -scheme UI ... test`: `Test run with 32 tests in 11 suites passed`,
  `** TEST SUCCEEDED **`.
- `xcodebuild -scheme Composition ... test`: `Test run with 44 tests in 17 suites
  passed`, `** TEST SUCCEEDED **`.
- `xcodebuild -scheme Feature ... test`, `xcodebuild -scheme App ...`([[TS-20260826-012]]):
  둘 다 `xctest` 프로세스가 부트스트랩 중 SIGSEGV로 종료([[TS-20260827-001]],
  [[TS-20260826-012]]).
- `grep -rl "import ComposableArchitecture" sources/Projects/<패키지> --include="*.swift"
  | wc -l`: `Domain`=0, `UI`=0, `Composition`=0, `Feature`=23, `App`=5. crash가
  재현된 두 scheme만 `ComposableArchitecture`를 import하는 파일을 갖고 있고, 재현되지
  않은 세 scheme은 0건이다.
- `xcrun simctl list devices`: 세 scheme 실행 내내 같은 시뮬레이터
  (`580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F`)가 `Booted` 상태로 유지됨을 확인해, 시뮬레이터
  재부팅이나 상태 변화가 이 차이를 설명하지 않음을 배제했다.

### 원인

확정되지 않았다. `ComposableArchitecture` import 여부와의 상관관계는 이 세션에서 직접
관찰한 사실이지만, `Composition`도 `ComposableArchitecture`에 간접 의존하는
`AuthenticationAssembly` 등을 가질 수 있어(미검증) import 여부만으로 인과관계를
단정하지 않는다. [[TS-20260826-012]]가 기록한 crash 지점(`realizeAllClasses` →
`swift_getSingletonMetadata` → `computeMetadataBoundsFromSuperclass`)은
`@Reducer`·`@ObservableState`·`@CasePathable` 등 `ComposableArchitecture`/`CasePaths`
매크로가 생성하는 제네릭 클래스 metadata 처리와 관련이 있을 가능성이 있는 가설이며,
이 세션에서 Swift 컴파일러나 런타임 소스로 직접 검증하지는 못했다.

### 조치

미실행. 이 crash를 우회하는 프로젝트 설정 변경은 시도하지 않았다.

### 검증

- `xcodebuild -scheme Domain test`: 성공(16/16).
- `xcodebuild -scheme UI test`: 성공(32/32).
- `xcodebuild -scheme Composition test`: 성공(44/44).
- `xcodebuild -scheme Feature test`, `AppTests`: 실패(SIGSEGV, [[TS-20260827-001]],
  [[TS-20260826-012]]).
- Infrastructure, Data scheme: 이 세션에서 재실행하지 않음(미실행).

### 재발 방지

다음 세션에서 이 가설을 더 좁히려면 (1) Infrastructure·Data scheme도 같은 방식으로
실행해 `ComposableArchitecture` 미의존 scheme 전체가 일관되게 통과하는지 확인하고,
(2) Feature 또는 App에서 `ComposableArchitecture` 매크로 사용을 최소화한 별도의 진단용
target으로 재현 여부를 좁히거나, (3) Xcode/Swift 버전을 변경할 수 있는 환경에서 같은
scheme을 재시도해 툴체인 버전 문제인지 확인한다. 이 상관관계가 재현되지 않는 반례가
나오면 이 항목을 참조하는 후속 항목으로 뒤집는다.

### 연결

[[TS-20260826-012]], [[TS-20260827-001]]

## TS-20260827-003: T095(App `[no-write]` build/test) 재시도에서도 TS-20260826-012 SIGSEGV 재발

**기록일**: 2026-08-27
**상태**: 환경 제약
**발생 단계**: speckit-implement, App 패키지(T083~T095) 검증, T095
**관련 항목**: T095, [[TS-20260826-012]], [[TS-20260827-001]], [[TS-20260827-002]]

### 증상

사용자가 T082(Feature `[no-write]` test)를 [[TS-20260827-001]]의 환경 제약으로 보류하고
App 패키지 진행을 명시적으로 승인해, App 패키지 구현(T083~T094, 이미 이전 세션에서
전부 완료)의 `[no-write]` 검증(T095)을 다시 시도했다. `xcodebuild -scheme App build`와
`xcodebuild -scheme AppTests build-for-testing`은 모두 성공했으나 `test-without-building`
실행 중 host 앱 `GitIt`이 다음과 같이 부트스트랩 단계에서 죽었다.

```text
Testing failed:
	GitIt (35742) encountered an error (Early unexpected exit, operation never finished
	bootstrapping - no restart will be attempted. (Underlying Error: The test runner
	crashed while preparing to run tests: GitIt at <external symbol>))
```

### 영향

T095가 다시 미완료로 남는다. `AppRootFeatureTests`·`PolicyManifestTests`·
`GitItCompositionLifetimeTests`·`GitItCompilationTests`의 실제 실행 결과는 이번
세션에서도 확정하지 못했다. 다만 production·테스트 컴파일 자체는 정상임을 재확인했다.

### 근거

- `xcodebuild -scheme App -destination 'generic/platform=iOS Simulator' build`:
  `** BUILD SUCCEEDED **`.
- `xcodebuild -scheme AppTests -derivedDataPath /tmp/gitit-app-verify-dd
  build-for-testing`: `** TEST BUILD SUCCEEDED **`.
- `xcodebuild -scheme AppTests -derivedDataPath /tmp/gitit-app-verify-dd
  test-without-building`: `** TEST EXECUTE FAILED **`, host `GitIt (35742)`.
- `~/Library/Logs/DiagnosticReports/GitIt-2026-08-27-174259.ips`: crashed thread가
  [[TS-20260826-012]]·[[TS-20260827-001]]과 프레임 단위로 동일
  (`+[XCTestCase(RuntimeUtilities) allSubclasses]` → `objc_copyClassList` →
  `realizeAllClasses()` → `swift_getSingletonMetadata` → `_swift_relocateClassMetadata`
  → `computeMetadataBoundsFromSuperclass`, `EXC_BAD_ACCESS`/`SIGSEGV`,
  `KERN_INVALID_ADDRESS at 0x0000000000bad4007`).
- `git status --porcelain=v1`을 build/test 실행 전후로 비교: 추적 파일 변경 없음
  (`[no-write]` 조건 충족).

### 원인

[[TS-20260826-012]]·[[TS-20260827-002]]와 동일. 새로운 원인 정보는 없다.

### 조치

미실행.

### 검증

- `xcodebuild -scheme App build`: 성공.
- `xcodebuild -scheme AppTests build-for-testing`: 성공.
- `xcodebuild -scheme AppTests test-without-building`: 실패(SIGSEGV).
- `git status` 전후 비교: 추적 파일 변경 없음.

### 재발 방지

[[TS-20260826-012]]·[[TS-20260827-002]]의 재발 방지 절차를 그대로 따른다. 이 재발은 그
절차의 우선순위를 바꾸지 않는다.

### 연결

[[TS-20260826-012]], [[TS-20260827-001]], [[TS-20260827-002]]

## TS-20260827-004: PolicyAgreementRow가 view.md §7.2 접근성 규칙 3가지를 위반함(라벨 미적용·combine 누락·isSelected trait 누락)

**기록일**: 2026-08-27
**상태**: 미해결
**발생 단계**: speckit-implement, "전체 완료 검증" T099(접근성 계약 검증) 수행 중
**관련 항목**: T099, T061, T058, `docs/conventions/view.md` §7.2

### 증상

`sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`가
`docs/conventions/view.md` §7.2의 접근성 규칙 중 3가지를 위반한다.

1. `private var accessibilityLabel`(line 61-64, `"필수/선택, {title}"` 형식 계산
   문자열)이 정의만 되어 있고 `body`의 어떤 View에도 `.accessibilityLabel(...)`로
   적용되지 않는 죽은 코드다.
2. 카드형 행 컴포넌트인데 `accessibilityElement(children: .combine)`이 없다 — 체크
   아이콘과 제목 `StyledText`가 결합되지 않은 채 각각 별도 접근성 요소로 남는다.
3. `isSelected` 상태가 아이콘 색상(`designSystemForeground(isSelected ? .blue100 :
   .grey400)`)과 SF Symbol 이름(`checkmark.circle.fill` vs `circle`) 전환으로만
   표현되고 `.accessibilityAddTraits(.isSelected)`가 없다 — 색상·심볼만으로 선택
   상태를 전달한다.
4. 내부 독립 동작 버튼(`onOpenLink`, `chevron.right` 심볼 전용)에 별도
   accessibilityLabel이 없다 — "심볼만 표시하는 컨트롤은 의미 라벨을 필수 초기화
   인자로 받는다"와 "묶인 요소 안 독립 동작 버튼은 별도 라벨로 분리한다" 규칙을 함께
   위반한다.

### 영향

`LegalAgreementScreen.swift:27-33`이 `PolicyAgreementRow`를 그대로 사용하므로, 약관
동의 화면의 각 정책 행이 VoiceOver 사용자에게 "필수 여부 + 문서명"을 하나의 의미
단위로 전달하지 못하고, 체크 여부(선택 상태)를 trait로 인지시키지 못하며, 열기
버튼이 무엇을 여는지 알려주지 않는다. `tasks.md`의 T099(전체 완료 검증, no-write)가
요구하는 "선택 상태가 색상 단독으로 전달되는 사례 0건" 기준을 이 컴포넌트가
충족하지 못한다. T061·T058은 이미 완료 표시된 상태이고 이 세션(전체 완료 검증
단계)에는 UI 패키지 파일을 수정할 수 있는 task 배정이 없어 결함만 기록하고
수정하지 않았다.

### 근거

- `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift:26-47`:
  `body` 전체에 accessibility modifier가 전혀 없음.
- 같은 파일 `:61-64`: 정의만 되고 적용되지 않는 `accessibilityLabel` 계산 프로퍼티.
- 대조군 `sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift:60-61`:
  같은 UI 패키지의 다른 선택형 컴포넌트는 `.accessibilityElement(children: .combine)`과
  `.accessibilityAddTraits(isSelected ? .isSelected : [])`를 올바르게 적용하고
  있어, `PolicyAgreementRow`만 예외적으로 누락됐음을 확인.
- 대조군 `sources/Projects/UI/Component/Scaffolds/ScreenHeader/ScreenHeader.swift:117`과
  `ScreenHeader+Control.swift`: 같은 패키지의 다른 심볼 버튼은
  `accessibilityElement(children: .combine)`과 심볼 전용 컨트롤의 필수 `label` 초기화
  인자 규칙을 지킨다.
- `sources/Projects/UI/Tests/Component/Unit/Controls/PolicyAgreementRowTests.swift`
  전체: `onToggle`/`onOpenLink` 콜백 호출과 `minimumHitArea` 상수만 검증하고, 실제
  뷰를 렌더링해 accessibilityLabel 적용 여부·combine 여부·`isSelected` trait 여부를
  검사하는 테스트가 하나도 없어 이 결함이 T058(테스트 작성)·T061(구현) 완료 표시
  이후에도 발견되지 않은 채 남아 있었다.
- `docs/conventions/view.md` §7.2(472-482행)의 규칙 텍스트와 컴포넌트 코드를 직접
  대조해 확인.

### 원인

T058 테스트가 콜백 전달과 44pt 상수만 검증하도록 작성되어 실제 SwiftUI 접근성
트리(라벨 적용·trait·combine 여부)를 검사하지 않았다. 이 때문에 T061 구현에서
`accessibilityLabel` 계산 프로퍼티를 만들어 두고 실제로 뷰에 붙이는 것을 빠뜨린
실수가 테스트로 걸러지지 않고 UI 패키지 승인 게이트(T065)를 통과했다.

### 조치

미실행. 이 세션은 "전체 완료 검증" 단계의 no-write 작업만 수행하도록 제한되어 있어
UI 패키지 파일을 수정할 권한이 없다. 결함을 기록하고 T099 결과에 실패 항목으로
반영한 뒤 사용자에게 보고했다.

### 검증

- 코드 읽기로 위 4가지 위반을 확인함(성공).
- Accessibility Inspector, VoiceOver 등 실행 기반 검증: 미실행.

### 재발 방지

후속 세션에서 `PolicyAgreementRow.swift`의 `body`에
`.accessibilityElement(children: .combine)`, `.accessibilityLabel(accessibilityLabel)`,
선택 시 `.accessibilityAddTraits(.isSelected)`, `onOpenLink` 버튼에 별도
accessibilityLabel(예: `"\(title) 전문 보기"`)을 추가하고,
`PolicyAgreementRowTests.swift`에 렌더링된 뷰의 접근성 트리를 실제로 검사하는
테스트를 추가해야 한다. 이 결함은 `/speckit-tasks`로 UI 패키지에 새 수정 작업을
추가한 뒤에만 고칠 수 있다.

### 연결

없음

## TS-20260827-005: Onboarding 화면 6개가 view.md §8의 "#Preview는 Screens 파일에 두지 않는다" 규칙을 위반하도록 tasks.md T075~T080이 지시함

**기록일**: 2026-08-27
**상태**: 미해결
**발생 단계**: speckit-implement, "전체 완료 검증" T103(S4 Preview·Figma 비교) 수행 중
**관련 항목**: T103, T075~T080, `docs/conventions/view.md` §8

### 증상

`docs/conventions/view.md` §8(현재 커밋된 상태 포함, 이번 세션의 미커밋 diff는 표의
경로 표기만 `Screens/Previews/`→`Previews/`로 바꿨을 뿐 규칙 자체는 이전부터
존재했다)은 "화면 파일 안에 `#Preview`를 두지 않습니다. 화면 프리뷰는 상태 조합마다
늘어나므로 화면 구현과 분리해 목록으로 관리합니다"라고 명시하며, Feature 화면의
Preview는 `Previews/<영역>Previews.swift`(구 표기 `Screens/Previews/`)에 있어야
한다고 규정한다. 그러나 `tasks.md`의 T075("···SplashScreen.swift에 ... 파일 하단
`iPhone 17 Pro Max` deterministic Preview를 구현한다")부터 T080까지 6개 작업이 모두
"화면 파일 하단에 Preview를 구현한다"고 명시적으로 지시했고, 실제 구현도 그 지시를
그대로 따라 `SplashScreen.swift`·`TutorialScreen.swift`·`LegalAgreementScreen.swift`·
`PositionSelectionScreen.swift`·`CareerSelectionScreen.swift`·`OnboardingScreen.swift`
6개 파일 모두 자기 파일 하단에 `#Preview`를 직접 선언했다.
`sources/Projects/Feature/Onboarding/Previews/`에는 `OnboardingPreviewSupport/`
(mock UseCase 등 지원 타입)만 있고 실제 `#Preview`를 담은 `*Previews.swift` 파일은
하나도 없다.

### 영향

이 세션(전체 완료 검증)은 소스 파일을 수정할 task 배정이 없어 이 불일치를 고칠 수
없다. `tasks.md`를 실행 계약으로 삼아 구현했으므로 T075~T080·T103 자체를 실패로
판정하지는 않았지만, `docs/conventions/view.md` §9 검토 체크리스트의 "화면 프리뷰가
`Previews/`에 있는가?" 항목 기준으로는 Onboarding 화면 6개 전부가 미충족 상태다.
다음에 이 컨벤션을 기준으로 리뷰하면 재작업(Preview를 별도 파일로 옮기는 리팩터링)이
필요하다.

### 근거

- `grep -rln "^#Preview" sources/Projects/Feature/Onboarding/Screens/`: 6개 파일
  전부에서 `#Preview` 발견(`OnboardingScreen.swift`, `LegalAgreementScreen.swift`,
  `PositionSelectionScreen.swift`, `CareerSelectionScreen.swift`,
  `TutorialScreen.swift`, `SplashScreen.swift`).
- `find sources/Projects/Feature/Onboarding/Previews -type f`: `OnboardingPreviewSupport/`
  하위 지원 타입 파일 7개만 있고 `*Previews.swift`는 없음.
- `git diff docs/conventions/view.md`: 이번 세션 시작 시점에 이미 uncommitted였던
  diff가 `Screens/Previews/<영역>Previews.swift` → `Previews/<영역>Previews.swift`로
  경로 표기만 바꿨을 뿐, "화면 파일 안에 `#Preview`를 두지 않는다"는 규칙 자체는 이
  diff 이전(즉 커밋된 버전)부터 존재했음을 확인 — 이 세션의 문서 개정이 만든 새 규칙이
  아니다.
- `specs/016-onboarding-login-tutorial-app-integration/tasks.md`의 T075~T080 6개
  작업 설명이 모두 "파일 하단 ... Preview를 구현한다"는 표현을 명시적으로 포함함을
  확인.

### 원인

확정 원인은 확인하지 못했다. `tasks.md`가 처음 작성될 때 view.md §8의 "화면 파일 안에
Preview를 두지 않는다" 규칙을 반영하지 못한 것으로 보이는 가설과, view.md §8이 이
기능의 작업 목록 확정 이후 추가된 규칙이라 tasks.md가 그 시점 기준으로는 정합했을
가설을 구분하지 못했다 — 두 문서의 변경 이력을 이 세션에서 직접 대조하지 않았다.

### 조치

미실행. 이 세션은 no-write 검증 단계라 `tasks.md`나 Screens 소스를 수정할 권한이 없다.

### 검증

- `grep`으로 6개 파일 전부에서 위반을 확인함(성공).
- `docs/conventions/view.md`의 커밋 이력(`git log -p`)으로 §8 규칙이 언제 추가됐는지
  확인: 미실행.

### 재발 방지

후속 세션에서 (1) `git log -p -- docs/conventions/view.md`로 §8 규칙의 도입 시점을
확인하고, (2) `/speckit-tasks`로 Onboarding 화면 6개의 `#Preview`를
`Feature/Onboarding/Previews/OnboardingScreensPreviews.swift`(또는 화면별 파일)로
옮기는 리팩터링 작업을 추가하거나, view.md §8이 이 기능에는 적용되지 않는다고
명시적으로 예외 처리할지 결정해야 한다.

### 연결

없음

## TS-20260827-006: UIUITests scheme도 동일한 xctest 부트스트랩 SIGSEGV로 재현되어 TS-20260827-002의 "ComposableArchitecture import 여부" 판별 기준이 반례에 부딪힘

**기록일**: 2026-08-27
**상태**: 미해결
**발생 단계**: speckit-implement, 작업 패키지 8(UI 후속 수정) T104(테스트 우선 작성) 수행 중
**관련 항목**: T104, T106, [[TS-20260826-012]], [[TS-20260827-001]], [[TS-20260827-002]]

### 증상

`UIUITests` scheme(`sources/Projects/UI/Tests/Component/UI/LayoutContractUITests.swift`가
속한 XCUITest scheme, `UIComponentPreviewApp`을 실제 구동)이
`xcodebuild -workspace sources/GitIt.xcworkspace -scheme UIUITests -destination
'platform=iOS Simulator,name=iPhone 17 Pro' test`로 재현 가능하게 3회 연속 SIGSEGV로
실패했다. 실패 메시지는 "UIComponentPreviewAppUITests-Runner encountered an error
(Early unexpected exit, operation never finished bootstrapping - no restart will be
attempted. (Underlying Error: The test runner crashed while preparing to run tests:
UIComponentPreviewAppUITests-Runner at _XCTRunnerRunTests))"이다.

이 crash signature는 [[TS-20260826-012]]·[[TS-20260827-001]]·[[TS-20260827-002]]가
기록한 것과 프레임 단위로 동일하다(`computeMetadataBoundsFromSuperclass` →
`_swift_relocateClassMetadata` → `swift_getSingletonMetadata` → `realizeAllClasses` →
`+[XCTestCase(RuntimeUtilities) _allSubclasses]`). 그런데 [[TS-20260827-002]]는
"SIGSEGV는 ComposableArchitecture를 import하는 scheme(Feature·App)에서만 재현되고,
재현되지 않은 Domain·UI·Composition 세 scheme은 ComposableArchitecture import가
0건"이라는 상관관계를 근거로 결론지었다. `UIUITests`는 `ComposableArchitecture`를
import하지 않는데도(같은 UI 패키지의 Swift Testing 유닛 테스트 scheme인 `UI`는 여전히
정상 통과) 동일한 crash가 재현되어, 이 상관관계 가설이 반례에 부딪혔다.

또한 같은 세션 안에서 이 crash가 결정적이지 않았다: 세션 시작 직후 실행한 project
build runner의 전체 `test` 단계에서는 `UIUITests`가 정상 통과("test 완료:
UIUITests")했고, 그로부터 약 1~2시간 뒤 iOS Simulator MCP 도구로 같은 시뮬레이터
(580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F)에 `GitIt.app`을 별도로 빌드·설치·실행(Apple
로그인 화면까지 조작)한 뒤부터는 같은 scheme이 시뮬레이터 재부팅 후에도 3회 연속
재현 가능하게 실패했다.

### 영향

T104가 요구하는 "테스트 우선 작성 뒤 실패를 실제로 확인"을 이 환경에서 실행 기반으로
검증하지 못했다. `LayoutContractCatalog.swift`(카탈로그에 `PolicyAgreementRow` 2개
추가)와 `LayoutContractUITests.swift`(신규 UI 테스트 3개 추가)의 코드는 작성해
컴파일까지 확인했지만, 실제 xctest 실행으로 "결함이 있는 현재 구현에서 실패 → T105
수정 후 통과"를 증명하지 못한 채 코드 검토로 대체해야 했다. 더 근본적으로,
[[TS-20260827-002]]의 "ComposableArchitecture import 여부가 이 crash의 판별 기준"이라는
결론은 이 반례로 더 이상 유지할 수 없다.

### 근거

- `sources/DerivedData/PreCommit/Logs/Test/Test-UIUITests-2026.08.27_19-19-51-+0900.xcresult`,
  `19-21-09`, `19-23-13` 3개 xcresult 모두 동일한 `_XCTRunnerRunTests` 부트스트랩 실패
  메시지를 기록.
- `~/Library/Logs/DiagnosticReports/UIComponentPreviewAppUITests-Runner-2026-08-27-192119.ips`
  (및 `192017`): `exception.type=EXC_BAD_ACCESS`, `signal=SIGSEGV`, `faultingThread`
  프레임이 `computeMetadataBoundsFromSuperclass`(imageOffset 156792) →
  `_swift_relocateClassMetadata` → `swift_getSingletonMetadata` → `realizeAllClasses()`
  → `objc_copyClassList` → `+[XCTestCase(RuntimeUtilities) _allSubclasses]` → ... →
  `_XCTestMain`으로 [[TS-20260826-012]]와 동일.
- `grep -rl "import ComposableArchitecture" sources/Projects/UI --include="*.swift"`:
  0건(UI 패키지 전체가 ComposableArchitecture를 import하지 않음에도 UIUITests에서 crash
  재현).
- `xcrun simctl shutdown 580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F && xcrun simctl boot
  580DF63E-93A7-4E5A-AC70-3EE2F2B07B6F` 뒤 재시도해도 동일하게 실패(3회차 로그에 추가로
  `objc[65886]: Class UIAccessibilityLoaderWebShared is implemented in both ...
  WebKit.axbundle ... and ... WebCore.axbundle ...` 중복 클래스 경고가 새로 관찰됨 — 이
  경고 자체가 crash 원인인지는 미확인).
- `project_build_runner compile`로 `UI` scheme을 포함한 8개 scheme build-for-testing이
  전부 성공(0 errors)해, 이번 세션에서 추가한 `LayoutContractCatalog.swift`·
  `LayoutContractUITests.swift` 코드 자체의 컴파일 문제가 아님을 확인.
- 세션 앞부분(T082/T095 검증 시점)의 project build runner 전체 `test` 실행 로그에서는
  "test 시작: UIUITests" 뒤 "test 완료: UIUITests"로 성공했음(같은 세션, 같은
  시뮬레이터).

### 원인

확정하지 못했다. crash signature 자체는 [[TS-20260826-012]]와 동일해 Swift 매크로가
생성하는 제네릭 클래스 metadata 처리(`realizeAllClasses`)와 관련된 이 macOS/Xcode 환경
고유 문제라는 기존 가설은 유지되지만, "ComposableArchitecture import 여부" 판별
기준은 반례로 기각한다. 세션 중 iOS Simulator MCP 도구로 같은 디바이스에 다른 앱을
설치·구동한 것이 실패 재현성을 바꾼 것처럼 보이는 시간적 상관관계가 있으나(재부팅
후에도 실패가 유지됐으므로 단순 앱 잔존 상태만으로는 설명되지 않음), 인과관계는
확인하지 못했다.

### 조치

미실행. 이 crash를 우회하는 프로젝트 설정 변경은 시도하지 않았다. T105(구현)는 이
테스트 실행 결과와 무관하게 코드 검토 기준으로 진행하고, T106에서 이 환경 제약을 다시
보고한다.

### 검증

- `xcodebuild -scheme UIUITests test`(3회, 시뮬레이터 재부팅 1회 포함): 모두 실패
  (SIGSEGV, 동일 시그니처).
- `project_build_runner compile`(UI 포함 8개 scheme): 성공.
- Domain·Data·Infrastructure·Composition·Feature(unit)·App(unit) scheme 재실행: 미실행
  (이 항목의 범위 밖).

### 재발 방지

후속 세션에서 (1) [[TS-20260827-002]]의 "ComposableArchitecture import" 판별 기준을
폐기하고 대신 "XCUITest(실제 앱 host를 실행하는 scheme)인지 여부"를 다음 가설로
검증한다(UIUITests·Feature·App은 모두 실제 host app을 실행하는 반면 Domain·UI(unit)·
Composition·Data·Infrastructure는 host 없이 라이브러리만 로드함 — 이 시점까지 관찰된
성공/실패 사례 전부와 일치하는지 대조), (2) 동일 시뮬레이터에 다른 앱을 설치·구동한
이력이 이후 XCUITest 재현성에 영향을 주는지 별도로 재현 실험한다(새 시뮬레이터
디바이스를 만들어 다른 앱 설치 없이 UIUITests만 먼저 실행), (3) 새 가설이 맞다면
[[TS-20260827-002]]를 뒤집는 후속 항목을 추가한다.

### 연결

TS-20260826-012, TS-20260827-001, TS-20260827-002

## TS-20260827-007: UIUITests가 실제 실행됐고 PolicyAgreementRow 접근성 identifier 조회가 진짜로 실패함(중복 accessibilityIdentifier)

**기록일**: 2026-08-27
**상태**: 미해결
**발생 단계**: `/speckit-implement` T109(작업 패키지 9: Feature 후속 수정, no-write 패키지 검증)
**관련 항목**: T104~T106(작업 패키지 8), T105 구현 파일 `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`, `sources/Projects/UI/ComponentPreviewApp/Catalogs/LayoutContractCatalog.swift`

### 증상

T107~T108 완료 뒤 `make tuist` → project build runner `test` 실행에서 `UIUITests` scheme이
TS-20260827-006이 기록한 xctest 부트스트랩 SIGSEGV 없이 실제로 실행됐다(이번 세션에서는
재현되지 않음). 그러나 `LayoutContractUITests`의 다음 3개 테스트가 진짜로 실패했다:
`testPolicyAgreementRowCombinesTitleAndRequirementIntoSingleAccessibilityElement`,
`testPolicyAgreementRowExposesIsSelectedTraitSeparatelyFromColor`,
`testPolicyAgreementRowOpenLinkButtonHasOwnAccessibilityLabel`. 세 테스트 모두 같은 오류로
실패했다: `LayoutContractUITests.swift:501: Failed to get matching snapshot: Find single
matching element. Multiple matching elements found`.

### 영향

`policyAgreementRow.unselected`/`policyAgreementRow.selected` identifier로 조회하면 버튼
2개(토글 버튼과 열기 버튼)가 동시에 매칭되어 T104가 의도한 단일 요소 조회, `.isSelected`
trait 검증, 열기 버튼 단독 라벨 검증을 어느 것도 수행할 수 없다. TS-20260827-004가 "코드
검토로 규칙 4가지를 반영했다고 판단했으나 실행 검증이 남아 있다"고 미확정으로 남긴 부분이
실제 실행에서 실패로 확인됐다.

### 근거

- `sources/DerivedData/PreCommit/TestSchemes/UIUITests/Logs/Test/Test-UIUITests-2026.08.27_19-42-35-+0900.xcresult`:
  `xcrun xcresulttool get test-results tests`로 추출한 실패 노드 3건이 모두
  `LayoutContractUITests.swift:501`에서 "Multiple matching elements found"를 보고하며,
  실패 로그의 sparse tree가 `Button, identifier: 'policyAgreementRow.unselected', label:
  '필수, 서비스 이용 약관'`과 `Button, identifier: 'policyAgreementRow.unselected', label:
  '서비스 이용 약관 전문 보기'` 두 버튼이 같은 identifier를 가짐을 보여준다(선택됨 케이스도
  동일 패턴).
- `sources/Projects/UI/ComponentPreviewApp/Catalogs/LayoutContractCatalog.swift:312-326`:
  `PolicyAgreementRow(...)` 인스턴스 전체에 `.accessibilityIdentifier("policyAgreementRow.
  unselected")`/`"policyAgreementRow.selected"`를 걸고 있다.
- `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`(T105
  구현): `onToggle` 버튼에는 `.accessibilityElement(children: .combine)` +
  `.accessibilityLabel` + 선택 시 `.isSelected` trait가 있고, `onOpenLink` 버튼은 형제
  요소로 분리되어 자체 `.accessibilityLabel`만 있고 `.accessibilityIdentifier`는 없다.

### 원인

SwiftUI는 컨테이너(또는 그 하위 View)에 건 `.accessibilityIdentifier`를, 자체
`.accessibilityIdentifier`가 없는 모든 하위 접근성 요소로 전파한다. `PolicyAgreementRow`가
`onToggle`·`onOpenLink` 두 개의 독립 접근성 요소(형제)를 노출하는데 `onOpenLink`에 고유
identifier가 없으므로, `LayoutContractCatalog`가 View 전체에 건 identifier를 두 버튼이
모두 상속해 같은 값을 공유하게 된다. 확정 원인이며 가설이 아니다(xcresult 로그의 sparse
tree가 두 버튼의 동일 identifier를 직접 보여준다).

### 조치

원인에 맞는 최소 수정(`onOpenLink` 버튼에 `title` 기반 고유 `.accessibilityIdentifier`를
추가해 외부에서 건 identifier가 그 버튼으로 전파되지 않도록 함)을 시도했으나, 이 파일은
이미 승인 게이트를 통과한 작업 패키지 8(UI)의 소유 경로이고 현재 활성 작업은 작업 패키지
9(Feature 후속 수정)의 T109(no-write 검증)이다. `/speckit-implement`의 패키지 소유권
규칙(9번: "후속 패키지에서 선행 패키지 수정이 필요하면 구현을 중단하고 이 작업 목록의
소유권과 순서를 재생성한다")에 따라 이 세션은 시도한 수정을 되돌리고 `PolicyAgreementRow.
swift`를 원래 상태로 유지했다. 실제 코드 수정은 미실행이며, `/speckit-tasks` 재실행으로
새 UI 후속 작업(승인 게이트 포함)을 추가해야 한다.

### 검증

- `project_build_runner test`(2026-08-27 19:46~19:48, `iPhone 17 Pro`): `UIUITests` scheme
  자체는 SIGSEGV 없이 실행 완료. `LayoutContractUITests`의 PolicyAgreementRow 관련 3개
  테스트는 실패로 확정. 나머지 `UIComponentPreviewAppUITests`의 다른 테스트는 이 세션에서
  개별 통과 여부를 별도 확인하지 않음(scheme 결과는 3건 실패로 인해 "Failed"로 집계).
- 되돌린 수정 자체의 재검증(수정 후 재실행)은 미실행 — 소유권 규칙에 따라 수정을
  보류했기 때문.

### 재발 방지

다음 세션(또는 `/speckit-tasks` 재실행으로 추가될 UI 후속 작업)에서 `onOpenLink` 버튼에
`onToggle`과 값이 겹치지 않는 고유 `.accessibilityIdentifier`(예: `title` 기반)를 부여하고,
`LayoutContractUITests`의 3개 실패 테스트를 다시 실행해 "Multiple matching elements
found"가 재현되지 않는지, `.isSelected` trait와 열기 버튼 단독 라벨 조회가 의도대로
동작하는지 확인한다.

### 연결

TS-20260827-004(선행, 실행 검증 미실시 상태로 열어 둠), TS-20260827-006(같은 세션에서
SIGSEGV가 재현되지 않음을 함께 확인)

## TS-20260827-008: T110의 "onOpenLink에 고유 identifier만 추가" 처방이 TS-20260827-007을 해소하지 못함(전파 방향 오판)

**기록일**: 2026-08-27
**상태**: 해결
**발생 단계**: `/speckit-implement` 작업 패키지 10(UI 후속 수정 2) T110~T111
**관련 항목**: T110, T111, `sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift`, TS-20260827-007

### 증상

T110은 "`onOpenLink` 버튼에 `title` 기반 고유 `.accessibilityIdentifier`를 추가하면
TS-20260827-007이 해소된다"고 명시했다. 지시대로 `onOpenLink` Button에만
`.accessibilityIdentifier("policyAgreementRow.openLink.\(title)")`를 추가하고 `UIUITests`
scheme을 `xcodebuild test-without-building`으로 iPhone 17 Pro 시뮬레이터에서 실행한 결과,
`LayoutContractUITests`의 PolicyAgreementRow 관련 3개 테스트가 TS-20260827-007과 동일한
"Failed to get matching snapshot: Find single matching element. Multiple matching elements
found"로 재현됐다. sparse tree는 여전히 `onToggle`·`onOpenLink` 두 버튼이 동일한 identifier
`policyAgreementRow.unselected`를 갖는다고 보여줬다(`onOpenLink`에 새로 추가한
`policyAgreementRow.openLink.*` identifier는 무시됨). derived data(`sources/DerivedData/
PreCommit/TestSchemes/UIUITests`, `.../UI`)를 완전히 삭제하고 clean build 후 재실행해도
동일하게 재현되어 캐시 문제가 아님을 확인했다.

### 영향

T110의 처방을 그대로 신뢰했다면 구현 완료로 잘못 보고할 뻔했다. 실제 xctest 실행 없이
코드 검토만으로 "해결"을 판정했던 T106(TS-20260827-004)과 같은 유형의 오판이 재발할
위험이 있었다.

### 근거

- `xcodebuild test-without-building -scheme UIUITests -only-testing:...testPolicyAgreementRow*`
  (2026-08-27 20:20 무렵, `iPhone 17 Pro`, derived data 완전 삭제 후 clean build): 3개
  테스트 모두 실패, sparse tree에 두 버튼이 동일 identifier `policyAgreementRow.unselected`를
  가짐을 직접 확인.
- 동일 조건에서 `onOpenLink`에 `.accessibilityElement(children: .ignore)` + 고유 identifier를
  추가한 변형도 동일하게 재현(collision 지속, 엘리먼트 타입만 Button→Other로 바뀜).
- 동일 조건에서 `onOpenLink`에만 로컬 `.accessibilityElement(children: .contain)`을 적용한
  변형도 동일하게 재현.
- `PolicyAgreementRow`의 `body` 최상위 `HStack` 전체에 `.accessibilityElement(children:
  .contain)`을 적용한 변형은 `onOpenLink` collision을 해소했으나(고유 label로 독립 조회
  성공), 대신 identifier `policyAgreementRow.unselected`가 새로 생긴 컨테이너 노드에
  바인딩되어 `onToggle`의 label 검증이 빈 문자열로 실패하고 `isSelected` trait 검증도
  실패함을 확인.

### 원인

T110은 "SwiftUI가 컨테이너에 건 identifier를 자체 identifier가 없는 하위 요소에만
전파한다"는 전제로 작성됐으나, 실기기 실행으로 반증됐다. 실제 동작은: `HStack`처럼 그
자체가 명시적 accessibility element/container(`.combine`/`.contain`/`.ignore`)로 등록되지
않은 컨테이너에 외부에서 `.accessibilityIdentifier`를 걸면, SwiftUI는 그 identifier를
"어디에 바인딩할지" 결정하지 못해 하위에서 발견되는 모든 접근성 leaf에 무조건 동일하게
복제·전파한다 — 하위 leaf가 자체 identifier를 이미 갖고 있는지 여부와 무관하다. 이
전파를 막으려면 identifier가 바인딩될 명시적 컨테이너 경계(`.contain`)가 필요하며, 그
경계가 없으면 하위 요소에 아무리 고유 identifier를 추가해도 덮어써진다. 확정 원인이며
가설이 아니다(3가지 변형 모두 clean build 후 실기기 실행으로 직접 재현·반증함).

### 조치

`PolicyAgreementRow.swift`의 `body` 최상위 `HStack`에 `.accessibilityElement(children:
.contain)`을 적용해 외부(Catalog)에서 건 identifier가 컨테이너 경계에서 멈추도록 하고,
동일 컨테이너에 `onToggle`이 이미 갖고 있던 것과 같은 값의 `.accessibilityLabel
(accessibilityLabel)`·`.accessibilityAddTraits(isSelected ? .isSelected : [])`를 중복
적용해, 외부 identifier가 이 컨테이너 노드에 바인딩되더라도 `reveal(identifier:)` 조회가
올바른 label·trait를 반환하도록 했다. `onOpenLink` 버튼의 `title` 기반 고유
`.accessibilityIdentifier`(T110 원안)는 유지했다. `onToggle` 버튼 자체의 기존
`.accessibilityElement(children: .combine)`·`.accessibilityLabel`·`.isSelected` trait와
시각 레이아웃(54pt 행 높이, leading 아이콘+제목, trailing chevron)은 변경하지 않았다.

### 검증

- `xcodebuild test-without-building -scheme UIUITests` 전체(2026-08-27 20:22~20:26,
  `iPhone 17 Pro`, clean build 반영): `LayoutContractUITests`를 포함한
  `UIComponentPreviewAppUITests` 19개 테스트 전부 통과("Executed 19 tests, with 0
  failures"), TS-20260827-007 재현 없음.
- `project_build_runner build`(2026-08-27 20:31 무렵): 9/9 성공.
- `project_build_runner compile`(2026-08-27 20:31 무렵): 8/8 성공.
- `project_build_runner test`(2026-08-27 20:33~20:37, `iPhone 17 Pro`): 8개 scheme 중 6개
  성공(`UIUITests` 포함, 신규로 통과). 실패 2건(`AppTests`·`Feature`)은 TS-20260826-012·
  TS-20260827-001~003·006과 동일한 시그니처의 xctest 부트스트랩 SIGSEGV이며 이번 변경과
  무관함을 로그로 확인.

### 재발 방지

SwiftUI 접근성 identifier가 여러 형제 요소를 가진 커스텀 컴포넌트에 외부에서 걸리는
구조라면, "하위 요소에 고유 identifier만 추가하면 충분하다"는 가정을 코드 검토만으로
확정하지 말고 반드시 실기기(UI test) 실행으로 먼저 반증 가능성을 확인한다. 컨테이너가
명시적 accessibility element/container로 등록되어 있지 않은 상태에서 외부 identifier가
걸리는 패턴이 있으면, 그 컨테이너를 `.contain`으로 경계 짓고 기존에 그 identifier로
조회되길 기대하는 특정 자식의 label·trait를 컨테이너에도 동일하게 재적용해야 하는지
함께 점검한다.

### 연결

TS-20260827-007(선행, 이 문제의 원인 처방이 T110에 기록됨), TS-20260827-004(같은
`PolicyAgreementRow` 접근성 결함 계열의 최초 발견)
