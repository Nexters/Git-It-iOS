# 011-server-data-api 문제 해결 기록

**대상 기능**: `011-server-data-api`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260821-001: 전체 완료 검증에서 시뮬레이터 서비스 허브 오류로 Data scheme test가 실패함

**기록일**: 2026-08-21
**상태**: 환경 제약
**발생 단계**: `$speckit-implement` 전체 완료 검증(T068)
**관련 항목**: T068, `SC-003`, `SC-007`, Data scheme `test-without-building`

### 증상

전체 Data scheme 대상 `"$project_build_runner" test` 1회차 실행에서 Data scheme이 테스트
본문에 진입하지 못한 채 실패했다. 같은 실행에서 App scheme도 실패해 `시도=7 성공=5 실패=2`로
끝났다. 관찰된 오류 문자열은 다음과 같다.

- Data scheme: `DTServiceHubClient failed to bless service hub for simulator iPhone 17 Pro`,
  이어서 `xctest encountered an error (Early unexpected exit, operation never finished
  bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with signal
  term before establishing connection.))`
- App scheme: `xctest encountered an error (Early unexpected exit, ... The test runner crashed
  while preparing to run tests: xctest at <external symbol>)`

`UIUITests`도 실행마다 서로 다른 테스트(`LayoutContractUITests` 소속)가 실패했다가 마지막
실행에서는 통과해, 특정 테스트의 결정적 실패가 아니라 실행 환경에 따라 결과가 흔들렸다.

### 영향

Data 패키지 구현 코드에는 문제가 없는데도 `T068`(SC-003, SC-007) 검증이 실패로 보고되어,
Member target 신규 추가나 swift-format 적용이 회귀를 유발한 것으로 잘못 판단할 수 있었다.

### 근거

- `"$project_build_runner" test` 1회차 출력: Data scheme에서 `DTServiceHubClient failed to
  bless service hub`와 `Test crashed with signal term before establishing connection` 관찰,
  요약 `작업=test 시도=7 성공=5 실패=2`.
- `xcrun simctl list devices`: 조치 전 `iPhone 17 Pro (6CA6AEA3-...-A29C6B0372C4)`가 부팅
  상태였으나 test runner 연결이 성립하지 않았다.
- 재실행 후 `sources/DerivedData/PreCommit/TestSchemes/Data/Logs/Test/*.xcresult`
  (`xcrun xcresulttool get test-results summary`): `result: Passed`, `passedTests: 69`,
  `failedTests: 0`.
- `git status --short -- sources/Projects/App`: 이번 명세에서 App 패키지 변경 없음.

### 원인

확정 원인은 로컬 iOS Simulator의 서비스 허브(DTServiceHub) 상태 손상이다. Data scheme은
동일 코드·동일 빌드 산출물로 재실행했을 때 성공했으므로 제품 코드 결함이 아니다.

App scheme이 시뮬레이터 재부팅 뒤에도 계속 실패하는 원인은 확인 중이다. 이번 명세가 App
패키지를 변경하지 않았다는 점만 확인했고, 실패 자체의 근본 원인은 조사하지 않았다.

### 조치

`xcrun simctl shutdown "iPhone 17 Pro"` 후 `xcrun simctl boot "iPhone 17 Pro"`로 대상
시뮬레이터를 재부팅하고 `"$project_build_runner" test`를 재실행했다. App scheme 실패에
대한 조치는 미실행이다.

### 검증

- `"$project_build_runner" build`: 성공(`시도=8 성공=8 실패=0`), `DataMember` 포함.
- `"$project_build_runner" compile`: 성공(`시도=7 성공=7 실패=0`).
- `"$project_build_runner" test` 재실행: Data scheme 완료, xcresult 기준 69개 통과·0개 실패.
- App scheme: 재부팅 후에도 실패 지속(미해결).

### 재발 방지

Data·Domain·Infrastructure·Composition 같은 순수 로직 scheme이 테스트 본문 진입 전
`Early unexpected exit` 또는 `DTServiceHubClient` 오류로 실패하면, 코드를 수정하기 전에
먼저 대상 시뮬레이터를 shutdown·boot 후 1회 재실행해 환경 문제인지 판별한다. 판별 근거는
실패 요약 문구가 아니라 xcresult의 `passedTests`/`failedTests`로 확인한다.

### 연결

유사 증상 선행 기록: `docs/spec-kit/007-learning-project-lifecycle/trouble-shooting.md`의
`TS-20260820-001`(시뮬레이터 부팅 실패),
`docs/spec-kit/006-final-uxui-screens/trouble-shooting.md`의 `Early unexpected exit` 항목들.
