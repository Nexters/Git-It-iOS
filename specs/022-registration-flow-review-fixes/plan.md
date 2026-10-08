# 구현 계획: 프로젝트 등록 흐름 리뷰 지적 사항 해소

**Git-flow 유형**: `feature`

**브랜치**: `feature/registration-flow-review-fixes`

**날짜**: 2026-09-01 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/022-registration-flow-review-fixes/spec.md`의 기능 명세

## 요약

`issue/` 아래 리뷰 리포트 3건 중 현재 HEAD `b5070bb`에서 재현되는 지적을 해소한다. 핵심은 네
가지다.

1. **생성 결과 유실 제거** — 버퍼 대신 구독 확립 후 생성 요청 전송으로 직렬화한다(R1).
2. **흐름 탈출 보장** — 생성 실패 시 시트를 닫고, 인증 종료 시 등록 흐름 child를 정리한다.
3. **푸시 수명 재구성** — 전역 static 콜백 저장소를 인스턴스 소유로 바꾸고, 조립 시점의
   unstructured `Task`를 명시적 `bootstrap()`으로 옮기며, 기기 등록 시점을 App의 인증 흐름으로
   이전한다. 등록 실패는 상태로 보존하고 앱 활성화·token 갱신 시 자동 재시도하며,
   동시 trigger는 하나의 요청으로 직렬화한다.
4. **경계별 어휘 정렬** — Domain은 `GenerationOutcome`, Data는 `QuizGeneration*`, Composition
   adapter가 변환한다.

부수적으로 화면 단계 상태를 Feature로 옮기고, Home의 조회 중 결과 폐기를 없애며, formatter 위반
2건을 해소한다.

## 기술 맥락

**언어/버전**: Swift 6 (Swift Concurrency, `Synchronization.Mutex`)

**주요 의존성**: The Composable Architecture, SwiftUI, UIKit(`UIApplication`),
`UserNotifications`, Firebase Cloud Messaging(Infrastructure에서만 접근)

**저장소**: Keychain(디바이스 식별자). 이 기능은 새 영속 저장을 도입하지 않는다(FR-004).

**테스트**: Swift Testing(기본), 테스트 함수 이름은 한국어 동작 문장

**대상 플랫폼**: iOS 26.0+

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 앱 (App / Composition / Feature / Domain / Data /
Infrastructure / UI)

**성능 목표**: 해당 없음. 이 기능은 처리량·지연 목표를 바꾸지 않는다.

**제약 조건**:

- 아키텍처 §3.1 의존 방향 준수. 특히 App ↛ Infrastructure, Feature ↛ Infrastructure
- 아키텍처 §7.2 전역 mutable dependency container 금지
- 형태 폴더 어휘는 `docs/conventions/file-vocabulary.md` §3이 정본
- Action 출처 분류는 `docs/conventions/tca/action.md` §2가 정본

**규모/범위**: 6개 프로젝트 내부 패키지 + 공용 문서 1개. 예상 변경 파일 약 35개(테스트 포함).

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 게이트 | 0단계 전 | 1단계 후 | 근거 |
| --- | --- | --- | --- |
| 브랜치 네임스페이스 | 통과 | 통과 | `feature/registration-flow-review-fixes`를 `/speckit-specify`가 HEAD `b5070bb`에서 생성 |
| 허용 수정 경로 | 통과 | 통과 | 이 실행은 `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 작성 |
| 명시적인 경계(원칙 1) | 통과 | 통과 | 모든 신규 경계 값이 아키텍처 §3.1 방향 안에 있다. [contracts/push-lifecycle.md](./contracts/push-lifecycle.md) §2 참고 |
| 상태와 데이터 안전성(원칙 2) | 주의 | 통과 | 조립 시점 unstructured `Task` 2개를 제거하고 소유자·취소 경로를 명시하는 것이 이 기능의 목표 중 하나다 |
| 검증 가능한 변경(원칙 3) | 통과 | 통과 | [quickstart.md](./quickstart.md) §3이 자동화 게이트와 14개 회귀 시나리오를 정의 |
| Git 실행 직렬화 | 통과 | 통과 | 구현 단계에서 단일 변경 체인만 실행 |
| 커밋 단위 구현(원칙 7) | 통과 | 통과 | 아래 §실행 단위에 단일 패키지 단위와 불가분한 integration unit을 분리 기록 |
| 책임 기반 네이밍(원칙 10) | 주의 | 통과 | 경계별 어휘 규칙과 전체 매핑을 [contracts/naming-map.md](./contracts/naming-map.md)에 확정 |
| 세션 지식 기록(원칙 9) | 해당 없음 | 조건부 | R3의 SwiftUI 초기화 순서와 R12의 runner 종료가 재현·재사용 가능하면 전용 기록 스킬로 남긴다 |

**위반 없음.** 복잡성 추적 표는 작성하지 않는다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/022-registration-flow-review-fixes/
├── plan.md              # 이 파일
├── research.md          # 0단계 산출물 — R1~R12 결정
├── data-model.md        # 1단계 산출물 — 모델·상태 변경
├── quickstart.md        # 1단계 산출물 — 검증 절차
├── contracts/
│   ├── naming-map.md    # 공개 이름 변경 매핑 정본
│   └── push-lifecycle.md# 푸시 수명·기기 등록 경계
├── checklists/
│   └── requirements.md  # 명세 품질 체크리스트
└── tasks.md             # 2단계 산출물(/speckit-tasks)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/
├── Domain/LearningProject/
│   ├── Models/LearningProject/GenerationOutcome.swift        # 변경 없음
│   ├── Contracts/GenerationOutcomeRepository.swift           # 변경 없음
│   └── UseCases/ObserveGenerationOutcomes/                   # LearningProjectOutcomes/ 에서 rename
├── Data/LearningProject/
│   ├── DTOs/QuizGenerationOutcomeDTO.swift                   # GenerationOutcomeDTO.swift 에서 rename
│   ├── Contracts/QuizGenerationOutcomeSource.swift           # GenerationOutcomeStream.swift 에서 rename
│   └── Sources/PushQuizGenerationOutcomeSource.swift         # Remotes/ 에서 이동 + rename
├── Infrastructure/PushMessaging/
│   ├── Remote/AppDelegates/FirebaseMessagingAppDelegate.swift# static 제거, 인스턴스 소유
│   ├── Remote/Clients/PushMessagingClient.swift              # token 갱신 스트림 추가
│   ├── Remote/Clients/FirebaseMessagingPushClient.swift      # 갱신 스트림 구현
│   ├── Remote/Models/PushNotificationCallbacks.swift         # 필드 rename
│   └── Local/Models/LocalNotificationRequest.swift           # formatter 위반 해소
├── Composition/Adapter/
│   ├── Assemblies/AppComposition.swift                       # bootstrap 분리, Task 제거, rename
│   ├── Assemblies/LearningProjectAssembly.swift              # Data rename 반영
│   ├── Factories/GenerationCompletionReminderCoordinator.swift # 구독 확립 후 반환
│   ├── Factories/PushNotificationAppDelegate.swift           # typealias 유지
│   └── Adapters/GenerationOutcomeRepositoryAdapter.swift     # 인자명 rename
├── Feature/
│   ├── ProjectRegistration/Reducers/ProjectRegistrationFeature.swift # 직렬화·시트·단계·rename
│   ├── ProjectRegistration/Screens/                          # @State 제거, 화면 rename
│   ├── Home/Reducers/HomeFeature.swift                       # pending refresh, Input 분류
│   └── MainShell/Reducers/MainShellFeature.swift             # delegate 통합
└── App/GitIt/
    ├── GitItApp.swift                                        # MainActor 계약, bootstrap 호출
    └── Reducers/AppRootFeature.swift                         # child 정리, 기기 등록 시점

docs/conventions/file-vocabulary.md                           # Data 형태 폴더에 Sources/ 추가
```

**구조 결정**: 기존 7개 패키지 구조를 유지한다. 새 target이나 패키지를 만들지 않는다. Data에
형태 폴더 `Sources/` 하나만 추가하고, 그 근거를 같은 작업 단위에서 형태 어휘 정본 문서에 반영한다.

## 실행 단위

### 의존성 위상 순서

아키텍처 §3.1 표에 따른 순서다. `A → B`는 A가 B를 빌드 의존성으로 참조함을 뜻한다.

```text
Domain (의존 없음)          ─┐
Infrastructure (의존 없음)  ─┼→ Data (→ Infrastructure)
                             ├→ Composition (→ Domain, Data, Infrastructure)
                             ├→ Feature (→ Domain, UI)
                             └→ App (→ Feature, Composition, Domain)
```

Feature는 Domain에만 의존하므로 Data·Composition과 순서 제약이 없다. App은 항상 마지막이다.

### 단위 목록

| 단위 | 유형 | 패키지 | 목적 | 분리 불가 근거 |
| --- | --- | --- | --- | --- |
| U1 | 기준선 | — | `compile` + `test` + `lint` 1회 실행으로 R12·FR-031 기준선 확정 | `[no-write]` 검증 |
| U2 | 단일 | Feature/ProjectRegistration | 구독-요청 직렬화(FR-001~FR-005), 실패 시 시트 닫기(FR-006, FR-007) | — |
| U3 | 단일 | Feature/ProjectRegistration | 단계 enum 도입과 `@State` 제거(FR-019), `RegistrationProgress` rename(FR-023) | — |
| U4 | 단일 | Feature/Home | pending refresh와 중복 멱등(FR-020, FR-021) | — |
| U5 | **통합** | Domain + Composition + Feature + App | 생성 결과 관찰 Use Case rename(FR-022a) | Domain 공개 protocol rename은 전 소비자가 함께 바뀌어야 compile된다 |
| U6 | **통합** | Data + Composition + Docs | DTO·소스 rename, `Remotes/` → `Sources/` 이동(FR-022b, FR-027), 형태 어휘 표 갱신 | Data 공개 타입 rename은 Composition assembly·adapter와 동시에 바뀌어야 compile되고, 새 형태 폴더는 같은 PR에서 어휘 표를 갱신해야 한다 |
| U7 | **통합** | Infrastructure + Composition + App | 콜백 static 제거와 인스턴스 소유, `bootstrap()` 분리, 리마인드 구독 확립 순서(FR-013, FR-013a, FR-017, FR-018) | Infrastructure 공개 API 변경과 조립·주입부가 동시에 바뀌어야 compile되고, 중간 상태에서는 푸시 수신 경로가 끊긴다 |
| U8 | **통합** | Infrastructure + Composition + App | token 갱신 스트림, 기기 등록 시점 이전, 실패 상태와 앱 활성화·token 갱신 재시도 직렬화(FR-014~FR-016) | 새 Infrastructure 연산·Composition 경계 값·App 상태와 호출 시점이 함께 있어야 동작한다 |
| U9 | **통합** | Feature + App | 리마인드 Action·시트 rename(FR-024), 화면 rename(FR-028) | `delegate(.notificationOptionSelected)`를 App이 소비한다 |
| U10 | **통합** | Feature + App | Home `Input` 분류 도입(FR-026), MainShell delegate 통합(FR-030) | 두 변경 모두 App의 handler와 동시에 바뀌어야 compile된다 |
| U11 | **통합** | Feature + App | 설정 화면 이동 의존성 `@MainActor` 계약(FR-010~FR-012) | 의존성 타입 변경이 Feature·App 양쪽을 동시에 바꾼다 |
| U12 | 단일 | App | 인증 종료 시 child 정리(FR-008, FR-009) | — |
| U13 | 단일 | Composition | `deviceID(keychainStore:)` → `loadOrCreateDeviceID(keychainStore:)` rename(FR-029) | 네이밍 변경만 소유 |
| U14 | **통합** | Infrastructure + Composition + App | `ingestPushPayload` → `ingestGenerationOutcomePayload` rename(FR-025) | Infrastructure 콜백과 Composition 공개 경계, App 주입부가 함께 바뀌어야 compile된다 |
| U15 | 마무리 | — | 전체 `[no-write]` 검증과 SC-010 심볼 검색, formatter 훅 | 원칙 7의 최종 단위 |

`U5`~`U11`, `U13`, `U14`의 rename 대상 전체 목록은 [contracts/naming-map.md](./contracts/naming-map.md)가
정본이다.

### 순서 제약

- `U1`이 가장 먼저다. 기준선 없이 회귀 여부를 판정할 수 없다.
- `U5`(Domain rename)는 `U6`~`U14`보다 앞선다. Use Case 이름이 Composition·Feature·App 전반에
  나타나므로 나중에 하면 같은 파일을 두 번 건드린다.
- `U7`은 `U8`보다 앞선다. `U8`이 `U7`이 만든 `bootstrap()` 경계 위에서 동작한다.
- `U7`의 콜백 소유권 변경이 완료된 뒤 `U14`의 콜백 이름을 변경한다. 두 단위는 동작·수명 변경과
  네이밍 변경을 분리한다.
- `U2`, `U3`, `U4`는 서로 독립이며 `U5` 이후 어느 순서로도 가능하다. `tasks.md`가 순서를 확정한다.
- `U12`는 `U9`, `U10`, `U11` 이후가 유리하다. 같은 `AppRootFeature.swift`를 여러 단위가 건드리므로
  App 변경을 뒤로 모은다.
- `U15`가 마지막이다.

### 패키지에 속하지 않는 파일

| 파일 | 배정 단위 | 근거 |
| --- | --- | --- |
| `docs/conventions/file-vocabulary.md` | U6 | 새 형태 폴더 `Sources/`를 도입하는 단위가 어휘 표 갱신을 함께 소유한다 |
| `sources/Projects/App/GitIt.entitlements` | 변경 없음 | BR-001은 이미 해소됨 |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/*.swift` | 변경 없음 | BR-009는 이미 해소됨. 새 target·의존성을 추가하지 않는다 |

### 검증

- 각 단위 완료 시: 해당 패키지 test target의 `compile` + `test`
- `U6`, `U7`, `U8` 완료 시: App production build까지 포함한 통합 검증(중간 상태에서 조립 경로가
  끊길 수 있는 단위)
- `U15`: [quickstart.md](./quickstart.md) §3 전체 + §4 수동 항목

## 승인이 필요한 지점

원칙 7에 따라 확정된 범위의 후속 단위는 반복 승인 없이 진행한다. 아래 두 경우에만 중단한다.

1. **R3 검증 결과가 설계를 바꿀 때** — SwiftUI `App.init()`과
   `didFinishLaunchingWithOptions`의 실제 순서가 대기 슬롯 설계로도 정확성을 보장하지 못하는 것으로
   드러나면, 새 설계 결정이 필요하므로 중단하고 보고한다.
2. **실제 기기 검증이 필요할 때** — quickstart §4.3의 APNs 수신 검증은 provisioning과 APNs key가
   연결된 기기가 필요하다. 준비 여부는 사용자만 판단할 수 있다.

## 복잡성 추적

헌법 점검에서 정당화가 필요한 위반이 없으므로 작성하지 않는다.
