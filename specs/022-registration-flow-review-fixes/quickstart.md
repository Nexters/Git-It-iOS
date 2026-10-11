# 빠른 시작: 검증 절차

**기능 브랜치**: `feature/registration-flow-review-fixes`

**날짜**: 2026-09-01

이 문서는 구현 결과를 검증하는 실행 가능한 절차만 담는다. 구현 세부는
[data-model.md](./data-model.md), [contracts/](./contracts/)와 `tasks.md`가 소유한다.

## 1. 사전 준비

```sh
make init
```

이미 초기화돼 있으면 다음으로 workspace만 갱신한다.

```sh
make tuist
```

빌드·테스트 공개 진입점을 경로 변수로 해석한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

## 2. 기준선 확인 (구현 시작 전 1회)

FR-032의 `Early unexpected exit` 재현 여부를 먼저 확인한다(R12).

```sh
"$project_build_runner" compile && "$project_build_runner" test
```

재현되면 원인을 분리한 뒤 진행하고, 재현되지 않으면 그 사실을 진행 보고에 남긴다.

현재 formatter 위반 2건도 기준선으로 확인한다(FR-031).

```sh
./tools/githooks/swift-format/bin/run.sh lint
```

## 3. 자동화 검증

### 3.1 전체 게이트

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
./tools/githooks/swift-format/bin/run.sh lint
```

네 명령이 모두 통과해야 SC-011과 SC-012를 만족한다. 세 build 명령은
`sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다.

### 3.2 신규 회귀 테스트가 덮어야 하는 시나리오

| 시나리오 | 대상 테스트 위치 | 검증 기준 |
| --- | --- | --- |
| 생성 요청 전 구독 확립 | `Feature/Tests/ProjectRegistration/Reducers/` | 생성 요청이 전송되는 시점에 구독이 이미 확립돼 있다 (SC-001) |
| 응답보다 먼저 도착한 결과 반영 | 동일 | 구독 확립 직후·응답 전에 주입한 완료 결과가 진행 화면에 반영된다 (SC-001) |
| 중복 결과 멱등 | 동일 / `Feature/Tests/Home/Reducers/` | 2회 수신해도 최종 상태와 재조회 횟수가 1회와 같다 (SC-002) |
| 시트 표시 중 실패 전이 | `Feature/Tests/ProjectRegistration/Reducers/` | 시트가 닫히고 재시도·종료 Action이 유효하다 (SC-003) |
| 인증 종료 시 child 정리 | `App/Tests/GitIt/Reducers/AppRootFeatureTests.swift` | `projectRegistration`이 `nil`이 되고 관찰 Effect가 취소된다 (SC-004) |
| 재로그인 시 stale presentation 부재 | 동일 | 이전 세션의 full-screen cover가 재표시되지 않는다 (SC-004) |
| 단계 상태 유지 | `Feature/Tests/ProjectRegistration/Reducers/` | View 재생성과 무관하게 `RegistrationStep`이 유지된다 (SC-008) |
| 조회 중 결과 반영 | `Feature/Tests/Home/Reducers/` | `projectLoad == .loading` 중 수신한 결과가 조회 완료 후 반영된다 (SC-009) |
| 조립 시 부수효과 부재 | `App/Tests/GitIt/GitItCompositionLifetimeTests.swift` | 객체 생성만으로 외부 SDK 접근·Keychain read/write·서버 호출이 0건이다 (SC-006) |
| 리마인드 구독 확립 순서 | `Composition/Tests/Adapter/Factories/` | `bootstrap()` 반환 시점에 구독이 확립돼 있다 (SC-002a) |
| 기기 등록 실패 노출 | `App/Tests/GitIt/Reducers/AppRootFeatureTests.swift` | 실패가 인증 세션 소유자의 상태로 남는다 (SC-007) |
| 앱 활성화 재시도 | 동일 | 등록 실패 후 앱 활성화 시 최신 token으로 재시도한다 (SC-007) |
| token 갱신 재시도 | 동일 | 등록 실패 후 token 갱신 시 갱신 token으로 재시도한다 (SC-007) |
| 동시 trigger 직렬화 | 동일 | 앱 활성화와 token 갱신이 동시에 발생해도 서버 등록 요청은 1회다 (SC-007) |

### 3.3 이름 정렬 검증 (SC-010)

```sh
rg -n 'LearningProjectOutcomes|GenerationOutcomeDTO|GenerationOutcomeStream|PushGenerationOutcomeStream|SubmissionStatus|notificationOption|ingestPushPayload' sources/Projects
```

출력이 없어야 한다.

`projectSelected`는 0건 검색으로 판정하지 않는다. 이 명세가 제거하는 대상은 `MainShellFeature`가
**외부로 내보내는** `Delegate.projectSelected(projectID:)` 하나뿐이며(FR-030,
[contracts/naming-map.md](./contracts/naming-map.md) §5), 다음 두 참조는 rename 후에도 정상적으로
남는다.

- `ProjectListFeature.Delegate.projectSelected(projectID:)` — child가 소유하는 UI 사건. 범위 밖
- `MainShellFeature`가 그 child delegate를 수신하는 패턴 매칭
  `case .projectList(.delegate(.projectSelected(let projectID))):` — T073이 이 case의 **변환
  대상**만 `projectDetailRequested`로 바꾼다

따라서 App에서만 0건을 확인한다.

```sh
rg -n 'projectSelected' sources/Projects/App
```

출력이 없어야 한다. `MainShellFeature`는 `Delegate` 선언과 방출부에서만 사라졌는지 눈으로
확인한다.

```sh
rg -n 'projectSelected|projectDetailRequested' sources/Projects/Feature/MainShell
```

기대 결과: `Delegate` enum에 `projectSelected` 선언이 없고, `.send(.delegate(...))`가
`projectDetailRequested`만 방출하며, `.projectList(.delegate(.projectSelected(...)))` 수신 패턴
1건만 남는다.

추가로 다음 두 검색도 확인한다.

```sh
rg -n 'QuizGeneration' sources/Projects/Domain
rg -n 'LearningSet.*Outcome|Outcome.*LearningSet' sources/Projects
```

## 4. 수동 검증 (Simulator / 실제 기기)

자동화로 덮을 수 없는 항목만 남긴다.

### 4.1 메인 스레드 위반 부재 (SC-005)

1. Xcode scheme diagnostics에서 Main Thread Checker를 켠다.
2. 알림 권한을 거부 상태로 만든다(설정 앱에서 알림 끄기).
3. 프로젝트를 등록하고 생성 진행 화면에서 `홈에서 기다리기`를 탭한다.
4. 알림 옵션 시트에서 `리마인드 알림 설정하기`를 탭한다.
5. 설정 앱 알림 화면으로 이동하고 콘솔에 `UIApplication.openURL:options:completionHandler:`
   위반 경고가 0건인지 확인한다.

### 4.2 등록 단계 유지 (SC-008)

1. 저장소 확인과 이해도 선택을 마쳐 생성 확정 화면까지 간다.
2. 앱을 background로 보냈다가 복귀하거나 다크 모드를 전환해 View를 재생성시킨다.
3. 같은 단계에 머무는지 확인한다.

### 4.3 cold launch 정합성 (FR-004)

1. 프로젝트를 등록한 뒤 앱을 완전히 종료한다.
2. 서버 생성이 끝나 silent push가 도착하게 한다.
3. 앱을 실행해 Home 목록이 완료 상태를 반영하는지 확인한다.

**전제**: 개발용 provisioning과 APNs key가 연결된 실제 기기가 필요하다. Simulator에서는
`xcrun simctl push`로 payload를 주입해 대체 검증할 수 있다.

```sh
xcrun simctl push booted com.nexters.hytime.gitit payload.json
```

`payload.json`은 `aps.content-available = 1`과 `projectId`, `status` 키를 포함해야 한다.

### 4.4 실패 시 흐름 탈출 (SC-003)

1. 알림 옵션 시트를 표시한 상태로 둔다.
2. 해당 프로젝트의 `status: failed` payload를 주입한다.
3. 시트가 닫히고 실패 화면에서 재시도 또는 종료가 가능한지 확인한다.

## 5. 완료 판정

- §3.1의 네 명령이 모두 통과한다.
- §3.2의 14개 시나리오에 대응하는 테스트가 존재하고 통과한다.
- §3.3의 검색 결과가 기대와 일치한다.
- §4의 수동 항목을 실행하고 결과를 PR에 기록한다. 실행하지 못한 항목은 미검증으로 명시한다.
