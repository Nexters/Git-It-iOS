# 빠른 시작: GitHub Public Repository Data 계약 검증

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **계약**:
[contracts/github-public-repository-data.md](./contracts/github-public-repository-data.md)

이 문서는 구현 완료 후 실행할 검증 절차다. 실제 GitHub 네트워크 호출은 Composition 범위이므로
Data 검증에서는 수행하지 않는다.

## 1. 사전 조건

- 저장소 루트에서 실행한다.
- `make init` 또는 `make tuist`로 workspace를 생성했다.
- 기본 destination인 `iPhone 17 Pro` Simulator를 사용할 수 있거나
  `GIT_IT_TEST_DESTINATION`을 유효한 destination으로 설정했다.
- 구현 파일이 [data-model.md](./data-model.md)와
  [contracts/github-public-repository-data.md](./contracts/github-public-repository-data.md)의
  공개 계약을 따른다.

## 2. 변경 범위 확인

production과 테스트 변경은 다음 두 root 안에 있어야 한다.

```text
sources/Projects/Data/ExternalRepository/
sources/Projects/Data/Tests/ExternalRepository/
```

`DataLearningProjectPlaceholder.swift`와 `DataLearningProjectCompilationTests.swift`는 제거되어야
한다. `DataModuleName.swift`와 `ProjectName.swift`는 `DataExternalRepository`와
`DataExternalRepositoryTests` target을 Data 공유 scheme에 연결해야 한다.

## 3. 금지 의존성 확인

```sh
if rg -n '^import (Domain|Infrastructure|Composition|Feature|UI)' \
  sources/Projects/Data/ExternalRepository; then
  echo 'Data 금지 의존성이 발견되었습니다' >&2
  exit 1
fi
```

예상 결과: 일치 항목 없이 종료 코드 0.

## 4. 허용된 Swift 파일 포맷

```sh
swift_format_runner=$(
  ./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_SWIFT_FORMAT_RUNNER
)
"$swift_format_runner" format \
  sources/Projects/Data/ExternalRepository/Contracts/ExternalRepositoryRemote.swift \
  sources/Projects/Data/ExternalRepository/DTOs/GitHubRepositoryResponseDTO.swift \
  sources/Projects/Data/ExternalRepository/Errors/DataExternalRepositoryError.swift \
  sources/Projects/Data/ExternalRepository/Requests/GitHubRepositoryRequest.swift \
  sources/Projects/Data/Tests/ExternalRepository/Contracts/ExternalRepositoryRemoteContractTests.swift \
  sources/Projects/Data/Tests/ExternalRepository/DTOs/GitHubRepositoryResponseDTOTests.swift \
  sources/Projects/Data/Tests/ExternalRepository/Errors/DataExternalRepositoryErrorTests.swift \
  sources/Projects/Data/Tests/ExternalRepository/Requests/GitHubRepositoryRequestTests.swift
```

예상 결과: 위 allowlist의 현재 변경 Swift 파일만 포맷되고 Git index와 대상 밖 파일은 변경되지
않는다.

## 5. Data 집중 테스트 컴파일

```sh
test_destination=${GIT_IT_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}
xcodebuild build-for-testing \
  -workspace GitIt.xcworkspace \
  -scheme Data \
  -destination "$test_destination" \
  -derivedDataPath sources/DerivedData/Feature012
```

예상 결과: Data 공유 scheme의 `DataExternalRepository`와 `DataExternalRepositoryTests` target이
build-for-testing에 성공한다.

## 6. Data 집중 테스트 실행

```sh
test_destination=${GIT_IT_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}
xcodebuild test-without-building \
  -workspace GitIt.xcworkspace \
  -scheme Data \
  -destination "$test_destination" \
  -derivedDataPath sources/DerivedData/Feature012
```

예상 결과:

- Request 테스트에서 `https://api.github.com/repos/{owner}/{repo}`, `GET`, 두 필수 header와
  credential 부재가 확인된다.
- DTO 테스트에서 정상·optional·추가 필드 fixture는 성공하고 필수 `owner`·필드 오류 fixture는
  실패한다.
- 오류 테스트에서 `offline`, `other` 두 케이스만 확인된다.
- Remote Probe 테스트에서 성공 DTO 또는 지정 오류가 손실 없이 전달된다.

두 명령은 같은 `sources/DerivedData/Feature012` 결과를 공유하므로 순서대로 실행한다. 변경 파일과
실제 결과를 사용자에게 보고한 뒤 Data 패키지 변경을 종료한다.

## 7. 전체 읽기 전용 검증

Data 패키지 결과 보고가 끝난 뒤 전체 build chain을 실행한다. 검증 전후 상태 비교에는 기존
사용자 변경도 포함되며, 같은 상태가 유지되어야 한다.

```sh
validation_status=$(mktemp "${TMPDIR:-/tmp}/git-it-feature012-status.XXXXXX")
trap 'rm -f "$validation_status" "$validation_status.after"' EXIT
git status --porcelain=v1 --untracked-files=all >"$validation_status"

project_build_runner=$(
  ./tools/repository-paths/bin/repository-paths.sh --absolute GIT_IT_PROJECT_BUILD_RUNNER
)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test

git status --porcelain=v1 --untracked-files=all >"$validation_status.after"
cmp "$validation_status" "$validation_status.after"
```

예상 결과: 모든 공유 production/test scheme 검증이 성공하고 `cmp`가 종료 코드 0을 반환한다.
`compile`과 `test`는 같은 `sources/DerivedData/PreCommit` 결과를 공유한다.

## 8. 완료 판정

다음을 모두 충족하면 이 기능의 전체 검증을 완료로 보고할 수 있다.

- Data 집중 build-for-testing·test-without-building과 전체 production build·test chain이 모두
  성공했다.
- 네 공개 계약 이외에 Domain 변환·HTTP Adapter·DI 구현이 추가되지 않았다.
- `full_name`, `language`, `Authorization`과 credential 저장 필드가 production 공개 모델에 없다.
- 포맷 대상 밖 파일과 Git index가 변경되지 않았고 전체 검증 전후 작업 트리 상태가 같다.
- 변경 파일과 Data 집중·전체 검증의 실제 결과를 사용자에게 보고했다.
