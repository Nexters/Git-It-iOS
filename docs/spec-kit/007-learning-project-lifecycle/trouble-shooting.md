# 007-learning-project-lifecycle 문제 해결 기록

**대상 기능**: `007-learning-project-lifecycle`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260820-001: DomainLearningProject 패키지 검증 중 iPhone 17 Pro 시뮬레이터 부팅 실패

**기록일**: 2026-08-20
**상태**: 해결
**발생 단계**: speckit-implement, Domain(DomainLearningProject) 패키지 정리와 검증(T033)
**관련 항목**: T033, `xcodebuild test -workspace GitIt.xcworkspace -scheme DomainLearningProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

### 증상

T033 검증 명령을 처음 실행했을 때 `** TEST FAILED **`로 종료됐다. 로그에 `[MT] IDELaunchReport: ... Install Actions Finished with error: Unable to boot device because it cannot be located on disk.`가 출력됐다.

### 영향

Domain 패키지 소스·테스트 코드 자체는 컴파일이 끝난 상태였지만, 시뮬레이터가 부팅되지
않아 실제 테스트 실행 결과(성공/실패)를 확인할 수 없었다 — 코드 결함과 환경 문제가
혼동될 수 있는 상황이었다.

### 근거

- `xcodebuild test -workspace GitIt.xcworkspace -scheme DomainLearningProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` 1차 실행 로그: `Testing failed:` 다음 줄에 `** TEST FAILED **`.
- `xcrun simctl boot 6CA6AEA3-FD6C-4549-A261-A29C6B0372C4` 직접 실행 결과: `Unable to boot device because it cannot be located on disk. The device's data is no longer present at /Users/jerry/Library/Developer/CoreSimulator/Devices/6CA6AEA3-FD6C-4549-A261-A29C6B0372C4/data.`
- `xcrun simctl list devices` 결과: 같은 UUID의 `iPhone 17 Pro`가 `iOS 26.5` 런타임 아래 `(Shutdown)` 상태로 정상 등록되어 있었다(디바이스 목록 메타데이터와 실제 디스크 데이터가 불일치).

### 원인

로컬 CoreSimulator 디바이스의 데이터 디렉터리(`.../Devices/6CA6AEA3-.../data`)가 실제
디스크에서 누락/손상된 상태였다 — Domain 패키지 소스나 테스트 코드의 결함이 아니라
로컬 시뮬레이터 환경 상태 손상이었다.

### 조치

`xcrun simctl erase 6CA6AEA3-FD6C-4549-A261-A29C6B0372C4` 실행 후 `xcrun simctl boot
6CA6AEA3-FD6C-4549-A261-A29C6B0372C4`로 정상 부팅을 확인했다. 이후 동일한 T033
`xcodebuild test` 명령을 재실행했다.

### 검증

- `xcrun simctl boot 6CA6AEA3-FD6C-4549-A261-A29C6B0372C4`(erase 후): 성공, 오류 출력 없음.
- `xcodebuild test -workspace GitIt.xcworkspace -scheme DomainLearningProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`(재실행): `** TEST SUCCEEDED **`, `Test Suite 'All tests' passed`, 42개 테스트 전부 통과(실패 0건).

### 재발 방지

같은 `xcodebuild test`가 "Unable to boot device because it cannot be located on disk"로
실패하면, 코드 변경을 의심하기 전에 먼저 `xcrun simctl list devices`로 대상 UUID가
목록에는 있는지, `xcrun simctl boot <UUID>`가 같은 디스크 오류를 재현하는지 확인한다.
재현되면 `xcrun simctl erase <UUID>` 후 재부팅으로 복구를 먼저 시도한다.

### 연결

없음
