# 조사: 기능·상태 단위 Feature 분해와 화면 Feature 합성

**기능**: [spec.md](./spec.md) · **계획**: [plan.md](./plan.md)

**기준 커밋**: `feature/feature-composition-refactor` HEAD (`bb6f073` 이후 작업 트리)

이 문서는 시나리오 1의 산출물(FR-015)이다. 분해 기준(§1), 공용 경계의 배치(§2), 비테스트 `@Reducer`
29개의 전수 식별과 통합·제외 판정(§3), 정본 동작 선택과 그로 인한 동작 차이(§4, FR-008),
작업 단위(§5), 단언 이관 대응표의 자리(§6)를 담는다. 통합이 완료되면 §1·§3·§4의 확정본을
`docs/conventions/tca/feature.md`와 `docs/conventions/tca/feature/classification.md`로
옮긴다(FR-020). 이 문서는 확정 전의 중간 산출물이다.

---

## 1. 분해 기준 (FR-001, FR-017, FR-018)

### 결정

Feature 패키지의 모든 Reducer를 다음 세 분류 중 **정확히 하나**로 판정한다. 판정은 이름이 아니라
State·Action·`body`의 실제 내용으로 한다.

| 분류 | 판정 조건 | 소유할 수 있는 것 | 소유하지 않는 것 |
| --- | --- | --- | --- |
| **기능 Feature** | 자식 Feature를 합성하지 않거나 기능 Feature만 합성하고, State가 하나의 관심사([관심사 판별](../../docs/conventions/tca/feature/definition-unit.md#관심사-판별))에 속한다 | 그 관심사의 상태 유형·전이 규칙·Effect·delegate | View(FR-027), 합성한 화면에 따른 분기(FR-005), 화면 전환 목적지 |
| **화면 합성 Feature** | 하나의 Screen에 대응하고 기능 Feature를 하나 이상 자식으로 합성한다 | 표시 범위(표시 전용 플래그·alert 표시 여부), 자식 결과에 대한 화면 고유 후속 동작, 상위로 올리는 delegate | 기능 관심사의 상태 유형(SC-008), 자식 내부 상태의 직접 변경(FR-006) |
| **전환 계층** | [Router-Feature](../../docs/conventions/tca/navigation/router.md) 또는 Shell로서 전환 컨텍스트 하나를 소유한다 | 활성 화면 값, 이동 이벤트, 자식 State 보유·생성, 자식 delegate 해석 | 기능 관심사의 상태 유형(시나리오 3-4), 자식 내부 필드의 직접 변경 |

보조 규칙은 다음과 같다.

1. **관심사 하나만 가진 화면의 Feature는 기능 Feature다.** 화면이 그 Feature의 store를 직접
   관찰한다. 감싸기만 하는 화면 합성 Feature를 새로 만들지 않는다(조합 깊이 자체가 목적이
   아니다, [Feature 조합](../../docs/conventions/tca/feature/composition.md)).
2. **자식을 합성하는 순간 그 Feature는 화면 합성 Feature나 전환 계층이다.** 이때 자기 화면만
   쓰는 관심사를 함께 들고 있으면, 그 관심사를 같은 화면 폴더의 기능 Feature로 분리한다(SC-008).
3. **화면 고유 후속 동작은 관심사가 아니다.** 자식의 결과를 받아 실행하는 한 번의 후속
   Effect는 화면 합성 Feature에 남는다(시나리오 3-2). 예: 로그인 성공 뒤 개발용 계정 재설정.
4. **같은 관심사의 판정 근거는 상태 모델과 전이 규칙의 동일성이다(FR-017).** 이름·화면
   유사성이나 "load/failed/retry" 같은 패턴 유사성은 근거가 아니다. 전이 규칙의 차이가
   재시도 조건·실패 표시 범위 같은 **정책 차이**이면 정본을 골라 통합하고 차이를 §4에
   기록한다. 상태 모델 자체나 호출하는 Use Case가 다르면 같은 관심사로 보지 않는다.
5. **통합 비용이 중복 유지 비용보다 크면 제외하고 사유를 남긴다(FR-016).**

### 근거

- [TCA 컨벤션 — 정의 단위](../../docs/conventions/tca/feature/definition-unit.md)가 이미 관심사를
  정의 단위로 정했고, 화면 없는 Feature와 Router-Feature를 정상 형태로 인정한다. 이 기준은 그
  규칙을 "어느 쪽으로 분류되는가"라는 판정 질문으로 바꾼 것이다.
- 보조 규칙 1이 없으면, 관심사 하나짜리 화면(예: `CareerSelectionFeature`)마다 빈 래퍼
  Feature가 생긴다. 이는 [테스트 검증 기준](../../docs/conventions/tca/feature/test-validation.md)의
  "테스트가 성립하지 않는 분리" 신호에 해당한다.
- 명세 명확화에 따라 분류는 이름이 아니라 컨벤션 문서와 디렉터리 위치로 표현한다(FR-025).

### 검토한 대안

- **화면마다 화면 합성 Feature를 반드시 둔다**: 관심사 하나짜리 화면에서 의미 없는 층이
  생기고 테스트가 중복되어 기각했다.
- **"load/failed/retry" 패턴 공용 Feature 도입**: 오류 타입·payload·도메인이 달라 제네릭
  상태 기계가 된다. 관심사가 아니라 구현 패턴의 공유이므로 기각했다(§3의 E3).

---

## 2. 공용 경계의 배치 (FR-022)

### 결정

| 사용 범위 | 배치 | 예 |
| --- | --- | --- |
| 한 화면만 합성 | 그 화면 폴더 루트 (`Feature/<흐름>/<화면>/`) | `Settings/Settings/AccountActionFeature.swift` |
| 한 전환 계층만 합성 | 그 흐름의 `Router/` | `Quiz/Router/LearningSessionFeature.swift` (선례: `Onboarding/Router/OnboardingExitFeature.swift`) |
| 같은 흐름의 둘 이상 화면 | `Feature/<흐름>/Shared/Reducers/` | 이번 식별 결과에는 해당 없음 |
| 둘 이상 흐름 | `Feature/Shared/Reducers/` | `UserProfileLoadFeature`, `SignInFeature/` |
| 둘 이상 흐름이 쓰는 값 타입 | `Feature/Shared/Models/` | `MainShellAccess` |

- 참조 방향은 **전환 계층 → 화면 → 공용**의 단방향이다. `Feature/Shared/**`는 흐름 디렉터리의
  타입을 참조하지 않는다.
- 공용 디렉터리(`Shared/Reducers/`)에는 View를 두지 않는다(FR-027, SC-015). 기능 상태를
  렌더링하는 View는 그 기능 Feature를 합성한 화면 폴더에 남는다. 예를 들어
  `LegalAgreementScreen`은 `Onboarding/LegalAgreement/`에 남고, `MainShellRouter` View는 전환
  계층이므로 이를 참조할 수 있다.
- 한 파일을 넘는 기능 Feature는 타입 패밀리 폴더를 만든다(`Feature/Shared/Reducers/SignInFeature/`,
  [타입 패밀리 규칙](../../docs/conventions/directory-file/type-family-rules.md)).
- 테스트는 같은 축으로 미러링한다: `Tests/Shared/Reducers/<Feature>Tests.swift`.
- `Reducers/`는 [형태 어휘 표](../../docs/conventions/file-vocabulary/shape-vocabulary.md)에 Feature
  패키지용으로 없다. [shape-rules](../../docs/conventions/directory-file/shape-rules.md)에 따라 같은
  PR에서 표에 `Feature/Shared/` 행(`Views/`·`Models/`·`Reducers/`)과 `Feature/<흐름>/Shared/`의
  `Reducers/`를 추가하고, [feature-layout](../../docs/conventions/directory-file/feature-layout.md)에
  배치 규칙을 추가한다(단위 U1).

### 근거

- `Feature/Shared/`는 [관심사 세그먼트](../../docs/conventions/directory-file/concern-segment.md)
  자리로 이미 허용되어 있고(`Feature/Shared/Views/FeedbackActionButton.swift` 선례), 그 아래는
  형태 폴더다. Reducer는 "선언이 코드에서 맡는 종류"로 판정되는 형태이며, App 패키지가 이미
  `Reducers/` 어휘를 쓴다.
- 기존 관행인 "한 흐름의 화면 폴더에 두고 다른 흐름이 참조"(`ProjectDetail/SingleQuestionEntry`를
  `MainShellRouterFeature`가 참조)는 화면 없는 Feature를 화면 폴더에 둔다는 점에서
  [feature-layout](../../docs/conventions/directory-file/feature-layout.md)의 "화면 폴더는 Screen
  하나와 그 Feature"와 어긋난다.

### 검토한 대안

- **관심사별 새 흐름 폴더(`Feature/Profile/`)**: 흐름 폴더는 화면이나 Router를 전제한다.
  화면 없는 흐름이 늘어나 흐름의 의미가 흐려지므로 기각했다.
- **`Feature/Shared/Features/`**: "Feature"는 패키지 이름과 겹쳐 폴더 자리에서 모호하다. App이
  이미 쓰는 `Reducers/`로 통일했다.
- **Feature target 분리**: 명세 가정과 FR-022가 단일 target 유지를 요구하므로 기각했다.

---

## 3. 전수 식별 결과 (FR-015, FR-016, FR-018)

### 3.1 모수

`sources/Projects/Feature`의 비테스트 소스에 있는 `@Reducer` 선언 29개를 모두 읽었다. 흐름별
개수는 AppEntry 1, Home 1, MainShell 2, ProjectList 1, Saved 1, Settings 3, Onboarding 6,
ProjectDetail 3, ProjectRegistration 6, Quiz 4, ShareRegistration 1이다. 최상위 `Router/`·`Presentation/`
디렉터리는 Git이 추적하지 않는 빈 디렉터리이며 Swift 파일이 없다.

### 3.2 통합 대상 관심사

| ID | 관심사 | 현재 선언 위치 | 판정 | 추출 Feature와 배치 | 단위 |
| --- | --- | --- | --- | --- | --- |
| I1 | 사용자 프로필 조회 | `Home/HomeFeature.swift` (`profileLoad`, `profileRequestID`), `Settings/Profile/ProfileFeature.swift` (`profileLoad`, `profileRequestID`), `Settings/Settings/SettingsFeature.swift` (`profile`, `profileLoad`) | 통합. 상태 모델이 같다(`idle/loading/loaded/failed(UserInfoError)`, 같은 Use Case). 차이는 시작 조건·로드 후 실패 처리 정책뿐이다 | `Feature/Shared/Reducers/UserProfileLoadFeature.swift` | U2 |
| I2 | 프로젝트 요약 목록 관찰·새로고침 | `Home/HomeFeature.swift` (`projectLoad`, `projectRequestID`), `ProjectList/ProjectListFeature.swift` (`projects`, `hasNextPage`, `initialLoad`, `requestID`) | 통합. 같은 `projects()` 스트림과 `refresh()`, 같은 취소 ID, 같은 오류 변환, 같은 "로드 뒤 새로고침 실패 무시" 규칙이다. 차이는 로딩 표시 조건 하나다. 페이지네이션은 ProjectList 고유 관심사로 분리한다(I2′) | `Feature/Shared/Reducers/ProjectSummaryListFeature.swift` | U3 |
| I3 | 프로젝트 삭제 | `ProjectList/ProjectListFeature.swift` (`deletion`), `ProjectDetail/ProjectDetailFeature.swift` (`deletion`) | 통합. 같은 `delete(_:)`와 같은 `confirming → committing → failed` 흐름이다. 차이는 `.notFound` 처리와 취소·재요청 가능 상태라는 정책 차이다 | `Feature/Shared/Reducers/ProjectDeletionFeature.swift` | U4 |
| I4 | 약관 동의를 포함한 로그인 | `MainShell/Router/GuestSignInFeature.swift` (+`+Phase`), `Onboarding/Tutorial/TutorialFeature.swift` (`authentication`, `requestID`) + `Onboarding/Router/OnboardingRouterFeature.swift` (동의 분기, `.guide(.legalAgreement)`) | 통합. 같은 `policyConsentStatus → (동의 화면) → consent → signIn(.apple)` 흐름이며 둘 다 `LegalAgreementFeature`를 쓴다. 차이는 동의 상태 적재 시점, 취소 결과 표현, 실패 표시 방식이다 | `Feature/Shared/Reducers/SignInFeature/` (`SignInFeature.swift`, `SignInFeature+Phase.swift`). 의존 Feature `LegalAgreementFeature`도 `Feature/Shared/Reducers/`로 이동 | U5 |

### 3.3 화면 고유 관심사의 분리 (§1 보조 규칙 2, SC-008)

위 통합으로 자식을 합성하게 되는 화면 Feature가, 자기 화면만 쓰는 관심사를 함께 들고 있는 경우다.

| ID | 화면 Feature | 분리할 관심사 | 분리 Feature와 배치 | 단위 |
| --- | --- | --- | --- | --- |
| I2′ | `ProjectListFeature` | 다음 페이지 요청(`pagination`, `requestNextPage`) | `ProjectList/ProjectListPaginationFeature.swift` | U7 |
| S1 | `SettingsFeature` | 직군·연차 즉시 반영(`positionMutation`, `careerLevelMutation`) | `Settings/Settings/CurationUpdateFeature.swift` | U6 |
| S2 | `SettingsFeature` | 로그아웃·회원 탈퇴(`accountAction`) | `Settings/Settings/AccountActionFeature.swift` | U6 |
| S3 | `SettingsFeature` | 알림 권한(`notificationStatus`) | `Settings/Settings/NotificationPermissionFeature.swift` | U6 |
| S4 | `ProjectDetailFeature` | 프로젝트 상세 조회(`detail`, `loadStatus`, `requestID`) | `ProjectDetail/ProjectDetailLoadFeature.swift` | U8 |

### 3.4 전환 계층의 기능 상태 반납 (시나리오 3-4)

| ID | 전환 계층 | 반납할 상태 | 처리 | 단위 |
| --- | --- | --- | --- | --- |
| R1 | `QuizRouterFeature` | 학습 세션 진행(`learningSet`, `currentQuestionIndex`, `resumption`, `sessionCorrectChoiceCount`, `bookmarkedQuestionIDs`) | `Quiz/Router/LearningSessionFeature.swift`로 분리한다. Router는 세션 delegate를 받아 문항 State를 만들고 화면을 전환한다 | U10 |
| R2 | `ShareRegistrationFeature` | 링크 검증·등록 요청(`status`의 `validating`·`invalidURL`·`signInRequired`·`appLaunchRequired`·`submitting`·`succeeded`·`failed`, `sharedURL`) | `ShareRegistration/SharedRepositoryRegistrationFeature.swift`로 분리한다. `ShareRegistrationFeature`는 단계 전환(`repositoryConfirmation`·`quizLevelSelection`·`quizGenerationConfirmation`)만 남기며, 타입 이름·파일 위치·App 호출부(`App/ShareExtension/ShareViewController.swift`)는 유지한다(사용자 결정, rename과 분리) | U11 |
| R3 | `SettingsRouterFeature` | 자식 필드 직접 쓰기(`settings.profile`, `settings.profileLoad`, `profile.profileLoad`) | I1 추출과 함께 `UserProfileLoadFeature`의 `replace` input 전달로 바꾼다 | U2 |
| R4 | `OnboardingRouterFeature` | 자식 필드 직접 쓰기(`careerSelection.position`), 동의 화면 활성 값(`.guide(.legalAgreement)`) | 동의 화면은 I4에서 `SignInFeature`가 소유하는 오버레이로 옮기고(U5), `careerSelection.position`은 input으로 바꾼다(U9) | U5, U9 |
| R5 | `ProjectRegistrationRouterFeature` | 자식 필드 직접 쓰기(`repositoryConfirmation.repository`, `repositoryLinkInput.validation`) | input으로 바꾼다 | U9 |

`MainShellRouterFeature.access`는 탭 선택 허용 규칙의 입력인 전환 상태로 보고 남긴다.
`state = State()`(로그아웃 뒤 재생성)와 `@Presents`·optional 자식 State의 생성은 자식 필드
변경이 아니라 수명 관리이므로 남긴다.

### 3.5 경로 정리 (FR-022 위반 해소, 순수 이동)

| ID | 대상 | 현재 위치 → 새 위치 | 이유 | 단위 |
| --- | --- | --- | --- | --- |
| P1 | `MainShellAccess` | `MainShell/Router/MainShellAccess.swift` → `Shared/Models/MainShellAccess.swift` | 화면인 `Home`이 전환 계층 디렉터리의 타입을 참조한다 | U1 |
| P2 | `SingleQuestionEntryFeature` | `ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift` → `Shared/Reducers/SingleQuestionEntryFeature.swift` | 두 흐름(`MainShell`, `ProjectDetail`)의 전환 계층이 합성하는 화면 없는 기능 Feature다 | U1 |
| P3 | `LegalAgreementFeature` | `Onboarding/LegalAgreement/LegalAgreementFeature.swift` → `Shared/Reducers/LegalAgreementFeature.swift` | I4의 `SignInFeature`(공용)가 합성한다. 공용은 흐름을 참조할 수 없다. `LegalAgreementScreen`은 제자리에 남는다 | U1 |

테스트 파일도 같은 축으로 이동한다(`Tests/ProjectDetail/SingleQuestionEntry/…` →
`Tests/Shared/Reducers/…`, `Tests/Onboarding/LegalAgreement/…` → `Tests/Shared/Reducers/…`).

### 3.6 제외 판정 (FR-016)

| ID | 후보 | 위치 | 제외 사유 |
| --- | --- | --- | --- |
| E1 | 로그아웃 | `AppEntryFeature`(복원 중 `memberUnavailable` 정리), `PositionSelectionFeature`(뒤로가기 = 이탈), `SettingsFeature`(계정 동작) | 공유하는 것은 `signOut()` 호출과 `SignOutResult` 분기뿐이다. 각각 복원 상태 기계, 온보딩 이탈 상태, 계정 동작 상태 기계 안의 한 전이이며, 상태 모델과 결과의 후속 의미가 다르다(FR-017). Settings 쪽은 S2로 분리한다 |
| E2 | 직군·연차 선택(사용자 입력 예시 "Curation → Curation & Setting") | `Onboarding/PositionSelection`·`CareerSelection`, `SettingsFeature` | 전이 규칙이 다르다. 온보딩은 선택을 초안으로 들고 있다가 `updateCuration(Curation)` 한 번으로 제출한다. 설정은 선택 즉시 `updatePosition`·`updateCareerLevel`을 필드별로 호출한다. 호출 Use Case도 다르다. 표시 매핑(`PositionDisplay`·`CareerLevelDisplay`와 온보딩 화면의 fileprivate `Display`) 중복은 상태 관심사가 아니다. 통일하려면 View 수정이 FR-023의 허용 범위를 넘으므로 후속 과제로 남긴다 |
| E3 | 적재·실패·재시도 패턴 | `SavedFeature.loadStatus`, `ProjectDetailFeature.loadStatus`, `LearningSetIntroFeature.setLoad` 등 | 구현 패턴이 비슷할 뿐 도메인·payload·오류 타입이 모두 다르다. 같은 관심사가 아니다(§1 보조 규칙 4) |
| E4 | 저장소 등록 단계 오케스트레이션 | `ProjectRegistrationRouterFeature`, `ShareRegistrationFeature` | 단계 Feature 3개는 이미 공유한다. 오케스트레이션 규칙이 다르다. 거절은 입력 화면 복귀 vs 확장 닫기, 조회 전 로컬 파싱·로그인 가능 확인은 공유 확장에만 있다. 등록 뒤에는 생성 진행 관찰 vs 즉시 성공이다 |
| E5 | 북마크 토글 | `QuestionSolvingFeature`(`isBookmarked`, `bookmarkMutation`), `SavedFeature`(`bookmarkOverrides`, `bookmarkMutations`) | 전이 규칙은 비슷하지만 상태 형태가 다르다(단일 문항 vs 문항별 map과 기본값 `true` override). 통합하면 Saved에 문항별 자식 컬렉션을 새로 도입해야 한다. 중복 유지 비용보다 크다 |
| E6 | 단건 문항 열기 조합 | `MainShellRouterFeature`, `ProjectDetailRouterFeature` | 준비 관심사는 이미 `SingleQuestionEntryFeature` 하나로 공유한다(P2). 남은 차이는 표시 방식(`@Presents` vs 활성 화면 값)이라는 전환 계층 고유 결정이다 |
| E7 | 조립 코드 중복 | `MainShellRouterFeature.profile(from:)`·`SettingsRouterFeature.profile(from:)`, `setBookmark` 클로저 3곳, `QuestionSolvingFeature(...)` 조립 3곳 | 상태·전이가 아니라 의존성 조립 코드의 중복이다. FR-003의 대상이 아니며, 동작을 바꾸지 않는 후속 정리로 남긴다 |
| E8 | 알림 권한 | `QuizGenerationProgressFeature`(대기 알림 시트), `SettingsFeature`(알림 행) | 규칙이 다르다. 진행 화면은 상태를 저장하지 않고 수락 흐름에서만 요청·설정 열기를 한다. 설정은 권한 상태를 저장하고 행 탭마다 분기한다. Settings 쪽은 S3로 분리한다 |

### 3.7 전체 분류 (리팩토링 완료 후 예정, SC-007)

기존 29개 중 `GuestSignInFeature`는 `SignInFeature`로 대체되어 사라진다. 새 기능 Feature 11개가
추가되어 모두 39개다.

| 흐름 | Reducer | 분류 | 비고 |
| --- | --- | --- | --- |
| AppEntry | `AppEntryFeature` | 기능 | 진입 복원·목적지 판단. 화면이 직접 관찰 |
| Home | `HomeFeature` | 화면 합성 | I1·I2 합성. 남는 것: `access`, 로그인 필요 alert, 생성 진행 표시, delegate |
| MainShell | `MainShellRouterFeature` | 전환 계층 | Shell. `SignInFeature`·`SingleQuestionEntryFeature` 합성 |
| MainShell | `GuestSignInFeature` | (제거) | I4로 대체 |
| ProjectList | `ProjectListFeature` | 화면 합성 | I2·I3·I2′ 합성. 남는 것: `mode` |
| ProjectList | `ProjectListPaginationFeature` | 기능 (신규) | I2′ |
| Saved | `SavedFeature` | 기능 | E5 |
| Settings | `ProfileFeature` | 화면 합성 | I1 합성. 남는 것: `settingsRequested` delegate |
| Settings | `SettingsFeature` | 화면 합성 | I1·S1·S2·S3 합성. 남는 것: 약관 URL, 행 탭 delegate |
| Settings | `CurationUpdateFeature` · `AccountActionFeature` · `NotificationPermissionFeature` | 기능 (신규) | S1·S2·S3 |
| Settings | `SettingsRouterFeature` | 전환 계층 | R3 |
| Onboarding | `TutorialFeature` | 화면 합성 | I4 합성. 남는 것: `page`, 개발용 계정 재설정 후속 동작 |
| Onboarding | `PositionSelectionFeature` · `CareerSelectionFeature` · `OnboardingExitFeature` | 기능 | E1·E2 |
| Onboarding | `OnboardingRouterFeature` | 전환 계층 | R4 |
| ProjectDetail | `ProjectDetailFeature` | 화면 합성 | I3·S4 합성. 남는 것: `isMenuPresented`, delegate |
| ProjectDetail | `ProjectDetailLoadFeature` | 기능 (신규) | S4 |
| ProjectDetail | `ProjectDetailRouterFeature` | 전환 계층 | |
| ProjectRegistration | `RepositoryLinkInputFeature` · `RepositoryConfirmationFeature` · `QuizLevelSelectionFeature` · `QuizGenerationConfirmationFeature` · `QuizGenerationProgressFeature` | 기능 | 화면이 직접 관찰 |
| ProjectRegistration | `ProjectRegistrationRouterFeature` | 전환 계층 | R5 |
| Quiz | `LearningSetIntroFeature` · `QuestionSolvingFeature` · `LearningCompletionFeature` | 기능 | |
| Quiz | `QuizRouterFeature` | 전환 계층 | R1 |
| Quiz | `LearningSessionFeature` | 기능 (신규) | R1 |
| ShareRegistration | `ShareRegistrationFeature` | 전환 계층 | R2 |
| ShareRegistration | `SharedRepositoryRegistrationFeature` | 기능 (신규) | R2 |
| Shared | `UserProfileLoadFeature` · `ProjectSummaryListFeature` · `ProjectDeletionFeature` · `SignInFeature` | 기능 (신규, 공용) | I1~I4 |
| Shared | `LegalAgreementFeature` · `SingleQuestionEntryFeature` | 기능 (이동, 공용) | P2·P3 |

---

## 4. 정본 동작 선택과 동작 차이 (FR-008)

관심사별로 누적한다. "의도한 차이"는 SC-002가 허용하는 유일한 동작 변경이며, 통합이 끝나면
`docs/conventions/tca/feature/classification.md`에 확정본을 옮긴다. 각 Feature의 공개 입력과
delegate는 [contracts](./contracts/feature-composition-contracts.md)에, 상태 모델은
[data-model.md](./data-model.md)에 있다.

### I1 사용자 프로필 조회

- **결정**: 입력을 셋으로 나눈다.
  - `load`: 로딩을 표시하며 다시 조회한다.
  - `reload`: 조회 완료 상태를 유지한 채 조용히 다시 조회하고, 그 실패는 무시한다. 조회 완료
    상태가 아니면 `load`와 같다.
  - `replace(UserProfile)`: 외부에서 확정된 프로필로 교체한다. 진행 중인 조회를 무효화한다.

  언제 어떤 입력을 보낼지는 화면이 정한다.
  - Home: `idle`일 때만 `load`, 재시도는 `failed`일 때 `load`.
  - Profile: `idle/failed → load`, `loaded → reload`.
  - Settings: 진입 시 항상 `load`.

  모든 결과는 request identity로 검증하고 `cancelInFlight`로 취소한다.
- **근거**: 세 곳의 차이는 "언제 조회를 시작하는가"라는 화면 정책이다. 전이 규칙은 `load`/`reload`
  두 입력으로 모두 표현된다. 요청 식별은
  [요청 식별 규칙](../../docs/conventions/tca/state/request-identity.md)이 요구한다.
- **검토한 대안**: Profile의 "task 한 번으로 분기" 규칙을 기능 Feature 안에 두는 것은 화면 정책을
  기능 Feature로 끌어들여(FR-005) 기각했다.
- **의도한 차이**
  1. Settings 프로필 조회에 request identity와 취소가 생긴다. 늦게 도착한 이전 응답이 더는 상태를
     덮어쓰지 않는다. 경합 상황에서만 관찰된다.
  2. Settings에서 직군·연차 변경 성공 뒤 반영(`replace`)이 진행 중인 조회를 무효화한다. 기존에는
     나중 조회 결과가 변경 결과를 덮어쓸 수 있었다.

### I2 프로젝트 요약 목록

- **결정**: 로딩 표시 조건을 "조회 완료 상태가 아닐 때"(Home 규칙)로 통일한다. 상태는
  `load: idle | loading | loaded(ProjectList) | failed(ProjectError)`와 request identity로 둔다.
  삭제 성공 뒤의 행 제거는 `projectRemoved(ProjectID)` input으로 받는다. 목록이 바뀔 때마다
  `listUpdated(ProjectList)` delegate를 보내, 페이지네이션 재설정과 빈 목록의 삭제 모드 종료를
  화면이 처리하게 한다.
- **근거**: ProjectList의 `projects.isEmpty` 조건은 "로드됐지만 비어 있음"과 "아직 로드되지 않음"을
  구분하지 못한다. [상태 형태 규칙](../../docs/conventions/tca/state/shape.md)에 맞는 쪽은 조회
  상태 기반 조건이다.
- **의도한 차이**
  1. ProjectList에서 이미 로드된 빈 목록을 새로고침하면 전체 로딩 표시가 다시 나타나지 않는다.
     빈 상태 화면이 유지된다.

### I3 프로젝트 삭제

- **결정**
  - 상태는 `idle | confirming(ProjectID) | committing(ProjectID) | failed(ProjectID, ProjectError)`로 둔다.
  - 요청은 `idle`·`failed`에서, 취소는 `confirming`·`failed`에서, 확정은 `confirming`에서만 받는다.
  - `.notFound`는 성공으로 본다(멱등 삭제).
  - 삭제 Effect는 중복 차단을 상태 전이로 하고 `cancelInFlight: false`다.
  - 성공 시 `deleted(projectID:)` delegate를 보낸다.
- **근거**: `.notFound`는 목표 상태(프로젝트 없음)가 이미 달성됐다는 뜻이다. `failed`에서 빠져나갈
  수 없는 ProjectList의 현재 규칙은 복구 경로를 보존하라는
  [상태 형태 규칙](../../docs/conventions/tca/state/shape.md)에 어긋난다.
- **의도한 차이**
  1. ProjectDetail에서 이미 삭제된 프로젝트를 삭제하면 실패 대신 삭제 완료로 처리되어 상세
     화면이 닫힌다.
  2. ProjectList에서 삭제 실패 뒤 취소하거나 다시 요청할 수 있다. 기존에는 `failed`에서 새 확인도
     취소도 받지 않았다.
  3. (차이 없음 확인) ProjectDetail의 취소는 기존에 `committing`을 제외한 모든 상태에서 `idle`로
     돌렸다. 정본은 `confirming`·`failed`에서만 받는다. 남은 상태는 원래 `idle`이므로 관찰되는
     결과는 같다.

### I4 약관 동의를 포함한 로그인

- **결정**
  - 상태는 `phase: idle | checkingConsent | agreeingToPolicies | signingIn | cancelled | failed`,
    자식 `legalAgreement`, request identity로 둔다.
  - 입력은 둘이다.
    - `prepareConsent`: 동의 상태를 미리 적재한다.
    - `start`: `idle·cancelled·failed`에서 받는다. 동의 상태가 적재되지 않았으면 적재를 기다린
      뒤 동의 여부를 판단한다.
  - delegate는 셋이다: `signedIn(needsCuration:)`, `consentCancelled`, `signInCancelled`.
  - 동의 화면 표시 여부는 `phase == .agreeingToPolicies`에서 파생한다.
  - 기존 화면 동작은 화면 정책으로 남긴다.
    - Onboarding의 "튜토리얼 표시 시 미리 적재"는 Tutorial이 `prepareConsent`를 보내 유지한다.
    - Tutorial의 인라인 오류는 `cancelled·failed`, MainShell의 실패 alert는 `failed`로 표시해 유지한다.
    - 동의 취소 뒤 마지막 페이지 복귀는 Tutorial의 후속 동작이다.
    - 개발용 계정 재설정(`deletesCompletedAccountOnSignIn`)은 Tutorial의 화면 고유 후속 동작이다.
      Tutorial이 `withdraw`를 소유한다(FR-004: MainShell에 `withdraw`를 강제하지 않는다).
- **근거**: 두 흐름의 상태 전이는 같은 순서의 같은 Use Case 호출이다. 차이는 표시와 시작 시점이다.
  동의 화면은 로그인 흐름 수명 안에서 완결되는 오버레이이므로
  [Navigation 경계](../../docs/conventions/tca/navigation/boundary.md)에 따라 기능 Feature가
  소유하고, Router의 활성 화면 값에서 뺀다.
- **의도한 차이**
  1. Onboarding에서 동의 상태 적재가 끝나기 전에 로그인을 누르면, 적재 완료를 기다린 뒤 판단한다.
     기존에는 미적재 상태를 "동의 필요"로 보고 빈 동의 화면을 보여줄 수 있었다.
  2. `OnboardingRouterFeature`의 이동 이벤트에서 `tutorial ↔ legalAgreement` 항목이 사라진다.
     사용자 화면은 같은 오버레이이며 테스트에서만 관찰된다.
  3. 개발용 계정 재설정 중 표시는 Tutorial의 재설정 진행 상태로 유지한다. 재설정 뒤 재로그인은
     저장된 동의가 유효하므로 동의 화면을 거치지 않는다(기존과 같음).

### I2′·S1~S4, R1·R2 (화면 고유 분리와 전환 계층 반납)

상태 모델과 전이 규칙을 그대로 옮긴다. 의도한 동작 차이는 없다. 부모가 자식 필드를 직접 쓰던
곳은 같은 값을 input으로 전달하도록 바꾸며, 관찰되는 결과는 같다.

---

## 5. 작업 단위와 순서 (FR-013)

| 단위 | 내용 | 주요 파일 | 선행 |
| --- | --- | --- | --- |
| U1 | 경로 정리 P1~P3(순수 이동), 형태 어휘·흐름 배치 문서 갱신 | 위 §3.5, `docs/conventions/file-vocabulary/shape-vocabulary.md`, `docs/conventions/directory-file/feature-layout.md` | — |
| U2 | I1 추출과 Home·Profile·Settings·SettingsRouter 합성 전환(R3 포함) | `Shared/Reducers/UserProfileLoadFeature.swift`, `Home/HomeFeature.swift`, `Home/ViewModels/HomeProfileDisplay.swift`, `Settings/Profile/ProfileFeature.swift`, `Settings/Profile/ViewModels/ProfileDisplay.swift`, `Settings/Settings/SettingsFeature.swift`, `Settings/Router/SettingsRouterFeature.swift`와 각 Screen·SubViews | U1 |
| U3 | I2 추출과 Home·ProjectList 합성 전환 | `Shared/Reducers/ProjectSummaryListFeature.swift`, `Home/HomeFeature.swift`, `Home/ViewModels/HomeProjectSectionState.swift`, `ProjectList/ProjectListFeature.swift`와 Screen | U2(`HomeFeature` 직렬) |
| U4 | I3 추출과 ProjectList·ProjectDetail 합성 전환 | `Shared/Reducers/ProjectDeletionFeature.swift`, `ProjectList/ProjectListFeature.swift`, `ProjectDetail/ProjectDetailFeature.swift`, `ProjectDetail/Router/ProjectDetailRouterFeature.swift`와 Screen | U3 |
| U5 | I4 추출, `GuestSignInFeature` 제거, MainShell·Tutorial·OnboardingRouter 합성 전환 | `Shared/Reducers/SignInFeature/*`, `MainShell/Router/*`, `Onboarding/Tutorial/TutorialFeature.swift`, `Onboarding/Router/OnboardingRouterFeature.swift`(+`+CurationExit`), `Onboarding/Router/OnboardingRouter.swift` | U1 |
| U6 | S1~S3 분리 | `Settings/Settings/{CurationUpdate,AccountAction,NotificationPermission}Feature.swift`, `SettingsFeature.swift`와 Screen·SubViews | U2 |
| U7 | I2′ 분리 | `ProjectList/ProjectListPaginationFeature.swift`, `ProjectListFeature.swift`와 SubViews | U4 |
| U8 | S4 분리 | `ProjectDetail/ProjectDetailLoadFeature.swift`, `ProjectDetailFeature.swift`와 Screen | U4 |
| U9 | R4(잔여)·R5 input 전환 | `Onboarding/Router/OnboardingRouterFeature.swift`, `Onboarding/CareerSelection/CareerSelectionFeature.swift`, `ProjectRegistration/Router/ProjectRegistrationRouterFeature.swift`, `ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationFeature.swift`, `ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputFeature.swift` | U5 |
| U10 | R1 분리 | `Quiz/Router/LearningSessionFeature.swift`, `Quiz/Router/QuizRouterFeature.swift` | U1 |
| U11 | R2 분리 | `ShareRegistration/SharedRepositoryRegistrationFeature.swift`, `ShareRegistration/ShareRegistrationFeature.swift`, `ShareRegistration/ShareRegistrationScreen.swift` | U1 |
| U12 | 컨벤션 문서화(시나리오 4)와 최종 검증 | `docs/conventions/tca/feature.md`, `docs/conventions/tca/feature/classification.md`, 이 문서 §6 | U2~U11 |

- 단위마다 해당 테스트 파일의 이관을 포함한다. 테스트 경로는 production 축을 미러링한다
  (`Tests/Shared/Reducers/`, `Tests/ProjectList/ProjectList/` 등).
- 최상위 Feature 생성자는 바뀌지 않는다. 대신 App이 직접 읽는 Feature 상태 경로가 바뀌는
  U3(`home.projectLoad`, `projectList.projects`)과 U8(`projectDetail.loadStatus`)은 Feature+App
  integration unit이다. App의 수정 파일은 `App/GitIt/Reducers/AppRootFeature.swift`(U3)와
  `App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`(U3·U8)이다.
  `App/ShareExtension/ShareViewController.swift`는 변경하지 않는다.
- 기존 흐름 루트에 파일을 두는 `ShareRegistration/`의 배치는
  [feature-layout](../../docs/conventions/directory-file/feature-layout.md)과 다른 기존 편차다. 이번에는
  바꾸지 않고, U11의 새 파일도 같은 자리에 둔다. 배치 정리는 rename·이동 전용 후속 과제로 남긴다.

---

## 6. 단언 이관 대응표 (SC-011)

구현 단위마다 이관 전 화면 테스트의 각 `@Test`가 어디로 갔는지 기록한다. 이관 뒤 위치는
**기능 Feature 테스트**, **합성 지점 검증**, **중복 제거(대체 테스트 명시)** 중 하나다. 대응표가 없는
단위는 완료로 보지 않는다. 표는 `/speckit-implement`가 각 단위에서 채운다.

| 단위 | 이관 전 테스트(파일 › 이름) | 이관 뒤 위치(파일 › 이름) | 구분 |
| --- | --- | --- | --- |
| U2 | Tests/Home/Home/HomeFeatureLoadTests.swift › 최초 task는 프로필을 한 번만 조회하고 복귀 task는 갱신만 다시 요청한다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 최초 task는 프로필을 한 번만 조회하고 복귀 task는 갱신만 다시 요청한다 | 합성 지점 검증 |
| U2 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로필 재시도는 프로젝트를 보존하고 프로필만 조회한다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로필 재시도는 프로젝트를 보존하고 프로필 조회에 load만 보낸다 | 합성 지점 검증 |
| U2 | Tests/Home/Home/HomeFeatureLoadTests.swift › 현재 request ID와 다른 응답은 상태를 바꾸지 않는다 | Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › 현재 request ID와 다른 응답은 상태를 바꾸지 않는다 | 기능 Feature 테스트 |
| U2 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 갱신 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 갱신 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다 | 합성 지점 검증 |
| U2 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 재시도는 프로필을 보존하고 갱신만 다시 요청한다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 재시도는 프로필을 보존하고 갱신만 다시 요청한다 | 합성 지점 검증 |
| U2 | Tests/Home/Home/HomeFeatureGuestAccessTests.swift › 로그인 사용자로 바뀌면 프로필과 프로젝트 적재를 시작한다 | Tests/Home/Home/HomeFeatureGuestAccessTests.swift › 로그인 사용자로 바뀌면 프로필과 프로젝트 적재를 시작한다 | 합성 지점 검증 |
| U2 | Tests/Home/Home/HomeFeatureGenerationProgressTests.swift › 진행 중에도 프로필 재시도 조회는 그대로 수행된다 | Tests/Home/Home/HomeFeatureGenerationProgressTests.swift › 진행 중에도 프로필 재시도 조회는 그대로 수행된다 | 합성 지점 검증 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 최초 task는 로딩을 세우고 받은 프로필을 노출한다 | Tests/Settings/Profile/ProfileFeatureTests.swift › 최초 task는 프로필 조회에 load를 보내 받은 프로필을 노출한다, Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › load는 로딩을 세우고 받은 프로필로 조회 완료 상태가 된다 | 합성 지점 검증 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 이미 받은 프로필이 있으면 task는 로딩을 거치지 않고 최신 값으로 바꾼다 | Tests/Settings/Profile/ProfileFeatureTests.swift › 이미 받은 프로필이 있으면 task는 로딩 없는 reload를 보낸다, Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › 조회 완료 상태의 reload는 로딩 없이 최신 프로필로 바꾼다 | 합성 지점 검증 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 갱신 실패는 이미 보여 주던 프로필을 그대로 유지한다 | Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › 조회 완료 상태의 reload 실패는 보여 주던 프로필을 유지한다 | 기능 Feature 테스트 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 최초 조회 실패는 실패 상태를 남기고 재시도로 다시 조회한다 | Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › load 실패는 실패 상태를 남긴다, Tests/Settings/Profile/ProfileFeatureTests.swift › 실패 상태의 재시도는 프로필 조회에 load를 보낸다 | 기능 Feature 테스트 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 실패 상태가 아니면 재시도는 조회하지 않는다 | Tests/Settings/Profile/ProfileFeatureTests.swift › 실패 상태가 아니면 재시도는 조회하지 않는다 | 합성 지점 검증 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 조회 중인 동안 다시 들어온 task는 조회를 새로 시작하지 않는다 | Tests/Settings/Profile/ProfileFeatureTests.swift › 조회 중인 동안 다시 들어온 task는 조회를 새로 시작하지 않는다, Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › 조회 중의 reload는 조회를 새로 시작하지 않는다 | 합성 지점 검증 |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 현재 request ID와 다른 응답은 상태를 바꾸지 않는다 | Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › 현재 request ID와 다른 응답은 상태를 바꾸지 않는다 | 중복 제거(대체 테스트 명시) |
| U2 | Tests/Settings/Profile/ProfileFeatureTests.swift › 설정 아이콘 탭은 설정 요청 delegate를 올린다 | Tests/Settings/Profile/ProfileFeatureTests.swift › 설정 아이콘 탭은 설정 요청 delegate를 올린다 | 합성 지점 검증 |
| U2 | Tests/Settings/Settings/SettingsFeatureTests.swift › task는 프로필을 조회해 설정 값의 근거로 남긴다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 프로필이 없으면 task는 프로필 조회에 load를 보내 설정 값의 근거로 남긴다 | 합성 지점 검증 |
| U2 | Tests/Settings/Settings/SettingsFeatureTests.swift › 프로필 조회 실패는 값 없이 실패 상태만 남긴다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 프로필 조회 실패는 값 없이 실패 상태만 남긴다, Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › load 실패는 실패 상태를 남긴다 | 합성 지점 검증 |
| U2 | Tests/Settings/Settings/SettingsFeatureTests.swift › task는 알림 권한 상태를 조회해 켜짐·꺼짐 값의 근거로 남긴다 | Tests/Settings/Settings/SettingsFeatureTests.swift › task는 알림 권한 상태를 조회해 켜짐·꺼짐 값의 근거로 남긴다 | 합성 지점 검증 |
| U2 | Tests/Settings/Settings/SettingsFeatureTests.swift › 직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다(`replace` 전달 단언), Tests/Shared/Reducers/UserProfileLoadFeatureTests.swift › replace는 조회 완료 상태로 바꾸고 진행 중인 조회 결과를 무효화한다 | 합성 지점 검증 |
| U2 | Tests/Settings/Settings/SettingsFeatureTests.swift › 연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다(`replace` 전달 단언) | 합성 지점 검증 |
| U2 | Tests/Settings/Settings/SettingsFeatureTests.swift › 저장 실패는 실패 상태를 남기고 이전 프로필을 그대로 둔다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 저장 실패는 실패 상태를 남기고 이전 프로필을 그대로 둔다 | 합성 지점 검증 |
| U2 | Tests/Settings/Router/SettingsRouterFeatureTests.swift › 설정 아이콘을 탭하면 프로필 값을 설정에 넘기고 설정 목록으로 전환한다 | Tests/Settings/Router/SettingsRouterFeatureTests.swift › 설정 아이콘을 탭하면 설정 목록으로 전환하고 프로필 값을 input으로 설정에 넘긴다, Tests/Settings/Settings/SettingsFeatureTests.swift › 외부에서 받은 프로필은 프로필 조회에 replace로 전달한다 | 합성 지점 검증 |
| U2 | Tests/Settings/Router/SettingsRouterFeatureTests.swift › 설정 목록에서 뒤로가기는 변경된 프로필을 프로필 화면에 반영하고 돌아간다 | Tests/Settings/Router/SettingsRouterFeatureTests.swift › 설정 목록에서 뒤로가기는 프로필 화면으로 돌아가고 변경된 프로필을 input으로 반영한다 | 합성 지점 검증 |
| U2 | Tests/MainShell/Router/MainShellRouterFeatureTests.swift › 탭을 왕복하면 프로젝트를 다시 조회하고 실패해도 그리던 목록을 유지한다 | Tests/MainShell/Router/MainShellRouterFeatureTests.swift › 탭을 왕복하면 프로젝트를 다시 조회하고 실패해도 그리던 목록을 유지한다(상태 경로만 변경) | 합성 지점 검증 |
| U2 | Tests/MainShell/Router/MainShellRouterFeatureTests.swift › 로그아웃과 계정 삭제는 네 child와 Home 기본 탭을 초기화한다 | Tests/MainShell/Router/MainShellRouterFeatureTests.swift › 로그아웃과 계정 삭제는 네 child와 Home 기본 탭을 초기화한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureLoadTests.swift › 최초 task는 프로필을 한 번만 조회하고 복귀 task는 갱신만 다시 요청한다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 최초 task는 프로필을 한 번만 조회하고 복귀 task는 갱신만 다시 요청한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로필 재시도는 프로젝트를 보존하고 프로필 조회에 load만 보낸다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로필 재시도는 프로젝트를 보존하고 프로필 조회에 load만 보낸다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 갱신 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 갱신 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 재시도는 프로필을 보존하고 갱신만 다시 요청한다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 프로젝트 재시도는 프로필을 보존하고 목록에 refresh만 보낸다 | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureLoadTests.swift › 실패 상태가 아니면 프로젝트 재시도는 아무 효과도 내지 않는다 | Tests/Home/Home/HomeFeatureLoadTests.swift › 실패 상태가 아니면 프로젝트 재시도는 아무 효과도 내지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureGuestAccessTests.swift › 로그인 사용자로 바뀌면 프로필과 프로젝트 적재를 시작한다 | Tests/Home/Home/HomeFeatureGuestAccessTests.swift › 로그인 사용자로 바뀌면 프로필과 프로젝트 적재를 시작한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureGenerationProgressTests.swift › 진행 중에도 카드 본문과 전체 보기 동작은 달라지지 않는다 | Tests/Home/Home/HomeFeatureGenerationProgressTests.swift › 진행 중에도 카드 본문과 전체 보기 동작은 달라지지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureGenerationProgressTests.swift › 진행 중에도 프로젝트 갱신 재시도는 그대로 수행된다 | Tests/Home/Home/HomeFeatureGenerationProgressTests.swift › 진행 중에도 프로젝트 갱신 재시도는 그대로 수행된다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureNavigationTests.swift › 프로젝트 등록 CTA는 동일한 delegate를 전달한다 | Tests/Home/Home/HomeFeatureNavigationTests.swift › 프로젝트 등록 CTA는 동일한 delegate를 전달한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureNavigationTests.swift › 적재된 목록에서 다음 퀴즈가 있는 프로젝트만 학습 delegate로 전달한다 | Tests/Home/Home/HomeFeatureNavigationTests.swift › 적재된 목록에서 다음 퀴즈가 있는 프로젝트만 학습 delegate로 전달한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureNavigationTests.swift › 다음 퀴즈가 없는 프로젝트는 학습 delegate를 전달하지 않는다 | Tests/Home/Home/HomeFeatureNavigationTests.swift › 다음 퀴즈가 없는 프로젝트는 학습 delegate를 전달하지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › task는 프로젝트 스트림을 구독하고 갱신을 한 번 요청한다 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › task는 프로젝트 스트림을 구독하고 갱신을 한 번 요청한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 스트림이 다시 방출하면 최신 목록으로 갈아끼운다 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 스트림이 다시 방출하면 최신 목록으로 갈아끼운다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 아직 적재되지 않은 목록은 표시 상태로 반영하지 않는다 | Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › 로드되지 않은 목록 수신은 상태를 바꾸지 않는다 | 기능 Feature 테스트 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 갱신에 실패해도 이미 적재된 목록을 오류로 덮지 않는다 | Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › 조회 완료 뒤 새로고침 실패는 목록을 유지한다 | 기능 Feature 테스트 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 적재 전 갱신 실패는 오류 의미를 보존한다 | Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › 조회 완료 전 새로고침 실패는 실패 상태가 된다 | 기능 Feature 테스트 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 지난 요청의 갱신 결과는 반영하지 않는다 | Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › 현재 request ID와 다른 새로고침 결과는 무시한다 | 기능 Feature 테스트 |
| U3 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 목록 재조회 입력은 갱신을 다시 요청한다 | Tests/Home/Home/HomeFeatureGenerationOutcomeTests.swift › 목록 재조회 입력은 목록에 refresh를 보낸다 | 합성 지점 검증 |
| U3 | Tests/MainShell/Router/MainShellRouterFeatureTests.swift › 탭을 왕복하면 프로젝트를 다시 조회하고 실패해도 그리던 목록을 유지한다 | Tests/MainShell/Router/MainShellRouterFeatureTests.swift › 탭을 왕복하면 프로젝트를 다시 조회하고 실패해도 그리던 목록을 유지한다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 진입하면 스트림이 준 목록으로 채운다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 진입하면 스트림이 준 목록으로 채운다(상태 경로만 변경), Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › start는 목록 관찰을 시작하고 새로고침한다 | 합성 지점 검증 |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 갱신에 실패하면 실패 상태를 남긴다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 갱신에 실패하면 실패 상태를 남긴다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 아직 적재되지 않은 목록은 반영하지 않는다 | Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › 로드되지 않은 목록 수신은 상태를 바꾸지 않는다 | 중복 제거(대체 테스트 명시) |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제에 성공하면 목록에서 그 프로젝트를 지운다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제에 성공하면 목록에서 그 프로젝트를 지운다(행 제거는 `projectRemoved`로 전달), Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › projectRemoved는 해당 행을 제거하고 listUpdated를 보낸다 | 합성 지점 검증 |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 이미 사라진 프로젝트는 삭제 실패로 남기지 않는다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 이미 사라진 프로젝트는 삭제 실패로 남기지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 마지막 프로젝트를 지우면 삭제 모드를 벗어난다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 마지막 프로젝트를 지우면 삭제 모드를 벗어난다(`listUpdated` 해석) | 합성 지점 검증 |
| U3 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 새로고침 입력은 목록 갱신을 다시 요청한다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 새로고침 입력은 목록에 refresh를 보낸다 | 합성 지점 검증 |
| U3 | (새 테스트, I2-1 동작 차이 고정) | Tests/Shared/Reducers/ProjectSummaryListFeatureTests.swift › 이미 로드된 빈 목록의 새로고침은 전체 로딩을 다시 세우지 않는다 | 기능 Feature 테스트 |
| U3 | (새 테스트) | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록이 갱신되면 페이지네이션을 다시 설정한다 | 합성 지점 검증 |
| U3 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › 프로젝트 목록의 학습 요청은 상세 위에 그 세트의 풀이 흐름을 연다 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › 프로젝트 목록의 학습 요청은 상세 위에 그 세트의 풀이 흐름을 연다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › Home 학습 요청은 일치하는 프로젝트가 있으면 그 세트의 풀이 흐름을 연다 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › Home 학습 요청은 일치하는 프로젝트가 있으면 그 세트의 풀이 흐름을 연다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › onboarding 표시 중 앱이 활성화되면 프로젝트 목록을 조회하지 않는다 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › onboarding 표시 중 앱이 활성화되면 프로젝트 목록을 조회하지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U3 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › 포그라운드 목록 갱신이 실패해도 mainShell 화면을 유지한다 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › 포그라운드 목록 갱신이 실패해도 mainShell 화면을 유지한다(수신 Action 경로 `home.projectSummaries.effect.refreshFinished`) | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제를 확인하기 전에는 삭제를 요청하지 않는다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 모드의 삭제 버튼은 삭제에 request를 보내고 확인 전에는 삭제를 요청하지 않는다 | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제를 확인하기 전에는 삭제를 요청하지 않는다(전이 단언) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 확인 전에는 confirm이 삭제를 요청하지 않는다 | 기능 Feature 테스트 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제를 취소하면 확인 상태를 벗어난다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 취소는 삭제에 cancel을 보낸다 | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제를 취소하면 확인 상태를 벗어난다(전이 단언) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 확인 중이거나 실패 상태의 cancel은 대기 상태로 돌린다 | 기능 Feature 테스트 |
| U4 | (새 테스트, I3-2 동작 차이 고정) | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 실패 뒤에도 다시 삭제를 요청할 수 있다 | 합성 지점 검증 |
| U4 | (새 테스트, I3-2 동작 차이 고정) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 대기나 실패 상태의 request는 삭제 확인 상태가 된다 | 기능 Feature 테스트 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제에 성공하면 목록에서 그 프로젝트를 지운다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제에 성공하면 목록에서 그 프로젝트를 지운다(수신 Action 경로 `deletion.effect.deletionFinished`) | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 이미 사라진 프로젝트는 삭제 실패로 남기지 않는다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 이미 사라진 프로젝트는 삭제 실패로 남기지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 마지막 프로젝트를 지우면 삭제 모드를 벗어난다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 마지막 프로젝트를 지우면 삭제 모드를 벗어난다(상태 경로만 변경) | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 실패는 목록과 삭제 모드를 유지한다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 실패는 목록과 삭제 모드를 유지한다(상태 경로만 변경) | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 실패는 목록과 삭제 모드를 유지한다(실패 전이 단언) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 그 밖의 삭제 오류는 실패 상태로 남긴다 | 기능 Feature 테스트 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 모드에서 뒤로 가면 목록 모드로 돌아온다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 모드에서 뒤로 가면 목록 모드로 돌아온다(삭제에 cancel 전달 수신 추가) | 합성 지점 검증 |
| U4 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 실패 후에도 뒤로 가면 목록 모드로 돌아온다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 삭제 실패 후에도 뒤로 가면 목록 모드로 돌아온다(삭제에 cancel 전달 수신 추가) | 합성 지점 검증 |
| U4 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제는 확인 단계를 거치고 취소하면 아무 것도 삭제하지 않는다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제는 메뉴를 닫고 삭제에 request를 보내며 취소하면 아무 것도 삭제하지 않는다 | 합성 지점 검증 |
| U4 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제 중에는 재입력을 무시하고 성공하면 삭제 완료를 알린다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제 중에는 재입력을 무시하고 성공하면 삭제 완료를 알린다(상태 경로만 변경) | 합성 지점 검증 |
| U4 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제 중에는 재입력을 무시하고 성공하면 삭제 완료를 알린다(전이 단언) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 삭제 중에는 confirm을 다시 받지 않는다, 삭제 성공은 대기 상태로 돌리고 deleted를 보낸다 | 기능 Feature 테스트 |
| U4 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제에 실패하면 오류를 남기고 삭제 완료를 알리지 않는다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 삭제에 실패하면 오류를 남기고 삭제 완료를 알리지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U4 | (새 테스트, I3-1 동작 차이 고정) | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 이미 사라진 프로젝트를 삭제하면 삭제 완료를 알린다 | 합성 지점 검증 |
| U4 | (새 테스트, I3-1 동작 차이 고정) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 이미 사라진 프로젝트의 삭제는 성공으로 보고 deleted를 보낸다 | 기능 Feature 테스트 |
| U4 | (새 테스트) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 확인 중이거나 삭제 중이면 request를 무시한다 | 기능 Feature 테스트 |
| U4 | (새 테스트) | Tests/Shared/Reducers/ProjectDeletionFeatureTests.swift › 삭제 중의 cancel은 무시한다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 약관 동의가 충족되면 바로 Apple 로그인을 시작한다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 약관 동의가 충족되면 바로 Apple 로그인을 시작한다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 약관 동의가 없으면 약관 단계로 가고 동의를 마친 뒤 로그인한다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 약관 동의를 마치면 로그인한다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 약관 동의를 취소하면 로그인 없이 대기 상태로 돌아간다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 약관 동의를 취소하면 로그인 없이 대기 상태로 돌아가고 consentCancelled를 보낸다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 로그인 성공은 직군 입력 필요 여부를 signedIn으로 위임한다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 로그인 성공은 직군 입력 필요 여부를 signedIn으로 위임한다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 로그인 취소는 실패 알럿 없이 대기 상태로 돌아간다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 로그인 취소는 실패 없이 취소 상태가 되고 signInCancelled를 보낸다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 재시도 가능한 실패는 실패 알럿을 띄우고 닫으면 대기 상태로 돌아간다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 재시도 가능한 실패는 실패 상태가 되고 닫으면 대기 상태로 돌아간다 | 기능 Feature 테스트 |
| U5 | Tests/MainShell/Router/GuestSignInFeatureTests.swift › 로그인 진행 중 start를 다시 받아도 로그인 요청을 추가로 보내지 않는다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 진행 중인 흐름에서는 start를 다시 받아도 로그인 요청을 추가로 보내지 않는다 | 기능 Feature 테스트 |
| U5 | (새 테스트) | Tests/Shared/Reducers/SignInFeatureTests.swift › prepareConsent는 동의 상태를 적재한다, 이미 적재된 동의 상태는 prepareConsent로 다시 적재하지 않는다 | 기능 Feature 테스트 |
| U5 | (새 테스트, I4-1 동작 차이 고정) | Tests/Shared/Reducers/SignInFeatureTests.swift › 동의 상태가 적재되기 전의 start는 적재 완료를 기다린 뒤 동의 필요 여부를 판단한다 | 기능 Feature 테스트 |
| U5 | (새 테스트) | Tests/Shared/Reducers/SignInFeatureTests.swift › 취소나 실패 뒤의 start는 로그인을 다시 시작한다 | 기능 Feature 테스트 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 현재 requestID와 다른 로그인 응답은 상태를 바꾸지 않는다 | Tests/Shared/Reducers/SignInFeatureTests.swift › request ID가 다르거나 로그인 중이 아니면 로그인 결과를 반영하지 않는다 | 기능 Feature 테스트 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 화면 진입은 appeared를 위임한다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 화면 진입은 로그인에 prepareConsent를 보낸다 | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › Apple 로그인 탭은 곧바로 로그인하지 않고 signInRequested를 위임한다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › Apple 로그인 성공은 마지막 페이지로 이동한 뒤 needsCuration을 그대로 위임한다(탭이 곧바로 로그인에 start를 보냄) | 중복 제거(대체 테스트 명시) |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › Apple 로그인 성공은 마지막 페이지로 이동한 뒤 needsCuration을 그대로 위임한다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › Apple 로그인 성공은 마지막 페이지로 이동한 뒤 needsCuration을 그대로 위임한다(수신 Action 경로 `signIn`) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 로그인 진행 중 중복 탭은 추가 로그인 호출을 만들지 않는다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 로그인 진행 중 중복 탭은 추가 로그인 호출을 만들지 않는다(수신 Action 경로 `signIn`) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › Apple 인증 취소는 재시도 오류와 구분되는 cancelled 상태로 남는다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › Apple 인증 취소는 재시도 오류와 구분되는 cancelled 상태로 남는다(상태 경로 `signIn.phase`) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › deletesCompletedAccountOnSignIn이 true면 needsCuration false 응답을 받은 뒤 회원탈퇴하고 자동으로 재로그인한다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › deletesCompletedAccountOnSignIn이 true면 needsCuration false 응답을 받은 뒤 회원탈퇴하고 자동으로 재로그인한다(`accountReset` 진행 상태 단언 추가) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › deletesCompletedAccountOnSignIn이 true여도 재시도가 다시 needsCuration false를 받으면 더 이상 반복하지 않는다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › deletesCompletedAccountOnSignIn이 true여도 재시도가 다시 needsCuration false를 받으면 더 이상 반복하지 않는다(`accountReset` 진행 상태 단언 추가) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 로그인 진행 중에는 비로그인 진입을 무시한다 | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 로그인 진행 중에는 비로그인 진입을 무시한다(상태 경로 `signIn.phase`) | 합성 지점 검증 |
| U5 | (새 테스트) | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 계정 재설정 중에는 로그인 진행 중으로 보고 비로그인 진입을 무시한다 | 합성 지점 검증 |
| U5 | (새 테스트) | Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 약관 동의를 취소하면 마지막 페이지로 되돌린다 | 합성 지점 검증 |
| U5 | Tests/Onboarding/Tutorial/TutorialAccessibilityTests.swift › TutorialFeature의 재시도 가능한 오류는 retryableFailure와 cancelled를 모두 포함한다 | Tests/Onboarding/Tutorial/TutorialAccessibilityTests.swift › TutorialFeature의 재시도 가능한 오류는 로그인 실패와 취소를 모두 포함한다 | 합성 지점 검증 |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 정상 완료 여정은 guide와 curation 및 splash를 거쳐 mainShell 전환을 위임하고 이동 이벤트를 남긴다 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 정상 완료 여정은 guide와 curation 및 splash를 거쳐 mainShell 전환을 위임하고 이동 이벤트를 남긴다(수신 Action 경로 `tutorial.signIn`) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 저장 동의가 유효하지 않으면 로그인을 시작하지 않고 legalAgreement 화면으로 이동하며 선택을 초기화한다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 약관 동의를 마치면 로그인한다(동의 필요 판단과 `.agreeingToPolicies` 전이). 이동 이벤트 단언은 I4-2에 따라 삭제 | 기능 Feature 테스트 |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 동의를 마치면 tutorial로 돌아와 로그인을 시작하고 needsCuration에 따라 curation으로 이동한다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 약관 동의를 마치면 로그인한다, Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 정상 완료 여정은 guide와 curation 및 splash를 거쳐 mainShell 전환을 위임하고 이동 이벤트를 남긴다 | 중복 제거(대체 테스트 명시) |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › legalAgreement 취소는 tutorial 마지막 페이지로 되돌린다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 약관 동의를 취소하면 로그인 없이 대기 상태로 돌아가고 consentCancelled를 보낸다, Tests/Onboarding/Tutorial/TutorialFeatureTests.swift › 약관 동의를 취소하면 마지막 페이지로 되돌린다 | 기능 Feature 테스트 |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 문서 sheet 닫기 view 액션은 legalAgreement의 표시 상태를 해제한다 | Tests/Shared/Reducers/SignInFeatureTests.swift › 문서 sheet 닫기는 legalAgreement의 문서 표시를 해제한다 | 기능 Feature 테스트 |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다(상태 경로 `tutorial.signIn`) | 합성 지점 검증 |
| U5 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 로그인 성공에서 needsCuration이 false이면 화면 전환 없이 mainShellRequested를 위임한다 | Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift › 로그인 성공에서 needsCuration이 false이면 화면 전환 없이 mainShellRequested를 위임한다(수신 Action 경로 `tutorial.signIn`) | 합성 지점 검증 |
| U5 | Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift › 홈의 로그인 요청은 로그인 흐름을 시작한다 | Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift › 홈의 로그인 요청은 로그인 흐름을 시작한다(자식 경로 `signIn`) | 합성 지점 검증 |
| U5 | Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift › 마이 탭 로그인 화면의 로그인은 로그인 흐름을 시작한다 | Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift › 마이 탭 로그인 화면의 로그인은 로그인 흐름을 시작한다(자식 경로 `signIn`) | 합성 지점 검증 |
| U5 | Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift › 로그인 성공은 직군 입력 필요 여부와 함께 signInSucceeded를 위임한다 | Tests/MainShell/Router/MainShellRouterFeatureGuestAccessTests.swift › 로그인 성공은 직군 입력 필요 여부와 함께 signInSucceeded를 위임한다(자식 경로 `signIn`) | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › task는 알림 권한 상태를 조회해 켜짐·꺼짐 값의 근거로 남긴다 | Tests/Settings/Settings/NotificationPermissionFeatureTests.swift › refresh는 알림 권한 상태를 조회해 켜짐·꺼짐 값으로 남긴다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › task는 알림 권한 상태를 조회해 켜짐·꺼짐 값의 근거로 남긴다(위임) | Tests/Settings/Settings/SettingsFeatureTests.swift › task는 알림 권한에 refresh를 보낸다 | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 앱 설정에서 알림을 켜고 돌아오면 알림 권한 상태를 다시 조회한다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 앱 설정에서 돌아오면 알림 권한에 refresh를 보낸다 | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 알림이 켜져 있으면 알림 항목 탭은 시스템 알림 설정 화면을 연다 | Tests/Settings/Settings/NotificationPermissionFeatureTests.swift › 알림이 켜져 있으면 rowTapped는 시스템 알림 설정 화면을 연다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 알림이 켜져 있으면 알림 항목 탭은 시스템 알림 설정 화면을 연다(위임) | Tests/Settings/Settings/SettingsFeatureTests.swift › 알림 항목 탭은 알림 권한에 rowTapped를 보낸다 | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 알림 권한을 정하지 않았으면 알림 항목 탭은 시스템 권한을 요청하고 결과로 상태를 갱신한다 | Tests/Settings/Settings/NotificationPermissionFeatureTests.swift › 알림 권한을 정하지 않았으면 rowTapped는 시스템 권한을 요청하고 결과로 상태를 갱신한다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 이미 거부한 알림 권한은 알림 항목 탭에서 권한을 요청하지 않고 시스템 알림 설정 화면으로 이어진다 | Tests/Settings/Settings/NotificationPermissionFeatureTests.swift › 이미 거부한 알림 권한은 rowTapped에서 권한을 요청하지 않고 시스템 알림 설정 화면으로 이어진다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다(수신 Action 경로 `curationUpdate`, 프로필 `replace` 연결) | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 직군 저장 성공은 직군만 바꾸고 연차와 통계를 유지한다(전이 단언) | Tests/Settings/Settings/CurationUpdateFeatureTests.swift › 직군 저장 성공은 대기 상태로 되돌리고 positionUpdated를 보낸다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다 | Tests/Settings/Settings/SettingsFeatureTests.swift › 연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다(수신 Action 경로 `curationUpdate`, 프로필 `replace` 연결) | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 연차 저장 성공은 연차만 바꾸고 직군과 통계를 유지한다(전이 단언) | Tests/Settings/Settings/CurationUpdateFeatureTests.swift › 연차 저장 성공은 대기 상태로 되돌리고 careerLevelUpdated를 보낸다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 저장 실패는 실패 상태를 남기고 이전 프로필을 그대로 둔다 | Tests/Settings/Settings/CurationUpdateFeatureTests.swift › 저장 실패는 실패 상태를 남기고 delegate를 보내지 않는다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 저장 실패는 실패 상태를 남기고 이전 프로필을 그대로 둔다(프로필 보존) | Tests/Settings/Settings/SettingsFeatureTests.swift › 저장 실패는 이전 프로필을 그대로 둔다 | 합성 지점 검증 |
| U6 | Tests/Settings/Settings/SettingsFeatureTests.swift › 저장 중에는 같은 항목의 선택을 다시 보내지 않는다 | Tests/Settings/Settings/CurationUpdateFeatureTests.swift › 직군 저장 중에는 직군 선택을 다시 보내지 않는다 | 기능 Feature 테스트 |
| U6 | (새 테스트) | Tests/Settings/Settings/CurationUpdateFeatureTests.swift › 연차 저장 중에는 연차 선택을 다시 보내지 않는다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 로그아웃 성공은 대기 상태로 되돌리고 signedOut delegate를 올린다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 로그아웃 성공은 대기 상태로 되돌리고 signedOut을 보낸다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 로그아웃이 실패해도 같은 화면에서 다시 로그아웃할 수 있다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 로그아웃이 실패해도 다시 로그아웃할 수 있다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 진행 중인 계정 작업은 새 로그아웃·삭제 요청으로 덮이지 않는다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 진행 중인 계정 작업은 새 로그아웃·삭제 요청으로 덮이지 않는다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 계정 삭제 탭은 확인 단계로 바꾸고 확인 요청 delegate를 올린다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 삭제 요청은 확인 단계로 바꾸고 deletionConfirmationRequested를 보낸다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 삭제 취소는 확인 상태를 해제하고 취소 delegate를 올린다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 삭제 취소는 확인 상태를 해제하고 deletionCancelled를 보낸다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 확인 단계를 거치지 않은 삭제 확인은 계정을 삭제하지 않는다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 확인 단계를 거치지 않은 삭제 확인은 계정을 삭제하지 않는다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 삭제 성공은 대기 상태로 되돌리고 accountDeleted delegate를 올린다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 삭제 성공은 대기 상태로 되돌리고 accountDeleted를 보낸다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › 삭제가 실패해도 확인 화면에서 다시 삭제를 진행할 수 있다 | Tests/Settings/Settings/AccountActionFeatureTests.swift › 삭제가 실패해도 다시 삭제를 진행할 수 있다 | 기능 Feature 테스트 |
| U6 | Tests/Settings/Settings/SettingsFeatureAccountActionTests.swift › (각 @Test의 view 액션 연결과 delegate 전달) | Tests/Settings/Settings/SettingsFeatureTests.swift › 계정 동작 탭은 계정 동작에 대응 input을 보낸다, 계정 동작 delegate는 기존 Settings delegate로 올린다 | 합성 지점 검증 |
| U6 | Tests/Settings/Router/SettingsRouterFeatureTests.swift › 계정 삭제 행은 확인 화면으로, 취소는 목록으로 되돌리며 확인 상태를 해제한다 | Tests/Settings/Router/SettingsRouterFeatureTests.swift › 계정 삭제 행은 확인 화면으로, 취소는 목록으로 되돌리며 확인 상태를 해제한다(수신 Action 경로 `settings.accountAction`) | 합성 지점 검증 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록이 갱신되면 페이지네이션을 다시 설정한다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록이 갱신되면 페이지네이션을 다시 설정한다(페이지네이션에 `listReplaced` 전달 수신) | 합성 지점 검증 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록이 갱신되면 페이지네이션을 다시 설정한다(전이 단언) | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › listReplaced는 다음 페이지 여부를 저장하고 페이지네이션을 다시 설정한다 | 기능 Feature 테스트 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록 끝에 닿으면 다음 페이지를 한 번 요청한다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록 끝에 닿으면 다음 페이지를 한 번 요청한다(페이지네이션에 `nextPageRequested` 전달 수신) | 합성 지점 검증 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 목록 끝에 닿으면 다음 페이지를 한 번 요청한다(전이 단언) | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › 대기 상태의 nextPageRequested는 다음 페이지를 요청하고 다음 페이지 여부로 결과 상태를 정한다 | 기능 Feature 테스트 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 다음 페이지가 없으면 목록 끝에 닿아도 요청하지 않는다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 다음 페이지가 없으면 목록 끝에 닿아도 요청하지 않는다(상태 경로만 변경) | 합성 지점 검증 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 다음 페이지를 불러오는 중에는 같은 요청을 반복하지 않는다 | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › 대기 상태가 아니면 nextPageRequested를 무시한다 | 기능 Feature 테스트 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 첫 조회 전에는 목록 끝에 닿아도 다음 페이지를 요청하지 않는다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 첫 조회 전에는 목록 끝에 닿아도 다음 페이지를 요청하지 않는다 | 합성 지점 검증 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 다음 페이지 조회에 실패하면 재시도로 다시 요청한다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 다음 페이지 조회에 실패하면 재시도로 다시 요청한다(수신 Action 경로 `pagination`) | 합성 지점 검증 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 다음 페이지 조회에 실패하면 재시도로 다시 요청한다(전이 단언) | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › 다음 페이지 조회 실패는 실패 상태로 남긴다, 실패 상태의 retry는 다음 페이지를 다시 요청한다 | 기능 Feature 테스트 |
| U7 | (새 테스트) | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › 실패 상태가 아니면 retry를 무시한다 | 기능 Feature 테스트 |
| U7 | (새 테스트) | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › refreshStarted는 진행 중인 다음 페이지 요청을 취소한다 | 기능 Feature 테스트 |
| U7 | (새 테스트) | Tests/ProjectList/ProjectList/ProjectListPaginationFeatureTests.swift › 조회 중이 아닐 때 도착한 결과는 반영하지 않는다 | 기능 Feature 테스트 |
| U7 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 새로고침 입력은 목록에 refresh를 보낸다 | Tests/ProjectList/ProjectList/ProjectListFeatureTests.swift › 새로고침 입력은 목록에 refresh를 보낸다(페이지네이션에 `refreshStarted` 전달 수신) | 합성 지점 검증 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 진입하면 상세를 조회하고 세트 진행 표시를 서버 값 그대로 파생한다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 진입하면 상세를 조회하고 세트 진행 표시를 서버 값 그대로 파생한다(수신 Action·상태 경로 `detailLoad`) | 합성 지점 검증 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 진입하면 상세를 조회하고 세트 진행 표시를 서버 값 그대로 파생한다(조회 전이) | Tests/ProjectDetail/ProjectDetail/ProjectDetailLoadFeatureTests.swift › load는 조회 중으로 바꾸고 성공 결과를 상세로 남긴다 | 기능 Feature 테스트 |
| U8 | (새 테스트) | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 진입·재시도·갱신 요청은 상세 조회에 load를 보낸다 | 합성 지점 검증 |
| U8 | (새 테스트) | Tests/ProjectDetail/ProjectDetail/ProjectDetailLoadFeatureTests.swift › 이미 조회한 상세가 있어도 load는 무조건 조회 중으로 바꾼다 | 기능 Feature 테스트 |
| U8 | (새 테스트) | Tests/ProjectDetail/ProjectDetail/ProjectDetailLoadFeatureTests.swift › 현재 request ID와 다른 결과는 상태를 바꾸지 않는다 | 기능 Feature 테스트 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 저장소 시작 컨트롤은 첫 미완료 세트로 같은 의도를 만든다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 저장소 시작 컨트롤은 첫 미완료 세트로 같은 의도를 만든다(상태 경로 `detailLoad`) | 합성 지점 검증 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 미완료 세트가 없으면 시작 컨트롤이 비활성이고 입력이 아무 일도 하지 않는다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 미완료 세트가 없으면 시작 컨트롤이 비활성이고 입력이 아무 일도 하지 않는다(상태 경로 `detailLoad`) | 합성 지점 검증 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 저장소 시작 컨트롤은 첫 미완료 세트로 같은 의도를 만든다(파생값) | Tests/ProjectDetail/ProjectDetail/ProjectDetailLoadFeatureTests.swift › 첫 미완료 세트와 시작 가능 여부는 상세에서 파생한다 | 기능 Feature 테스트 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 갱신 요청은 상세를 다시 조회해 서버 값을 그대로 반영한다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 갱신 요청은 상세를 다시 조회해 서버 값을 그대로 반영한다(수신 Action·상태 경로 `detailLoad`) | 합성 지점 검증 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 조회에 실패하면 오류 의미를 보존한다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailLoadFeatureTests.swift › 조회에 실패하면 오류 의미를 보존한다 | 기능 Feature 테스트 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 조회에 실패하면 오류 의미를 보존한다(합성 경로) | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 조회에 실패하면 오류 의미를 보존한다(수신 Action·상태 경로 `detailLoad`) | 합성 지점 검증 |
| U8 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 세트 시작은 라벨만 담은 진입 의도를 만든다 | Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift › 세트 시작은 라벨만 담은 진입 의도를 만든다(상태 준비 경로만 변경) | 합성 지점 검증 |
| U8 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › 풀이 중 답안을 제출하면 프로젝트 목록도 상세도 갱신하지 않는다 | App/Tests/GitIt/Reducers/AppRootFeatureTests.swift › 풀이 중 답안을 제출하면 프로젝트 목록도 상세도 갱신하지 않는다(상태 경로 `projectDetail.projectDetail.detailLoad`) | 합성 지점 검증 |

**U2 비고**: Settings의 `task`는 프로필이 없으면 `load`, 이미 있으면 `reload`를 보낸다. 기존 Settings는 재진입
조회 중에도 받은 프로필 값을 계속 보여 주고 그 실패를 화면에 드러내지 않았으므로, 이 관찰 동작을
그대로 유지하려고 contracts의 "task 때 `load`"를 `reload` 분기로 구체화했다. 고정 테스트는
`SettingsFeatureTests › 이미 받은 프로필이 있으면 task는 값을 유지한 채 reload를 보낸다`다. Settings의 자식
필드는 `userProfile`로 두고 기존 `profile`은 자식에서 파생한 computed로 남겨, U6 소유 서브뷰를 U2에서
바꾸지 않는다.

**U3 비고**: 같은 기능 Feature를 같은 navigation 경로에서 두 부모가 `Scope`로 합성하면 private
`CancelID`가 겹쳐 한 인스턴스의 새로고침·관찰이 다른 인스턴스를 취소한다(App 테스트
`포그라운드 목록 갱신이 실패해도 mainShell 화면을 유지한다`에서 발견). `ProjectSummaryListFeature`는 State에
인스턴스 식별자를 두고(동등성 비교에서 제외) 취소 ID를 인스턴스별로 만든다(FR-026). 또
`HomeFeatureGuestAccessTests.swift`는 T038 목록에 없지만 `projectRequestID` 경로가 사라져 컴파일되지 않으므로
U3에서 상태 경로만 바꿨다.

**U4 비고**: `ProjectDeletionFeature`도 U3과 같은 이유로 취소 ID를 인스턴스별로 만든다. research §4 I3의
동작 차이 1은 `ProjectDetailFeatureTests › 이미 사라진 프로젝트를 삭제하면 삭제 완료를 알린다`, 동작 차이 2는
`ProjectListFeatureTests › 삭제 실패 뒤에도 다시 삭제를 요청할 수 있다`가 고정한다.

**U5 비고**: MainShell의 로그인 취소는 기존에 `idle`로 돌아갔지만 `SignInFeature`는 `cancelled`로 둔다.
MainShell은 `failed`만 alert로 표시하고 `cancelled`에서도 `start`를 받으므로 관찰 동작은 같다. Tutorial의
화면 본문과 `SignInSection`은 로그인 상태를 참조하지 않아 T062에서 바꿀 곳이 없고 Preview만 바꿨다.
`OnboardingRouterPreviews.swift`와 `MainShellAccountUseCaseStub.swift`도 새 구조에서 그대로 compile되어 수정하지
않았다. Tutorial의 `input.returnToLastPage`는 큐레이션 이탈 복귀에서 Router가 계속 쓰므로 남겼다.

**U6 비고**: `SettingsFeature`의 view 액션(`positionSelected`, `signOutTapped` 등)은 그대로 두고 자식 input으로
바꿔 보낸다. 화면 View는 상태 참조 경로만 바뀌고 액션 연결은 바뀌지 않는다(SC-012). 알림 권한 조회 결과
Effect 이름은 자식 안에서 `authorizationChecked`로 바꿨다. `SettingsTestFixture.swift`는 새 구조에서 그대로
쓰여 수정하지 않았다.

**U7 비고**: `ProjectListPaginationFeature`는 마지막으로 받은 `hasNextPage`를 함께 보관해, 다음 페이지 조회
성공 뒤 `idle`·`exhausted` 판정을 기존처럼 목록의 다음 페이지 여부로 한다. 목록 조건(`loaded`, `hasNextPage`)
판정은 부모에 남긴다.

**U8 비고**: `ProjectDetailFeature`의 `projectID`는 자식 `detailLoad.projectID`에서 파생한다. 상세 화면의
`RepositorySummaryView`와 `ProjectDetailRouterFeature.swift`, `ProjectDetailRouterFeatureTests.swift`는
상세 조회 상태를 직접 참조하지 않아 수정하지 않았다.
