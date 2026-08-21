# 작업 목록: GitHub Public Repository Data 계약

**입력**: `/specs/012-github-public-repository-data/`의 `spec.md`, `plan.md`, `research.md`,
`data-model.md`, `contracts/`, `quickstart.md`

**테스트**: spec.md FR-016이 자동화된 계약 테스트를 요구하므로 테스트를 구현보다 먼저 작성하고
대상 production 선언 부재로 실패하는 Red 상태를 확인한다.

**구성**: 적용 대상은 `Data(DataLearningProject)` 단일 패키지다. S1~S3 추적성은 Data 단계
안에서 유지하고, 허용된 Swift 파일 포맷과 Data 집중 검증·결과 보고 뒤에는 Git 추적 파일을
변경하지 않는 전체 저장소 검증만 수행한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 Data 패키지 안에서 서로 다른 파일을 수정하고 미완료 구현에 의존하지 않아
  병렬 실행할 수 있다.
- **[S1]**: Public Repository 최소 응답 데이터 디코딩
- **[S2]**: GitHub 요청 대상과 인증 경계
- **[S3]**: `offline`·`other` 실패 계약
- **[no-write]**: Git 추적 파일을 변경하지 않는 확인·build·test·결과 보고 작업. 실행 전후
  추적 상태가 달라지면 작업 실패로 처리한다.

## 작업 패키지 1: Data(DataLearningProject)

**목표**: GitHub Public Repository 조회를 위한 기술 중립 요청 값, 최소 응답 DTO, Remote와
오류 계약을 제공하고 구체 HTTP 기술이나 Domain 타입 없이 독립적으로 검증한다.

**소유 경로**: `sources/Projects/Data/LearningProject/`,
`sources/Projects/Data/Tests/LearningProject/`

**관련 변경 시나리오**: S1(P1), S2(P1), S3(P2)

**독립 검증**: Data 공유 scheme의 `DataLearningProject` production·test target을
build-for-testing한 뒤 같은 DerivedData로 test-without-building을 실행한다. S1 fixture,
S2 요청 불변조건과 credential 부재, S3 두 오류의 의미·전달 계약이 모두 통과해야 한다.

### 준비와 현재 구성 확인

- [ ] T001 [no-write] `git status --porcelain=v1 --untracked-files=all`의 구현 전 baseline을 세션 결과로 보존하고 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`와 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`에서 `DataLearningProject`·`DataLearningProjectTests` source root와 Data 공유 scheme 연결이 이미 존재함을 확인한다

### 테스트: S1 Public Repository 최소 데이터

- [ ] T002 [P] [S1] `sources/Projects/Data/Tests/LearningProject/DTOs/GitHubRepositoryResponseDTOTests.swift`에 정상 최소 JSON, 추가 필드, avatar key 누락·`null`, topics 누락·`null`·빈 배열, star 0, 필수 owner 누락·`null`, 필수 필드 누락·잘못된 타입과 공개 저장 필드 네 개를 검증하는 Swift Testing 테스트를 작성한다

### 테스트: S2 요청과 인증 경계

- [ ] T003 [P] [S2] `sources/Projects/Data/Tests/LearningProject/Requests/GitHubRepositoryRequestTests.swift`에 대표 owner/repository의 `https`, `api.github.com`, `GET`, `/repos/{owner}/{repo}`, 두 필수 header와 `Authorization`·Git-It access/refresh token·Apple identity token 부재를 검증하는 Swift Testing 테스트를 작성한다

### 테스트: S3 오류와 Remote 계약

- [ ] T004 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Errors/DataExternalRepositoryErrorTests.swift`에 `allCases == [.offline, .other]`, 두 케이스의 구분과 `Equatable`·`Error` 계약을 검증하는 Swift Testing 테스트를 작성한다
- [ ] T005 [P] [S3] `sources/Projects/Data/Tests/LearningProject/Contracts/ExternalRepositoryRemoteContractTests.swift`에 actor Probe가 `GitHubRepositoryRequest`를 한 번 기록해 DTO를 그대로 반환하고 지정된 `.offline`·`.other` 실패를 손실 없이 전달하며 성공 DTO를 반환하지 않는 계약 테스트를 작성한다

### 테스트 Red 확인

- [ ] T006 `GIT_IT_SWIFT_FORMAT_RUNNER` 공개 진입점으로 `sources/Projects/Data/Tests/LearningProject/DTOs/GitHubRepositoryResponseDTOTests.swift`, `sources/Projects/Data/Tests/LearningProject/Requests/GitHubRepositoryRequestTests.swift`, `sources/Projects/Data/Tests/LearningProject/Errors/DataExternalRepositoryErrorTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/ExternalRepositoryRemoteContractTests.swift`만 포맷하고 Git index와 대상 밖 파일이 변경되지 않았음을 확인한다
- [ ] T007 [no-write] `GIT_IT_TEST_DESTINATION` 또는 기본 `platform=iOS Simulator,name=iPhone 17 Pro`와 `sources/DerivedData/Feature012Red`를 사용해 `GitIt.xcworkspace` Data scheme의 build-for-testing이 실행 환경·구성 문제가 아니라 T002~T005가 참조하는 production 선언 부재로 실패함을 확인한다

### 구현: S1 Public Repository 최소 데이터

- [ ] T008 [P] [S1] `sources/Projects/Data/LearningProject/DTOs/GitHubRepositoryResponseDTO.swift`에 네 공개 필드와 public initializer를 가진 `Decodable`·`Equatable`·`Sendable` DTO를 구현하고, 필수 owner nested container, optional `avatar_url`, 기본 빈 배열 `topics`, 필수 `html_url`·`stargazers_count` 규칙을 custom decoding으로 적용한다

### 구현: S2 요청과 인증 경계

- [ ] T009 [P] [S2] `sources/Projects/Data/LearningProject/Requests/GitHubRepositoryRequest.swift`에 `owner`·`repository`만 받는 public initializer와 고정 scheme·host·method·path·두 header를 가진 불변 `Equatable`·`Sendable` 요청 값을 구현하고 arbitrary header·credential 주입 경로를 두지 않는다

### 구현: S3 오류와 Remote 계약

- [ ] T010 [P] [S3] `sources/Projects/Data/LearningProject/Errors/DataExternalRepositoryError.swift`에 연관값 없는 `offline`, `other`와 `CaseIterable`·`Equatable`·`Error`·`Sendable` 채택을 구현하고 두 case의 의미와 실제 기술 오류 매핑이 Composition 책임임을 공개 문서 주석으로 명시한다
- [ ] T011 [S3] `sources/Projects/Data/LearningProject/Contracts/ExternalRepositoryRemote.swift`에 `Sendable` 프로토콜과 `repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO` 단일 연산을 구현하고 실제 HTTP 변환·전송·오류 매핑은 포함하지 않는다

### 정리와 포맷

- [ ] T012 [P] `sources/Projects/Data/LearningProject/DataLearningProjectPlaceholder.swift`를 실제 production 계약으로 대체했으므로 삭제한다
- [ ] T013 [P] `sources/Projects/Data/Tests/LearningProject/DataLearningProjectCompilationTests.swift`를 실제 계약 테스트로 대체했으므로 삭제한다
- [ ] T014 `GIT_IT_SWIFT_FORMAT_RUNNER` 공개 진입점으로 `sources/Projects/Data/LearningProject/DTOs/GitHubRepositoryResponseDTO.swift`, `sources/Projects/Data/LearningProject/Requests/GitHubRepositoryRequest.swift`, `sources/Projects/Data/LearningProject/Errors/DataExternalRepositoryError.swift`, `sources/Projects/Data/LearningProject/Contracts/ExternalRepositoryRemote.swift`, `sources/Projects/Data/Tests/LearningProject/DTOs/GitHubRepositoryResponseDTOTests.swift`, `sources/Projects/Data/Tests/LearningProject/Requests/GitHubRepositoryRequestTests.swift`, `sources/Projects/Data/Tests/LearningProject/Errors/DataExternalRepositoryErrorTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/ExternalRepositoryRemoteContractTests.swift`만 포맷하고 Git index와 대상 밖 파일이 변경되지 않았음을 확인한다

### Data 패키지 검증과 결과 보고

- [ ] T015 [no-write] T001의 구현 전 baseline과 현재 상태를 비교해 기존 사용자 변경을 보존하고 이 기능이 새로 만든 변경만 T002~T014에 명시된 정확한 파일 allowlist와 일치하는지 확인하며, `sources/Projects/Data/LearningProject/`에서 Domain·Infrastructure·Composition·Feature·UI import, `fullName`·`language` 공개 저장 필드, `Authorization`과 credential 저장값이 없음을 `rg`로 확인한다
- [ ] T016 [no-write] `test_destination=${GIT_IT_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}`를 사용해 `xcodebuild build-for-testing -workspace GitIt.xcworkspace -scheme Data -destination "$test_destination" -derivedDataPath sources/DerivedData/Feature012`를 실행하고 `DataLearningProject`·`DataLearningProjectTests` target 성공과 Git 추적 파일 무변경을 확인한다
- [ ] T017 [no-write] T016의 destination과 `sources/DerivedData/Feature012`를 사용해 `xcodebuild test-without-building -workspace GitIt.xcworkspace -scheme Data -destination "$test_destination" -derivedDataPath sources/DerivedData/Feature012`를 실행하고 S1~S3 계약 테스트 통과와 Git 추적 파일 무변경을 확인한다
- [ ] T018 [no-write] `sources/Projects/Data/LearningProject/`와 `sources/Projects/Data/Tests/LearningProject/`의 변경 파일, T015~T017의 실제 명령·성공·실패 결과와 미검증 범위를 사용자에게 보고하고 Data 패키지 변경을 종료한다

**승인 게이트**: T001~T018의 변경 파일과 검증 결과를 보고한 뒤 production/test 파일 변경을
중단한다. 이 명세에는 다음 적용 대상 패키지가 없으므로 패키지 간 진행 승인은 발생하지 않는다.
Domain·Infrastructure·Composition·UI·Feature·App 작업이 필요하면 tasks.md를 먼저 갱신하고
사용자의 명시적 승인을 받아야 한다. 아래 전체 완료 검증은 읽기 전용이므로 Data 보고 후 진행할
수 있다.

---

## 전체 완료 검증

**선행 조건**: Data 패키지 구현·포맷·집중 검증·결과 보고가 완료되어야 한다. 아래 작업은 Git
추적 파일을 변경하지 않으며 같은 checkout의 공개 build chain을 순차 실행한다.

- [ ] T019 [no-write] 전체 검증 직전 `git status --porcelain=v1 --untracked-files=all` 결과를 임시 파일에 저장하고 `./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_PROJECT_BUILD_RUNNER`로 판독한 공개 runner의 `build`를 실행해 모든 공유 production scheme의 Debug build가 성공함을 확인한다
- [ ] T020 [no-write] T019와 같은 공개 runner의 `compile`을 실행해 `sources/DerivedData/PreCommit`에 모든 test scheme의 build-for-testing 결과를 생성하고 성공을 확인한다
- [ ] T021 [no-write] T020 직후 같은 공개 runner의 `test`를 실행해 동일 DerivedData의 test-without-building 전체 테스트가 성공함을 확인한다
- [ ] T022 [no-write] 전체 검증 후 `git status --porcelain=v1 --untracked-files=all`을 T019의 임시 기준과 비교해 Git 추적·미추적 상태가 정확히 같음을 확인하고, `specs/012-github-public-repository-data/spec.md`의 S1 fixture·필수 필드 실패, S2 endpoint·header·credential 부재, S3 `offline`·`other`의 구분·전달과 성공 DTO 미반환 수용 기준을 T017·T021 테스트 결과와 대조해 누락 0건을 최종 보고한다

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 적용 패키지는 Data 하나이며 Constitution 순서에서 제외된 Domain·Infrastructure·Composition·
  UI·Feature·App은 작업하지 않는다.
- T001~T018을 완료하고 Data 변경 파일과 검증 결과를 보고한 뒤 production/test 파일 변경을
  종료한다.
- 다른 패키지가 필요해지면 기존 Data 결과를 보존하고 `/speckit-tasks`로 소유권과 순서를 먼저
  갱신한다.
- 전체 검증 T019~T022는 Data 완료 보고 뒤에만 순차 실행하며 상태 비교가 실패하면 완료로
  판정하지 않는다.

### 변경 시나리오 완료 순서

```text
S1(P1) ─┐
        ├─▶ 테스트 Red 확인 ─▶ Data 구현·포맷·집중 검증 ─▶ 전체 읽기 전용 검증
S2(P1) ─┤
        │
S3(P2) ─┘
```

- S1, S2, S3의 테스트 작성은 서로 다른 파일이므로 병렬 가능하다.
- Red 상태는 테스트 파일을 먼저 포맷한 뒤 production 선언 부재만을 원인으로 확인한다.
- S1 DTO, S2 Request, S3 Error production 구현은 각 대응 테스트와 Red 확인 뒤 병렬 가능하다.
- S3 Remote 구현은 Request·DTO·Error 선언과 Remote 계약 테스트가 준비된 뒤 수행한다.
- 세 시나리오는 우선순위가 다르지만 Data target 컴파일 시 함께 필요하므로 T015 이전에 모두
  구현한다.

### 시나리오별 독립 검증 기준

- **S1**: fixture를 DTO로 디코딩했을 때 네 필드만 보존되고 optional·추가 필드는 성공하며
  owner·필수 필드 오류는 실패한다.
- **S2**: 대표 입력의 요청 값이 scheme·host·method·path·두 header와 정확히 일치하고
  `Authorization` 및 금지 credential이 없다.
- **S3**: 오류 계약이 `offline`, `other` 두 케이스를 제공하고 Remote Probe의 지정된 실패가
  손실 없이 관찰되며 성공 DTO가 반환되지 않는다. 기술 오류의 실제 매핑은 검증하지 않는다.

### Data 패키지 내부 병렬 실행 예시

```text
# T001 완료 뒤 테스트 파일 병렬 작성
T002 [S1] DTO 테스트
T003 [S2] Request 테스트
T004 [S3] Error 테스트
T005 [S3] Remote 테스트

# T006~T007 포맷·Red 확인 뒤 독립 production 타입 병렬 구현
T008 [S1] DTO
T009 [S2] Request
T010 [S3] Error

# 위 선언 완료 뒤
T011 [S3] Remote → T012/T013 정리 → T014 포맷 → T015~T018 순차 검증·보고
```

같은 파일을 수정하는 작업과 build/test는 병렬 실행하지 않는다. T016과 T017은 같은
`sources/DerivedData/Feature012`를 공유하고 T019~T021은 저장소 공개 runner의 build chain을
공유하므로 반드시 순차 실행한다.

## 구현 전략

1. T001로 기존 target·scheme 구성과 구현 전 작업 트리 baseline을 확인한다.
2. T002~T005의 테스트를 먼저 작성하고 T006으로 포맷한 뒤 T007에서 대상 선언 부재에 따른
   예상된 Red 상태를 확인한다.
3. T008~T011을 구현하고 T012~T013으로 placeholder를 제거한 뒤 T014로 정확한 allowlist만
   포맷한다.
4. T015~T017로 기존 사용자 변경 보존, Data 경계·컴파일·테스트와 추적 파일 무변경을 검증하고
   T018에서 변경과 결과를 보고한다.
5. 파일 변경을 중단한 상태로 T019~T022의 전체 읽기 전용 검증과 전후 상태 비교를 순차 수행한다.

## 최소 가치 범위

S1은 최소 응답 데이터 소비 가치를 독립적으로 설명하지만 Data target의 공개 계약 완결성과
FR-016 검증을 위해 실제 구현 최소 범위는 S1+S2+S3 전체다. 적용 패키지는 하나이므로 별도
패키지 승인 게이트를 생략하지 않으며 T018의 결과 보고를 반드시 수행한다.

## 참고

- 모든 파일 변경 작업은 정확한 repository-relative 파일 경로와 Data 단일 패키지 소유권을
  가진다. 기존 작업 트리 변경은 T001 baseline으로 보존하며 이 기능 범위 위반으로 세지 않는다.
- `docs/spec-kit/012-github-public-repository-data/trouble-shooting.md`와
  `tacit-knowledge.md`는 구현 작업이 아니다. 실제 기록 조건이 발생한 세션에서 전용 스킬이
  별도로 append-only 기록한다.
- 자동 `after_implement` 포맷 훅은 T014와 같은 allowlist를 다시 확인하며 변경이 없는 멱등
  검증으로 끝나야 한다.
