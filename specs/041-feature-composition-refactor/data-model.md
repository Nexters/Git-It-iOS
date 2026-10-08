# 데이터 모델: 기능·상태 단위 Feature 분해와 화면 Feature 합성

**기능**: [spec.md](./spec.md) · **조사**: [research.md](./research.md)

이 기능은 영속 데이터를 다루지 않는다. 이 문서의 "모델"은 두 가지다.

1. 분해 작업이 다루는 **분류 엔터티**(명세 "핵심 엔터티"의 구체화)
2. 새로 추출하는 **기능 Feature의 State 모델**

공개 입력과 delegate는 [contracts](./contracts/feature-composition-contracts.md)가 소유한다. 상태
표현 규칙은 [TCA State 컨벤션](../../docs/conventions/tca/state.md)을 따른다.

---

## 1. 분류 엔터티

### 1.1 Reducer 분류 기록

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `reducer` | 타입 이름 | Feature 패키지 비테스트 소스의 `@Reducer` 선언 하나 |
| `path` | 저장소 상대경로 | [research.md §2](./research.md#2-공용-경계의-배치-fr-022)의 배치 규칙을 만족한다 |
| `classification` | `기능` \| `화면 합성` \| `전환 계층` | 정확히 하나다(FR-018, SC-007). 판정 기준은 [research.md §1](./research.md#1-분해-기준-fr-001-fr-017-fr-018)이다 |
| `concerns` | 관심사 ID 목록 | `기능`은 정확히 1개다. `화면 합성`·`전환 계층`은 자신이 선언하는 관심사가 0개이고, 합성하는 자식만 참조한다 |
| `children` | Reducer 목록 | `화면 합성`은 1개 이상의 `기능`이다. `전환 계층`은 화면·기능 Feature다 |

**불변식**

- 어떤 관심사 ID도 둘 이상의 `기능` 기록에 나타나지 않는다(FR-003, SC-001).
- `화면 합성` 기록의 State에는 관심사 상태 유형이 없다(SC-008).
- 경로 참조 방향: 전환 계층 → 화면 → `Feature/Shared/**`. 화면 디렉터리 간 참조는 없다(SC-010).
- 공용 디렉터리(`Shared/Reducers/`)에 View 타입이 없다(SC-015).

### 1.2 기능 관심사

| 필드 | 타입 | 규칙 |
| --- | --- | --- |
| `id` | `I1`~`I4`, `I2′`, `S1`~`S4`, `R1`, `R2` | [research.md §3](./research.md#3-전수-식별-결과-fr-015-fr-016-fr-018) |
| `stateModel` | State 타입 | 아래 §2의 모델 |
| `transitionRules` | 입력 → 상태 변화 목록 | 계약 문서의 표 |
| `dependencies` | 클로저 목록 | 그 관심사가 실제로 호출하는 Use Case subset만(FR-004, FR-024) |
| `owner` | Reducer | 정확히 하나 |
| `composedBy` | Reducer 목록 | 둘 이상 흐름이면 `Feature/Shared/Reducers/`에 둔다(FR-022) |

### 1.3 제외 판정 기록

| 필드 | 규칙 |
| --- | --- |
| `id` | `E1`~`E8` |
| `locations` | 후보가 선언된 Reducer와 필드 |
| `reason` | 상태 모델 차이, 전이 규칙 차이 또는 비용 비교 중 하나 이상을 명시한다(FR-016, FR-017) |

### 1.4 동작 차이 기록 (FR-008)

| 필드 | 규칙 |
| --- | --- |
| `concern` | 관심사 ID |
| `before` / `after` | 화면에서 관찰되는 동작 문장 |
| `screens` | 영향받는 화면 |
| `verifiedBy` | 차이를 고정하는 테스트 이름 |

### 1.5 단언 이관 기록 (SC-011)

| 필드 | 규칙 |
| --- | --- |
| `unit` | 작업 단위 ID |
| `before` | 이관 전 `파일 › @Test 이름` |
| `after` | 이관 뒤 `파일 › @Test 이름` |
| `kind` | `기능 Feature 테스트` \| `합성 지점 검증` \| `중복 제거(대체 테스트 명시)` |

이관 전 테스트 하나당 기록이 하나 이상 있어야 한다. `after`가 비어 있는 기록은 허용하지 않는다.

---

## 2. 추출 기능 Feature의 State 모델

모든 State는 `@ObservableState`, `Sendable`, `Equatable`이다. 요청을 교체할 수 있는 관심사는
request identity를 보존한다. 타입은 기존 선언을 옮기는 것을 우선하고, 이름은 관심사를 드러내게
짓는다. 중첩 타입이 여럿이면 `{상위타입}+{중첩타입}.swift`로 분할한다
([중첩 타입 분할](../../docs/conventions/file-vocabulary/nested-type-split.md)).

### 2.1 `UserProfileLoadFeature` (I1) — `Feature/Shared/Reducers/`

| 필드 | 타입 | 출처 |
| --- | --- | --- |
| `load` | `Load` = `idle` \| `loading` \| `loaded(UserProfile)` \| `failed(UserInfoError)` | `HomeFeature.State.ProfileLoad`·`ProfileFeature.State.ProfileLoad` 통합 |
| `requestID` | `Int` | `profileRequestID` |

- 전이: `load` → `.loading`, `requestID += 1`. `reload`는 `loaded`면 상태를 유지한 채
  `requestID += 1`로 재조회하고, `loading`이면 무시하며, 그 밖에는 `load`와 같다. 결과는
  `requestID`가 일치할 때만 반영한다. 성공은 `.loaded`로 바꾼다. 실패는 현재 상태가 `loaded`이면
  무시하고(조용한 재조회의 실패), 아니면 `.failed`로 바꾼다. `replace(p)` → `.loaded(p)`,
  `requestID += 1`, 진행 중 조회를 취소한다.
- 조용한 재조회 여부는 결과 도착 시점의 상태(`loaded`)로 판별되므로 별도 플래그를 저장하지 않는다
  ([정본과 파생값](../../docs/conventions/tca/state/source-of-truth.md)).
- 파생값(`profile: UserProfile?`)은 computed로 둔다. `SettingsFeature.profile` 저장 필드는 제거한다.

### 2.2 `ProjectSummaryListFeature` (I2) — `Feature/Shared/Reducers/`

| 필드 | 타입 | 출처 |
| --- | --- | --- |
| `load` | `Load` = `idle` \| `loading` \| `loaded(ProjectList)` \| `failed(ProjectError)` | `HomeFeature.State.ProjectLoad`. ProjectList의 `projects`·`hasNextPage`·`initialLoad`는 이 값에서 파생 |
| `requestID` | `Int` | `projectRequestID` / `requestID` |

- 전이: 새로고침 시작 → `loaded`가 아니면 `.loading`. `projectsReceived(list)`는 `list.isLoaded`일
  때만 `.loaded(list)`로 바꾸고 `listUpdated` delegate를 보낸다. `refreshFinished(error)`는
  `requestID`가 일치하고 `loaded`가 아닐 때만 `.failed`. `projectRemoved(id)`는 `loaded` payload에서
  행을 제거하고 `listUpdated` delegate를 보낸다.

### 2.3 `ProjectDeletionFeature` (I3) — `Feature/Shared/Reducers/`

| 필드 | 타입 |
| --- | --- |
| `deletion` | `Deletion` = `idle` \| `confirming(ProjectID)` \| `committing(ProjectID)` \| `failed(ProjectID, ProjectError)` |

- 전이는 [research.md §4 I3](./research.md#i3-프로젝트-삭제)과 같다. `ProjectListFeature.mode`와
  `ProjectDetailFeature.isMenuPresented`는 화면 고유 표시 상태로 각 화면에 남는다.

### 2.4 `SignInFeature` (I4) — `Feature/Shared/Reducers/SignInFeature/`

| 필드 | 타입 | 출처 |
| --- | --- | --- |
| `phase` | `Phase` = `idle` \| `checkingConsent` \| `agreeingToPolicies` \| `signingIn` \| `cancelled` \| `failed` | `GuestSignInFeature.Phase` + Tutorial의 `cancelled` |
| `legalAgreement` | `LegalAgreementFeature.State` | 자식(항상 보유) |
| `requestID` | `Int` | 두 곳의 `requestID` |

- 파생: `isLegalAgreementPresented`(`phase == .agreeingToPolicies`), `isSigningIn`, `isFailed`,
  `isCancelled`.
- `TutorialFeature`에 남는 것: `page`, `bundleVersion`, `hasAttemptedCompletedAccountReset`,
  `accountReset: idle | resetting`(재설정 후속 동작 진행 표시).

### 2.5 화면 고유 분리 Feature

| Feature | 배치 | 필드(기존 선언에서 이동) |
| --- | --- | --- |
| `ProjectListPaginationFeature` (I2′) | `ProjectList/` | `pagination: idle \| loading \| failed(ProjectError) \| exhausted` |
| `CurationUpdateFeature` (S1) | `Settings/Settings/` | `positionMutation`, `careerLevelMutation` (`MutationStatus`) |
| `AccountActionFeature` (S2) | `Settings/Settings/` | `accountAction: idle \| signingOut \| confirmingDeletion \| deletingAccount \| failed(UserInfoError)` |
| `NotificationPermissionFeature` (S3) | `Settings/Settings/` | `notificationStatus: idle \| allowed \| denied` |
| `ProjectDetailLoadFeature` (S4) | `ProjectDetail/` | `projectID`, `detail: ProjectDetail?`, `loadStatus`, `requestID`. 파생 `firstIncompleteSet`, `isResumeEnabled`, `isEmpty` |

### 2.6 전환 계층 반납 Feature

| Feature | 배치 | 필드(기존 선언에서 이동) |
| --- | --- | --- |
| `LearningSessionFeature` (R1) | `Quiz/Router/` | `learningSet: QuizSet?`, `currentQuestionIndex`, `resumption: LearningSetResumption?`, `sessionCorrectChoiceCount`, `bookmarkedQuestionIDs` |
| `SharedRepositoryRegistrationFeature` (R2) | `ShareRegistration/` | `sharedURL: String?`, `phase: validating \| ready(ExternalRepository) \| invalidURL(reason:) \| signInRequired \| appLaunchRequired \| submitting \| succeeded \| failed(reason:, retry: RetryTarget)` |

- `ShareRegistrationFeature`에 남는 것: 단계 값 `step: repositoryConfirmation | quizLevelSelection |
  quizGenerationConfirmation`, 단계 자식 State 3개, `registration` 자식 State. `canDismiss`·`canRetry`는
  자식 `phase`에서 파생한다.
- `QuizRouterFeature`에 남는 것: `activeScreen`, `screenTransitions`, 자식 State(`learningSetIntro`,
  `questionSolving?`, `learningCompletion`, `session`).

---

## 3. 상태 전이 요약 (기능 Feature 간 관계)

```text
HomeFeature ─┬─ UserProfileLoadFeature
             └─ ProjectSummaryListFeature
ProfileFeature ── UserProfileLoadFeature
SettingsFeature ─┬─ UserProfileLoadFeature
                 ├─ CurationUpdateFeature ──(updated)──▶ SettingsFeature ──(replace)──▶ UserProfileLoadFeature
                 ├─ AccountActionFeature
                 └─ NotificationPermissionFeature
ProjectListFeature ─┬─ ProjectSummaryListFeature ──(listUpdated)──▶ ProjectListFeature ──▶ ProjectListPaginationFeature
                    ├─ ProjectDeletionFeature ──(deleted)──▶ ProjectListFeature ──(projectRemoved)──▶ ProjectSummaryListFeature
                    └─ ProjectListPaginationFeature
ProjectDetailFeature ─┬─ ProjectDetailLoadFeature
                      └─ ProjectDeletionFeature
TutorialFeature ── SignInFeature ── LegalAgreementFeature
MainShellRouterFeature ─┬─ SignInFeature ── LegalAgreementFeature
                        └─ SingleQuestionEntryFeature
QuizRouterFeature ── LearningSessionFeature
ShareRegistrationFeature ── SharedRepositoryRegistrationFeature
```

같은 기능 Feature를 여러 화면이 합성해도 인스턴스는 화면마다 독립적이다(FR-026). 한 화면의 상태
변화는 다른 화면에 반영되지 않는다.
