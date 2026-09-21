# Feature 분류 — 기능·화면 합성·전환 계층

[Git It iOS TCA 컨벤션 — Feature 분리](../feature.md)의 규칙 문서입니다.

**Feature 패키지의 모든 Reducer는 기능 Feature, 화면 합성 Feature, 전환 계층 중 정확히
하나로 분류합니다.** 분류는 이름이 아니라 State·Action·`body`의 실제 내용으로 판정하고,
코드에는 분류 표식을 붙이지 않습니다. 분류는 이 문서와 디렉터리 위치로 드러납니다.

## 세 분류

Reducer는 자식 합성 여부와 소유하는 상태의 성격으로 나눕니다. 기능 Feature는 관심사를,
화면 합성 Feature는 화면의 표시 범위를, 전환 계층은 전환 컨텍스트를 소유합니다.

### 분류 기준

| 분류 | 판정 조건 | 소유할 수 있는 것 | 소유하지 않는 것 |
| --- | --- | --- | --- |
| **기능 Feature** | 자식 Feature를 합성하지 않거나 기능 Feature만 합성하고, State가 [관심사 하나](./definition-unit.md#관심사-판별)에 속한다 | 그 관심사의 상태 유형, 전이 규칙, Effect, delegate | View, 합성한 화면이나 상위를 식별하는 분기, 화면 전환 목적지 |
| **화면 합성 Feature** | Screen 하나에 대응하고 기능 Feature를 하나 이상 자식으로 합성한다 | 표시 범위(표시 전용 플래그, alert 표시 여부), 자식 결과에 대한 화면 고유 후속 동작, 상위로 올리는 delegate | 기능 관심사의 상태 유형, 자식 내부 상태의 직접 변경 |
| **전환 계층** | [Router-Feature](../navigation/router.md) 또는 Shell로서 전환 컨텍스트 하나를 소유한다 | 활성 화면 값, 이동 이벤트, 자식 State의 보유·생성, 자식 delegate 해석 | 기능 관심사의 상태 유형, 자식 내부 필드의 직접 변경 |

### 판정 규칙

1. **관심사 하나만 가진 화면의 Feature는 기능 Feature입니다.** 화면이 그 Feature의 store를
   직접 관찰합니다. 감싸기만 하는 화면 합성 Feature를 새로 만들지 않습니다.
2. **자식을 합성하는 순간 그 Feature는 화면 합성 Feature나 전환 계층입니다.** 이때 자기
   화면만 쓰는 관심사를 함께 들고 있으면 그 관심사를 같은 화면 폴더의 기능 Feature로
   분리합니다.
3. **화면 고유 후속 동작은 관심사가 아닙니다.** 자식의 결과를 받아 실행하는 한 번의 후속
   Effect는 화면 합성 Feature에 남습니다. 로그인 성공 뒤 개발용 계정 재설정이 그 예입니다.
4. **같은 관심사의 판정 근거는 상태 모델과 전이 규칙의 동일성입니다.** 이름·화면의
   유사성이나 "적재·실패·재시도" 같은 구현 패턴의 유사성은 근거가 아닙니다. 전이 규칙의
   차이가 재시도 조건이나 실패 표시 범위 같은 정책 차이이면 정본을 골라 하나로 통합하고
   차이를 기록합니다. 상태 모델이나 호출하는 Use Case가 다르면 같은 관심사로 보지 않습니다.
5. **통합 비용이 중복 유지 비용보다 크면 통합하지 않고 사유를 남깁니다.**
6. **상위는 자식 내부 필드를 직접 쓰지 않습니다.** 자식에 값을 알릴 때는 자식의 `input`을
   보냅니다. 자식 State의 생성과 초기화(`State()`로 다시 만들기, optional·`@Presents` 자식의
   생성)는 필드 변경이 아니라 수명 관리이므로 허용합니다.
7. **기능 Feature는 상위가 받은 의존성을 그대로 받습니다.** 상위는 자식을 위해 받은
   의존성을 구현 교체나 새 생성 없이 전달합니다.

## 공용 경계의 배치

기능 Feature는 사용 범위가 좁은 곳에 둡니다. 참조 방향은 **전환 계층 → 화면 → 공용**의
단방향이며, `Feature/Shared/**`는 흐름 디렉터리의 타입을 참조하지 않습니다.

### 배치 기준

| 사용 범위 | 배치 | 예 |
| --- | --- | --- |
| 한 화면만 합성 | 그 화면 폴더 루트 | `Settings/Settings/AccountActionFeature.swift` |
| 한 전환 계층만 합성 | 그 흐름의 `Router/` | `Quiz/Router/LearningSessionFeature.swift` |
| 같은 흐름의 둘 이상 화면 | `Feature/<흐름>/Shared/Reducers/` | 현재 해당 없음 |
| 둘 이상 흐름 | `Feature/Shared/Reducers/` | `UserProfileLoadFeature`, `SignInFeature/` |
| 둘 이상 흐름이 쓰는 값 타입 | `Feature/Shared/Models/` | `MainShellAccess` |

- `Shared/Reducers/`에는 View를 두지 않습니다. 기능 상태를 그리는 View는 그 Feature를 합성한
  화면 폴더에 남습니다(`LegalAgreementScreen`은 `Onboarding/LegalAgreement/`).
- 파일이 둘 이상인 기능 Feature는 타입 패밀리 폴더를 만듭니다(`Shared/Reducers/SignInFeature/`).
- 테스트는 같은 축으로 둡니다(`Tests/Shared/Reducers/<Feature>Tests.swift`).
- 폴더 어휘는 [형태 어휘 표](../../file-vocabulary/shape-vocabulary.md)와
  [Feature 레이아웃](../../directory-file/feature-layout.md)을 따릅니다.
- 같은 부모 아래 여러 번 합성되는 기능 Feature는 State에 인스턴스 식별자를 두고 취소 ID를
  인스턴스별로 만듭니다. `Scope`는 취소 ID의 범위를 나누지 않으므로, 식별자가 없으면 한
  인스턴스의 Effect가 다른 인스턴스의 Effect를 취소합니다. 식별자는 State 동등성 비교에서
  제외합니다.

## 전체 분류표

분류표는 현재 코드의 모든 Reducer가 위 기준 중 어디에 속하는지 보여 주는 판정 사례입니다.
Reducer를 추가하거나 분류가 바뀌면 이 표를 함께 갱신합니다.

### 분류표

Feature 패키지의 비테스트 `@Reducer` 39개입니다.

| 흐름 | Reducer | 분류 | 합성·비고 |
| --- | --- | --- | --- |
| AppEntry | `AppEntryFeature` | 기능 | 진입 복원·목적지 판단. 화면이 직접 관찰 |
| Home | `HomeFeature` | 화면 합성 | `UserProfileLoadFeature`·`ProjectSummaryListFeature`. 남는 것: 접근 권한, 로그인 필요 alert, 생성 진행 표시, delegate |
| MainShell | `MainShellRouterFeature` | 전환 계층 | Shell. `SignInFeature`·`SingleQuestionEntryFeature` 합성 |
| ProjectList | `ProjectListFeature` | 화면 합성 | `ProjectSummaryListFeature`·`ProjectDeletionFeature`·`ProjectListPaginationFeature`. 남는 것: `mode` |
| ProjectList | `ProjectListPaginationFeature` | 기능 | 다음 페이지 조회 |
| Saved | `SavedFeature` | 기능 | 제외 E5 |
| Settings | `ProfileFeature` | 화면 합성 | `UserProfileLoadFeature`. 남는 것: 설정 이동 delegate |
| Settings | `SettingsFeature` | 화면 합성 | `UserProfileLoadFeature`·`CurationUpdateFeature`·`AccountActionFeature`·`NotificationPermissionFeature`. 남는 것: 약관 URL, 행 탭 delegate |
| Settings | `CurationUpdateFeature` | 기능 | 직군·연차 즉시 반영 |
| Settings | `AccountActionFeature` | 기능 | 로그아웃·회원 탈퇴 |
| Settings | `NotificationPermissionFeature` | 기능 | 알림 권한 |
| Settings | `SettingsRouterFeature` | 전환 계층 | |
| Onboarding | `TutorialFeature` | 화면 합성 | `SignInFeature`. 남는 것: `page`, 개발용 계정 재설정 후속 동작 |
| Onboarding | `PositionSelectionFeature` | 기능 | 제외 E1·E2 |
| Onboarding | `CareerSelectionFeature` | 기능 | 제외 E2 |
| Onboarding | `OnboardingExitFeature` | 기능 | 흐름 이탈 판단. `Onboarding/Router/`에 배치 |
| Onboarding | `OnboardingRouterFeature` | 전환 계층 | |
| ProjectDetail | `ProjectDetailFeature` | 화면 합성 | `ProjectDetailLoadFeature`·`ProjectDeletionFeature`. 남는 것: `isMenuPresented`, delegate |
| ProjectDetail | `ProjectDetailLoadFeature` | 기능 | 프로젝트 상세 조회 |
| ProjectDetail | `ProjectDetailRouterFeature` | 전환 계층 | |
| ProjectRegistration | `RepositoryLinkInputFeature` | 기능 | 화면이 직접 관찰 |
| ProjectRegistration | `RepositoryConfirmationFeature` | 기능 | 화면이 직접 관찰 |
| ProjectRegistration | `QuizLevelSelectionFeature` | 기능 | 화면이 직접 관찰 |
| ProjectRegistration | `QuizGenerationConfirmationFeature` | 기능 | 화면이 직접 관찰 |
| ProjectRegistration | `QuizGenerationProgressFeature` | 기능 | 화면이 직접 관찰. 제외 E8 |
| ProjectRegistration | `ProjectRegistrationRouterFeature` | 전환 계층 | 제외 E4 |
| Quiz | `LearningSetIntroFeature` | 기능 | |
| Quiz | `QuestionSolvingFeature` | 기능 | 제외 E5 |
| Quiz | `LearningCompletionFeature` | 기능 | |
| Quiz | `LearningSessionFeature` | 기능 | 학습 세션 진행. `Quiz/Router/`에 배치 |
| Quiz | `QuizRouterFeature` | 전환 계층 | `LearningSessionFeature` 합성 |
| ShareRegistration | `SharedRepositoryRegistrationFeature` | 기능 | 공유 링크 검증·등록 요청 |
| ShareRegistration | `ShareRegistrationFeature` | 전환 계층 | 단계 전환. `SharedRepositoryRegistrationFeature` 합성. 제외 E4 |
| Shared | `UserProfileLoadFeature` | 기능 (공용) | Home·Profile·Settings |
| Shared | `ProjectSummaryListFeature` | 기능 (공용) | Home·ProjectList |
| Shared | `ProjectDeletionFeature` | 기능 (공용) | ProjectList·ProjectDetail |
| Shared | `SignInFeature` | 기능 (공용) | MainShell·Tutorial. `LegalAgreementFeature` 합성 |
| Shared | `LegalAgreementFeature` | 기능 (공용) | `SignInFeature` |
| Shared | `SingleQuestionEntryFeature` | 기능 (공용) | MainShell·ProjectDetail 전환 계층 |

## 통합하지 않은 후보

비슷해 보이지만 판정 규칙 4·5에 따라 하나로 합치지 않은 후보입니다.

### 제외 사유

| ID | 후보 | 사유 |
| --- | --- | --- |
| E1 | 로그아웃(`AppEntryFeature`, `PositionSelectionFeature`, `AccountActionFeature`) | 공유하는 것은 `signOut()` 호출과 결과 분기뿐입니다. 각각 복원 상태 기계, 온보딩 이탈, 계정 동작 상태 기계 안의 한 전이이며 결과의 후속 의미가 다릅니다 |
| E2 | 직군·연차 선택(온보딩 `PositionSelectionFeature`·`CareerSelectionFeature`, 설정 `CurationUpdateFeature`) | 온보딩은 선택을 초안으로 들고 있다가 `updateCuration` 한 번으로 제출하고, 설정은 선택 즉시 필드별 Use Case를 호출합니다. 전이 규칙과 Use Case가 다릅니다. 표시 매핑 중복은 상태 관심사가 아닙니다 |
| E3 | 적재·실패·재시도 패턴(`SavedFeature`, `ProjectDetailLoadFeature`, `LearningSetIntroFeature` 등) | 구현 패턴만 비슷하고 도메인·payload·오류 타입이 모두 다릅니다 |
| E4 | 저장소 등록 단계 조합(`ProjectRegistrationRouterFeature`, `ShareRegistrationFeature`) | 단계 Feature 셋은 이미 공유합니다. 거절 처리, 조회 전 확인, 등록 뒤 동작이 다른 전환 계층 고유 규칙입니다 |
| E5 | 북마크 토글(`QuestionSolvingFeature`, `SavedFeature`) | 단일 문항 상태와 문항별 map·override로 상태 형태가 다릅니다. 통합하려면 Saved에 문항별 자식 컬렉션이 필요해 중복 유지 비용보다 큽니다 |
| E6 | 단건 문항 열기 조합(`MainShellRouterFeature`, `ProjectDetailRouterFeature`) | 준비 관심사는 `SingleQuestionEntryFeature`로 이미 공유합니다. 남은 차이는 표시 방식이라는 전환 계층 고유 결정입니다 |
| E7 | 의존성 조립 코드 중복(`profile(from:)`, `setBookmark` 클로저, `QuestionSolvingFeature` 조립) | 상태·전이가 아니라 조립 코드의 중복입니다. 동작을 바꾸지 않는 후속 정리로 남깁니다 |
| E8 | 알림 권한(`QuizGenerationProgressFeature`, `NotificationPermissionFeature`) | 진행 화면은 권한 상태를 저장하지 않고 수락 흐름에서만 요청하며, 설정은 권한 상태를 저장하고 행 탭마다 분기합니다 |

## 통합으로 확정한 동작 차이

관심사를 하나로 합치면서 정본을 고른 결과 달라진 동작입니다. 각 차이는 아래 테스트가 고정합니다.

### 동작 차이 목록

| 관심사 | 동작 차이 | 고정 테스트 |
| --- | --- | --- |
| 사용자 프로필 조회 | Settings 프로필 조회에 request identity와 취소가 생겨 늦게 도착한 이전 응답이 상태를 덮어쓰지 않습니다 | `UserProfileLoadFeatureTests › 현재 request ID와 다른 응답은 상태를 바꾸지 않는다` |
| 사용자 프로필 조회 | Settings에서 직군·연차 변경 성공 뒤의 반영(`replace`)이 진행 중인 조회를 무효화합니다 | `UserProfileLoadFeatureTests › replace는 조회 완료 상태로 바꾸고 진행 중인 조회 결과를 무효화한다` |
| 사용자 프로필 조회 | Settings 진입은 프로필이 없으면 `load`, 이미 있으면 보여 주던 값을 유지한 채 `reload`를 보냅니다(기존 관찰 동작 유지) | `SettingsFeatureTests › 이미 받은 프로필이 있으면 task는 값을 유지한 채 reload를 보낸다` |
| 프로젝트 요약 목록 | ProjectList에서 이미 로드된 빈 목록을 새로고침해도 전체 로딩 표시가 다시 나타나지 않습니다 | `ProjectSummaryListFeatureTests › 이미 로드된 빈 목록의 새로고침은 전체 로딩을 다시 세우지 않는다` |
| 프로젝트 삭제 | ProjectDetail에서 이미 삭제된 프로젝트를 삭제하면 실패 대신 삭제 완료로 처리되어 상세 화면이 닫힙니다 | `ProjectDetailFeatureTests › 이미 사라진 프로젝트를 삭제하면 삭제 완료를 알린다` |
| 프로젝트 삭제 | ProjectList에서 삭제 실패 뒤에도 취소하거나 다시 요청할 수 있습니다 | `ProjectListFeatureTests › 삭제 실패 뒤에도 다시 삭제를 요청할 수 있다` |
| 약관 동의를 포함한 로그인 | Onboarding에서 동의 상태 적재가 끝나기 전에 로그인을 누르면 적재 완료를 기다린 뒤 동의 필요 여부를 판단합니다 | `SignInFeatureTests › 동의 상태가 적재되기 전의 start는 적재 완료를 기다린 뒤 동의 필요 여부를 판단한다` |
| 약관 동의를 포함한 로그인 | 동의 화면이 로그인 흐름의 오버레이가 되어 `OnboardingRouterFeature` 이동 이벤트에서 `tutorial ↔ legalAgreement` 항목이 사라집니다. 사용자 화면은 같습니다 | `SignInFeatureTests › 약관 동의를 마치면 로그인한다`, `OnboardingRouterFeatureTests › 로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다` |
| 약관 동의를 포함한 로그인 | MainShell의 로그인 취소는 `cancelled` 상태로 남지만 실패 alert는 `failed`에서만 표시하고 `cancelled`에서도 다시 시작할 수 있어 관찰 동작은 같습니다 | `SignInFeatureTests › 취소나 실패 뒤의 start는 로그인을 다시 시작한다` |
| 약관 동의를 포함한 로그인 | 개발용 계정 재설정 중 진행 표시는 Tutorial의 재설정 진행 상태가 유지하고, 재설정 뒤 재로그인은 저장된 동의로 동의 화면을 거치지 않습니다 | `TutorialFeatureTests › deletesCompletedAccountOnSignIn이 true면 needsCuration false 응답을 받은 뒤 회원탈퇴하고 자동으로 재로그인한다` |

화면 고유 관심사 분리(`ProjectListPaginationFeature`, `CurationUpdateFeature`, `AccountActionFeature`,
`NotificationPermissionFeature`, `ProjectDetailLoadFeature`)와 전환 계층 반납(`LearningSessionFeature`,
`SharedRepositoryRegistrationFeature`, 자식 필드 직접 쓰기의 `input` 전환)은 상태 모델과 전이 규칙을
그대로 옮겼으며 의도한 동작 차이가 없습니다.
