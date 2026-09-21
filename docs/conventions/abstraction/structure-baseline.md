# 구조 기준선

[Git It iOS 추상화 컨벤션](../abstraction.md)의 참고 문서입니다. 프로토콜이 다시 늘어날
때 어디에서 늘었는지 대조할 수 있도록 수치와 존치 근거를 남깁니다.

## 1. 수치

| 항목 | 적용 전 | 적용 후 | 명세 036 후 | 명세 042 후 |
| --- | --- | --- | --- | --- |
| 프로덕션 Swift 파일 수 | 521 | 512 | 535 | 551 |
| 프로덕션 프로토콜 수 | 56 | 47 | 50 | 42 |
| Data 프로덕션 Contracts 파일 수 | 11 | 2 | 6 | 6 |

"적용 전"은 `feature/layer-overengineering`의 시작 commit `51ee74f`, "적용 후"는 그
브랜치의 계층 축소 작업을 마친 시점입니다. "명세 036 후"는
`feature/pending-repository-legacy-cleanup`에서 생성 대기 Repository 통합과 Data 역할 계약
도입을 마친 시점입니다. "명세 042 후"는 `feature/component-attribute-modifiers`에서
UIComponent 시각 속성 계약 도입과 표시 값 모델 전환을 마친 시점입니다.

## 2. 세는 명령

`find`는 `tuist generate`가 만드는 `Derived/` 아래 생성 파일까지 세므로 Git이 추적하는
파일만 대상으로 삼습니다.

```sh
# 프로덕션 Swift 파일 수
git ls-files 'sources/Projects/**/*.swift' | grep -v '/Tests/' | wc -l

# 프로덕션 프로토콜 수
git ls-files 'sources/Projects/**/*.swift' | grep -v '/Tests/' \
  | xargs grep -hE '^[[:space:]]*(public )?protocol ' | wc -l

# Data 프로덕션 Contracts 파일 수
git ls-files 'sources/Projects/Data/**/Contracts/*.swift' | grep -v '/Tests/' | wc -l
```

프로토콜 목록을 파일 경로와 함께 보려면 다음을 씁니다.

```sh
git ls-files 'sources/Projects/**/*.swift' | grep -v '/Tests/' \
  | xargs grep -nE '^[[:space:]]*(public )?protocol '
```

## 3. 남은 프로토콜과 존치 근거

근거 A·B의 정의는 [두 가지 근거](./protocol-criteria.md)에 있습니다.

### 3.1 근거 A — 패키지 경계를 넘는 계약 (28개)

요구하는 쪽이 계약을 소유하고 제공하는 쪽이 채택해 의존 방향을 뒤집습니다.

| 소유 패키지 | 프로토콜 | 채택 위치 |
| --- | --- | --- |
| Domain Authentication | `AuthenticationRepository`, `LoginSessionRepository`, `PolicyConsentRepository`, `CurrentSessionRepository`, `SharedSignInStateRepository` | Composition Adapter |
| Domain LearningProject | `AnswerRepository`, `BookmarkRepository`, `ExternalRepositoryLookup`, `ExternalRepositoryLocator`, `GenerationOutcomeRepository`, `GenerationReminderScheduler`, `LearningProjectRepository`, `LearningSetRepository`, `NotificationAuthorization`, `PendingGenerationRepository` | Composition Adapter |
| Domain LearningProject | `GenerationReminderRegistration` | Domain `ScheduleGenerationReminderUseCase`가 상속(Composition 채택자 없음, 존치 재검토는 점검 문서 DS-12) |
| Domain Member | `DeviceIdentifierRepository`, `MemberRepository` | Composition Adapter |
| Data LearningProject | `QuizGenerationOutcomeSource` | Data 내부 구현과 Composition |
| Data Shared | `KeyValueStorage`, `SecureValueStorage`, `RequestTransport` | Data 내부 구현(생성 진입점), Composition·테스트가 대체 구현 주입 |
| Data Notification | `LocalReminderNotifier`, `RemoteMessageReceiver` | Data 내부 구현(생성 진입점), Composition·테스트가 대체 구현 주입 |
| Infrastructure | `HTTPTransport`, `HTTPBodyCoding`, `NotificationAuthorizationClient`, `PushMessagingClient` | Data 내부 구현 |

`HTTPTransport`는 근거 B도 함께 충족합니다. `URLSessionTransport`가 프로덕션 구현이고
테스트가 다른 구현을 넣습니다.

### 3.2 제네릭 제약 (1개)

| 프로토콜 | 비고 |
| --- | --- |
| `TabShellItem` (UI) | `associatedtype`·`CaseIterable` 제약을 표현하는 형태이며 교체 가능성과 무관합니다. [추상화 컨벤션](../abstraction.md)의 적용 범위 밖입니다 |

### 3.3 UI 시각 속성 계약 (5개)

| 프로토콜 | 비고 |
| --- | --- |
| `StyleConfigurable`, `SizeConfigurable`, `TextStyleConfigurable`, `ForegroundColorConfigurable`, `BackgroundColorConfigurable` (UI `Component/Contracts/`) | 여러 역할 폴더의 컴포넌트가 같은 이름·형태의 시각 속성 메서드를 제공하도록 강제하는 공개 API 형태 계약입니다. 근거 A·B가 아니며 [추상화 컨벤션](../abstraction.md)의 적용 범위 밖입니다 |

### 3.4 UseCase 프로토콜 (20개) — 별도 명세가 판단합니다

Domain Authentication 7개(`PolicyConsentUseCase`, `RefreshSessionUseCase`,
`ResolveSessionAvailabilityUseCase`, `RestoreSessionUseCase`, `SignInUseCase`,
`SignOutUseCase`, `VerifyAuthorizationUseCase`), Domain LearningProject
10개(`CreateLearningProjectUseCase`, `FetchExternalRepositoryUseCase`,
`FetchLearningProjectsUseCase`, `LearningLibraryUseCase`,
`RequestGenerationReminderUseCase`, `ScheduleGenerationReminderUseCase`,
`SetQuestionBookmarkUseCase`, `SubmitChoiceAnswerUseCase`,
`SubmitEssayAnswerUseCase`, `TrackGenerationUseCase`), Domain Member
3개(`DeleteMemberAccountUseCase`, `MemberAccountUseCase`,
`RegisterCurrentDeviceUseCase`)입니다.

Feature·App이 패키지 경계를 넘어 받지만 구현도 같은 Domain 패키지에 있어 의존 방향이
뒤집히지 않습니다. 근거 A를 온전히 충족한다고 보기 어렵습니다. UseCase 계층의 존치와
통합은 별도 명세가 소유하므로 이 기준선에서는 분류만 남깁니다.

### 3.5 근거를 충족하지 못하는 항목 (1개)

| 프로토콜 | 상태 |
| --- | --- |
| `SharedItemAttachment` (App ShareExtension) | 프로덕션 채택자는 `NSItemProvider` 하나뿐이고 나머지 채택자는 테스트 스텁입니다. 패키지 경계를 넘지 않고 교체 지점도 프로덕션에 없어 근거 A·B 어느 쪽도 아닙니다. 다음 점검 대상입니다 |

## 4. 이 문서를 갱신할 때

프로덕션 프로토콜을 추가하거나 제거하면 2절의 명령으로 수치를 다시 재고 3절 목록을
함께 갱신합니다. 새 프로토콜은 근거 A 또는 B 중 하나에 대응시켜 적습니다. 대응시킬 수
없으면 3.5에 두고 그대로 두는 이유를 남깁니다.
