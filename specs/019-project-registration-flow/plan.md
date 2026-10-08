# 구현 계획: 프로젝트 등록·학습 세트 생성 흐름

**Git-flow 유형**: `feature`

**브랜치**: `feature/project-registration-flow`

**날짜**: 2026-08-30 | **명세**: [spec.md](./spec.md)

**입력**: `specs/019-project-registration-flow/spec.md`의 기능 명세

## 요약

Home의 `지금 불러오기`가 출력만 하던 `projectRegistrationRequested` delegate를 실제
등록 화면과 연결한다. 기존 `ProjectRegistrationFeature`(URL 입력 → 검증 → 이해도 선택 →
제출)를 하나의 Feature로 유지한 채, 제출 성공 이후의 "생성 진행" 국면(5단계 정적
체크리스트, `홈에서 기다리기` CTA, 완료 알림 옵션 시트)을 같은 State에 추가한다.
`AppRootFeature`는 `@Presents` 자식으로 `ProjectRegistrationFeature.State`를 소유하고
`fullScreenCover`로 표시해 MainShell 탭 전환을 자연히 차단한다. 실제 생성 완료·실패
판정은 새로 도입하는 Domain 관찰 계약(`ObserveLearningProjectGenerationOutcomesUseCase`)이
공급하는 `AsyncStream`으로만 내리며, 이 스트림은 Composition이 조립하는 다중 구독자
허브가 Infrastructure의 Firebase Cloud Messaging silent push 수신을 Data DTO로 변환한
뒤 공급한다. 알림 채널 자체는 사용자의 시스템 알림 권한과 무관하게 동작해야 하므로
`content-available` silent push만 판정 근거로 쓰고, 배지·사운드 같은 권한 의존 부가 표시는
이번 기능에서 구현하지 않는다. 디바이스 등록은 이미 존재하는
`RegisterMemberDeviceUseCase`/`MemberDeviceInfo`를 재사용한다.

`MessagingDelegate`(FirebaseMessaging SDK) 채택은 Infrastructure의
`FirebaseMessagingPushClient` 안에서 완결한다. Composition은 어떤 UIKit·Firebase
프로토콜도 채택하지 않고 `AppComposition`이 노출하는 두 closure
(`forwardAPNsToken`, `ingestPushPayload`)로만 Infrastructure/Data를 감싼다. 디바이스
등록 토큰 처리(`registerMemberDevice` 호출)는 AppDelegate 콜백과 분리해
`AppComposition.live(...)` 생성 시점에 Composition이 직접 시작하는 백그라운드 `Task`로
처리한다. 플랫폼 생명주기(`UIApplicationDelegate`)는 App이 소유하는 신규
`GitItAppDelegate`(`UNUserNotificationCenterDelegate`만 함께 채택, FirebaseMessaging
미의존)가 담당하며 Composition이 노출한 두 closure를 그대로 호출한다. 이 배치는
[아키텍처 문서](../../docs/architecture.md)의 "App은 플랫폼 생명주기를 담당", "Composition의
외부 기술 사용은 Infrastructure API를 통해 수행" 제약과 Composition 책임(Adapter 구현·조립·
객체 수명)을 그대로 지킨다.

## 기술 맥락

**언어/버전**: Swift 6.0 (Tuist `swift-tools-version: 6.0`, `iOS 26.0` 최소 배포 타깃)

**주요 의존성**: SwiftUI, The Composable Architecture 1.26+ (`ComposableArchitecture`),
`firebase-ios-sdk` 12.16+ 중 `FirebaseMessaging`(신규 소비, 워크스페이스
`sources/Tuist/Package.swift`에는 이미 선언되어 있으나 어떤 target도 아직 소비하지 않음)

**저장소**: N/A (이 기능은 새 영속 저장소를 추가하지 않는다. 생성 진행·알림 옵션 상태는
`ProjectRegistrationFeature.State`의 메모리 상태이며, FCM outcome 허브도 프로세스
메모리 내 `AsyncStream` 멀티캐스트다.)

**테스트**: Swift Testing 기반 `TestStore`(Feature), Domain/Composition 단위 테스트,
UIKit `UNUserNotificationCenterDelegate`/`MessagingDelegate` 통합은 실기기·Simulator
수동 검증(Push 수신은 XCTest로 결정적으로 재현하기 어려움)

**대상 플랫폼**: iOS 26.0+ (iPhone, `platform=iOS Simulator,name=iPhone 17 Pro` 기본 테스트
destination)

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지: App/Composition/Feature/Domain/Data/
Infrastructure/UI)

**성능 목표**: 명세에 별도 수치 목표 없음. 생성 진행 화면은 정적 체크리스트만 표시하므로
폴링으로 인한 추가 네트워크 비용이 없어야 한다(SC-010).

**제약 조건**: 진행률(%) 조회 폴링 API 신설 금지(SC-010), production
`@Dependency`/Service Locator 금지(FR-017), FCM 수신은 시스템 알림 권한 승인 여부와
무관하게 동작해야 함(명확화 세션 결정).

**규모/범위**: 화면 5개(Figma node `986:13739`/`986:13646` 계열, `737:10890`,
`737:10882`/`737:10874`, `737:10830`, `737:10800`/`824:12149`), 패키지 6개(App,
Composition, Feature, Domain, Data, Infrastructure) 동시 변경.

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **브랜치 네임스페이스**: `feature/project-registration-flow`는 `speckit-specify`가
  생성한 기존 브랜치를 재사용하며 원칙 8을 위반하지 않는다.
- **허용 수정 경로**: 이 명령은 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 만든다. 아래 프로젝트 구조에 기록한 실제 구현
  경로는 `tasks.md`가 소유하며 이 단계에서 수정하지 않는다.
- **세션 지식 기록**: 계획 단계에서 트러블슈팅·암묵지 기록 대상 사건이 없었다. 필요
  시점에 전용 스킬을 별도 실행한다.
- **Git 실행 직렬화**: 계획 단계는 읽기 전용 조사와 문서 생성만 수행하며 Git index를
  변경하지 않는다.
- **커밋 단위 구현**: 아래 "실행 단위" 절에서 위상 순서와 각 단위의 파일·검증 범위를
  기록한다. `/speckit-tasks`가 이를 `tasks.md`의 커밋 단위로 세분화한다.
- **책임 기반 네이밍**: 신규 공개 이름(`LearningProjectGenerationOutcome`,
  `ObserveLearningProjectGenerationOutcomesUseCase`,
  `LearningProjectGenerationOutcomeRepository`, `PushMessagingClient` 등)은
  [네이밍 컨벤션](../../docs/conventions/naming.md)에 따라 공급자 중립(Domain에
  "FCM"·"Firebase" 미노출)과 책임 중심 이름을 적용했다. 검증은 아래 "복잡성 추적" 이후
  절 없음(위반 없음).
- **실행 단위 진행**: 적용 대상 패키지는 Domain, Infrastructure, Data, Composition,
  Feature, App이다. 아키텍처 문서 3.1의 의존 방향에 따라 Domain·Infrastructure(상호
  독립) → Data(Infrastructure 의존) → Composition(Domain·Data·Infrastructure 의존) →
  Feature(Domain 의존) → App(Feature·Composition·Domain 의존) 순서로 구현한다.

**게이트 결과**: 통과. 원칙 위반이나 정당화가 필요한 예외 없음.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/019-project-registration-flow/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물
├── data-model.md         # 1단계 산출물
├── quickstart.md         # 1단계 산출물
├── contracts/            # 1단계 산출물
│   ├── domain-data-contracts.md
│   └── feature-app-contracts.md
└── tasks.md              # 2단계 산출물(/speckit-tasks, 이 명령이 생성하지 않음)
```

### 소스 코드(저장소 루트)

Tuist 멀티 패키지 구조(`sources/Projects/<패키지>/`)를 그대로 사용한다. 새 파일은
기존 패키지의 역할 폴더(`Models/`, `Contracts/`, `UseCases/`, `Screens/`,
`Reducers/`, `Adapter/Assemblies|Adapters/`) 아래에 배치하고 새 target은 만들지
않는다(Infrastructure의 Push 수신 API만 새 역할 폴더 `PushMessaging/`를 기존
`InfrastructureAuthentication`처럼 별도 target으로 추가할지, 기존 target에 얹을지는
`research.md`에서 결정한다).

```text
sources/Projects/
├── Domain/LearningProject/
│   ├── Models/LearningProject/LearningProjectGenerationOutcome.swift        # 신규
│   ├── Contracts/LearningProjectGenerationOutcomeRepository.swift           # 신규
│   └── UseCases/ObserveLearningProjectGenerationOutcomes/
│       ├── ObserveLearningProjectGenerationOutcomesUseCase.swift            # 신규
│       └── ObserveLearningProjectGenerationOutcomes.swift                   # 신규
├── Infrastructure/PushMessaging/                                            # 신규 역할 폴더
│   ├── Clients/PushMessagingClient.swift                                    # 신규(프로토콜, registrationToken/setAPNsToken)
│   └── Clients/FirebaseMessagingPushClient.swift                            # 신규(구현, MessagingDelegate 채택을 여기서 완결)
├── Data/LearningProject/
│   ├── Contracts/ProjectGenerationOutcomeRemote.swift                       # 신규
│   ├── DTOs/ProjectGenerationOutcomeDTO.swift                               # 신규
│   └── Remotes/PushProjectGenerationOutcomeRemote.swift                     # 신규(멀티캐스트 허브)
├── Composition/Adapter/
│   ├── Adapters/LearningProjectGenerationOutcomeRepositoryAdapter.swift     # 신규
│   └── Assemblies/
│       ├── LearningProjectAssembly.swift                                   # 수정(관찰 Use Case·push 허브 배선)
│       └── AppComposition.swift                                            # 수정(observeLearningProjectGenerationOutcomes,
│                                                                            #      forwardAPNsToken, ingestPushPayload 노출 +
│                                                                            #      디바이스 등록 토큰 Task 시작)
├── Feature/ProjectRegistration/
│   ├── Reducers/ProjectRegistrationFeature.swift                           # 수정(생성 진행·알림 옵션 국면 추가)
│   ├── Screens/ProjectRegistrationScreen.swift                             # 신규
│   ├── Screens/…(레포 확인·이해도 선택·진행 화면 하위 View)                 # 신규
│   └── Previews/…                                                          # 신규
├── Feature/Home/Reducers/HomeFeature.swift                                 # 수정(FCM 관찰·1회 재조회)
├── Feature/MainShell/Reducers/MainShellFeature.swift                       # 수정(필요 시 delegate 통과만 확인)
└── App/GitIt/
    ├── AppDelegates/GitItAppDelegate.swift                                 # 신규(UIApplicationDelegate,
    │                                                                       #      UNUserNotificationCenterDelegate만 채택,
    │                                                                       #      FirebaseMessaging 미의존 — §7 형태 폴더
    │                                                                       #      표에 없는 신규 형태이므로 tasks.md의
    │                                                                       #      App 작업 단위가 docs/conventions/
    │                                                                       #      directory-file.md §7 App 행 갱신을
    │                                                                       #      명시적 파일 작업으로 포함해야 한다)
    ├── GitItApp.swift                                                      # 수정(@UIApplicationDelegateAdaptor(GitItAppDelegate.self) 연결)
    ├── Reducers/AppRootFeature.swift                                       # 수정(@Presents 등록 흐름 연결)
    └── Screens/AppRootView.swift                                           # 수정(fullScreenCover)
```

**구조 결정**: 기존 패키지 경계와 폴더 관례(`Models/Contracts/UseCases`,
`Adapter/Adapters|Assemblies`, `Reducers/Screens/Previews`)를 그대로 따르고 새 target을
만들지 않는다. Infrastructure의 Push 수신 능력만 `Authentication/`처럼 새 하위 역할
폴더(`PushMessaging/`)를 쓸지 기존 target에 종속시킬지는 `research.md`에서 확정한다.
Composition에는 `PushRegistration/` 같은 새 형태 폴더를 만들지 않는다 — `MessagingDelegate`
채택 자체가 Infrastructure 안에서 완결되므로 Composition은 기존 `Adapters/`·`Assemblies/`
형태만으로 충분하다(`/speckit-analyze`가 지적한 아키텍처 경계 위반 수정). App에만 새 형태
`AppDelegates/`가 필요하며, 이는 `docs/conventions/directory-file.md` §7 표 갱신 대상이다.

## 실행 단위(패키지 위상 순서)

1. **Domain (LearningProject)** — `LearningProjectGenerationOutcome` 모델,
   `LearningProjectGenerationOutcomeRepository` 계약,
   `ObserveLearningProjectGenerationOutcomesUseCase`/구현체. 다른 패키지에 의존하지
   않으므로 독립적으로 완결·검증 가능.
2. **Infrastructure** — `PushMessagingClient` 프로토콜과
   `FirebaseMessagingPushClient` 구현(APNs 등록, FCM 등록 토큰 조회, silent push
   payload를 `[String: String]`으로 정규화해 노출). Domain을 참조하지 않는다.
3. **Data (LearningProject)** — `ProjectGenerationOutcomeRemote` 계약과
   `PushProjectGenerationOutcomeRemote`(Infrastructure `PushMessagingClient`를
   소비하는 멀티캐스트 허브 actor, payload → `ProjectGenerationOutcomeDTO` 디코딩).
   Infrastructure에만 의존(불가분 아님, 단일 패키지 단위).
4. **Composition** — `LearningProjectGenerationOutcomeRepositoryAdapter`(Domain↔Data),
   `LearningProjectAssembly`/`AppComposition`에 새 Use Case와 두 closure
   (`forwardAPNsToken`, `ingestPushPayload`) 노출, `AppComposition.live(...)` 생성
   시점에 등록 토큰을 기다렸다가 기존 `registerMemberDevice`를 호출하는 백그라운드
   `Task` 시작. UIKit·Firebase 프로토콜은 채택하지 않는다. Domain·Data·Infrastructure
   모두에 의존하는 조립 지점이므로 하나의 integration unit으로 묶는다(분리하면 배선이
   컴파일되지 않음).
5. **Feature** — `ProjectRegistrationFeature`(생성 진행·알림 옵션 국면, 신규
   Screen), `HomeFeature`(FCM 관찰 Effect, 1회 재조회 View Action). 두 Feature는
   서로 다른 상태를 소유하므로 각각 독립적인 단위로 진행할 수 있다.
6. **App** — `AppRootFeature`(`@Presents` 등록 흐름, delegate 처리), `AppRootView`
   (`fullScreenCover`), 신규 `GitItAppDelegate`(`UIApplicationDelegate`,
   `UNUserNotificationCenterDelegate` — 플랫폼 생명주기를 App이 직접 소유, Composition의
   두 closure만 호출), `GitItApp`(`@UIApplicationDelegateAdaptor(GitItAppDelegate.self)`
   연결). Feature와 Composition 모두 완성된 뒤에만 컴파일된다.

이 명세가 변경하지 않는 패키지(UI, Quiz, ProjectDetail, Saved, Settings, Onboarding,
AppEntry)는 건너뛴다. `tasks.md`는 이 순서를 그대로 커밋 단위로 세분화한다.

## 헌법 재점검 (1단계 설계 후)

`research.md`·`data-model.md`·`contracts/**` 작성 후 다시 검토했다.

- 새 공개 이름은 모두 [네이밍 컨벤션](../../docs/conventions/naming.md)의
  공급자 중립·책임 중심 기준을 통과한다(Domain에 "FCM"/"Firebase" 미노출,
  Infrastructure/Composition에서만 `Firebase`·`Push` 등 구현 문맥 노출).
- 의존성 방향은 [아키텍처 3.1](../../docs/architecture.md#31-프로젝트-내부-패키지-의존성)을
  그대로 따른다: Data는 Infrastructure에만, Composition은 Domain·Data·Infrastructure에,
  App은 Feature·Composition·Domain에만 의존한다. Data→Domain, App→Data/Infrastructure
  같은 금지 경로는 설계 어디에도 없다.
- `GitItAppDelegate`의 정적 `configure(...)` 통로는 여러 곳에서 production
  의존성을 조회하는 Service Locator가 아니라 앱 시작 시 단 한 번만 값을 채우는
  조립 지점이며 FR-017의 생성자 주입 원칙과 배치되지 않는다(연구 항목 5 근거).
- 플랫폼 생명주기(`UIApplicationDelegate`)는 App이 소유하고(아키텍처 문서
  "App은 플랫폼 생명주기를 담당") `MessagingDelegate` 채택은 Infrastructure
  안에서 완결되어 Composition은 어떤 UIKit·Firebase 프로토콜도 채택하지 않는다
  (아키텍처 문서 "Composition의 외부 기술 사용은 Infrastructure API를 통해
  수행"). 최초 설계 검토에서 `/speckit-analyze`가 지적한 위반(Composition이
  `UIApplicationDelegate`/`MessagingDelegate`를 직접 채택)을 이 재설계로 해소했다.
- 새로 만드는 폴링 API 없음(SC-010 유지), 알림 권한 요청 UI 신설 없음(FR-014/015
  유지).

**게이트 결과**: 통과. 원칙 위반이나 정당화가 필요한 예외 없음.

## 복잡성 추적

해당 없음. 헌법 게이트를 위반하는 예외가 없다.
