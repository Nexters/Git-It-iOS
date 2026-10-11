# 구현 계획: 공유 확장에서 진행 중인 생성이 있으면 새 생성 요청 차단

**Git-flow 유형**: `feature`

**브랜치**: `feature/share-generation-guard` (`/speckit-specify`가 생성)

**날짜**: 2026-09-28 | **명세**: [spec.md](./spec.md)

**입력**: `specs/047-share-generation-guard/spec.md`의 기능 명세

**계획 입력**: 사용자 설명: "생성 상태 확인 및 요청에 대해서 기본앱과 공유앱에서 동일한 로직을 유지하도록 하며, 동일한 UseCase 를 사용해 일관성을 유지하도록 합니다"

## 요약

공유 확장이 저장소 조회 전과 등록 요청 직전에 진행 중인 생성이 있는지 판정해, 생성 중이면 생성 중 안내를, 생성 상태를 확인할 수 없으면
확인 실패 안내와 재시도를 보여 주고 등록을 막는다. 본 앱과 공유 확장은 같은 `ProjectGenerationUseCase`와 같은 판정 규칙을 쓴다.

0. **Feature 배치 정리**: 기능 구현 전에 `ShareRegistration` 흐름의 소스·테스트를 동작 변경 없이 화면 폴더
   `ShareRegistration/`로 옮긴다([research R9](./research.md#r9-공유-확장-흐름-배치-정리-fr-012-명확화-2026-09-29), FR-012).
1. **Domain**: "생성 중" 판정 규칙을 `ProjectGenerationState.hasRequestInProgress` 한 곳에 둔다([R1](./research.md#r1-생성-중-판정-규칙의-소유자)).
   `ProjectGenerationUseCase.currentState()`를 추가해 관찰 없이 현재 상태를 한 번 읽고, 읽기 실패는 `stateUnavailable`로 알린다
   ([R2](./research.md#r2-공유-확장이-생성-상태를-한-번-읽는-연산)).
2. **Data·Composition**: 읽기 실패(저장소 없음, 저장 값 해석 불가)를 Data 공유 저장 계약의 새 연산 `verifiedValue`와 생성 기록
   저장소 `verifiedState()`로 드러내고, Composition Adapter가 이를 Domain 오류 `stateUnavailable`로 바꿔 Domain 저장소 계약
   `confirmedPendingState()`로 전달한다([R3](./research.md#r3-읽기-실패를-드러내는-경로-명확화-2026-09-28-사용자-결정)).
3. **Feature**: 판정 전용 타입을 두지 않는다. 하위 `SharedRepositoryRegistrationFeature`는 UseCase 전체 대신 `lookUpRepository`·
   `requestGeneration`·`currentGenerationState` 클로저만 받고, 루트 `ShareRegistrationFeature`가 공개 initializer를 유지한 채 이 클로저를
   만들어 전달한다. 하위 Feature는 조회 결과를 `hasRequestInProgress`와 읽기 오류로만 분기한다([R4](./research.md#r4-공유-확장-feature의-단순화된-usecase-경계-fr-009)).
   화면 상태 두 개와 재시도를 추가한다([R5](./research.md#r5-공유-확장-화면-상태와-재시도)).
4. **App**: 진단 로그에 새 사례를 기록하고, 홈 잠금 판정이 Domain 규칙을 쓰도록 바꾼다(결과는 동일).

## 기술 맥락

**언어/버전**: Swift 6 (strict concurrency, typed throws), iOS 26.0 이상

**주요 의존성**: SwiftUI, The Composable Architecture, Swift Concurrency(`actor`, `AsyncStream`)

**저장소**: 기존 App Group `UserDefaults` 기반 키 값 저장소(`LocalKeyValueStorage`)의 생성 기록(`generationState` 키). 저장 형식·키는 바꾸지 않는다.

**테스트**: Swift Testing(`@Suite`, `@Test`), TCA `TestStore`

**대상 플랫폼**: iOS 26.0 이상 iPhone, Share Extension. 기본 테스트 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: 판정은 로컬 저장소 1회 읽기이며 네트워크 호출이 없다. 생성 중·확인 실패 시 저장소 조회·등록 요청 0회(SC-001, SC-003, SC-003a)

**제약 조건**: 새 Domain 상태 모델 금지(FR-008), 판정 규칙 정의 한 곳(FR-011, SC-004), 앱 홈 잠금 결과·생성 기록 저장 규칙·서버 API 불변(FR-010),
공유 확장은 앱을 실행하지 않음(027 FR-025), 공유 확장에서 생성 상태 관찰을 시작하지 않음(명세 가정)

**규모/범위**: Data 2개 target(`DataShared`, `DataLearningProject`), Domain 1개(`DomainProjectGeneration`), Composition 1개
(`CompositionLearningProject`), Feature 1개 흐름(`ShareRegistration`, 이동 파일 15개 포함), App 2개 target(`GitIt`, `ShareExtension`).
두 프로토콜 요구사항 추가로 테스트 더블 10개와 App 프리뷰 1개가 함께 바뀐다.

미해결 `NEEDS CLARIFICATION`은 없다.

## 헌법 점검

| 원칙 | 점검 | 결과 |
|---|---|---|
| 1. 명시적인 경계 | 판정 규칙은 Domain, 저장 기술 실패 변환은 Data, Data 오류→Domain 오류 변환은 Composition Adapter, 화면 상태는 Feature, 진단 기록·조립은 App. 새 의존 방향 없음 | 통과 |
| 2. 상태와 데이터 안전성 | 생성 기록 읽기는 기존 직렬 실행(`exclusively`) 안에서 한다. `currentState()`는 actor 상태를 바꾸지 않고 관찰을 시작하지 않는다 | 통과 |
| 3. 검증 가능한 변경 | 단위마다 `compile`, 마지막에 `build`·`compile`·`test`. 확인 실패 안내는 실기기 재현이 어려워 자동 테스트로만 검증하고 PR에 미검증 범위로 적는다 | 통과 |
| 4·5. 수정 경로 | 이 명령은 계획 산출물(`plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`)만 수정했다 | 통과 |
| 6. 한국어 산출물 | 모든 자연어 본문은 한국어, 식별자는 원문 | 통과 |
| 7. 위험 기반 실행 단위 | 아래 실행 단위 0~4. 배치 이동은 동작 변경과 분리한 단일 패키지 단위. 프로토콜 요구사항 추가와 enum 사례 추가로 적합 타입·exhaustive switch가 함께 바뀌어야 하는 단위만 integration unit | 통과 |
| 8. 브랜치 | `feature/share-generation-guard`는 `/speckit-specify`가 생성한 현재 브랜치 | 통과 |
| 9. 세션 지식 기록 | 기록 조건 해당 없음 | 통과 |
| 10. 네이밍 | [research R7](./research.md#r7-새-공개-이름)의 책임 문장. 새 조회 연산은 실패 가능성이 아니라 판독 가능성 확인 책임(`verified`·`confirmed`)으로 구분하고, Domain 계약에 저장소 연산 동사를 쓰지 않는다(D-ARCH-004) | 통과 |
| 11. 컨벤션 근거 | 아래 적용 컨벤션. 기존 흐름 배치 위반(R9)과 하위 Feature의 UseCase 전체 주입(R4)은 이번 기능에서 해소한다 | 통과 |

설계 후 재점검(2026-09-29 analyze D1~D4 반영): 판정 규칙이 Domain 한 곳에만 있고(R1), Data 오류는 Adapter에서 Domain 오류로
바뀌며(R3), 하위 Feature는 쓰는 동작 클로저 3개만 받고(R4), 새 연산 이름이 네이밍 컨벤션을 따르며(R7), 흐름 배치가 컨벤션과 일치한다(R9).
기존 `value` 연산과 `ShareRegistrationFeature` 공개 initializer가 유지된다. 위반 없음.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/architecture.md](../../docs/architecture.md) | 위상 순서 Infrastructure → Data → Domain → Composition → Feature → App. Data·Domain은 서로 의존하지 않고 Composition이 연결한다 |
| [docs/package-rules/data.md](../../docs/package-rules/data.md) | 저장 기술 오류는 Data 소유 오류(`KeyValueStorageError`)로 바꾸고, 기술 이름 없는 역할 계약(`KeyValueStorage`)에 연산을 둔다. Data 테스트는 역할 계약 더블을 쓴다 |
| [docs/package-rules/domain.md](../../docs/package-rules/domain.md) | "생성 중" 규칙과 일회 조회 연산은 기존 관심사 `DomainProjectGeneration`의 모델·계약에 둔다. 말단 Feature(`SharedRepositoryRegistrationFeature`)에는 UseCase 전체가 아니라 쓰는 동작 클로저 3개만 전달하고, UseCase 계약은 루트 Feature까지만 쓴다 |
| [docs/package-rules/composition.md](../../docs/package-rules/composition.md) | Data→Domain 변환(`verifiedState` → `GenerationState`), Data 오류(`KeyValueStorageError`)→Domain 오류(`stateUnavailable`) 변환과 보관 기한 정리 연결은 `PendingGenerationRepositoryAdapter`에서. Data 오류 타입을 Domain 계약 밖으로 내보내지 않는다. 비즈니스 판정을 Adapter에 두지 않는다 |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | Domain 규칙을 Feature에 다시 구현하지 않는다(`hasRequestInProgress`만 사용). Domain UseCase 프로토콜을 Feature production target과 프리뷰에서 구현하지 않는다(테스트 더블 해석은 R4). 상위는 하위에 최소 subset(조회·요청·상태 조회 클로저)만 전달한다. 필수 의존성에 기본값을 주지 않는다 |
| [docs/package-rules/app.md](../../docs/package-rules/app.md) | App은 Domain 규칙을 다시 판단하지 않는다(홈 잠금이 `hasRequestInProgress` 사용). production에 preview·test 구현을 주입하지 않는다(`NoopProjectGeneration`은 프리뷰 전용) |
| [docs/conventions/abstraction.md](../../docs/conventions/abstraction.md) | 공유 확장 판정에 프로토콜이나 래퍼 타입을 두지 않는다(근거 A·B 없음). 상태 조회 클로저 `currentGenerationState`를 주입하고 테스트는 클로저에 대역을 넣는다 |
| [docs/conventions/naming.md](../../docs/conventions/naming.md) | 새 공개 이름은 책임 문장과 최소 문맥으로 정한다([R7](./research.md#r7-새-공개-이름)). [연산](../../docs/conventions/naming/operation.md): 실패 가능성을 이름에 중복하지 않는다. 배치 이동은 [rename](../../docs/conventions/naming/rename.md)처럼 동작 변경과 분리한다 |
| [docs/conventions/file-vocabulary.md](../../docs/conventions/file-vocabulary.md) | 파일 하나에 타입 하나. Data `Errors/`·`Contracts/`·`Stores/`, Domain `Models/`·`Contracts/`·`UseCases/`·`Errors/`, Feature 화면 폴더의 `SubViews/`·`Previews/`, 테스트 `TestDoubles/` 어휘를 따른다 |
| [docs/conventions/directory-file.md](../../docs/conventions/directory-file.md) | [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)는 흐름 1뎁스에 `Router/`·`<화면>/`·`Previews/`·`Shared/`·`Resources/`만 허용한다. 실행 단위 0에서 `ShareRegistration` 흐름을 화면 폴더 `ShareRegistration/`(화면·두 Feature·진단 사례·`SubViews/`·`Previews/`)와 테스트 `Tests/ShareRegistration/ShareRegistration/`로 옮기고(R9), 이후 작업은 새 경로만 쓴다. 새 타입 파일은 추가하지 않는다 |
| [docs/conventions/test.md](../../docs/conventions/test.md) | Swift Testing, 한국어 동작 문장 테스트 이름, Test Double은 initializer 주입, 둘 이상 파일에서 쓰는 더블만 `TestDoubles/`. 테스트는 `Tests/<흐름>/<화면>/`을 미러링한다 |
| [docs/conventions/tca/README.md](../../docs/conventions/tca/README.md) | 의존성은 Reducer initializer로 주입하고 private 불변 프로퍼티로 보존한다. 판정은 기존 Effect 안에서 하고 결과는 기존 `validationFinished`로 보내 새 Action을 만들지 않는다(R5). Effect 취소 ID는 기존 `validation`·`registration`을 그대로 쓴다 |
| [docs/conventions/localization.md](../../docs/conventions/localization.md) | 새 문구 4개는 Feature 문구 카탈로그와 `LocalizedText.ShareRegistration` 확장으로만 조회한다 |
| [docs/conventions/view.md](../../docs/conventions/view.md) | 새 두 상태는 기존 화면 전용 서브뷰 `GuidanceView`를 재사용하고, 새 상태 프리뷰는 화면 폴더 `Previews/`의 [프리뷰](../../docs/conventions/view/preview.md) 파일에 추가한다 |

Figma: [Figma 노드 인덱스](../../.agents/skills/implement-figma-ui/references/figma-index.md)에 공유 확장 노드가 없다. 구현 전
`implement-figma-ui`로 노드 유무를 확인하고, 없으면 기존 안내 화면 구성을 재사용한다(명세 가정).

## 프로젝트 구조

### 문서(이 기능)

```text
specs/047-share-generation-guard/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── generation-state-read.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks 산출물
```

### 소스 코드(`sources/Projects/` 기준)

```text
Data/Shared/
├── Contracts/KeyValueStorage.swift                    # verifiedValue 추가
├── Errors/KeyValueStorageError.swift                  # 신규
└── Stores/{LocalKeyValueStorage,UnavailableKeyValueStorage}.swift
Data/LearningProject/Stores/LocalPendingGenerationStore.swift   # verifiedState 추가
Domain/ProjectGeneration/
├── Models/ProjectGenerationState.swift                # hasRequestInProgress
├── Errors/ProjectGenerationError.swift                # stateUnavailable
├── Contracts/PendingGenerationRepository.swift        # confirmedPendingState
└── UseCases/{ProjectGenerationUseCase,ProjectGeneration}.swift   # currentState
Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift   # 오류 변환 포함
Feature/ShareRegistration/ShareRegistration/           # 실행 단위 0에서 흐름 루트·1뎁스에서 이동
├── SharedRepositoryRegistrationFeature.swift          # 클로저 3개 주입, 판정 분기
├── ShareRegistrationFeature.swift                     # 공개 init 유지, 클로저 생성
├── ShareRegistrationScreen.swift
├── ShareRegistrationDiagnosticEvent.swift
├── SubViews/ShareRegistrationScreen+{GuidanceView,LoadingView}.swift
└── Previews/{ShareRegistrationScreenPreviews,ShareRegistrationPreviewSupport}.swift
Feature/Shared/Localization/{Localizable.xcstrings,LocalizedText+ShareRegistration.swift}
Feature/Tests/ShareRegistration/ShareRegistration/     # 실행 단위 0에서 이동
App/ShareExtension/ShareRegistrationDiagnosticLog.swift
App/GitIt/Reducers/AppRootFeature.swift
```

**구조 결정**: 기존 관심사 target과 형태 폴더만 사용한다. 새 target·manifest 변경은 없다. `Feature` target의 `sourceDirectory`가
패키지 루트라 흐름 내부 이동은 manifest를 바꾸지 않는다.

## 실행 단위

위상 순서: Infrastructure(변경 없음) → Data → Domain → Composition → Feature → App. 실행 단위 0(Feature 배치 이동)은 단위 1·2와
빌드 의존이 없어 위상 순서의 예외가 아니며, 이후 단위가 새 경로만 참조하도록 기능 변경보다 먼저 둔다.

| 순서 | 단위 | 종류 | 목적 | 분리 불가 근거 | 통합 검증 |
|---|---|---|---|---|---|
| 0 | 공유 확장 흐름 배치 정리 | Feature | `git mv`로 소스 8개·테스트 7개를 화면 폴더로 이동. 코드·동작 변경 없음 | 단일 패키지 | `compile` |
| 1 | 저장소 판독 실패 전달 | integration (Data → Composition 테스트 더블) | `KeyValueStorageError`, `verifiedValue`, `verifiedState`와 Data 테스트 | `KeyValueStorage` 요구사항 추가는 Data·Composition 테스트 target의 `InMemoryKeyValueStorage` 6개가 같은 커밋에서 바뀌어야 compile된다 | `compile` |
| 2 | 생성 상태 일회 조회 | integration (Domain → Composition → Feature 테스트 → App) | `hasRequestInProgress`, `stateUnavailable`, `confirmedPendingState`, `currentState`와 Adapter 오류 변환, 적합 타입 갱신 | 두 프로토콜 요구사항 추가는 Composition Adapter, Domain·Feature·App 테스트 더블과 App 프리뷰가 같은 커밋에서 바뀌어야 compile된다 | `compile` |
| 3 | 공유 확장 생성 판정 | integration (Feature → App) | 하위 Feature 클로저 3개 주입과 판정 분기, 화면 상태·재시도, 문구, 진단 사례와 App 진단 로그 | `ShareRegistrationDiagnosticEvent` 사례 추가는 App `ShareRegistrationDiagnosticLog`의 exhaustive switch가 같은 커밋에서 바뀌어야 compile된다 | `compile` |
| 4 | 앱 홈 잠금 판정 규칙 통일 | App | `AppRootFeature`가 `hasRequestInProgress` 사용 | 단일 패키지 | `compile`, 마지막에 `build`·`compile`·`test` |

### 단위별 파일(`sources/Projects/` 기준)

`SR`은 `Feature/ShareRegistration/ShareRegistration`, `SRT`는 `Feature/Tests/ShareRegistration/ShareRegistration`을 줄인 표기다. 이동 대상 전체
경로는 [research R9](./research.md#r9-공유-확장-흐름-배치-정리-fr-012-명확화-2026-09-29) 표가 정본이다.

| 단위 | 패키지 | 파일 |
|---|---|---|
| 0 | Feature | R9 표의 이동 전·후 경로 15개(소스 8개: 화면·두 Feature·진단 사례·서브뷰 2개·프리뷰 2개, 테스트 3개, `TestDoubles/` 4개) |
| 1 | Data | `Data/Shared/Errors/KeyValueStorageError.swift`(신규), `Data/Shared/Contracts/KeyValueStorage.swift`, `Data/Shared/Stores/LocalKeyValueStorage.swift`, `Data/Shared/Stores/UnavailableKeyValueStorage.swift`, `Data/LearningProject/Stores/LocalPendingGenerationStore.swift`, `Data/Tests/Shared/Stores/LocalKeyValueStorageTests.swift`, `Data/Tests/Shared/Factories/StorageFactoryTests.swift`, `Data/Tests/LearningProject/Stores/LocalPendingGenerationStoreTests.swift`, `Data/Tests/Authentication/TestDoubles/InMemoryKeyValueStorage.swift`, `Data/Tests/LegalConsent/TestDoubles/InMemoryKeyValueStorage.swift`, `Data/Tests/LearningProject/TestDoubles/InMemoryKeyValueStorage.swift` |
| 1 | Composition | `Composition/Tests/Authentication/TestDoubles/InMemoryKeyValueStorage.swift`, `Composition/Tests/ShareExtension/TestDoubles/InMemoryKeyValueStorage.swift`, `Composition/Tests/LearningProject/TestDoubles/InMemoryKeyValueStorage.swift` |
| 2 | Domain | `Domain/ProjectGeneration/Models/ProjectGenerationState.swift`, `Domain/ProjectGeneration/Errors/ProjectGenerationError.swift`, `Domain/ProjectGeneration/Contracts/PendingGenerationRepository.swift`, `Domain/ProjectGeneration/UseCases/ProjectGenerationUseCase.swift`, `Domain/ProjectGeneration/UseCases/ProjectGeneration.swift`, `Domain/Tests/ProjectGeneration/Models/ProjectGenerationStateTests.swift`(신규), `Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift`, `Domain/Tests/ProjectGeneration/TestDoubles/InMemoryPendingGenerationRepository.swift` |
| 2 | Composition | `Composition/LearningProject/Adapters/PendingGenerationRepositoryAdapter.swift`, `Composition/Tests/LearningProject/Adapters/PendingGenerationRepositoryAdapterTests.swift` |
| 2 | Feature | `Feature/Tests/ProjectRegistration/TestDoubles/ProjectGenerationUseCaseStub.swift`, `SRT/TestDoubles/ProjectGenerationUseCaseSpy.swift` |
| 2 | App | `App/GitIt/Screens/AppRootView.swift`, `App/Tests/GitIt/TestDoubles/ProjectGenerationUseCaseMock.swift` |
| 3 | Feature | `SR/SharedRepositoryRegistrationFeature.swift`, `SR/ShareRegistrationFeature.swift`, `SR/ShareRegistrationScreen.swift`, `SR/ShareRegistrationDiagnosticEvent.swift`, `SR/Previews/ShareRegistrationScreenPreviews.swift`, `Feature/Shared/Localization/Localizable.xcstrings`, `Feature/Shared/Localization/LocalizedText+ShareRegistration.swift`, `SRT/SharedRepositoryRegistrationFeatureTests.swift`, `SRT/ShareRegistrationFeatureFailureTests.swift`, `SRT/TestDoubles/ProjectGenerationUseCaseSpy.swift` |
| 3 | App | `App/ShareExtension/ShareRegistrationDiagnosticLog.swift` |
| 4 | App | `App/GitIt/Reducers/AppRootFeature.swift`, `App/Tests/GitIt/Reducers/AppRootFeatureTests.swift` |

적합 타입 목록은 구현 시 `: KeyValueStorage`, `: PendingGenerationRepository`, `: ProjectGenerationUseCase`, `ShareRegistrationDiagnosticEvent`
검색으로 다시 확인하고, 누락된 파일이 있으면 해당 단위에 포함한다. `SharedRepositoryRegistrationFeature.init`의 생성 지점은
`SR/ShareRegistrationFeature.swift`와 `SRT/SharedRepositoryRegistrationFeatureTests.swift` 두 곳이다(프리뷰 지원 파일은 생성하지 않는다).
`ProjectGenerationUseCaseSpy.swift`는 단위 2에서 `currentState()`를 추가하고, 단위 3에서 루트 Feature 테스트가 조회 결과(상태 또는 오류)를
설정할 수 있게 확장한다. 하위 Feature 테스트는 세 클로저에 대역을 직접 넣는다. `ExternalRepositoryUseCaseFixedResultStub`은 루트 Feature
테스트 두 파일(`ShareRegistrationFeatureStepTests`, `ShareRegistrationFeatureFailureTests`)이 계속 쓰므로 `TestDoubles/`에 남는다.
`ShareRegistrationFeatureStepTests.swift`는 Action이 늘지 않으므로(R5) 단위 3에서 바뀌지 않는다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 저장 계약 변경이 Data·Composition 테스트 더블 6개에 번짐 | 명확화(읽기 실패 시 확인 실패 안내)와 사용자 결정(저장소 불가+디코딩 실패)으로 실패 구분이 저장 계약에서 시작되어야 한다 | 프로토콜 extension 기본 구현은 더블이 새 연산을 드러내지 못하고 누락이 컴파일 오류로 드러나지 않는다(research R3) |
| 기능 범위에 흐름 배치 이동 15개 파일 포함 | 기존 배치가 Feature 흐름 배치 컨벤션을 어겨 이번 변경 경로가 원칙 11을 지키려면 이동이 먼저 필요하다(명확화 2026-09-29) | 예외로 남기면 위반이 늘고, 기능 커밋에 섞으면 리뷰·되돌리기가 어렵다. 동작 변경 없는 별도 단위 0으로 분리한다(research R9) |
