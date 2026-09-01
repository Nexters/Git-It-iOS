# 구현 계획: 등록 흐름·홈 화면 UX 결함 해소

**Git-flow 유형**: `feature`

**브랜치**: `feature/registration-home-ux-fixes`

**날짜**: 2026-09-01(초판), 2026-09-02(개정) | **명세**: [spec.md](./spec.md)

**입력**: `/specs/023-registration-home-ux-fixes/spec.md`의 기능 명세

## 요약

프로젝트 등록 흐름과 홈 화면에서 확인된 UX 결함 8건을 해소한다. 링크 입력 화면의 키보드
동작(FR-001~004), 홈 카드 배치와 로딩 표시(FR-017~023)는 화면 계층에서 끝나는 국소 수정이다.
나머지 세 덩어리는 계층을 가로지른다.

- **최소 대기 시간 게이트**: 진행 화면 전이·완료 알림 발송·홈 진행 중 표시 해제를
  `max(요청 + 300초, 결과 확정)`이라는 하나의 시점으로 묶는다. 규칙은 Domain이 소유하고
  Feature와 Composition이 같은 값을 참조한다(R-005).
- **생성 진행 상태의 영속화**: 진행 상태를 기기에 보존해 앱 재실행 후 복원한다. 기존
  `PolicyConsent` 저장 경로(Data 계약 → Composition 어댑터 → Domain 계약)를 그대로 따른다(R-008).
- **공유 시트 진입**: 앱 확장 target을 새로 추가해 URL 공유를 받고, App Group 컨테이너로
  URL을 전달한다(R-010). 확장은 URL 형식을 판정하지 않으며(FR-028, FR-029), 앱은 전달받은
  URL로 링크 입력 화면에 랜딩한 뒤 "다음"을 1회 자동 실행한다(FR-025a, R-013).

항목 8(유저 프로필 이미지)은 현행 구현이 이미 요구를 충족하므로 코드를 바꾸지 않고 회귀
확인만 한다(R-012).

기술 판단의 근거와 기각한 대안은 [research.md](./research.md)에, 타입 정의는
[data-model.md](./data-model.md)에, 패키지 경계를 넘는 공개 계약은
[contracts/](./contracts/)에 있다. 검증 절차는 [quickstart.md](./quickstart.md)를 따른다.

## 2026-09-02 개정

`/speckit-clarify` 세션 2026-09-02이 공유 진입의 검증 소유자와 랜딩 후 동작을 확정해 이
계획을 개정했다.

| 확정 | 계획 반영 |
| --- | --- |
| 공유 확장은 URL 형식을 판정하지 않고 그대로 넘긴다(FR-028, FR-029) | R-014 신설. U13의 확장 소스에서 판정 로직과 Data 의존 제거 |
| 랜딩 후 "다음"을 1회 자동 실행한다(FR-025a) | R-013 신설. U12 범위 확대 |

초판 계획의 「외부 입력 검증」 결정(확장에서 검증하지 않는다)은 그대로 유효하다. 개정은
그 결정을 코드에 다시 맞추는 일과, 새로 추가된 자동 실행 요구를 배정하는 일 두 가지다.
구현이 이미 진행된 상태에서 개정됐으므로 남은 작업은 아래 「2026-09-02 개정 이후 남은 작업」에
델타로 정리했다.

## 기술 맥락

**언어/버전**: Swift(`SWIFT_VERSION = 5.0` 설정, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
`SWIFT_APPROACHABLE_CONCURRENCY = YES`)

**주요 의존성**: SwiftUI, The Composable Architecture, Tuist, UserNotifications,
Firebase Messaging(기존 원격 푸시 경로)

**저장소**: `InfrastructureStorage.UserDefaultsStore`(생성 진행 상태), App Group 공유
컨테이너(공유 URL 전달). Keychain은 기존 인증 경로에만 사용하며 이번 범위에서 변경하지 않는다.

**테스트**: Swift Testing 기본. 테스트 함수 이름은 한국어 동작 문장. TCA `TestStore`로 Feature
동작을 검증하고, 시간 의존은 짧은 `GenerationWaitPolicy`와 고정 `now` 주입으로 검증한다.

**대상 플랫폼**: iOS 26.0 이상. 기본 테스트 destination은
`platform=iOS Simulator,name=iPhone 17 Pro`.

**프로젝트 유형**: 모바일 앱. Tuist 기반 멀티 패키지(App, Composition, Feature, Domain, Data,
Infrastructure, UI).

**성능 목표**: 홈 카드 가로 스크롤의 회전 효과가 기존 프레임 성능을 유지한다. 진행 화면 완료
전이·알림 발송·홈 표시 해제의 시점 차이 1초 이내(SC-009).

**제약 조건**:

- Domain/Data는 프로젝트 내부 패키지에 의존하지 않는다. Data는 Domain 계약을 직접 구현할 수
  없어 Composition 어댑터를 경유한다([아키텍처 3.1](../../docs/architecture.md)).
- 의존성은 생성자 주입으로만 전달한다. `@Dependency` 키, Service Locator, 전역 mutable
  container를 production 경로에 쓰지 않는다.
- 공유로 전달받은 URL은 검증 전 외부 입력이다. 기존 링크 검증 경로를 통과하기 전에는 어떤
  요청에도 사용하지 않는다.
- 예약 알림은 시스템(`UNUserNotificationCenter`)이 보관해야 한다. 인프로세스 타이머는 앱
  정지 시 발화하지 않아 FR-010을 충족하지 못한다.

**규모/범위**: 변경 패키지 7개, 신규 target 1개(공유 확장), 수정 화면 3개(링크 입력, 생성 진행,
홈), 신규 Domain 타입 3개, 실행 단위 13개(`tasks.md`에서 패키지 8단계로 재편).

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

### 설계 전 점검 (통과)

**브랜치 네임스페이스**: `feature/registration-home-ux-fixes`를 `/speckit-specify`가 명세
산출물 작성 전에 현재 HEAD(`dfa8604`)에서 직접 생성하고 검증했다. 개정 후 생성된 브랜치이며
`feature/` 네임스페이스가 목적에 맞는다. 통과.

**허용 수정 경로**: 이 명령은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
`contracts/**`만 작성했다. 구현 파일은 아래 실행 단위에 경로로만 기록했다. 통과.

**세션 지식 기록**: Constitution 원칙 9의 기록 문턱을 이번 계획 단계에서는 충족하지 않는다.
구현 중 재사용 가능한 원인·복구 절차나 문서화되지 않은 규칙 해석이 나오면 그때
`speckit-troubleshooting` 또는 `speckit-tacit-knowledge`를 별도로 사용한다. 계획 산출물이나
구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 이 계획은 Git index나 작업 파일을 바꾸지 않는다. 구현 단계에서 각
커밋 체인을 하나씩만 실행하고, 이전 체인의 종료와 결과를 확인한 뒤 다음으로 넘어간다.

**커밋 단위 구현**: 아래 「실행 단위」가 13개 단위를 목적·패키지·파일 경로·검증으로 나눴고,
`tasks.md`가 이를 패키지 8단계로 재편했다. 단일 패키지 단위가 대부분이고, 분리하면
`tuist generate`가 성립하지 않는 공유 확장만 다중 패키지 통합 단위다.

**책임 기반 네이밍**: 새로 만드는 공개 이름은 책임을 드러내고 최소 문맥만 포함한다.
`GenerationProgress`, `GenerationWaitPolicy`, `GenerationProgressRepository`,
`TrackGenerationProgressUseCase`, `SharedRepositoryLink`는 기존
`GenerationOutcome`, `GenerationReminderRegistry`와 같은 어휘를 이어받는다. 저장 기술 이름은
경계에 노출하지 않는다(Domain 계약은 `Repository`, 저장 기술을 아는 이름은 Data의
`LocalGenerationProgressStore`에만 둔다). 일괄 접두어·축약은 적용하지 않는다.

**실행 단위 진행**: 변경 패키지를 식별하고 의존성 위상 순서로 정렬했다(아래). 각 단위의
변경 파일과 검증 결과를 진행 상황으로 보고하며, 같은 기능 범위의 다음 단위는 반복 승인 없이
진행한다.

### 설계 후 재점검 (통과)

1단계 설계를 마친 뒤 다시 확인했다.

| 항목 | 결과 |
| --- | --- |
| 의존성 방향 | Domain은 내부 무의존, Data는 Infrastructure만 참조, Feature는 Domain·UI만 참조. Data가 Domain 계약을 직접 구현하지 않고 Composition 어댑터를 경유하도록 설계했다. 위반 없음 |
| 생성자 주입 | `GenerationWaitPolicy`, `now`, 저장소·클라이언트를 모두 생성자 인자로 전달한다. `@Dependency` 키를 도입하지 않는다 |
| 상태 소유자와 수명 | 진행 상태의 소유자는 `AppRootFeature`이고 영속 사본은 Domain 계약을 통해 저장한다. 수명은 `max(readyDate, 결과 확정)`과 보존 상한으로 한정했다(원칙 2) |
| 비동기 오류·취소 | 대기는 취소 가능한 Effect로 두고, 등록 파이프라인의 기존 `CancelID` 경계를 유지한다 |
| 외부 입력 검증 | 공유 URL은 확장에서 검증하지 않고 앱의 기존 링크 검증 경로로 넘긴다. 자동 실행되는 "다음"도 사용자가 누른 경로와 같은 검증을 거친다(R-013, R-014) |
| 파일당 타입 1개 | 신규 타입은 모두 개별 파일로 배치했다(data-model.md의 경로 참조) |
| 검증 가능한 변경 | 각 실행 단위에 집중 검증을, 마지막 단위에 전체 읽기 전용 검증을 배정했다 |

**복잡성 추적 없음**: 정당화가 필요한 헌법 위반이 없다. 공유 확장의 다중 패키지 통합 단위는
원칙 7이 허용하는 형태이며 분리 불가 근거를 아래에 기록했다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/023-registration-home-ux-fixes/
├── spec.md              # 기능 명세(/speckit-specify, /speckit-clarify)
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물
├── data-model.md        # 1단계 산출물
├── quickstart.md        # 1단계 산출물
├── contracts/           # 1단계 산출물
│   ├── domain-generation-progress.md
│   ├── feature-and-ui-surface.md
│   ├── infrastructure-local-notification.md
│   └── share-entry.md
├── checklists/
│   └── requirements.md  # 명세 품질 체크리스트
└── tasks.md             # 2단계 산출물(/speckit-tasks, 이 명령이 생성하지 않음)
```

### 소스 코드(저장소 루트)

변경·추가 대상만 표시한다. `+`는 신규 파일이다.

```text
sources/
├── Tuist/ProjectDescriptionHelpers/Projects/
│   └── AppModuleName.swift                     # 공유 확장 target, App Group, URL 스킴
└── Projects/
    ├── Domain/LearningProject/
    │   ├── Models/LearningProject/
    │   │   ├── GenerationProgress.swift                      +
    │   │   └── GenerationWaitPolicy.swift                    +
    │   ├── Contracts/GenerationProgressRepository.swift      +
    │   └── UseCases/TrackGenerationProgress/
    │       ├── TrackGenerationProgress.swift                 +
    │       └── TrackGenerationProgressUseCase.swift          +
    ├── Infrastructure/PushMessaging/Local/Clients/
    │   ├── LocalNotificationClient.swift          # schedule/cancel 추가
    │   └── UserNotificationCenterLocalClient.swift
    ├── Data/LearningProject/
    │   ├── DTOs/GenerationProgressDTO.swift                  +
    │   ├── Contracts/GenerationProgressStore.swift           +
    │   └── Stores/LocalGenerationProgressStore.swift         +
    ├── UI/Component/Controls/LabeledTextField/
    │   └── LabeledTextField.swift                # 포커스 바인딩 노출
    ├── Feature/
    │   ├── ProjectRegistration/
    │   │   ├── Reducers/ProjectRegistrationFeature.swift     # 대기 게이트, 초기 입력값
    │   │   └── Screens/ProjectRegistrationScreen.swift       # 키보드 동작
    │   └── Home/
    │       ├── Reducers/HomeFeature.swift                    # 진행 중 입력 수신
    │       └── Screens/HomeScreen.swift                      # 진행 중 패널, 카드 배치·높이
    ├── Composition/Adapter/
    │   ├── Adapters/GenerationProgressRepositoryAdapter.swift +
    │   ├── Factories/GenerationCompletionReminderCoordinator.swift  # 예약 발송으로 전환
    │   └── Assemblies/{AppComposition,LearningProjectAssembly}.swift
    └── App/
        ├── GitIt/Models/SharedRepositoryLink.swift            +
        ├── GitIt/Reducers/AppRootFeature.swift                # 진행 상태 수명·복원, 공유 진입
        ├── GitIt/GitItApp.swift                               # URL 스킴 수신
        ├── GitIt.entitlements                                 # App Group
        └── ShareExtension/                                    +  신규 확장 target 소스
```

테스트는 각 패키지의 `Tests/` 아래 대응 경로에 둔다(예:
`sources/Projects/Feature/Tests/Home/Reducers/`,
`sources/Projects/Domain/Tests/LearningProject/UseCases/`).

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 그대로 사용한다. 새 패키지는 만들지 않고, 새
target은 공유 확장 하나만 추가한다. 확장 소스는 App 프로젝트 아래 `ShareExtension/` 폴더에
두어 `AppModuleName`이 소유하게 한다(폴더 이름은 역할만 사용하는 컨벤션을 따른다).

## 실행 단위

### 변경 패키지와 위상 순서

`A → B`는 A가 B를 빌드 의존성으로 참조한다는 뜻이다. 의존 대상을 먼저 구현한다.

```text
Domain, Infrastructure, UI   (내부 의존 없음)
        ↓
      Data                   (→ Infrastructure)
        ↓
Feature (→ Domain, UI)   Composition (→ Domain, Data, Infrastructure)
        ↓                        ↓
              App (→ Feature, Composition, Domain)
```

Feature와 Composition은 서로 의존하지 않으므로 상대 순서는 자유다. 아래 순서는 `tasks.md`가
확정한다.

### 단위 목록

| # | 패키지 | 목적 | 주요 요구사항 |
| --- | --- | --- | --- |
| U1 | UI | `LabeledTextField`에 포커스 바인딩 노출 | FR-002 |
| U2 | Feature | 링크 입력 화면 키보드 회피 억제와 빈 영역 터치 해제 | FR-001~004 |
| U3 | Feature | 첫 카드 기울기가 0이 되도록 기준 위치를 측정값으로 전환 | FR-021~023 |
| U4 | Feature | 카드 영역 높이 통일과 로딩 표시 정리 | FR-017~020 |
| U5 | Domain | 진행 상태 모델·대기 정책·저장 계약·추적 UseCase | FR-005, FR-008, FR-011 |
| U6 | Infrastructure | 로컬 알림 예약·취소 API 추가 | FR-010, FR-012, FR-014 |
| U7 | Data | 진행 상태 로컬 저장소와 DTO | FR-005 |
| U8 | Composition | 저장소 어댑터 조립과 완료 알림 예약 전환 | FR-010~016 |
| U9 | Feature | 등록 흐름 최소 대기 게이트(완료·실패 공통) | FR-012, FR-013 |
| U10 | Feature | 홈 진행 중 표시와 진입 차단 | FR-005~009 |
| U11 | App | 진행 상태 수명 소유·복원과 홈 전달 | FR-005, FR-008 |
| U12 | Feature | 링크 입력 초기값 주입 지점과 랜딩 후 "다음" 1회 자동 실행 | FR-025, FR-025a |
| U13 | **통합** App + Tuist manifest | 공유 확장 target과 앱 소비 경로 | FR-024, FR-026~029 |

U1~U4는 다른 단위에 의존하지 않는 국소 수정이라 먼저 배치했다. U2는 U1의 공개 API를 쓰므로
그 뒤에 온다.

**tasks.md와의 관계**: `/speckit-tasks`가 위 13개 단위를 패키지 8단계로 재편했다. 최종 실행
구조는 `tasks.md`가 정본이다.

| tasks.md 단계 | 대응 단위 |
| --- | --- |
| 패키지 0 작업 트리 소유권 확정 | 계획 단계에 없던 단위. 이 브랜치의 커밋되지 않은 변경이 U2~U4·U10의 대상 파일과 겹쳐 추가됐다 |
| 패키지 1 Domain | U5 |
| 패키지 2 Infrastructure | U6 |
| 패키지 3 UI | U1 |
| 패키지 4 Data | U7 |
| 패키지 5 Feature | U2, U3, U4, U9, U10, U12 |
| 패키지 6 Composition | U8 |
| 패키지 7 App | U11, U13 |

U1~U4를 앞에 두려던 이 계획과 달리 `tasks.md`는 위상 순서를 우선했다. 그 결과 S1·S4·S5의
완료 시점이 뒤로 밀린다.

### U13을 다중 패키지 통합 단위로 두는 근거

- **포함 대상**: `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift`,
  `sources/Projects/App/ShareExtension/**`(신규), `sources/Projects/App/GitIt.entitlements`,
  확장용 entitlements와 Info.plist, `sources/Projects/App/GitIt/GitItApp.swift`,
  `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`,
  `sources/Projects/App/GitIt/Models/SharedRepositoryLink.swift`.
- **분리 불가 이유**: manifest에 target을 선언하지 않으면 확장 소스는 어떤 빌드 대상에도
  속하지 않고, 소스 없이 target만 선언하면 `tuist generate` 후 빌드가 실패한다. App Group
  entitlement도 앱과 확장 양쪽에 동시에 존재해야 컨테이너 접근이 성립한다. 중간 상태가
  컴파일되지 않으므로 나눌 수 없다.
- **의존 순서**: manifest·entitlements → 확장 소스 → 앱 소비 경로.
- **통합 검증**: `tuist generate` 후 전체 build, 이어서 compile·test.
  [quickstart.md](./quickstart.md)의 시나리오 6 수동 절차로 공유 시트 노출과 랜딩을 확인한다.
- 편의상 묶은 것이 아니다. 나머지 12개 단위는 모두 단일 패키지로 나뉘어 있다.

### 2026-09-02 개정 이후 남은 작업

초판 계획의 13개 단위는 구현·검증을 마쳤다. 개정으로 생긴 델타만 아래에 남긴다. 실행 순서는
`/speckit-converge`가 `tasks.md` 끝에 새 단계로 추가한다.

| 단위 | 패키지 | 작업 | 파일 | 요구사항 |
| --- | --- | --- | --- | --- |
| U12′ | Feature | View lifecycle Action(`task`) 추가, 1회용 자동 실행 표식을 `State.init(initialRepositoryURL:)`에서 세우고 `task`에서 소비, `validateTapped`와 공통 시작 경로 추출 | `sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift`, `sources/Projects/Feature/ProjectRegistration/Screens/ProjectRegistrationScreen.swift`, `sources/Projects/Feature/ProjectRegistration/Tests/ProjectRegistrationFeatureTests.swift` | FR-025a |
| U13′ | **통합** App + Tuist manifest | 확장에서 `GitHubRepositoryURLParser` 판정과 `DataExternalRepository` 의존 제거, URL 항목의 첫 번째 값을 형식 무관하게 기록 | `sources/Projects/App/ShareExtension/ShareViewController.swift`, `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift` | FR-028, FR-029 |

- U13′도 확장 소스와 manifest의 의존성 선언을 함께 바꿔야 `tuist generate` 후 빌드가
  성립하므로 초판 U13과 같은 이유로 통합 단위다.
- U12′는 Feature 단일 패키지다. U13′과 파일이 겹치지 않아 순서 제약이 없지만, 통합 검증은
  두 단위가 모두 끝난 뒤 한 번 수행한다.
- `ExternalRepositoryURLParser`(Domain) · `GitHubRepositoryURLParser`(Data) ·
  `ExternalRepositoryURLParserAdapter`(Composition)는 앱 경로에서 계속 쓰이므로 되돌리지
  않는다(R-014).

### 패키지에 속하지 않는 파일의 배정

| 파일 | 배정 단위 | 근거 |
| --- | --- | --- |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift` | U13 | App 프로젝트의 target 구성을 선언하는 파일이라 App 책임 |
| `sources/Projects/App/GitIt.entitlements` | U13 | 앱 서명 구성. 확장 entitlements와 동시에 존재해야 함 |
| 확장 Info.plist·entitlements(신규) | U13 | 확장 target 구성 |

배정하지 못한 파일은 없다.

### 단위별 검증

각 단위는 자기 패키지의 테스트로 집중 검증하고, 마지막 단위(U13)에서 전체 읽기 전용 검증을
수행한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

- 단위 진행 중: 해당 패키지 테스트 target 중심으로 `compile`·`test`
- 마지막 단위: `build` → `compile` → `test` 전체 순차 실행(공유 DerivedData이므로 병렬 금지)
- 셸 스크립트를 건드리면 `tools/script-tests`와 `tools/script-verification` 실행

### 승인이 필요한 지점

명시적 승인은 아래에서만 요청한다. 그 외 단위는 확정된 범위의 후속 작업이므로 반복 승인 없이
진행한다.

| 지점 | 이유 |
| --- | --- |
| `tasks.md` T001에서 기존 작업 트리 변경의 소유권 확정 | 이 브랜치의 커밋되지 않은 8개 경로가 패키지 1·5의 작업 대상과 겹친다. 사용자 소유 변경을 이 명세의 커밋이 소비할지 결정한다(Constitution 원칙 7) |
| U13(`tasks.md` T041)에서 App Group 식별자·URL 스킴과 확장 target 이름 확정 | 앱 서명 구성과 외부에 노출되는 식별자를 새로 도입하는 제품 결정 |
| U5(`tasks.md` T003)에서 `GenerationWaitPolicy.retentionLimit` 값 확정 | 명세가 상한의 존재만 요구하고 값을 정하지 않았다. 제안값은 86400초(24시간) |

2026-09-02 개정의 델타(U12′·U13′)에는 새 승인 게이트가 없다. 자동 실행과 확장의 무판정은
`/speckit-clarify` 세션 2026-09-02에서 사용자가 확정했고, U13′은 새 식별자나 서명 구성을
도입하지 않고 이미 있는 확장 target에서 의존성과 판정 코드를 제거하기만 한다.

## 계획 단계에서 남긴 미결 사항

초판이 남긴 두 건은 구현 단계에서 확정됐다.

1. `GenerationWaitPolicy.retentionLimit`(R-008) → **3600초**. `GenerationWaitPolicy.standard`에
   `minimumWait = 300`과 함께 고정했다.
2. App Group 식별자와 커스텀 URL 스킴(R-010) → **`group.com.nexters.hytime.gitit`**,
   **`gitit`**(랜딩 URL `gitit://shared-link`), 확장 target 이름 **`ShareExtension`**.
   사용자 승인을 받아 `AppModuleName.swift`와 양쪽 entitlements에 등록했다.

2026-09-02 개정이 새로 남긴 미결 사항은 없다.

## 범위에 대한 참고

명세의 8개 항목 중 5건은 화면 계층에서 끝나지만, 항목 4·5·6은 Domain·Data·Infrastructure·
Composition·App까지 내려간다. 특히 진행 상태 영속화(명확화 10)와 공유 확장(항목 6)이 전체
작업량의 대부분을 차지한다. 두 결정 모두 명세 단계에서 사용자가 명시적으로 선택한 것이며,
구현 비용이 예상보다 크면 각각 「앱 실행 중에만 유지」와 「후속 기능으로 분리」로 축소할 수
있다. 축소는 명세 변경이므로 `/speckit-clarify` 또는 사용자 확인을 거친다.
