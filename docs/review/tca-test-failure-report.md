# TCA 테스트 실패 조사 리포트

## 요약

`feature/domain-usecase-redesign` 브랜치에서 `AppTests`와 `Feature` scheme의 테스트가 전량
실패하던 문제를 조사해 원인을 규명하고 29건을 모두 수정했다. 전체 7개 scheme이 통과한다.

조사 범위에서 **제품 코드 결함은 발견되지 않았다.** 확정된 원인은 모두 테스트 코드와
테스트 대역 쪽 결함이다.

| 단계 | 실패 수 | 전체 `test` 경과 |
| --- | --- | --- |
| 조사 시작 | 약 165건 (전량 크래시) | 3202s |
| MainActor 격리 후 | 29건 | 217s |
| 유형별 수정 후 | 6건 | 측정 생략 |
| 최종 | 0건 | 171s |

## 1. 근본 원인: TestStore의 MainActor 격리 누락

### 증상

`Feature`와 `AppTests`의 거의 모든 테스트가 `signal trap`으로 죽고 테스트 프로세스가
재시작됐다. 테스트 하나마다 재시작이 일어나 `Feature` scheme 한 개가 51분 걸렸다.

### 원인

```
libdispatch          _dispatch_assert_queue_fail
libswift_Concurrency swift_task_isCurrentExecutorWithFlags
ComposableArchitecture  Store.init(initialState:reducer:withDependencies:)
ComposableArchitecture  TestStore.init(...)
FeatureTests            makeRepositoryLinkInputStore(...)
```

`TestStore`가 non-isolated 컨텍스트에서 생성되어 executor 검사에 걸렸다. `TestStore`를
직접 또는 helper 경유로 만드는 스위트 24개 파일에 `@MainActor`가 빠져 있었다. 같은
패키지의 Settings·Home 테스트 14개 파일은 이미 `@MainActor`를 쓰고 있었으므로, 관행에서
이탈한 파일만의 문제였다.

### 조치

스위트와 store 팩토리에 `@MainActor`를 붙였다 (커밋 `a31a870`).

## 2. 유형별 실패와 조치

### 2.1 `There were no received actions to skip.` — 11건

해당 reducer 분기가 `.none`을 반환해 받을 액션이 애초에 없는데 `skipReceivedActions()`가
기본값 `strict: true`로 호출됐다. 각 테스트의 실질 단언은 모두 통과하고 있었고 이 호출
한 줄만 실패했다.

`skipReceivedActions(strict: false)`로 바꿨다 (커밋 `08c40ee`). 실제로 액션을 받는 나머지
17개 호출은 그대로 뒀다.

### 2.2 `Must handle N received actions before sending an action.` — 8건

첫 effect가 진행 중일 때 두 번째 입력을 보내는 "중복 입력 무시" 시나리오인데, 테스트
대역이 즉시 응답해 중첩 자체가 성립하지 않았다. 먼저 도착한 액션 때문에 다음 `send`가
실패했다.

`AccountUseCaseRestorationMock`, `AccountUseCaseSignInMock`, `UserInfoUseCaseCurationMock`에
`suspendsRequests`와 `resumeOldest`를 추가하고 테스트에서 명시적으로 resume하도록 고쳤다
(커밋 `0e799cd`). 저장소에 이미 있던 `ExternalRepositoryUseCaseStub`과 같은 형태를 따랐다.

### 2.3 `Received unexpected action:` — 3건

`SettingsFeature.task`가 프로필 조회와 알림 권한 조회를 `.merge`로 동시에 실행하는데,
테스트가 프로필 결과를 먼저 받는 것으로 단언했다. 실제로는 알림 권한 조회가 actor hop이
하나 적어 먼저 도착한다.

수신 순서를 실제 도착 순서에 맞췄다 (커밋 `ee53a1e`).

**주의**: 이 수정은 effect 도착 순서에 의존한다. `.merge`의 순서는 TCA가 보장하지 않으므로
구현이 바뀌면 다시 깨질 수 있다. 더 견고하게 가려면 `exhaustivity = .off` + 최종 상태 단언으로
바꿔야 하지만 액션별 검증력을 잃는다. 현재는 검증력을 유지하는 쪽을 택했다.

### 2.4 반복문 첫 회차 무변경 — 1건

`QuizLevelSelectionFeatureTests`의 `levelSelected` 테스트가 기본값 `.l1`인 State에서
`QuizLevel.allCases`를 `.l1`부터 순회해 첫 회차에서 상태가 바뀌지 않는데 trailing closure가
변경을 단언했다. 초기값을 `.l3`으로 바꿔 모든 회차가 실제 전이를 검증하게 했다
(커밋 `94112f2`).

## 3. 나머지 6건

### 3.1 개별 원인과 조치

#### `ShareRegistrationFeatureValidationTests.조회가 인증 오류로 실패하면 로그인 필요 상태가 된다`

**판정: 테스트 결함.** 테스트가 `ProjectGenerationError.unauthorized`를 조회 실패로
주입하는데, 이 오류는 해당 경로에서 발생할 수 없다.

- `ExternalRepositoryUseCase.repository(at:)`의 실제 구현
  (`ExternalRepositoryResolver`)과 어댑터(`ExternalRepositoryLookupAdapter`)는
  `ExternalRepositoryError`만 던진다.
- `ExternalRepositoryError`에는 `unauthorized` case가 없다
  (`invalidURLFormat`, `offline`, `other`).

따라서 reducer가 알 수 없는 오류로 보고 `.failed(reason: "저장소 정보를 가져오지 못했어요.")`를
내는 것은 정상 동작이다. 인증 처리는 별도로 이미 되어 있다 — 조회 전
`signInAvailability` 검사가 `.signInRequired`를 내고, 등록 경로는
`ProjectGenerationError.unauthorized`를 `.signInRequired`로 매핑한다.

**조치**: 테스트를 삭제했다. 등록 경로의 인증 오류는
`ShareRegistrationFeatureSubmissionTests`가, 조회 전 가용성 검사는 같은 파일의 다른
테스트가 이미 검증하므로 중복이기도 했다.

#### `QuestionSolvingFeatureTests.북마크는 반영 중 재입력을 무시하고 같은 문제의 결과만 반영한다`

**판정: 테스트 결함 (2.2와 동종).** reducer의 중복 방지 guard
(`guard state.bookmarkMutation != .committing`)는 정상 동작한다.
`QuizDetailUseCaseBookmarkStub`이 즉시 응답해 두 번째 탭 시점에 이미 `.committing`이
아니므로 두 번 호출된다.

**조치**: `QuizDetailUseCaseBookmarkStub`에 `suspendsRequests`와 `resumeOldest`를 추가했다.

#### `ProjectDetailFeatureTests.삭제 중에는 재입력을 무시하고 성공하면 삭제 완료를 알린다`

**판정: 테스트 결함.** `ProjectUseCaseDeletionStub`이 즉시 응답해 첫
`deletionFinished`가 두 번째 `send(.view(.deletionConfirmed))` 시점에 이미 도착해 있고,
`exhaustivity = .off`에서 `send`는 대기 중이던 수신 액션을 단언 없이 흡수한다. 이후
`receive`가 받을 액션이 남지 않는다.

reducer는 정상이다 — `guard state.deletion == .confirming`이 두 번째 입력을 막고
(`callCount == 1` 단언은 통과), effect는 `cancelInFlight: false`라 취소되지도 않는다.

**조치**: `ProjectUseCaseDeletionStub`에 `suspendsRequests`와 `resumeOldest`를 추가했다.

#### `AppRootFeatureTests.복원 가능한 실패는 route를 바꾸지 않고 재시도하면 목적지를 결정한다`

**판정: 테스트 결함 (위와 동일 메커니즘).** `AccountUseCaseMock`이 즉시 응답해 첫
`restoreSignInFinished`가 `send(.appEntry(.view(.splashAnimationFinished)))`에 흡수된다.
남은 수신은 자동 재시도분 1건뿐이라 두 번째 `receive`가 1초 타임아웃으로 실패한다.

**조치**: `splashAnimationFinished` 입력을 두 수신 단언 뒤로 옮겼다. 목을 바꾸지 않는
최소 변경이며, 이 테스트가 검증하는 것(복원 가능한 실패가 route를 유지하고 재시도가
목적지를 결정한다)은 그대로 유지된다.

#### `MainShellRouterFeatureTests.준비가 끝나면 단일 문제 화면을 연다`

**판정: 테스트 결함.** 사전 상태 설정이 빠졌다. 새 store에서 곧바로
`.singleQuestionEntry(.delegate(.questionPrepared(...)))`를 보내는데
`state.singleQuestionEntry`가 `nil`이라 `ifLet`이 경고한다.

**조치**: 바로 앞 테스트처럼 `.saved(.delegate(.questionSelected(bookmark)))`로 진입시켜
child state를 먼저 만들도록 했다.

#### `OnboardingRouterFeatureTests.로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다`

**판정: 테스트 결함.** 사전 조건 설정이 빠졌다.

`OnboardingRouterFeature`는 `.tutorial(.delegate(.signInRequested))`를 받으면
`legalAgreement.isStoredConsentValid`가 `false`일 때 로그인을 시작하지 않고
`activeScreen`을 `.guide(.legalAgreement)`로 돌린다. 이 값의 기본값은 `false`이므로
로그인이 시작되지 않고 `signInFinished`도 발생하지 않는다.

조사 과정에서 한 번 오판했는데, 기록해 둘 가치가 있다. 같은 테스트의
`activeScreen == .guide(.tutorial)`과 `transitionLog.isEmpty` 단언이 통과하는 것을 보고
"라우터가 delegate를 처리한 흔적이 없다"고 읽었다. 실제로는 비엄격 모드에서 수신 액션이
다음 `receive`까지 큐에 대기하고, 실패한 `receive`가 큐를 적용하지 못한 채 끝나기 때문에
두 단언이 **아무 것도 검증하지 못한 상태로** 통과한 것이었다. 비엄격 TestStore에서 앞선
`receive`가 실패하면 그 뒤 상태 단언은 신뢰할 수 없다.

**조치**: 초기 State에 `legalAgreement.isStoredConsentValid = true`를 설정했다.

## 4. 검증 방법

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build     # 9/9 통과
"$project_build_runner" compile   # 7/7 통과
"$project_build_runner" test      # 7/7 통과
```

개별 스위트는 다음으로 확인했다.

```sh
xcodebuild test-without-building \
  -workspace sources/GitIt.xcworkspace -scheme Feature -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath sources/DerivedData/PreCommit/TestSchemes/Feature \
  -disableAutomaticPackageResolution \
  -only-testing:FeatureTests/<스위트 이름>
```

실패 상세는 `xcrun xcresulttool get test-results tests --path <xcresult>`로 확인할 수 있다.

## 5. 함께 발견한 사항

### 5.0 `QuizDetailBookmarkTests`의 flaky 실패

전체 `test` 1회차에서 `Domain` scheme의
`QuizDetailBookmarkTests.같은 퀴즈의 북마크 변경은 호출 순서대로 처리한다`가 실패했다.
단독 실행 3회는 모두 통과했고 전체 재실행에서도 통과했다. 이 테스트는 두 번째 요청이
아직 시작되지 않았음을 `Task.yield()` 50회 루프로 확인하는데, 전체 실행의 부하에서는
이 가정이 깨질 수 있다. 이번 변경과 무관한 기존 취약점이며 별도 보완이 필요하다.

### 5.1 컴파일 오류 3건 (수정 완료, 커밋 `c05f4f1`)

`15970a9 [Feat] 관심사별 Domain 타깃과 UseCase 추가`에서 `UserProfile`이
`detail`/`curation` 구조로 재구성됐는데 호출부 2곳이 남아 있어
`App`·`Feature`·`AppTests`·`AllTests` scheme이 빌드되지 않았다.

- `SettingsScreen+CareerLevelSelectionView.swift` — `profile?.careerLevel` → `profile?.curation?.careerLevel`
- `SettingsScreen+PositionSelectionView.swift` — `profile?.position` → `profile?.curation?.position`
- `RequestCredentialProviderTests.swift` — throwing 호출을 쓰는 테스트에 `throws` 누락

### 5.2 `LocalKeyValueStorage`의 Sendable 경고 (해결)

```
LocalKeyValueStorage.swift:45: warning: stored property 'userDefaults' of 'Sendable'-conforming
struct 'LocalKeyValueStorage' has non-Sendable type 'UserDefaults';
this is an error in the Swift 6 language mode
```

`@unchecked Sendable`을 되돌리는 대신 구조를 바꿔 해결했다. Infrastructure
`UserDefaultsStore`를 제네릭 없는 바이트(`Data`) 저장 actor로 바꾸고,
`LocalKeyValueStorage`가 `UserDefaults` 대신 `UserDefaultsStore`를 생성자로 주입받아
JSON 인코딩·디코딩을 직접 담당한다. `UserDefaults`가 actor 밖으로 나오지 않으므로 경고가
사라지고, 저장소 전체의 `@unchecked Sendable`·`nonisolated(unsafe)` 0개 상태도 유지된다.
호출마다 새 actor를 만들던 구조도 함께 없어져 같은 저장소의 연산이 하나의 actor에서
직렬화된다.

### 5.3 pre-commit 훅 비활성

이 세션의 모든 커밋에서 `pre-commit 요약: 실행=0 비활성=6`이 나왔다. 훅이 빌드·테스트·셸
검증을 수행하지 않았다. 의도한 상태가 아니라면 `make hooks`로 재설치가 필요하다.

### 5.4 기존 경고 (이번 변경과 무관)

- `AuthenticationRepositoryAdapter.swift:29` — `'as' test is always true`
- `PendingGenerationRepositoryAdapter.swift:15` — non-Sendable 함수를 `@Sendable () -> Date`로 변환
- `HomeProfileDisplay.swift:46` — `switch must be exhaustive`
- `store.send` 직접 호출 경고 6건 (`@ViewAction` 사용 View)

## 6. 관련 커밋

```
94112f2 [Test] levelSelected 테스트의 첫 회차 무변경 단언 제거
ee53a1e [Test] 설정 화면 task의 동시 effect 수신 순서를 실제 순서에 맞춤
0e799cd [Test] 진행 중 중첩 입력 시나리오의 테스트 대역을 지연 응답으로 바꿈
08c40ee [Test] 받을 액션이 없는 경로의 skipReceivedActions를 비엄격으로 바꿈
a31a870 [Test] TCA 테스트 스위트를 MainActor로 격리해 크래시 해소
c05f4f1 [Fix] UserProfile 재구성 이후 남은 컴파일 오류 수정
fa9a947 [Style] 저장소 계약과 테스트 대역 포맷 정리
```
