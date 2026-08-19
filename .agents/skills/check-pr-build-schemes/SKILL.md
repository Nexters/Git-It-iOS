---
name: check-pr-build-schemes
description: Git-It-iOS의 PR 생성 전에 Tuist 공유 scheme, 테스트 target 연결, 전체 production build, build-for-testing과 test-without-building을 점검하고 실패를 구성·컴파일·테스트·Simulator 환경으로 분류한다. PR 준비 상태를 확인하거나 build/test scheme 검증을 요청할 때 사용하며, 코드 수정·커밋·푸시·PR 생성은 수행하지 않는다.
---

# PR 전 build scheme 점검

현재 checkout의 생성 설정과 로컬 Xcode 실행 결과를 근거로 PR 전 build·test gate를 판정한다.
원격 GitHub Actions 성공이나 전체 PR 품질 검토를 대신하지 않는다.

## 실행 경계

- 저장소 루트, branch, `HEAD`, staged·unstaged·untracked 상태를 먼저 기록한다.
- 기존 `xcodebuild`, pre-commit 또는 같은 Derived Data를 쓰는 build/test 체인이 실행 중이면 결과와
  소유권을 확인할 때까지 새 체인을 시작하지 않는다. 임의로 프로세스를 종료하지 않는다.
- 생성 workspace가 없거나 source 추가·삭제·이름 변경 또는 Tuist manifest 변경으로 stale 가능성이
  있으면 저장소 루트에서 `make tuist`를 먼저 실행한다. product source는 수정하지 않는다.
- build·test 중 formatter가 추적 파일을 바꾸는지 실행 전후 Git 상태를 비교한다. 사용자가 만든 기존
  변경과 이번 실행의 부수효과를 구분하고 임의로 되돌리지 않는다.
- Derived Data 삭제, Simulator 초기화·앱 제거, source/config 수정은 점검 범위가 아니다. 필요하면
  근거와 영향 범위를 보고하고 사용자 승인을 받는다.

## 점검 절차

1. `AGENTS.md`, `.specify/memory/constitution.md`, `README.md`의 현재 build·test 명령을 확인한다.
2. `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`와 관련 ModuleName 선언을 읽어 production
   target, test target, shared scheme의 의도된 관계를 확인한다.
3. 생성된 `*.xcscheme`을 관찰해 전체 공유 scheme과 `<TestableReference>`가 있는 testable scheme을
   구분한다. source-of-truth 선언과 생성 결과가 다르면 구성 실패로 판정한다.
4. 저장소 루트에서 다음 검증을 실행해 빈 테스트 target과 저장소 셸 회귀를 확인한다.

   ```sh
   ./tools/script-tests/bin/run.sh
   ```

5. 사용할 Simulator를 실행 직전에 확인한다. 부팅된 유효한 기기가 있으면 그 UUID를 사용한다.
   부팅된 기기가 없으면 available 기기 하나를 UUID로 선택해 `simctl boot`와 `bootstatus -b`를
   완료한다. `GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=<UUID>'`를 compile과 test에
   동일하게 사용한다.
6. 저장소 공개 runner를 해석한 뒤 다음 세 명령을 반드시 순차 실행한다. `compile`과 `test`는 같은
   `sources/DerivedData/PreCommit/TestSchemes/<scheme>` 제품을 공유하므로 사이에 다른 build/test를
   끼우거나 병렬 실행하지 않는다.

   ```sh
   project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
   "$project_build_runner" build
   GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=<UUID>' "$project_build_runner" compile
   GIT_IT_TEST_DESTINATION='platform=iOS Simulator,id=<UUID>' "$project_build_runner" test
   ```

7. 실행 후 Git 상태를 다시 읽고 시작 상태와 비교한다. 검증 명령이 만든 추적 파일 변경이 있으면
   PR gate 실패로 보고하되 자동 복구하지 않는다.

## 실패 분류

- **생성·구성 실패**: Tuist 생성 실패, workspace 누락, 선언과 생성 scheme 불일치, 공유 scheme 누락.
- **scheme 계약 실패**: 빈 test target 등록, Test Action 또는 `TestableReference` 누락, 잘못된 host 연결.
- **production build 실패**: `build` action의 컴파일·링크·resource·의존성 오류.
- **테스트 빌드 실패**: `build-for-testing` 중 test source typecheck·링크·runner 생성 오류.
- **테스트 실행 실패**: 테스트 본문이 시작된 뒤 assertion·crash·timeout 발생.
- **환경 실패**: 테스트 본문 전에 CoreSimulator, runner 설치 preflight, XCTest bootstrap 또는 Xcode
  service가 실패. product 실패로 단정하지 말고 실패 scheme의 `.xcresult`, Simulator 로그와 실제
  실행된 테스트 수를 확인한다.

환경 실패만 확인된 경우 관련 실행이 종료됐는지 확인한 뒤 같은 조건으로 최대 한 번만 재시도한다.
재발하면 실패를 보존하고 중단한다. product·Tuist 설정을 추측으로 바꾸지 않는다.
제한된 Codex 실행에서 `CoreSimulatorService` 권한 오류와 `workspace is not a workspace`가 함께
발생하면 같은 gate를 Xcode 접근이 허용된 환경에서 재실행한 결과로 product 성공 여부를 판정한다.

## 완료 판정과 보고

다음을 모두 만족할 때만 이 스킬 범위에서 **PR 전 build·test gate 통과**로 판정한다.

- `make tuist`가 필요했던 경우 성공했다.
- script tests가 성공했다.
- 생성된 공유 scheme 목록과 testable scheme 연결이 source-of-truth와 일치한다.
- 공개 runner의 `build`, `compile`, `test`가 모두 종료 코드 0이다.
- 테스트 실행 건수와 실패 0건을 `.xcresult` 또는 runner 결과로 확인했다.
- 실행 전후 비교에서 의도하지 않은 추적 파일 변경이 없다.

최종 보고에는 branch와 `HEAD`, 전체/testable scheme 수와 이름, gate별 명령·성공/실패, 테스트 수,
실패 분류, `.xcresult` 경로, 미검증 범위를 포함한다. 로컬 통과를 GitHub Actions 통과로 표현하지
않고, commit·push·PR 생성은 사용자의 별도 요청 전까지 수행하지 않는다.
