# 작업 목록: GitHub Public Repository Data 계약

**입력**: `/specs/012-github-public-repository-data/`의 `spec.md`, `plan.md`, `research.md`,
`data-model.md`, `contracts/`, `quickstart.md`

**테스트**: spec.md FR-016이 계약 테스트를 요구하므로 production 구현 전 테스트를 작성하고,
`DataExternalRepository` 선언 부재가 유일한 Red 원인인지 확인한다.

**구성**: 적용 대상은 `Data(DataExternalRepository)` 단일 패키지다. GitHub Public Repository
계약은 `DataLearningProject` target에 두지 않고, 전용 production/test target과 source root로
분리한다. 전체 검증은 Git 추적 파일을 변경하지 않는 마지막 단계에서만 실행한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 승인된 Data 패키지 안에서 서로 다른 파일을 수정하고 미완료 구현에 의존하지 않아
  병렬 실행할 수 있다.
- **[S1]**: Public Repository 최소 응답 데이터 디코딩
- **[S2]**: GitHub 요청 대상과 인증 경계
- **[S3]**: `offline`·`other` 실패 계약
- **[no-write]**: Git 추적 파일을 변경하지 않는 확인·build·test·결과 보고 작업

## 작업 패키지 1: Data(DataExternalRepository)

**목표**: 전용 `DataExternalRepository` target에서 GitHub Public Repository 조회의 기술 중립
요청 값, 최소 응답 DTO, Remote와 오류 계약을 제공한다. `DataLearningProject` target은 이 계약을
소유하지 않는다.

**소유 경로**: `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`,
`sources/Projects/Data/ExternalRepository/`,
`sources/Projects/Data/Tests/ExternalRepository/`,
`sources/Projects/Data/LearningProject/DataLearningProjectPlaceholder.swift`,
`sources/Projects/Data/Tests/LearningProject/DataLearningProjectCompilationTests.swift`

**관련 변경 시나리오**: S1(P1), S2(P1), S3(P2)

**독립 검증**: Data 공유 scheme이 `DataExternalRepository`와
`DataExternalRepositoryTests`를 build-for-testing하고 test-without-building에서 S1~S3 계약
테스트를 실행한다.

### 준비와 target 분리

- [ ] T001 [no-write] `git status --porcelain=v1 --untracked-files=all`의 기준 상태를 보존하고 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`와 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`에서 기존 `DataLearningProject`/`DataLearningProjectTests` 선언과 Data 공유 scheme 연결을 확인한다
- [ ] T002 `sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift`에서 `DataLearningProject`와 `DataLearningProjectTests`를 `DataExternalRepository`와 `DataExternalRepositoryTests`로 교체하고 sourceDirectory가 `ExternalRepository` root를 가리키도록 구현한다
- [ ] T003 `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`에서 Data 공유 scheme의 buildTargets와 testTargets를 `DataExternalRepository`와 `DataExternalRepositoryTests`로 교체한다

### 테스트: S1 Public Repository 최소 데이터

- [ ] T004 [P] [S1] `sources/Projects/Data/Tests/ExternalRepository/DTOs/GitHubRepositoryResponseDTOTests.swift`에 정상 최소 JSON, 추가 필드, avatar key 누락·`null`, topics 누락·`null`·빈 배열, star 0, 필수 owner 누락·`null`, 필수 필드 누락·잘못된 타입과 공개 저장 필드 네 개를 검증하는 Swift Testing 테스트를 작성한다

### 테스트: S2 요청과 인증 경계

- [ ] T005 [P] [S2] `sources/Projects/Data/Tests/ExternalRepository/Requests/GitHubRepositoryRequestTests.swift`에 대표 owner/repository의 `https`, `api.github.com`, `GET`, `/repos/{owner}/{repo}`, 두 필수 header와 `Authorization`·Git-It access/refresh token·Apple identity token 부재를 검증하는 Swift Testing 테스트를 작성한다

### 테스트: S3 오류와 Remote 계약

- [ ] T006 [P] [S3] `sources/Projects/Data/Tests/ExternalRepository/Errors/DataExternalRepositoryErrorTests.swift`에 `allCases == [.offline, .other]`, 두 케이스의 구분과 `Equatable`·`Error` 계약을 검증하는 Swift Testing 테스트를 작성한다
- [ ] T007 [P] [S3] `sources/Projects/Data/Tests/ExternalRepository/Contracts/ExternalRepositoryRemoteContractTests.swift`에 actor Probe가 `GitHubRepositoryRequest`를 한 번 기록해 DTO를 그대로 반환하고 지정된 `.offline`·`.other` 실패를 손실 없이 전달하며 성공 DTO를 반환하지 않는 계약 테스트를 작성한다

### 테스트 Red 확인

- [ ] T008 `sources/Projects/Data/Tests/ExternalRepository/DTOs/GitHubRepositoryResponseDTOTests.swift`, `sources/Projects/Data/Tests/ExternalRepository/Requests/GitHubRepositoryRequestTests.swift`, `sources/Projects/Data/Tests/ExternalRepository/Errors/DataExternalRepositoryErrorTests.swift`, `sources/Projects/Data/Tests/ExternalRepository/Contracts/ExternalRepositoryRemoteContractTests.swift`만 `GIT_IT_SWIFT_FORMAT_RUNNER` 공개 진입점으로 포맷한다
- [ ] T009 [no-write] `sources`에서 `tuist generate`를 실행한 뒤 `GIT_IT_TEST_DESTINATION` 또는 기본 `platform=iOS Simulator,name=iPhone 17 Pro`와 `sources/DerivedData/Feature012Red`를 사용해 `GitIt.xcworkspace` Data scheme의 build-for-testing이 실행 환경·target 구성 문제가 아니라 T004~T007이 참조하는 production 선언 부재로 실패함을 확인한다

### 구현: S1 Public Repository 최소 데이터

- [ ] T010 [P] [S1] `sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift`에 네 공개 필드와 public initializer를 가진 `Decodable`·`Equatable`·`Sendable` DTO를 구현하고, 필수 owner nested container, optional `avatar_url`, 기본 빈 배열 `topics`, 필수 `html_url`·`stargazers_count` 규칙을 custom decoding으로 적용한다

### 구현: S2 요청과 인증 경계

- [ ] T011 [P] [S2] `sources/Projects/Data/ExternalRepository/Requests/GitHubRepositoryRequest.swift`에 `owner`·`repository`만 받는 public initializer와 고정 scheme·host·method·path·두 header를 가진 불변 `Equatable`·`Sendable` 요청 값을 구현하고 arbitrary header·credential 주입 경로를 두지 않는다

### 구현: S3 오류와 Remote 계약

- [ ] T012 [P] [S3] `sources/Projects/Data/ExternalRepository/Errors/DataExternalRepositoryError.swift`에 연관값 없는 `offline`, `other`와 `CaseIterable`·`Equatable`·`Error`·`Sendable` 채택을 구현하고 두 case의 의미와 실제 기술 오류 매핑이 Composition 책임임을 공개 문서 주석으로 명시한다
- [ ] T013 [S3] `sources/Projects/Data/ExternalRepository/Contracts/ExternalRepositoryRemote.swift`에 `Sendable` 프로토콜과 `repository(_ request: GitHubRepositoryRequest) async throws -> GitHubRepositoryResponseDTO` 단일 연산을 구현하고 실제 HTTP 변환·전송·오류 매핑은 포함하지 않는다

### 정리와 포맷

- [ ] T014 [P] `sources/Projects/Data/LearningProject/DataLearningProjectPlaceholder.swift`를 전용 ExternalRepository 계약으로 대체했으므로 삭제한다
- [ ] T015 [P] `sources/Projects/Data/Tests/LearningProject/DataLearningProjectCompilationTests.swift`를 전용 ExternalRepository 계약 테스트로 대체했으므로 삭제한다
- [ ] T016 [P] `sources/Projects/Data/LearningProject/DTOs/GitHubRepositoryResponseDTO.swift`, `sources/Projects/Data/LearningProject/Requests/GitHubRepositoryRequest.swift`, `sources/Projects/Data/LearningProject/Errors/DataExternalRepositoryError.swift`, `sources/Projects/Data/LearningProject/Contracts/ExternalRepositoryRemote.swift`의 전용 target 분리 전 미추적 계약 파일을 삭제한다
- [ ] T017 [P] `sources/Projects/Data/Tests/LearningProject/DTOs/GitHubRepositoryResponseDTOTests.swift`, `sources/Projects/Data/Tests/LearningProject/Requests/GitHubRepositoryRequestTests.swift`, `sources/Projects/Data/Tests/LearningProject/Errors/DataExternalRepositoryErrorTests.swift`, `sources/Projects/Data/Tests/LearningProject/Contracts/ExternalRepositoryRemoteContractTests.swift`의 전용 target 분리 전 미추적 테스트 파일을 삭제한다
- [ ] T018 `sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift`, `sources/Projects/Data/ExternalRepository/Requests/GitHubRepositoryRequest.swift`, `sources/Projects/Data/ExternalRepository/Errors/DataExternalRepositoryError.swift`, `sources/Projects/Data/ExternalRepository/Contracts/ExternalRepositoryRemote.swift`, `sources/Projects/Data/Tests/ExternalRepository/DTOs/GitHubRepositoryResponseDTOTests.swift`, `sources/Projects/Data/Tests/ExternalRepository/Requests/GitHubRepositoryRequestTests.swift`, `sources/Projects/Data/Tests/ExternalRepository/Errors/DataExternalRepositoryErrorTests.swift`, `sources/Projects/Data/Tests/ExternalRepository/Contracts/ExternalRepositoryRemoteContractTests.swift`만 `GIT_IT_SWIFT_FORMAT_RUNNER` 공개 진입점으로 포맷한다

### Data 패키지 검증과 결과 보고

- [ ] T019 [no-write] 변경 파일이 T002~T018에 명시된 경로뿐이고 기존 사용자 변경을 보존했는지 확인하며, `sources/Projects/Data/ExternalRepository/`에서 Domain·Infrastructure·Composition·Feature·UI import, `fullName`·`language` 공개 저장 필드, `Authorization`과 credential 저장값이 없음을 `rg`로 확인한다
- [ ] T020 [no-write] `sources`에서 `tuist generate`를 실행한 뒤 `test_destination=${GIT_IT_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}`를 사용해 `xcodebuild build-for-testing -workspace GitIt.xcworkspace -scheme Data -destination "$test_destination" -derivedDataPath sources/DerivedData/Feature012`를 실행하고 전용 production/test target 성공과 Git 추적 파일 무변경을 확인한다
- [ ] T021 [no-write] T020의 destination과 `sources/DerivedData/Feature012`를 사용해 `xcodebuild test-without-building -workspace GitIt.xcworkspace -scheme Data -destination "$test_destination" -derivedDataPath sources/DerivedData/Feature012`를 실행하고 S1~S3 계약 테스트 통과와 Git 추적 파일 무변경을 확인한다
- [ ] T022 [no-write] Data target 분리, 변경 파일, T019~T021의 실제 결과와 미검증 범위를 사용자에게 보고하고 Data 패키지 변경을 종료한다

**승인 게이트**: T001~T022의 변경 파일과 검증 결과를 보고한 뒤 production/test 파일 변경을
중단한다. 이 명세에는 다음 적용 대상 패키지가 없으며, 아래 전체 검증은 읽기 전용이다.

---

## 전체 완료 검증

**선행 조건**: Data 패키지 구현·포맷·집중 검증·결과 보고가 완료되어야 한다.

- [ ] T023 [no-write] 전체 검증 직전 상태와 이후 상태를 비교하고 `./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_PROJECT_BUILD_RUNNER`로 판독한 공개 runner의 `build`를 실행해 모든 공유 production scheme Debug build가 성공함을 확인한다
- [ ] T024 [no-write] T023과 같은 공개 runner의 `compile`을 실행해 `sources/DerivedData/PreCommit`에 모든 test scheme의 build-for-testing 결과를 생성하고 성공을 확인한다
- [ ] T025 [no-write] T024 직후 같은 공개 runner의 `test`를 실행해 동일 DerivedData의 test-without-building 전체 테스트가 성공함을 확인한다
- [ ] T026 [no-write] 전체 검증 후 Git 상태가 T023 직전과 같음을 확인하고 S1 fixture·필수 필드 실패, S2 endpoint·header·credential 부재, S3 `offline`·`other` 구분·전달과 성공 DTO 미반환 수용 기준을 T021·T025 결과와 대조해 누락 0건을 최종 보고한다

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 적용 패키지는 Data 하나이며 Domain·Infrastructure·Composition·UI·Feature·App은 작업하지 않는다.
- T001~T022를 완료한 뒤 production/test 파일 변경을 종료한다.
- 전체 검증 T023~T026은 Data 완료 뒤에만 순차 실행한다.

### 변경 시나리오 완료 순서

```text
S1(P1) ─┐
        ├─▶ target 분리·테스트 Red 확인 ─▶ Data 구현·포맷·집중 검증 ─▶ 전체 읽기 전용 검증
S2(P1) ─┤
        │
S3(P2) ─┘
```

- T004~T007과 T010~T012는 각각 다른 파일에서 병렬 실행할 수 있다.
- T013은 Request·DTO·Error 선언 완료 뒤 실행한다.
- T018과 T019, T021~T023은 각자 같은 DerivedData를 공유하므로 순차 실행한다.

## 구현 전략

1. 기존 LearningProject target을 `DataExternalRepository` target으로 교체하고 Data 공유 scheme을 갱신한다.
2. ExternalRepository 전용 test root에서 계약 테스트를 작성해 Red 상태를 확인한다.
3. production 계약을 같은 전용 source root에 구현하고 LearningProject placeholder를 제거한다.
4. Tuist를 재생성해 source 목록을 갱신한 뒤 Data 집중 검증과 전체 공개 build chain을 실행한다.

## 최소 가치 범위

S1은 최소 응답 데이터 소비 가치를 독립적으로 설명하지만, 전용 target의 공개 계약 완결성과
FR-016 검증을 위해 구현 최소 범위는 S1+S2+S3 전체다.
