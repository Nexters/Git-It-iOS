# 014-ui-convention-refactor 문제 해결 기록

**대상 기능**: `014-ui-convention-refactor`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260822-001: feature.json 부재로 초기 명세 패치 중단

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-specify` 기능 디렉터리 생성
**관련 항목**: `.specify/feature.json`, `specs/014-ui-convention-refactor/spec.md`

### 증상

초기 패치가 `.specify/feature.json`을 기존 파일로 갱신하려 했으나 파일이 없어 검증 단계에서 중단됐다. 패치는 원자적으로 실패해 명세와 체크리스트도 부분 생성되지 않았다.

### 영향

활성 기능 경로를 저장하지 못해 명세 생성 절차가 일시 중단됐다. application source와 기존 기능 디렉터리에는 변경이 발생하지 않았다.

### 근거

- `apply_patch`: `Failed to read file to update .../.specify/feature.json: No such file or directory (os error 2)`를 반환했다.
- `.specify/feature.json` 존재 확인: 초기 패치 시점에 파일이 없었다.

### 원인

새 저장소 상태에서는 `.specify/feature.json`이 아직 생성되지 않았는데 기존 파일이라고 가정하고 `Update File` 연산을 사용했다.

### 조치

부분 적용이 없음을 확인한 뒤 동일 내용을 다시 적용하면서 `.specify/feature.json`을 `Add File` 연산으로 생성했다.

### 검증

- `.specify/scripts/bash/check-prerequisites.sh --json --paths-only`: 성공, `FEATURE_DIR`을 `specs/014-ui-convention-refactor`로 판독했다.
- `git diff --check -- specs/014-ui-convention-refactor .specify/feature.json`: 성공, whitespace 오류가 없었다.

### 재발 방지

활성 기능 경로를 저장하기 전에 `.specify/feature.json`의 존재 여부를 확인하고, 존재 여부에 맞춰 생성 또는 갱신 연산을 선택한다.

### 연결

없음

## TS-20260822-002: 지원되지 않는 project-build help action 실행

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` 검증 진입점 조사
**관련 항목**: `tools/githooks/project-build/bin/run.sh`, `specs/014-ui-convention-refactor/quickstart.md`

### 증상

검증 runner의 지원 action을 조사하는 과정에서 `./tools/githooks/project-build/bin/run.sh help`를 실행했고, runner가 unsupported ACTION 오류와 exit 2를 반환했다.

### 영향

읽기 전용 조사 명령 하나가 실패했으나 파일 변경이나 build/test 실행은 발생하지 않았다. 지원 action을 별도 근거로 다시 확인해야 했다.

### 근거

- `./tools/githooks/project-build/bin/run.sh help`: unsupported ACTION, exit 2.
- `tools/githooks/project-build/bin/run.sh:8`: 지원 공개 action을 오류 메시지로 열거한다.

### 원인

runner가 help subcommand를 제공하는지 먼저 source에서 확인하지 않고 일반적인 CLI 관례를 적용했다.

### 조치

runner source와 관련 script tests를 읽어 `build`, `build-app`, `compile`, `test`, `compile-unit`, `test-unit`, `compile-ui`, `test-ui`를 지원 action으로 확인하고 quickstart에는 실제 공개 action만 기록했다.

### 검증

- `rg -n 'compile-ui|test-ui|project-build' tools/githooks/project-build tools/script-tests README.md`: 성공, UI 검증 action과 scheme policy 근거를 확인했다.
- `git status --short`: 실행으로 인한 추가 파일 변경이 없음을 확인했다.

### 재발 방지

프로젝트 소유 CLI의 도움말 지원 여부와 공개 action은 실행 전에 source 또는 README에서 확인한다.

### 연결

없음

## TS-20260822-003: 동일 plan 파일의 Delete와 Add를 한 패치에 지정

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-plan` 산출물 작성
**관련 항목**: `specs/014-ui-convention-refactor/plan.md`

### 증상

계획 템플릿을 완성본으로 교체하는 패치에서 같은 `plan.md`를 `Delete File`과 `Add File` 대상으로 동시에 지정해 patch validation이 실패했다. 부분 적용은 발생하지 않았다.

### 영향

계획 산출물 작성이 한 차례 중단됐으나 기존 template과 다른 파일은 해당 실패로 변경되지 않았다.

### 근거

- `apply_patch`: `invalid patch: multiple operations target .../specs/014-ui-convention-refactor/plan.md`를 반환했다.
- 후속 `find specs/014-ui-convention-refactor -maxdepth 2 -type f`: 복구 뒤 계획 산출물 전체가 존재했다.

### 원인

한 `apply_patch` 호출에서 같은 경로에 복수 연산을 적용할 수 없다는 도구 제약을 위반했다.

### 조치

`plan.md` 삭제와 완성본 추가를 별도 patch 호출로 분리하고, 나머지 설계 산출물을 허용 경로에 생성했다.

### 검증

- `git diff --check -- specs/014-ui-convention-refactor`: 성공, whitespace 오류가 없었다.
- unresolved placeholder 검색: template placeholder는 0건이며 `NEEDS CLARIFICATION`은 해결 완료를 설명하는 문장에만 존재했다.

### 재발 방지

파일 전체 교체가 필요하면 단일 `Update File` 연산을 사용하거나 삭제와 추가를 별도 호출로 분리한다.

### 연결

없음

## TS-20260822-004: 생성 직후 workspace를 project-build runner가 인식하지 못함

**기록일**: 2026-08-22
**상태**: 환경 제약
**발생 단계**: `speckit-implement` T008 Red 검증
**관련 항목**: T008, `sources/GitIt.xcworkspace`, `tools/githooks/project-build/bin/run.sh`

### 증상

`make tuist`가 `Project generated`와 `workspace-link` 성공을 반환한 직후 repository project-build runner의 `compile-unit`을 실행했으나, 모든 선택 scheme이 `xcodebuild: error: '.../sources/GitIt.xcworkspace' is not a workspace file.`로 실패했다. 따라서 새 직접 입력·Preview 계약의 미구현으로 인한 Swift 컴파일 오류까지 도달하지 못했다.

### 영향

T008이 요구하는 예상 Red 실패 원인을 판별할 수 없어 UI 패키지 구현을 시작할 수 없다. 이후 T009~T057은 T008 통과 또는 예상 실패 원인 확인이 선행되어야 하므로 실행하지 않았다.

### 근거

- `make tuist`: `Project generated` 및 `workspace-link` 성공을 반환했다.
- `file sources/GitIt.xcworkspace`: `directory`이며 `contents.xcworkspacedata`가 존재한다.
- `project_build_runner=...; "$project_build_runner" compile-unit`: UI를 포함한 6개 scheme 모두 workspace file 오류로 실패했다.
- 같은 실행 출력: `CoreSimulatorService connection became invalid` 및 `Operation not permitted` 로그가 함께 발생했다.

### 원인

확정 원인은 확인 중이다. 저장소 생성 절차는 성공했고 workspace 메타데이터 파일도 존재하지만, 현재 실행 환경의 Xcode/CoreSimulator 서비스 또는 권한 상태가 `xcodebuild`의 workspace 인식을 방해한 것으로 관찰된다. UI source와 Red 테스트의 Swift 오류 여부는 아직 확인하지 못했다.

### 조치

`make tuist`를 한 번 실행해 생성 workspace를 갱신했다. source 또는 Tuist 설정을 우회 수정하지 않았고, 이후 구현 작업은 중단했다.

### 검증

- `make tuist`: 성공.
- repository project-build runner `compile-unit`: 실패, 예상한 직접 입력 API 컴파일 오류가 아니라 workspace 인식 오류.
- `git diff --check`: 성공.

### 재발 방지

직접 입력 API 구현 전에 `xcodebuild`가 생성 workspace를 인식하는지 runner의 단일 compile action으로 확인한다. 동일 오류가 재발하면 CoreSimulator/Xcode 서비스 및 실행 권한을 복구한 뒤 T008부터 다시 실행하고, source 변경으로 원인을 추정하지 않는다.

### 연결

없음

## TS-20260822-005: 권한 확장 UI build도 Lottie code-sign 오류로 중단

**기록일**: 2026-08-22
**상태**: 환경 제약
**발생 단계**: `speckit-implement` T008 Red 검증 재시도
**관련 항목**: T008, `sources/DerivedData/PreCommit/TestSchemes/UI`, Lottie framework

### 증상

권한 확장 환경에서 `xcodebuild -workspace sources/GitIt.xcworkspace -list`는 `UI`와 `UIUITests`를 포함한 workspace scheme을 정상 표시했다. 이어서 UI scheme의 `build-for-testing`을 실행했으나 Swift 직접 입력 테스트를 컴파일하기 전에 Lottie framework code-sign이 `resource fork, Finder information, or similar detritus not allowed`로 실패했다.

### 영향

TS-20260822-004의 workspace 인식 실패는 샌드박스 환경 제약으로 분리됐지만, T008은 여전히 새 계약 테스트의 예상 Red 오류를 확인하지 못했다. UI source 구현과 T009 이후 작업은 계속 중단 상태다.

### 근거

- `xcodebuild -workspace sources/GitIt.xcworkspace -list`: `Information about workspace "GitIt"`와 `UI`, `UIUITests` scheme을 반환했다.
- `xcodebuild -workspace sources/GitIt.xcworkspace -scheme UI -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath sources/DerivedData/PreCommit/TestSchemes/UI build-for-testing`: `CodeSign .../Lottie.framework` 실패와 `resource fork, Finder information, or similar detritus not allowed`를 반환했다.
- 같은 build 출력: `** TEST BUILD FAILED **`; 새 test source의 Swift diagnostic은 출력되지 않았다.

### 원인

직접 입력 API 구현과 무관한 Lottie framework 산출물의 Finder/resource metadata가 code-sign을 차단한 것으로 관찰된다. 이 metadata의 생성 경로와 안전한 정리 절차는 확인하지 않았다.

### 조치

workspace 인식 여부를 read-only `xcodebuild -list`로 분리 확인했다. Lottie framework 또는 DerivedData의 metadata를 삭제·변경하지 않았고 UI source 변경을 진행하지 않았다.

### 검증

- `xcodebuild -workspace sources/GitIt.xcworkspace -list`: 성공.
- UI `build-for-testing`: 실패, Lottie code-sign 오류.
- `git diff --check`: 성공.

### 재발 방지

T008 재개 전 Lottie framework code-sign을 막는 Finder/resource metadata의 소유 경로와 프로젝트 승인 정리 절차를 확인한다. 정리 권한과 대상이 확정되기 전에는 framework나 DerivedData를 삭제하지 않는다.

### 연결

TS-20260822-004

## TS-20260822-006: UI test 중 지정 Simulator가 Invalid device state로 중단

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-implement` T055 UI test 검증
**관련 항목**: T055, Simulator `FF975095-E0FC-434D-89E9-E3EBA19EB913`

### 증상

`compile-ui` 성공 직후 같은 destination으로 `test-ui`를 실행했으나 앱 설치 단계에서 `com.apple.CoreSimulator.SimError` code 405, `Invalid device state`와 `NSMachErrorDomain` code -308 `server died`가 발생했다. 이후 `DebuggerLLDB.DebuggerVersionStore.StoreError` 경고가 반복되며 테스트가 완료되지 않았다.

### 영향

UI test body의 성공 여부를 판정할 수 없었으며, 환경 실패를 제품 코드 회귀로 오판할 수 있었다.

### 근거

- `GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913' ./tools/githooks/project-build/bin/run.sh compile-ui`: 성공 1/1.
- 같은 destination의 `test-ui`: `Invalid device state`, CoreSimulator server 종료 후 중단.
- `xcrun simctl list devices`: 지정 Simulator가 `Booted`로 표시됐지만 앱 설치가 불가능한 불일치 상태였다.

### 원인

지정 Simulator가 Booted로 표시되면서도 CoreSimulator 서비스가 앱 설치 요청을 처리하지 못하는 비정상 실행 상태였던 것으로 확인했다. 제품 코드나 UI test assertion 실패는 관찰되지 않았다.

### 조치

UUID를 변경하지 않고 `xcrun simctl shutdown`, `xcrun simctl boot`, `xcrun simctl bootstatus -b` 순서로 지정 Simulator를 재부팅했다.

### 검증

- `xcrun simctl bootstatus FF975095-E0FC-434D-89E9-E3EBA19EB913 -b`: `Finished`.
- 동일 destination의 `test-ui` 재실행: 성공 1/1.
- 동일 destination의 `compile-unit`: 성공 6/6.
- 동일 destination의 `test-unit`: 성공 6/6.

### 재발 방지

`Invalid device state` 또는 CoreSimulator server 종료가 나타나면 test assertion을 분석하기 전에 destination UUID의 상태를 확인하고, 동일 UUID를 재부팅한 뒤 같은 명령으로 재검증한다. `DebuggerVersionStore` 경고만으로 테스트 실패 원인을 판정하지 않는다.

### 연결

TS-20260822-004

## TS-20260822-007: 기본 Simulator 이름 불일치로 전체 compile이 중단

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-implement` T060 전체 test scheme build-for-testing
**관련 항목**: T060, T061, Simulator `FF975095-E0FC-434D-89E9-E3EBA19EB913`

### 증상

기본 destination인 `platform=iOS Simulator,name=iPhone 17 Pro`로 전체 `compile`을 실행했을 때 모든 test scheme이 시작 전에 실패했다. Xcode가 사용 가능한 simulator로 `default-1`, `default-2`만 제시했고, 지정한 UUID는 `FF975095-E0FC-434D-89E9-E3EBA19EB913`이었다.

### 영향

제품 코드 컴파일 또는 test body 실패와 구분하지 않으면 전체 검증 실패를 UI 변경 회귀로 잘못 판정할 수 있었다.

### 근거

- `./tools/githooks/project-build/bin/run.sh compile`: `Unable to find a device matching ... name:iPhone 17 Pro`와 compile 0/7 성공을 반환했다.
- `GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913' ./tools/githooks/project-build/bin/run.sh compile`: compile 7/7 성공을 반환했다.
- 같은 destination의 `./tools/githooks/project-build/bin/run.sh test`: test 7/7 성공을 반환했다.

### 원인

현재 실행 환경에 기본 이름 `iPhone 17 Pro`와 일치하는 simulator가 없고, UUID로 식별되는 사용 가능한 simulator의 표시 이름이 달랐기 때문이다.

### 조치

사용 가능한 simulator UUID를 `GIT_IT_TEST_DESTINATION`으로 명시해 전체 compile과 test를 재실행했다. source, test, Tuist 설정은 변경하지 않았다.

### 검증

- `GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913' ./tools/githooks/project-build/bin/run.sh compile`: 성공 7/7.
- `GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=FF975095-E0FC-434D-89E9-E3EBA19EB913' ./tools/githooks/project-build/bin/run.sh test`: 성공 7/7.

### 재발 방지

전체 test 검증 전 runner 기본 destination의 표시 이름이 실제 simulator 목록과 일치하는지 확인한다. 이름 불일치가 있으면 제품 코드 오류를 분석하기 전에 사용 가능한 UUID를 명시해 같은 DerivedData 흐름으로 재실행한다.

### 연결

TS-20260822-004, TS-20260822-006

## TS-20260822-008: sandbox에서 Swift formatter module cache 접근이 거부됨

**기록일**: 2026-08-22
**상태**: 해결
**발생 단계**: `speckit-swift-format-run` 사후 포맷 훅
**관련 항목**: T056, 모든 적용 패키지 완료 뒤 formatter 훅

### 증상

sandbox에서 `GIT_IT_SWIFT_FORMAT_RUNNER`를 실행했을 때 SwiftPM manifest가 `/Users/jerry/.cache/clang/ModuleCache`에 module cache를 만들 수 없어 formatter가 시작 전에 실패했다.

### 영향

필수 사후 포맷과 lint gate의 성공 여부를 판정할 수 없었다. 이 실패는 UI source의 format 또는 lint 위반을 의미하지 않는다.

### 근거

- sandbox formatter 실행: `error opening ... ModuleCache ... Operation not permitted`와 `swift-format.formatter-failed`를 반환했다.
- 권한 확장 동일 formatter 실행: 변경 Swift 파일 40개를 처리했고 각 파일에서 lint 0 violations를 반환했다.

### 원인

SwiftPM과 clang이 사용자 cache 경로에 쓰기를 필요로 하지만 sandbox 권한에 그 경로가 포함되지 않았기 때문이다.

### 조치

동일한 `GIT_IT_SWIFT_FORMAT_RUNNER` 공개 진입점을 권한 확장 환경에서 재실행했다. formatter 구현, source와 Git index를 직접 변경하지 않았다.

### 검증

- 권한 확장 formatter: 40개 변경 Swift 파일 처리 및 파일별 lint 0 violations.
- formatter 전후 `git diff --cached --binary --no-ext-diff`: 동일.
- `git diff --check`: 성공.

### 재발 방지

formatter가 `ModuleCache` 권한 오류로 시작 전에 실패하면 source format 오류로 판단하지 말고, cache 쓰기가 가능한 환경에서 같은 공개 runner를 재실행한다.

### 연결

TS-20260822-007
