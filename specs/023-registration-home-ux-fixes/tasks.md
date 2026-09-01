---

description: "등록 흐름·홈 화면 UX 결함 해소 구현 작업 목록"
---

# 작업 목록: 등록 흐름·홈 화면 UX 결함 해소

**입력**: `/specs/023-registration-home-ux-fixes/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 명세가 자동 검증을 직접 요구한 범위(FR-023, SC-004, SC-006, SC-007, SC-010)에만
테스트 작업을 둔다.

**구성**: 실행 단위를 최상위 구조로 사용하고 변경 시나리오는 각 단위 안의 `[S#]` 라벨로
추적한다. 7개 단위 중 6개가 단일 패키지이고, 공유 확장만 다중 패키지 integration unit이다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[S#]**: [spec.md](./spec.md)의 변경 시나리오 번호
  - S1 링크 입력 키보드 · S2 홈 진행 중 표시 · S3 알림·화면 대기 게이트
  - S4 카드 로딩 표시 · S5 첫 카드 기울기 · S6 공유 진입
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `tuist generate`가 만드는 workspace·project는 `.gitignore` 대상이라 추적 파일을
  바꾸지 않는다. 실행 전후 `git status`를 비교하고 추적 파일 변경이 생기면 완료로 처리하지
  않는다.

---

## 작업 패키지 0: 기존 작업 트리 변경의 소유권 확정 (승인 필요)

**목표**: 이 브랜치에 이미 존재하는 커밋되지 않은 변경의 소유권을 확정해, 이후 단위의 정확한
staging이 사용자 소유 변경을 의도치 않게 소비하지 않게 한다.

**이 단위가 먼저 필요한 이유**: 아래 파일은 패키지 5(Feature)와 패키지 1(Domain)의 작업 대상과
겹친다. 소유권을 정하지 않은 채 파일 단위로 staging하면 이 명세가 소유하지 않은 hunk가 함께
커밋된다. Constitution 원칙 7은 사용자 소유 변경의 소비에 명시적 승인을 요구한다.

**현재 커밋되지 않은 변경**

| 경로 | 내용 | 이 명세와의 관계 |
| --- | --- | --- |
| `sources/Projects/Feature/Home/Models/HomeCardScrollLayout.swift` | 기준 위치 왼쪽 각도를 `position * 16`으로 변경 | S5와 **직접 충돌**. T024가 기준값 산출 방식을 바꾸므로 함께 정리해야 한다 |
| `sources/Projects/Feature/Tests/Home/Models/HomeCardScrollLayoutTests.swift` | 위 변경에 맞춘 기대값 | S5 |
| `sources/Projects/Feature/Home/Screens/HomeScreen.swift` | 빈 데크 실루엣 도입, 조회 실패 재시도 UI | S4·S5와 겹침. 재시도 UI 부분은 이 명세 범위 밖 |
| `sources/Projects/Feature/Home/Screens/HomeEmptyDeckShape.swift`(신규) | 빈 데크 실루엣 도형 | S4가 재사용 |
| `sources/Projects/Feature/Home/Reducers/HomeFeature.swift` | `projectRetryTapped` 추가 | 이 명세 범위 밖(022 계열) |
| `sources/Projects/Feature/Tests/Home/Reducers/HomeFeatureLoadTests.swift` | 위 변경 테스트 | 이 명세 범위 밖 |
| `sources/Projects/Feature/ProjectRegistration/Screens/RepositoryConfirmationScreen.swift` | 썸네일 `AsyncImage` 제거 | 이 명세 범위 밖 |
| `sources/Projects/Domain/LearningProject/Models/LearningProject/LearningProjectPage.swift` | 미확인 변경 | 이 명세 범위 밖 |

- [X] T001 위 8개 경로 각각을 「이 명세가 채택」·「보존하되 이 명세의 커밋에서 제외」·「되돌림」
      중 하나로 분류받는다. 분류가 확정되기 전에는 패키지 1과 패키지 5의 파일 변경 작업을
      시작하지 않는다.
- [X] T002 [no-write] T001의 분류를 근거로, 채택하지 않는 경로를 이후 단위의 staging 범위에서
      제외하는 목록을 확정하고 기록한다. 이 목록은 각 커밋 단위의 파일 snapshot에 적용된다.

**진행 점검**: T001~T002는 파일을 바꾸지 않는다. 분류가 끝나면 패키지 1로 진행한다.

---

## 작업 패키지 1: Domain

**목표**: 생성 진행 상태와 최소 대기 정책의 정본을 Domain에 두어 Feature와 Composition이 같은
규칙을 참조하게 한다(R-005).

**소유 경로**: `sources/Projects/Domain/LearningProject/`,
`sources/Projects/Domain/Tests/LearningProject/`

**관련 변경 시나리오**: S2, S3

**독립 검증**: Domain은 프로젝트 내부 패키지에 의존하지 않는다. Domain scheme 테스트만으로
정책 계산과 추적 UseCase 동작을 검증할 수 있다.

### 승인 필요

- [X] T003 `GenerationWaitPolicy.retentionLimit` 값을 확정받는다. 제안값은 86400초(24시간)이며,
      정상적으로 느린 생성을 끊지 않으면서 멈춘 상태가 하루 안에 해소되는 값이다. 명세는 상한의
      존재만 요구하고 값을 정하지 않았다([data-model.md](./data-model.md) 2절). 확정 전에는
      T009를 시작하지 않는다.

### 준비와 기반

- [X] T004 [S2] [S3] `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationProgress.swift`에
      `projectID: String`과 `requestedAt: Date`를 갖는 `GenerationProgress`를 추가한다.
      `Equatable`, `Sendable`, `Codable`을 채택한다.
- [X] T005 [P] [S2] `sources/Projects/Domain/LearningProject/Contracts/GenerationProgressRepository.swift`에
      `load() async -> GenerationProgress?`, `save(_:) async`, `clear() async`를 갖는
      `GenerationProgressRepository` 프로토콜을 추가한다.
- [X] T006 [P] [S2] `sources/Projects/Domain/LearningProject/UseCases/TrackGenerationProgress/TrackGenerationProgressUseCase.swift`에
      `begin(projectID:requestedAt:)`, `current()`, `end()`를 갖는 프로토콜을 추가한다.

### 테스트

- [X] T007 [P] [S2] `sources/Projects/Domain/Tests/LearningProject/TestDoubles/StubGenerationProgressRepository.swift`에
      저장 계약 테스트 더블을 추가한다.
- [X] T008 [P] [S3] `sources/Projects/Domain/Tests/LearningProject/Models/GenerationWaitPolicyTests.swift`에
      `readyDate(for:)`가 `requestedAt + 300초`를 반환하고 `isExpired(_:now:)`가 상한 초과를
      판정하는 테스트를 작성한다.
- [X] T009 [S2] `sources/Projects/Domain/Tests/LearningProject/UseCases/TrackGenerationProgressTests.swift`에
      `begin` 후 `current`가 값을 반환하고, 두 번 `begin`해도 마지막 1건만 남으며, `end` 후
      `nil`을 반환하는 테스트를 작성한다.

### 구현

- [X] T010 [S3] `sources/Projects/Domain/LearningProject/Models/LearningProject/GenerationWaitPolicy.swift`에
      `minimumWait = 300`, T003에서 확정한 `retentionLimit`, `readyDate(for:)`,
      `isExpired(_:now:)`와 `standard`를 구현한다. 테스트가 짧은 값으로 대체할 수 있도록 값
      타입으로 둔다.
- [X] T011 [S2] `sources/Projects/Domain/LearningProject/UseCases/TrackGenerationProgress/TrackGenerationProgress.swift`에
      `GenerationProgressRepository`를 생성자로 주입받는 `TrackGenerationProgressUseCase`
      구현을 추가한다.

### 정리와 패키지 검증

- [X] T012 [no-write] Domain scheme 테스트를 실행해 T008, T009가 통과하는지 확인한다.

**진행 점검**: T003~T012의 변경 파일과 검증 결과를 보고하고 패키지 2로 진행한다.

---

## 작업 패키지 2: Infrastructure

**목표**: 로컬 알림을 지정 시각에 예약하고 취소할 수 있게 한다(R-007).

**소유 경로**: `sources/Projects/Infrastructure/PushMessaging/Local/Clients/`

**관련 변경 시나리오**: S3

**독립 검증**: 추가 전용 변경이라 기존 `present` 호출부가 영향을 받지 않는다. Infrastructure
scheme build만으로 확인한다. 예약 시각 계산의 동작 검증은 가짜 클라이언트를 쓰는 패키지 6에서
수행한다.

### 구현

- [X] T013 [S3] `sources/Projects/Infrastructure/PushMessaging/Local/Clients/LocalNotificationClient.swift`에
      `schedule(_ request: LocalNotificationRequest, at date: Date)`와
      `cancel(identifier: String)`을 추가한다. `present`의 시그니처와 동작은 바꾸지 않는다.
- [X] T014 [S3] `sources/Projects/Infrastructure/PushMessaging/Local/Clients/UserNotificationCenterLocalClient.swift`에
      `UNTimeIntervalNotificationTrigger`와 `removePendingNotificationRequests(withIdentifiers:)`로
      두 메서드를 구현한다. 이미 지난 시각이면 추가 지연 없이 즉시 발송하고, 같은 식별자로 다시
      예약하면 1건만 남게 한다([contracts/infrastructure-local-notification.md](./contracts/infrastructure-local-notification.md)).

### 정리와 패키지 검증

- [X] T015 [no-write] Infrastructure scheme build로 추가 API가 기존 호출부를 깨지 않는지
      확인한다.

**진행 점검**: T013~T015의 변경 파일과 검증 결과를 보고하고 패키지 3으로 진행한다.

---

## 작업 패키지 3: UI

**목표**: `LabeledTextField`가 포커스 상태를 노출해 화면이 키보드를 내릴 수 있게 한다(R-002).

**소유 경로**: `sources/Projects/UI/Component/Controls/LabeledTextField/`

**관련 변경 시나리오**: S1

**독립 검증**: 새 인자의 기본값이 `nil`이라 기존 호출부가 변경 없이 컴파일된다. UI scheme
build로 확인한다.

### 구현

- [X] T016 [S1] `sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift`에
      기본값 `nil`인 `focus: FocusState<Bool>.Binding?` 인자를 추가하고 내부 `TextField`에
      연결한다. 기존 인자 순서와 표시·검증 동작은 바꾸지 않는다.

### 정리와 패키지 검증

- [X] T017 [no-write] UI scheme build로 기존 호출부가 변경 없이 컴파일되는지 확인한다.

**진행 점검**: T016~T017의 변경 파일과 검증 결과를 보고하고 패키지 4로 진행한다.

---

## 작업 패키지 4: Data

**목표**: 생성 진행 상태를 기기에 보존한다(R-008).

**소유 경로**: `sources/Projects/Data/LearningProject/`,
`sources/Projects/Data/Tests/LearningProject/`

**관련 변경 시나리오**: S2

**독립 검증**: Data는 Infrastructure만 참조한다. Domain 타입을 쓰지 않고 자체 DTO와 계약으로
컴파일·테스트된다. 경로 구조는 기존 `LegalConsent` 저장소와 같다.

### 준비와 기반

- [X] T018 [P] [S2] `sources/Projects/Data/LearningProject/DTOs/GenerationProgressDTO.swift`에
      `projectID: String`, `requestedAt: Date`를 갖는 `Codable` DTO를 추가한다.
- [X] T019 [P] [S2] `sources/Projects/Data/LearningProject/Contracts/GenerationProgressStore.swift`에
      `load()`, `save(_:)`, `clear()` 계약을 추가한다.

### 테스트

- [X] T020 [S2] `sources/Projects/Data/Tests/LearningProject/Stores/LocalGenerationProgressStoreTests.swift`에
      저장·복원·해제와 단일 레코드 유지 테스트를 작성한다. 격리된 `UserDefaults` suite를 써서
      다른 테스트와 상태를 공유하지 않는다.

### 구현

- [X] T021 [S2] `sources/Projects/Data/LearningProject/Stores/LocalGenerationProgressStore.swift`에
      `InfrastructureStorage.UserDefaultsStore<GenerationProgressDTO>` 기반 구현을 추가한다.
      단일 키에 1건만 보관한다.

### 정리와 패키지 검증

- [X] T022 [no-write] Data scheme 테스트로 T020 통과를 확인한다.

**진행 점검**: T018~T022의 변경 파일과 검증 결과를 보고하고 패키지 5로 진행한다.

---

## 작업 패키지 5: Feature

**목표**: 링크 입력 키보드, 홈 카드 배치와 로딩 표시, 홈 진행 중 표시, 등록 흐름 대기 게이트,
공유 링크 초기값을 구현한다.

**소유 경로**: `sources/Projects/Feature/ProjectRegistration/`,
`sources/Projects/Feature/Home/`, `sources/Projects/Feature/Tests/`

**관련 변경 시나리오**: S1, S2, S3, S4, S5, S6

**독립 검증**: Feature는 Domain과 UI만 참조한다. `TestStore`로 reducer 동작을, 단위 테스트로
카드 배치 계산을 화면 렌더링 없이 검증한다(FR-023).

**선행 조건**: 패키지 0의 T001 분류가 확정되어야 한다. 이 단계의 대상 파일 다수에 커밋되지 않은
변경이 남아 있다.

### S1 — 링크 입력 키보드

- [X] T023 [S1] `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`의
      `linkInputContent`에 키보드 안전 영역 무시를 적용해, 키보드가 오르내려도 하단
      `ActionButton`의 화면 내 위치가 변하지 않게 한다(FR-001).
- [X] T024 [S1] `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`에
      `@FocusState`를 두고 T016의 포커스 인자로 `LabeledTextField`에 연결한 뒤, 배경 레이어
      터치로 포커스를 해제한다. 안내 패널 버튼·입력 지우기 버튼·액션
      버튼의 히트 테스트를 가로채지 않는다(FR-002~004).

### S5 — 첫 카드 기울기

- [X] T025 [S5] `sources/Projects/Feature/Tests/Home/Models/HomeCardScrollLayoutTests.swift`에
      기준 위치에서 각도가 정확히 0이고 기준 위치 좌우로 각도가 연속임을 확인하는 테스트를
      정리한다. T001에서 채택 여부가 정해진 기존 변경분을 함께 반영한다.
- [X] T026 [S5] `sources/Projects/Feature/Home/Screens/HomeScreen.swift`의 `projectCardScroll`에서
      카드 목록 콘텐츠 선행 가장자리 앵커를 카드 중심과 **같은 좌표 공간**에서 읽어
      `HomeCardScrollLayout`의 `p0CenterX`로 주입한다. `CardLayout.p0CenterX` 상수 기반 계산을
      제거해 좌표계 원점 가정을 없앤다(R-003, FR-021~022).

### S4 — 카드 로딩 표시

- [X] T027 [S4] `sources/Projects/Feature/Home/Screens/HomeScreen.swift`의 로딩·빈 상태 컨테이너
      높이를 실제 카드 영역과 같은 `cardHeight + verticalPadding * 2`로 고정하고, 빈 데크
      실루엣을 그 안에 원본 비율로 배치한다. 로딩 인디케이터 표시는 유지한다(R-004, FR-017~019).
      빈 목록 안내와 조회 실패 안내의 기존 표시는 그대로 보존한다(FR-020). T001에서
      `HomeEmptyDeckShape.swift`를 「되돌림」으로 분류하면 실루엣 도형 신규 작성이 이 작업
      범위에 포함된다.

### S2 — 홈 진행 중 표시

- [X] T028 [S2] `sources/Projects/Feature/Tests/Home/Reducers/`에 진행 중 입력을 받으면 등록
      진입이 차단되고 해제되면 복귀하는 테스트와, 진행 중에도 프로필 조회·카드 표시·전체 보기
      동작이 달라지지 않는 테스트를 추가한다(FR-005~007, FR-009).
- [X] T029 [S2] `sources/Projects/Feature/Home/Reducers/HomeFeature.swift`에
      `Input.generationProgressChanged(isInProgress:)`와 대응 상태 값을 추가하고, 진행 중에는
      `view(.projectRegistrationTapped)`가 `delegate(.projectRegistrationRequested)`를 보내지
      않게 한다(FR-005~007).
- [X] T030 [S2] `sources/Projects/Feature/Home/Screens/HomeScreen.swift`의 `registrationPanel`에
      진행 중 표기("문제 생성 중" 문구, 진행 인디케이터, 비활성 스타일)를 추가한다. 값은 Figma
      `1859:21645`를 근거로 한다(FR-006).

### S3 — 등록 흐름 대기 게이트

- [X] T031 [S3] `sources/Projects/Feature/Tests/ProjectRegistration/Reducers/ProjectRegistrationFeatureTests.swift`에
      준비 완료 시각 전 결과 도착 시 전이 보류, 준비 완료 시각 도달 시 전이, 이미 지난 뒤
      도착하면 즉시 전이, 실패도 같은 게이트를 따르는 테스트를 추가한다. 짧은
      `GenerationWaitPolicy`와 고정 `now`를 주입한다(FR-012, FR-013).
- [X] T032 [S3] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`에
      `waitPolicy: GenerationWaitPolicy`와 `now: @Sendable () -> Date` 생성자 인자를 추가하고,
      도착한 생성 결과를 상태에 보관했다가 준비 완료 시각에 완료 또는 실패로 전이하는 게이트를
      구현한다. 대기는 기존 `CancelID` 경계를 유지하는 취소 가능한 Effect로 둔다.
- [X] T033 [S3] `sources/Projects/Feature/ProjectRegistration/Screens/QuizGenerationProgressScreen.swift`가
      진행률 시뮬레이션 종료 후에도 마지막 단계를 진행 중 상태로 유지하고 완료 표시나 화면
      전환을 하지 않는지 확인하고, 필요한 경우에만 조정한다. 180~300초 무작위 구간 자체는
      변경하지 않는다(FR-013, 명확화 2).

### S6 — 공유 링크 초기값

- [X] T034 [S6] `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`의
      `State`에 `init(initialRepositoryURL: String = "")`을 추가한다. 값은 검증되지 않은 외부
      입력이므로 기존 검증 경로를 그대로 통과해야 한다(FR-025).

### 정리와 패키지 검증

- [ ] T035 [no-write] Feature scheme 테스트를 실행해 T025, T028, T031이 통과하는지 확인한다.

**진행 점검**: T023~T035의 변경 파일과 검증 결과를 보고하고 패키지 6으로 진행한다.

---

## 작업 패키지 6: Composition

**목표**: 진행 상태 저장소를 Domain 계약으로 연결하고, 완료 알림을 즉시 발송에서 예약 발송으로
바꾼다.

**소유 경로**: `sources/Projects/Composition/Adapter/`,
`sources/Projects/Composition/Tests/Adapter/`

**관련 변경 시나리오**: S2, S3

**독립 검증**: 가짜 `LocalNotificationClient`로 예약 시각·취소·중복 방지를 검증한다. Composition
scheme 테스트만으로 확인할 수 있다.

### 테스트

- [X] T036 [S3] `sources/Projects/Composition/Tests/Adapter/Factories/GenerationCompletionReminderCoordinatorTests.swift`에
      완료 결과 도착 시 `present`가 아니라 준비 완료 시각으로 `schedule`이 호출되고, 이미 지난
      시각이면 즉시 발송이며, 실패 결과에는 발송하지 않고, 같은 결과가 다시 와도 1회만
      예약되며, 알림 권한이 없으면 예약도 발송도 하지 않는 테스트를 갱신·추가한다
      (FR-010, FR-012, FR-014, FR-015, FR-016).

### 구현

- [X] T037 [S2] `sources/Projects/Composition/Adapter/Adapters/GenerationProgressRepositoryAdapter.swift`에
      Data의 `GenerationProgressStore`를 Domain의 `GenerationProgressRepository`로 잇는 어댑터를
      추가한다. 기존 `GenerationReminderRegistryAdapter`와 같은 형태를 따른다.
- [X] T038 [S3] `sources/Projects/Composition/Adapter/Factories/GenerationCompletionReminderCoordinator.swift`에서
      `GenerationProgressRepository`와 `GenerationWaitPolicy`를 생성자 인자로 추가하고,
      보존된 진행 상태의 `requestedAt`과 `GenerationWaitPolicy.readyDate(for:)`로 예약 시각을
      계산해 `schedule`로 발송한다. 즉시 `present` 호출을 제거하되 기존 `isAuthorized` 가드는
      유지한다.
- [X] T039 [S2] [S3] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`와
      `sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift`에
      `UserDefaultsStore`, `LocalGenerationProgressStore`, T037의 어댑터,
      `TrackGenerationProgress`를 조립하고 `trackGenerationProgress`를 공개한다. 같은 조립
      경로에서 T038이 새로 요구하는 두 인자를 코디네이터 생성 지점에 주입한다. 두 파일은 같은
      조립 경로라 함께 바꾸지만 모두 Composition 패키지 소유이므로 단일 패키지 단위다.

### 정리와 패키지 검증

- [X] T040 [no-write] Composition scheme 테스트로 T036 통과를 확인한다.

**진행 점검**: T036~T040의 변경 파일과 검증 결과를 보고하고 패키지 7로 진행한다.

---

## 작업 패키지 7: App (공유 확장 integration unit 포함)

**목표**: 진행 상태의 수명을 소유·복원해 홈에 전달하고, 공유 시트 진입 경로를 만든다.

**소유 경로**: `sources/Projects/App/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`

**관련 변경 시나리오**: S2, S3, S6

**독립 검증**: App scheme 테스트로 진행 상태 수명과 공유 링크 소비 규칙을 검증하고, 공유 시트
노출과 랜딩은 [quickstart.md](./quickstart.md) 시나리오 6 절차로 확인한다.

### 승인 필요

- [X] T041 App Group 식별자와 커스텀 URL 스킴 문자열을 확정받는다. 제안값은
      `group.com.nexters.hytime.gitit`과 `gitit`이다. 앱 서명 구성과 외부에 노출되는 식별자를
      새로 도입하는 결정이므로 확정 전에 T047 이후를 시작하지 않는다.

### S2 · S3 — 진행 상태 수명과 복원

- [X] T042 [S2] [S3] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에
      제출 성공 시 추적 시작, 준비 완료 시각까지 진행 중 유지, 결과 확정 후 해제, 앱 시작 시
      복원, 상한 초과 시 만료, 복원된 `projectID`가 학습 프로젝트 목록에 있으면 해제하는
      테스트를 추가한다(FR-005, FR-008, SC-010).
- [X] T043 [S2] [S3] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 진행 상태 수명을
      구현한다. 등록 제출 성공 시 `trackGenerationProgress.begin`, 준비 완료 시각까지 대기,
      결과 확정 시 `end`, 상태 변화를 `mainShell.home(.input(.generationProgressChanged(...)))`로
      전달, 앱 시작 시 `current()`로 복원한다(R-009).
- [X] T044 [S2] [S3] `sources/Projects/App/GitIt/Screens/AppRootView.swift`와
      `sources/Projects/App/GitIt/GitItApp.swift`에 `trackGenerationProgress`,
      `GenerationWaitPolicy`, `now` 주입 배선을 추가한다.

### S6 — 공유 진입 (integration unit)

**분리 불가 근거**: manifest에 target을 선언하지 않으면 확장 소스는 어떤 빌드 대상에도 속하지
않고, 소스 없이 target만 선언하면 `tuist generate` 후 빌드가 실패한다. App Group entitlement도
앱과 확장 양쪽에 동시에 존재해야 컨테이너 접근이 성립한다. T045~T050은 중간 상태가 컴파일되지
않으므로 하나의 커밋 단위로 묶는다.

**의존 순서**: manifest·entitlements(T045~T047) → 확장 소스(T048) → 앱 소비 경로(T049~T051).

- [X] T045 [S6] `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`에
      `product: .appExtension`인 공유 확장 target을 추가한다. enum case 이름은
      `ShareExtension`으로 두어 `sourceDirectory`가 `ShareExtension`으로 도출되게 하고,
      exhaustive switch인 `sourceDirectory`와 `target` 양쪽에 새 case 분기를 함께 추가한다.
      앱 target에는 확장 의존과 `CFBundleURLTypes`(T041의 스킴)를 등록한다.
- [X] T046 [S6] `sources/Projects/App/GitIt.entitlements`에 T041의 App Group을 추가한다.
- [X] T047 [S6] 확장용 entitlements 파일을 `sources/Projects/App/`에 추가하고 같은 App Group을
      선언한다. 파일명은 T045의 target 이름과 일치시킨다.
- [X] T048 [S6] `sources/Projects/App/ShareExtension/` 아래에 확장 소스와 `Info.plist`를
      추가한다. `NSExtensionActivationRule`을 URL 항목이 있는 공유로 한정하고(FR-024), 전달받은
      첫 번째 URL만 App Group 컨테이너에 기록한 뒤 커스텀 URL 스킴으로 컨테이너 앱을 연다.
      확장은 URL을 검증하지 않는다(FR-028, [contracts/share-entry.md](./contracts/share-entry.md)).
- [X] T049 [S6] `sources/Projects/App/GitIt/Models/SharedRepositoryLink.swift`에 공유 URL 1건을
      나타내는 값 타입을 추가한다.
- [X] T050 [S6] `sources/Projects/App/GitIt/GitItApp.swift`에 URL 스킴 수신 경로를 추가하고,
      App Group 컨테이너에서 값을 읽는 즉시 컨테이너에서 삭제한다(R-011).
- [X] T051 [S6] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 공유 링크 소비
      규칙을 구현한다. 인증 완료 후 `ProjectRegistrationFeature.State(initialRepositoryURL:)`로
      전달, 미인증이면 진입 흐름 완료까지 메모리에 보관, 생성 진행 중이면 폐기하고 홈의 진행 중
      상태를 표시, 1회만 소비(FR-025~027).
- [X] T052 [S6] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 공유 링크
      소비 규칙 테스트를 추가한다. 인증 완료 후 전달, 진행 중 폐기, 1회 소비 후 재사용되지
      않음을 확인한다.

### 정리와 패키지 검증

- [ ] T053 [no-write] `tuist generate`를 다시 실행한 뒤 App scheme 테스트로 T042, T052 통과를
      확인한다. 생성 산출물은 `.gitignore` 대상이라 추적 파일을 바꾸지 않는다. 실행 전후
      `git status`를 비교해 추적 파일 변경이 없는지 확인한다.

**진행 점검**: T041~T053의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 진행한다.

---

## 전체 완료 검증

**선행 조건**: 패키지 7의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할 마지막
커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 패키지 7의 마지막 커밋 단위에 배정한다. 모든 검증과
필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다. 읽기 전용 전체 검증은 반복
승인 없이 같은 실행에서 이어서 수행한다.

- [X] T054 [no-write] `make tuist`로 파생 workspace·project를 갱신하고, 실행 전후 `git status`를
      비교해 추적 파일 변경이 없는지 확인한다. 추적 파일이 바뀌면 완료로 처리하지 않는다.
- [ ] T055 [no-write] 아래를 순차 실행하고 결과를 기록한다. 세 명령은
      `sources/DerivedData/PreCommit`을 공유하므로 병렬 실행하지 않는다.
      `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`
      실행 후 `build` → `compile` → `test`.
- [ ] T056 [no-write] [S1] [S2] [S3] [S4] [S5] [S6] [quickstart.md](./quickstart.md)의 수동 검증
      절차로 시나리오 1~6의 독립 수용 기준을 확인한다. 시간 의존 항목은 짧은
      `GenerationWaitPolicy`를 주입한 구성으로 확인한 뒤 기본값으로 1회 재확인한다.
- [X] T057 [no-write] 홈 프로필 영역이 프로필 데이터와 무관하게 기존 고정 기본 아바타를
      유지하는지 확인한다(FR-030). 코드 변경 없이 회귀만 확인한다.

## 의존성과 실행 순서

### 실행 단위 순서와 근거

채택한 순서는 [아키텍처 문서 3.1](../../docs/architecture.md)의 의존성 표에서 도출한 위상
순서다. `A → B`는 A가 B를 빌드 의존성으로 참조한다는 뜻이며, 피의존 패키지를 먼저 구현한다.

```text
패키지 0 (소유권 확정, 파일 변경 없음)
        ↓
패키지 1 Domain   패키지 2 Infrastructure   패키지 3 UI      (내부 의존 없음)
        ↓                    ↓
                    패키지 4 Data            (→ Infrastructure)
        ↓                    ↓
패키지 5 Feature (→ Domain, UI)     패키지 6 Composition (→ Domain, Data, Infrastructure)
                    ↓
            패키지 7 App (→ Feature, Composition, Domain)
```

- 패키지 1·2·3은 서로 의존하지 않는다. Domain을 먼저 둔 이유는 패키지 5와 6이 모두
  `GenerationWaitPolicy`를 참조하기 때문이다.
- 패키지 5(Feature)와 6(Composition)은 서로 의존하지 않는다. Feature를 먼저 둔 이유는 S1·S4·S5가
  다른 패키지 없이 완결되어 사용자에게 보이는 결과를 먼저 확보하기 때문이다. 이 상대 순서는
  구현이 끝날 때까지 바꾸지 않는다.
- 패키지 0은 파일을 바꾸지 않지만, 이후 단위의 staging 범위를 정하므로 가장 먼저 둔다.

### 위험 기반 승인

아래 두 지점에서만 중단하고 명시적 승인을 요청한다. 그 외 단위는 확정된 기능 범위의 후속
작업이므로 반복 승인 없이 진행한다.

| 작업 | 이유 |
| --- | --- |
| T001 | 사용자 소유의 커밋되지 않은 변경을 이 명세의 커밋이 소비할지 결정한다 |
| T003 | 명세가 값을 정하지 않은 보존 상한을 새로 정한다 |
| T041 | 앱 서명 구성과 외부 노출 식별자를 새로 도입하는 제품 결정이다 |

### 변경 시나리오 추적성

| 시나리오 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| S1 링크 입력 키보드 | T016, T017, T023, T024 | 키보드를 올려도 하단 버튼 위치가 변하지 않고, 빈 영역 터치로 닫히며 기존 조작이 살아 있다 |
| S2 홈 진행 중 표시 | T004~T007, T009, T011, T018~T022, T028~T030, T037, T039, T042~T044 | 생성 중 홈에서 새 불러오기를 시작할 수 없고, 결과 확정과 앱 재실행 후 상태가 올바르다 |
| S3 알림·화면 대기 게이트 | T003, T008, T010, T013~T015, T031~T033, T036, T038, T039, T042~T044 | 요청 후 300초 전에는 알림도 화면 전이도 일어나지 않고, 세 시점이 함께 발생한다 |
| S4 카드 로딩 표시 | T027 | 로딩 중과 로딩 후 카드 영역 높이가 같아 아래 요소가 이동하지 않는다 |
| S5 첫 카드 기울기 | T025, T026 | 정지 상태의 첫 카드 기울기가 정확히 0이고 각도 함수에 불연속이 없다 |
| S6 공유 진입 | T034, T041, T045~T052 | URL 공유에서만 앱이 노출되고, 링크 입력 화면이 그 URL로 채워진 채 열린다 |

FR-030(항목 8)은 코드 변경 작업이 없고 T057의 회귀 확인만 대응한다.

### 실행 단위 내부 실행

- 테스트를 포함한 단계는 같은 패키지 구현 전에 테스트를 작성하고 예상한 이유로 실패하는지
  확인한다(T008·T009 → T010·T011, T020 → T021, T028 → T029, T031 → T032, T036 → T038).
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용한다.
- 같은 파일을 바꾸는 작업은 순차 실행한다. 특히 `HomeScreen.swift`(T026, T027, T030),
  `ProjectRegistrationFeature.swift`(T032, T034), `AppRootFeature.swift`(T043, T051)는 병렬
  실행하지 않는다.
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 패키지의 미완료 작업을 하나의 목적과 독립적인
  rollback 경계를 갖는 순서화된 커밋 단위로 묶는다. 구현과 직접 관련된 테스트는 같은 단위에 둘
  수 있지만 기능, 구조 정리, rename과 자동 포맷은 목적이 다르면 분리한다.
- 각 커밋 단위는 포함 작업 ID, 정확한 파일 경로, 검증과 커밋 메시지를 먼저 제시한다. 단위의
  검증과 `[X]` 표시를 완료한 뒤 해당 파일과 이 `tasks.md`만 stage·commit하고, 커밋 성공을
  확인하기 전에는 다음 단위를 시작하지 않는다.
- 단위를 시작할 때 작업 ID와 파일 경로를 snapshot하며, T002가 확정한 제외 목록을 그 snapshot에
  적용한다. Commit 성공 뒤 단위 경로와 tasks.md에 staged·unstaged 잔여가 없어야 다음 단위로
  진행할 수 있다. 제외 목록의 경로는 잔여로 남는 것이 정상이다.
- 패키지 7의 마지막 단위는 전체 완료 검증과 필수 `after_implement` hook이 끝날 때까지
  commit하지 않는다.

### 현재 실행 단위 내부 병렬 실행 예시

패키지 1(Domain) 준비 단계:

```text
T005 GenerationProgressRepository.swift
T006 TrackGenerationProgressUseCase.swift
```

T004 완료 후 서로 다른 파일이라 동시에 진행할 수 있다.

패키지 1 테스트 단계:

```text
T007 StubGenerationProgressRepository.swift
T008 GenerationWaitPolicyTests.swift
```

패키지 4(Data) 준비 단계:

```text
T018 GenerationProgressDTO.swift
T019 GenerationProgressStore.swift
```

다른 패키지의 작업과는 병렬 실행하지 않는다.

## 구현 전략

1. 중단 단위와 tasks.md 전체 diff를 분류하고 blob hash와 diff를 기준선으로 고정한다. 재개
   단위가 없으면 패키지 0부터 시작한다.
2. 선택한 실행 단위의 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다. 패키지 7의
   마지막 단위는 전체 완료 검증과 필수 hook까지 열린 상태로 유지한다.
4. 단위가 커밋되면 변경 파일, 검증 결과와 커밋을 진행 상황으로 보고하고 같은 범위의 다음
   단위로 이어간다.
5. T001, T003, T041에서만 중단하고 명시적 승인을 요청한다.
6. 패키지 7에서 전체 읽기 전용 검증과 시나리오 수용 검증, 필수 `after_implement` hook을
   실행하고 결과를 재검증한 뒤 마지막 단위를 최종 commit한다.

### 최소 가치 범위

S1(링크 입력 키보드)이 가장 작은 완결 범위다. 패키지 3의 T016~T017과 패키지 5의 T023~T024
네 작업으로 완결되며 다른 시나리오에 의존하지 않는다. S4와 S5도 패키지 5 안에서 완결된다.

다만 이 순서에서 S1·S4·S5는 **가장 먼저 완료되지 않는다.** 위상 순서를 우선해 Domain·
Infrastructure·Data를 앞에 두었기 때문에 패키지 5에 도달해야 세 시나리오가 끝난다. 사용자에게
보이는 결과를 더 이른 시점에 확보해야 하면 UI와 Feature의 국소 작업(T016~T017, T023~T027)을
앞선 별도 단위로 분리할 수 있으나 작업 ID 재배치가 필요하므로 구현 시작 전에 결정한다.
세 시나리오 모두 새 권한을 요구하지 않으므로 승인 없이 연속 진행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 모두 정확한 저장소 상대 경로를 포함한다.
- 변경 시나리오의 독립성은 유지하되 구현 단위는 논리적 실행 단위다.
- 커밋 단위는 단일 패키지가 기본이며, 공유 확장(T045~T052)만 불가분한 다중 파일 단위다.
- 문제 해결과 암묵지 기록은 구현 작업 ID로 만들지 않는다. 조건이 발생하면 각 전용 기록 스킬을
  별도로 사용한다.

---

## 단계 8: 수렴

**근거**: `/speckit-clarify` 세션 2026-09-02이 공유 진입의 검증 소유자(FR-028, FR-029)와 랜딩
후 "다음" 자동 실행(FR-025a)을 확정했고, `/speckit-plan` 2026-09-02 개정이 R-013·R-014로
반영했다. 아래는 현재 코드와 그 확정 사이의 차이만 담는다.

**실행 단위 순서**: Feature → App(통합). 두 단위는 파일이 겹치지 않아 상호 의존은 없지만,
활성 tasks.md가 확정한 위상 순서(Feature 이전, App 이후)를 그대로 따른다.

### 작업 패키지: Feature

- [X] T058 [S6] `ProjectRegistrationFeature`에 View lifecycle case `task`를 추가하고,
      `State.init(initialRepositoryURL:)`이 비어 있지 않은 값을 받을 때 1회용 자동 실행
      표식을 세우며, `task` 수신 시 그 표식을 소비해 `validateTapped`와 같은 내부 시작
      경로로 검증을 시작하도록
      `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`를
      수정한다. per FR-025a, R-013 (missing)
- [X] T059 [S6] 링크 입력 화면이 표시될 때 `task`를 보내도록
      `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`의
      `linkInputContent`를 수정한다. 화면은 자동 실행 여부를 판단하지 않는다. per FR-025a,
      S6/AC2 (missing)
- [X] T060 [P] [S6] 초기값이 있으면 `task`에서 검증이 1회 시작되고, 빈 초기값이면 시작되지
      않으며, `task`를 두 번 보내도 1회만 시작되는지 검증하는 테스트를
      `sources/Projects/Feature/ProjectRegistration/Tests/ProjectRegistrationFeatureTests.swift`에
      추가한다. per quickstart 자동 테스트 표, FR-025a (missing)

#### 정리와 패키지 검증

- [ ] T061 [no-write] Feature scheme의 `ProjectRegistration` 테스트로 T060과 기존
      `ProjectRegistrationFeatureTests`가 모두 통과하는지 확인하고 결과를 보고한다.

### 작업 패키지: App (공유 확장 integration unit)

**분리 불가 근거**: 확장 소스가 `DataExternalRepository`를 import하는 상태에서 manifest의
의존성 선언만 제거하면 `tuist generate` 후 빌드가 실패하고, 반대로 소스에서 참조만 지우면
사용되지 않는 의존성이 남아 계획 결정(R-014)을 만족하지 못한다. 중간 상태가 컴파일되지
않거나 의도를 어기므로 두 파일을 하나의 단위로 변경한다.

**통합 검증**: `make tuist` 이후 App scheme 빌드. 전체 검증은 아래 「전체 수렴 완료 검증」에서
한 번 수행한다.

- [ ] T062 [S6] `firstRepositoryURL()`이 URL 항목의 첫 번째 값을 형식과 무관하게 반환하도록
      바꾸고 `GitHubRepositoryURLParser` 사용과 `DataExternalRepository` import를 제거하도록
      `sources/Projects/App/ShareExtension/ShareViewController.swift`를 수정한다. per FR-028,
      FR-029, S6/AC6 (contradicts)
- [ ] T063 [S6] `ShareExtension` target의 `dependencies`에서
      `.fromData(.DataExternalRepository)`와 관련 주석을 제거해 확장이 프로젝트 내부 패키지를
      참조하지 않도록
      `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`를 수정한다.
      per plan: R-014 (contradicts)

#### 정리와 패키지 검증

- [ ] T064 [no-write] `make tuist`로 파생 workspace·project를 갱신하고, 실행 전후
      `git status`를 비교해 추적 파일 변경이 없는지 확인한 뒤 App scheme 빌드가 성공하는지
      확인하고 결과를 보고한다. 추적 파일이 바뀌면 완료로 처리하지 않는다.

### 전체 수렴 완료 검증

**커밋 경계**: 아래 `[no-write]` 작업은 이 수렴 단계의 마지막 커밋 단위에 배정한다. 모든
검증과 필수 `after_implement` hook을 마친 뒤 그 단위를 최종 commit한다. 반복 승인 없이 같은
실행에서 이어서 수행한다.

- [ ] T065 [no-write] `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)`
      실행 후 `build` → `compile` → `test`를 순차 실행하고 결과를 기록한다. 세 명령은
      `sources/DerivedData/PreCommit`을 공유하므로 병렬 실행하지 않는다.
- [ ] T066 [no-write] [S6] [quickstart.md](./quickstart.md) 시나리오 6의 수동 절차로 (1) 공유
      선택 후 추가 조작 없이 "다음"이 1회 자동 실행되는지, (2) 뒤로 돌아와도 재실행되지
      않는지, (3) 일반 웹페이지 URL 공유 시 링크 입력 화면에 검증 실패 안내가 표시되는지를
      확인한다. per FR-025a, FR-028, FR-029, SC-008
