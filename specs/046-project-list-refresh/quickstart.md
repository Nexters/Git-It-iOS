# 빠른 시작: 프로젝트 목록 자동 갱신 검증

**명세**: [spec.md](./spec.md) | **계약**: [contracts/app-lifecycle-refresh.md](./contracts/app-lifecycle-refresh.md), [contracts/domain-contracts.md](./contracts/domain-contracts.md) | **기록**: [device-verification.md](./device-verification.md)

이 문서는 구현이 끝난 뒤 기능이 동작함을 확인하는 실행 절차다. 구현 코드는 담지 않는다.

## 1. 사전 조건

- `make init`을 마쳤고 `sources/GitIt.xcworkspace`가 있다. 없으면 `sources`에서 `tuist generate`를 실행한다.
- 자동 검증은 `iPhone 17 Pro` 시뮬레이터(기본 destination)를 쓴다. 다르면 `GIT_IT_TEST_DESTINATION`으로 지정한다.
- 실기기 검증은 개발 빌드를 설치한 실기기, 실제 서버, 회원 계정, 네트워크 계측 수단(Xcode Instruments의 Network
  계측 또는 HTTP 프록시)을 준비한다. 목록 자동 갱신에는 진단 로그가 없으므로 요청 횟수는 네트워크 계측으로만 센다.

## 2. 자동 검증

저장소 루트에서 순서대로 실행한다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 병렬로 실행하지 않는다.

```sh
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

기대 결과:

| 대상 | 확인 내용 | 근거 |
|---|---|---|
| `DomainProject` 테스트 | 진행 중 요청 대체, 대체된 응답 미반영, 대체된 호출자의 무오류 대기, 동시 첫 페이지 요청 1개 이하. 기존 `refresh()` 합류·페이지 이어 받기·삭제 테스트 통과 | FR-005, SC-005, SC-006 |
| `DomainProjectGeneration` 테스트 | 결과 수신마다 `outcomeArrivals()` 방출, 기록 없는 결과도 방출, 같은 결과의 중복 도착은 미방출, 보존 결과 재시도는 미방출. 기존 045 테스트 통과 | FR-002, FR-005, SC-005, SC-008~SC-012 |
| `GitIt`(App) 테스트 | 백그라운드→활성 1회, 비활성→활성 0회, 포그라운드 결과 도착 1회, 백그라운드 중 도착 0회, 게스트·온보딩 0회, 연속 계기 대체 | FR-001~FR-005, SC-003~SC-005 |
| Feature 테스트 | 수동 새로고침·페이지 이어 받기·삭제 후 갱신 테스트가 변경 없이 통과 | SC-006 |

`build`, `compile`, `test` 결과는 각각 기록한다. 실패하면 구성·컴파일·테스트·Simulator 환경 중 어디서 실패했는지 구분한다.

## 3. 시뮬레이터 보조 확인(선택)

`simctl push`는 content-available 알림을 앱에 전달하지 못하므로 백그라운드 수신 경로는 확인할 수 없다. 포그라운드 표시
경로(`willPresent`)만 확인한다.

1. 회원으로 로그인해 홈을 띄운다.
2. 서버 목록에 없는 프로젝트 식별자로 alert payload(`projectId`, `status: completed`)를 `xcrun simctl push`로 보낸다.
3. 네트워크 계측에서 목록 첫 페이지 요청이 1회 시작되는지 확인한다.
4. 홈을 띄운 채 제어 센터를 내렸다 닫는다. 목록 요청이 0회인지 확인한다(비활성→활성).
5. 홈 화면으로 나갔다가 앱 아이콘으로 돌아온다. 목록 요청이 1회인지 확인한다(백그라운드→활성).

## 4. 실기기 검증(FR-019, SC-013)

[device-verification.md](./device-verification.md)의 빈칸을 채운다. 병합 빌드로 검증하므로 "검증 환경" 표에 새 행(빌드 커밋)을
추가한다. "목록 자동 갱신" 표에는 "갱신 응답에 알림 프로젝트 포함" 칸이 있어야 한다(작업으로 추가).

| 순서 | 조작 | 기대 결과 | 기록 위치 |
|---|---|---|---|
| 1 | 백그라운드에서 서버 목록을 바꾼 뒤(다른 기기에서 생성 완료 등) 앱 아이콘으로 복귀 | 목록 요청 1회, 2초 안에 목록 일치 | 목록 자동 갱신 — 포그라운드 진입 |
| 2 | 앱을 보는 중 생성을 요청하고 완료 알림 수신 | 목록 요청 1회, 2초 안에 새 프로젝트 표시, 버튼 활성화, 갱신 응답에 알림 프로젝트 포함 | 목록 자동 갱신 — 포그라운드 중 원격 알림, 앱 상태별 결과 — 포그라운드 |
| 3 | 알림 권한을 끈 상태로 2를 반복 | content-available 수신 시 목록 요청 1회. 수신되지 않으면 그 사실을 기록 | 목록 자동 갱신, 서버 payload |
| 4 | 백그라운드에서 완료 알림 수신 | 수신 시점 목록 요청 0회, 복귀 시 1회 | 목록 자동 갱신 — 백그라운드 중 원격 알림 |
| 5 | 백그라운드에서 알림 탭 | 결과 반영, 복귀 계기로 목록 요청 1회 | 앱 상태별 결과 — 백그라운드 알림 탭 |
| 6 | 강제 종료 후 알림 탭으로 실행 | 결과 반영, 최초 로드로 목록 표시 | 앱 상태별 결과 — 사용자 강제 종료 |
| 7 | 게스트로 1·2 조작 | 목록 요청 0회 | 목록 자동 갱신 — 게스트 상태 |
| 8 | 수신한 payload 확인 | `content-available`, `projectId`·`status` 키와 값 형식, 등록 응답 `projectId`와 일치 여부 | 서버 payload |

2의 갱신 응답에 알림 프로젝트가 없으면 명세 가정(서버가 알림 시점에 목록 API에 반영)이 어긋난 것이다. 앱을 고치지 않고
서버 협의 항목으로 분리해 PR에 기록한다(명확화 2026-09-28 질문 3).

실기기 검증을 수행하지 못하면 PR에 미검증 범위(백그라운드 수신 경로, 2초 기준, 서버 반영 순서)로 남긴다(Constitution 원칙 3).
