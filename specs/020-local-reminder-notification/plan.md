# 구현 계획: 생성 완료 리마인드 알림의 실제 권한 요청과 로컬 알림 발송

**Git-flow 유형**: `feature`

**브랜치**: `feature/local-reminder-notification`

**날짜**: 2026-08-31 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/020-local-reminder-notification/spec.md`의 기능 명세

## 요약

알림 옵션 시트에서 리마인드를 수락하면 실제 `UNUserNotificationCenter` 권한을 확인·요청하고,
이미 거부된 상태라면 기존 `openNotificationSettings`로 설정 화면을 안내한다. 권한이 허용된
프로젝트는 `projectID` 단위로 리마인드 대상에 등록되며, 이 등록은 등록 흐름 화면이 닫힌
뒤에도 유지된다. Composition이 소유하는 새 조정자가 019가 이미 구축한
`LearningProjectOutcomesUseCase` 멀티캐스트 스트림을 독립적으로 구독해, 리마인드 대상
프로젝트의 완료 신호를 수신하면 새 Infrastructure 기술 API로 사용자에게 보이는 로컬 알림을
발송한다. 019의 FCM 수신·완료 판정 로직 자체는 변경하지 않는다.

Feature가 갖는 의존성은 019가 확립한 패턴(Domain UseCase + Domain 계약을 Composition
Adapter가 구현)을 그대로 따라 하나의 명시적 Domain UseCase(`RequestGenerationReminderUseCase`)로
표현한다. 결과 타입(`NotificationAuthorizationOutcome`)도 Domain이 소유해 Feature가 이미
허용된 Domain 의존성만으로 필요한 정보를 받으며, Infrastructure 타입을 Bool/String으로 깎아
경계를 우회하지 않는다(근거: [research.md](./research.md) 3절).

## 기술 맥락

**언어/버전**: Swift 5.9(iOS 26.0+ 배포 대상), SwiftUI, TCA(The Composable Architecture)

**주요 의존성**: 기존 `InfrastructurePushMessaging`(FirebaseMessaging), 신규로 그 안에 추가하는
`UserNotifications` 프레임워크 래퍼, 기존 `LearningProjectOutcomesUseCase`(Domain)

**저장소**: 리마인드 대상 등록은 앱 프로세스 메모리에만 유지한다(영속 저장소 없음, 가정 참고)

**테스트**: Swift Testing(기본), 신규 Infrastructure concrete 구현은 컴파일 검증만(기존
`InfrastructurePushMessaging` 관례와 동일하게 별도 테스트 target 없음), Feature/Composition
공개 표면은 Swift Testing으로 검증

**대상 플랫폼**: iOS 26.0+

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: 로컬 알림은 완료 신호 수신 후 사용자가 인지할 수 있는 지연(수 초 이내)으로
발송되어야 한다. 별도 수치 SLA는 없다(NEEDS CLARIFICATION 아님 — 알림 API 자체가 즉시성을
보장하며 이 기능이 새로 만드는 지연 요소가 없다).

**제약 조건**: FR-011(생성자 주입만 사용), FR-012(Infrastructure 계층 소유), 019의 FCM
수신·판정 로직 변경 금지

**규모/범위**: 화면 변경 없음(기존 알림 옵션 시트 UI 그대로), 새 Infrastructure API 1개,
Composition 조정자 1개, `ProjectRegistrationFeature`/`AppRootFeature`/`GitItApp` 배선 확장

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **브랜치 네임스페이스**: `feature/local-reminder-notification`은 `speckit-specify`가 이미
  생성·검증했다. 통과.
- **허용 수정 경로**: 이 계획 문서, `research.md`, `data-model.md`, `quickstart.md`,
  `contracts/**`만 수정한다. 실제 구현 파일 경로는 아래 프로젝트 구조와 `contracts/`에
  기록하고 `tasks.md`(향후 `/speckit-tasks`)가 작업 단위로 배정한다. 통과.
- **Git 실행 직렬화**: 이 계획 단계는 Git 상태를 변경하지 않는다. 해당 없음.
- **커밋 단위 구현**: 실행 순서는 아래 "실행 단위와 패키지 위상 순서"에 기록하며
  `/speckit-tasks`/`/speckit-implement`가 실제 커밋 단위로 세분화한다. 통과.
- **책임 기반 네이밍**: 신규 공개 이름(`RequestGenerationReminderUseCase`,
  `NotificationAuthorizationGateway`, `GenerationReminderRegistry`,
  `NotificationAuthorizationOutcome`, `LocalNotificationClient` 등)은 각 패키지 책임을
  드러내며, Feature는 이미 허용된 Domain 의존성 하나(`RequestGenerationReminderUseCase`)만
  명시적으로 주입받는다. Infrastructure 결과 타입은 Composition Adapter가 Domain 모델로
  변환하며 Feature 경계를 넘지 않는다(기존 `fetchExternalRepository` 등 UseCase 의존성
  스타일과 일관됨). 통과.
- **실행 단위 진행**: 변경 대상 패키지는 Domain → Infrastructure → Feature → Composition →
  App 순서로 위상 정렬했다(아래 참고). 통과.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/020-local-reminder-notification/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md         # 1단계 산출물(/speckit-plan)
├── quickstart.md         # 1단계 산출물(/speckit-plan)
├── contracts/            # 1단계 산출물(/speckit-plan)
│   └── notification-permission-contracts.md
└── tasks.md              # 2단계 산출물(/speckit-tasks, 이 계획은 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── Domain/LearningProject/
│   ├── Models/
│   │   └── NotificationAuthorizationOutcome.swift            # 신규: authorized/declined/previouslyDenied
│   ├── Contracts/
│   │   ├── NotificationAuthorizationGateway.swift             # 신규: 권한 확인·요청 계약
│   │   └── GenerationReminderRegistry.swift                   # 신규: 리마인드 대상 등록 계약
│   └── UseCases/RequestGenerationReminder/
│       ├── RequestGenerationReminderUseCase.swift              # 신규: 프로토콜
│       └── RequestGenerationReminder.swift                     # 신규: 구현(비즈니스 규칙 소유)
├── Infrastructure/PushMessaging/
│   └── Clients/
│       ├── LocalNotificationClient.swift                    # 신규: 프로토콜 + Infrastructure 전용 결과 타입
│       └── UNUserNotificationCenterLocalNotificationClient.swift  # 신규: concrete 구현
├── Composition/Adapter/
│   ├── Adapters/
│   │   ├── NotificationAuthorizationGatewayAdapter.swift     # 신규: Domain↔Infrastructure 결과 타입 변환
│   │   └── GenerationReminderRegistryAdapter.swift            # 신규: Domain 계약 → 조정자 위임
│   ├── Factories/
│   │   └── GenerationCompletionReminderCoordinator.swift     # 신규: 리마인드 대상 등록·구독 조정자(Domain 미노출)
│   └── Assemblies/
│       └── AppComposition.swift                              # 수정: requestGenerationReminder UseCase 공개 표면 배선
├── Feature/ProjectRegistration/
│   └── Reducers/
│       └── ProjectRegistrationFeature.swift                  # 수정: init에 requestGenerationReminder 추가, notificationOptionAccepted 로직 확장
├── App/GitIt/
│   ├── Reducers/
│   │   └── AppRootFeature.swift                              # 수정: requestGenerationReminder를 ProjectRegistrationFeature로 전달
│   └── GitItApp.swift                                        # 수정: composition.requestGenerationReminder를 AppRootFeature에 주입
└── (각 패키지의 Tests/ 아래 대응 테스트 파일 갱신)
```

**구조 결정**: 기존 019가 확립한 "Domain UseCase + Domain 계약 → Composition Adapter가
Infrastructure/내부 조정자에 위임 → Feature가 Domain UseCase를 명시적으로 주입받음 → App이
Composition↔Feature 연결" 구조를 그대로 재사용한다. 새 Tuist target은 추가하지 않으며
(`InfrastructurePushMessaging`가 이미 다루는 "iOS 알림" 기술 영역 안에 `LocalNotificationClient`를
추가), 완료·실패 판정 자체의 Domain 모델은 019가 이미 소유한
`LearningProjectGenerationOutcome`을 그대로 재사용한다. 다만 알림 권한 확인·요청과 리마인드
등록이라는 새 비즈니스 규칙은 Domain에 새 UseCase·계약으로 명시한다(Feature가 Infrastructure
결과 타입을 익명 closure로 우회 수신하지 않도록 하기 위함, 근거는 research.md 3절).

## 실행 단위와 패키지 위상 순서

아키텍처 문서 3.1의 의존성 표(`App → Feature, Composition, Domain` / `Composition → Domain,
Data, Infrastructure` / `Feature → Domain, UI` / `Infrastructure → (없음)` / `Domain → (없음)`)
기준으로 이 기능이 바꾸는 패키지의 위상 순서를 다음과 같이 고정한다.

1. **Domain**(`DomainLearningProject`): 다른 프로젝트 내부 패키지에 의존하지 않으므로 가장
   먼저 구현한다. `NotificationAuthorizationOutcome` 모델, `NotificationAuthorizationGateway`·
   `GenerationReminderRegistry` 계약, `RequestGenerationReminderUseCase`/
   `RequestGenerationReminder`(비즈니스 규칙 소유)를 추가한다.
2. **Infrastructure**(`InfrastructurePushMessaging`): Domain과 마찬가지로 다른 패키지에
   의존하지 않으므로 Domain과 독립적으로 진행할 수 있다. `LocalNotificationClient` 프로토콜과
   `UNUserNotificationCenter` 기반 concrete 구현을 추가한다.
3. **Feature**(`Feature`): 1에서 확정한 Domain 계약(`
   RequestGenerationReminderUseCase`, `NotificationAuthorizationOutcome`)만 있으면 되고
   Infrastructure에는 의존하지 않으므로, Domain 완료 뒤 곧바로 진행한다.
   `ProjectRegistrationFeature.init`에 `requestGenerationReminder` 인자를 추가하고
   `notificationOptionAccepted` 처리를 확장한다.
4. **Composition**(`Composition`): 1의 Domain 계약과 2의 Infrastructure 구현이 모두 필요하므로
   네 번째로 진행한다. `NotificationAuthorizationGatewayAdapter`,
   `GenerationReminderRegistryAdapter`, `GenerationCompletionReminderCoordinator`를 추가하고
   `AppComposition`이 `requestGenerationReminder` UseCase를 공개하도록 배선한다.
5. **App**(`GitIt`): Feature와 Composition이 모두 끝나야 두 계약을 연결할 수 있으므로
   마지막에 진행한다. `AppRootFeature`가 `requestGenerationReminder`를 받아
   `ProjectRegistrationFeature`로 전달하도록 초기화 인자를 확장하고, `GitItApp`이
   `composition.requestGenerationReminder`를 `AppRootFeature`에 주입한다.

각 단위는 독립적으로 컴파일·테스트 가능한 경계이며, `/speckit-tasks`가 이 순서를 그대로
`tasks.md`의 작업 패키지 순서로 반영한다. 019가 이미 구현한 Domain·Data 계약(`
LearningProjectOutcomesUseCase`, `LearningProjectGenerationOutcome`)은 변경 대상이 아니므로
위상 순서에서 제외한다.

## 복잡성 추적

해당 없음(헌법 점검 위반 없음).
