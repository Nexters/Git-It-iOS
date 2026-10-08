# 조사: 공유 확장에서 진행 중인 생성이 있으면 새 생성 요청 차단

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

## 현재 구조 조사

- 공유 확장 조립(`ShareExtensionComposition`)은 본 앱과 같은 `LearningProjectAssembly`로 `ProjectGeneration`을 만들고,
  생성 기록은 같은 App Group 저장소(`LocalPendingGenerationStore` + `StorageFactory.keyValueStorage(location: .appGroup)`)에
  기록한다. 생성 요청은 이미 두 경로가 같은 UseCase 구현을 쓴다.
- 앱 홈 잠금 판정은 `AppRootFeature.applyGenerationState`가 `ProjectGenerationState.requests`에 `.inProgress` 단계가 있는지
  직접 검사한다. 이 규칙이 Domain에 없고 App에만 있다.
- 공유 확장의 `SharedRepositoryRegistrationFeature`는 로그인 판정 → 저장소 조회 → `projectGeneration.request()` 순으로만
  진행하며 생성 상태를 보지 않는다. `request()`의 `GenerationState.beginning`은 같은 저장소의 진행 중 기록만 거절한다.
- `ProjectGenerationUseCase.states()`는 처음 호출될 때 결과 스트림·로그아웃·저장소 변경 관찰을 시작하고 만료 타이머를 둔다.
  공유 확장에서 한 번 읽으려고 이 관찰을 시작하면 결과 소스 구독과 타이머가 확장 수명 동안 남는다.
- 공유 저장 계약 `KeyValueStorage.value(_:forKey:)`는 실패를 `nil`로 삼킨다. App Group을 쓸 수 없으면
  `UnavailableKeyValueStorage`가 `nil`을, 저장된 JSON 디코딩이 실패하면 `LocalKeyValueStorage`가 `try?`로 `nil`을 돌려준다.
  따라서 생성 기록 저장소와 `ProjectGenerationState`는 "읽기 실패"와 "기록 없음"을 구분하지 못한다.
- `SecureValueStorage`는 `throws(SecureValueStorageError)`로 실패를 드러내는 선례다.
- 하위 등록 Feature `SharedRepositoryRegistrationFeature`는 `ExternalRepositoryUseCase`와 `ProjectGenerationUseCase` 전체를 받지만
  실제로는 `repository(at:)`와 `request(_:)`만 쓴다. 루트 `ShareRegistrationFeature`는 두 UseCase를 하위에 그대로 넘기기만 한다.
- `ShareRegistration` 흐름은 화면·Feature·진단 사례가 흐름 루트에, 서브뷰·화면 프리뷰가 흐름 1뎁스에 있고 테스트도 화면 축을
  미러링하지 않아 [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)와 어긋난다.

## R1. "생성 중" 판정 규칙의 소유자

- 결정: `ProjectGenerationState`에 계산 프로퍼티 `hasRequestInProgress`(진행 중 단계 요청이 하나라도 있으면 참)를 둔다.
  `AppRootFeature`의 홈 잠금 판정과 공유 확장 판정이 모두 이 프로퍼티만 사용한다.
- 근거: FR-011·SC-004는 판정 규칙의 정의가 한 곳이어야 한다고 요구한다. [domain.md](../../docs/package-rules/domain.md)는 비즈니스
  규칙을 Domain이 소유하고, [feature.md](../../docs/package-rules/feature.md)·[app.md](../../docs/package-rules/app.md)는 Feature와 App이
  Domain 규칙을 다시 구현하지 못하게 한다. 새 모델이 아니라 기존 모델의 계산 프로퍼티이므로 FR-008(새 Domain 상태 모델 금지)을 지킨다.
- 검토한 대안: 공유 확장 Feature 안에 같은 검사를 두는 방식. 규칙이 App과 Feature 두 곳에 생겨 FR-011을 어긴다.

## R2. 공유 확장이 생성 상태를 한 번 읽는 연산

- 결정: `ProjectGenerationUseCase`에 `currentState() async throws(ProjectGenerationError) -> ProjectGenerationState`를 추가한다.
  관찰을 시작하지 않고 저장소의 현재 기록을 한 번 읽어 `states()`와 같은 투영 규칙(보관 기한 경과 제외, 단계 변환)으로 돌려준다.
  읽기에 실패하면 `ProjectGenerationError.stateUnavailable`을 던진다.
- 근거: FR-011은 본 앱과 공유 확장이 같은 UseCase를 쓰도록 요구한다. 명세 가정은 관찰 없이 판정 시점마다 한 번 읽기로 했고,
  `states()`는 관찰을 시작하므로 확장에 맞지 않는다. 투영 함수를 `states()`와 공유하므로 두 연산의 규칙이 갈라지지 않는다.
- 검토한 대안:
  - `states()`의 첫 값만 받고 스트림을 끊는 방식. 관찰과 타이머가 시작되고, 읽기 실패를 전달할 수 없다.
  - 공유 확장 전용 UseCase를 Domain에 새로 두는 방식. FR-011(같은 UseCase)을 어긴다.

## R3. 읽기 실패를 드러내는 경로 (명확화 2026-09-28, 사용자 결정)

- 결정: 저장소를 쓸 수 없는 경우와 저장된 생성 상태를 해석할 수 없는 경우를 모두 확인 실패로 본다. 실패는 아래 경로로 전달한다.
  1. Data `DataShared`: 새 오류 `KeyValueStorageError`(`unavailable`, `unreadable`)와 `KeyValueStorage.verifiedValue(_:forKey:)
     async throws(KeyValueStorageError) -> Value?`를 추가한다. 값이 없으면 `nil`, 저장소를 쓸 수 없으면 `unavailable`,
     디코딩에 실패하면 `unreadable`을 던진다. 기존 `value(_:forKey:)`의 의미는 바꾸지 않는다.
  2. Data `DataLearningProject`: `LocalPendingGenerationStore.verifiedState() async throws(KeyValueStorageError) -> GenerationStateDTO`를
     추가한다. 다른 연산과 같은 직렬 실행(`exclusively`) 안에서 읽는다.
  3. Domain `DomainProjectGeneration`: `PendingGenerationRepository.confirmedPendingState() async throws -> GenerationState`를 추가한다.
     기존 Domain 저장소 계약과 같이 untyped `throws`를 쓰고, 던지는 오류는 Domain 오류(`ProjectGenerationError`)로 약속한다.
  4. Composition `CompositionLearningProject`: `PendingGenerationRepositoryAdapter.confirmedPendingState()`가 `pendingState()`와 같은
     보관 기한 정리(`purged`)를 적용하고, 저장소 오류(`KeyValueStorageError`의 모든 사례)를 `ProjectGenerationError.stateUnavailable`로
     바꿔 던진다. Data 오류 타입은 Domain 계약 밖으로 나가지 않는다.
  5. `ProjectGeneration.currentState()`는 저장소 계약이 던진 `ProjectGenerationError`를 그대로 전달하고, 그 밖의 오류는
     `stateUnavailable`로 본다.
- 근거: [data.md](../../docs/package-rules/data.md)는 기술 오류를 Data 소유 오류로 바꾸고 기술 이름 없는 역할 계약으로 공개하게 한다.
  [composition.md](../../docs/package-rules/composition.md)는 Data 오류와 Domain 오류 사이의 변환을 Domain↔Data Adapter 책임으로 두며,
  `ProjectGenerationRepositoryAdapter.domainError(for:)`가 같은 관심사의 선례다. `SecureValueStorage`의 typed throws가 같은 저장 계약
  계열의 선례다. 기존 `value`를 바꾸면 인증·약관 저장 호출부까지 오류 처리가 번지므로 새 연산으로 분리한다.
- 검토한 대안:
  - `value`를 throws로 바꾸는 방식. 모든 호출부가 바뀌고 이번 범위와 무관한 동작 변경 위험이 생긴다.
  - 프로토콜 extension에 기본 구현을 두는 방식. 테스트 더블이 새 연산을 드러내지 못하고 누락이 컴파일 오류로 드러나지 않는다
    (046 계획의 같은 판단). 모든 적합 타입(구현 2개, 테스트 더블 6개)을 같은 단위에서 갱신한다.
  - 디코딩 실패는 기록 없음으로 두는 방식. 사용자 결정으로 제외했다.
  - Adapter가 저장소 오류를 그대로 던지고 UseCase가 변환하는 방식(초기 계획). Data 오류 타입이 Domain 계약을 통과해
    composition.md의 변환 책임을 어긴다(analyze D1).
  - Domain 계약을 `throws(ProjectGenerationError)`로 두는 방식. 기존 Domain 저장소 계약이 모두 untyped `throws`라 관행이 갈린다.

## R4. 공유 확장 Feature의 단순화된 UseCase 경계 (FR-009)

- 결정: 판정 전용 타입을 두지 않고, 하위 등록 Feature에는 쓰는 동작만 클로저로 준다(명확화 2026-09-29 사용자 결정 두 건).
  - `SharedRepositoryRegistrationFeature.init`은 `externalRepository: any ExternalRepositoryUseCase`와
    `projectGeneration: any ProjectGenerationUseCase` 인자를 없애고 다음 클로저 3개를 받는다. 모두 기본값이 없고 private 불변
    프로퍼티로 보존한다.
    - `lookUpRepository: @escaping @Sendable (ExternalRepositoryURL) async throws -> ExternalRepository`
    - `requestGeneration: @escaping @Sendable (ProjectGenerationRequest) async throws -> ProjectGenerationReceipt`
    - `currentGenerationState: @escaping @Sendable () async throws -> ProjectGenerationState`
  - 하위 Feature는 조회한 상태의 `hasRequestInProgress`가 참이면 생성 중, 거짓이면 진행 가능, 조회가 오류를 던지면 확인 실패로
    분기한다. 이 분기는 화면 상태 전환이며 "생성 중" 판정 규칙 자체는 Domain `hasRequestInProgress`에만 있다.
  - 루트 `ShareRegistrationFeature`는 공개 initializer(`externalRepository`, `projectGeneration` 인자)를 유지한 채
    `{ try await externalRepository.repository(at: $0) }`, `{ try await projectGeneration.request($0) }`,
    `{ try await projectGeneration.currentState() }`를 만들어 하위 Feature에 전달한다. App 조립(`ShareViewController`)은 바뀌지 않는다.
- 근거:
  - [domain.md](../../docs/package-rules/domain.md) "말단 화면 Feature는 UseCase 계약 전체를 받지 않고 쓰는 동작 하나만 클로저로
    받는다. UseCase 계약은 Router와 루트 Feature까지만 쓰인다"와 [feature.md](../../docs/package-rules/feature.md) "상위가 하위에
    최소 subset만 전달"을 따른다. 하위 Feature가 UseCase 전체를 함께 보유하면 FR-009 경계가 코드로 강제되지 않는다(analyze D2).
  - [abstraction](../../docs/conventions/abstraction.md)의 [두 가지 근거](../../docs/conventions/abstraction/protocol-criteria.md)에 따르면
    구현이 하나이고 경계를 뒤집을 필요가 없으므로 프로토콜을 두지 않는다. 테스트는 클로저에 대역을 넣는다
    ([테스트 더블은 근거가 아님](../../docs/conventions/abstraction/test-double-injection.md)).
  - 판정 규칙은 Domain `hasRequestInProgress`에만 있으므로 FR-009("별도 판정 로직을 갖지 않음")와 FR-011을 지킨다.
  - 새 타입 파일을 두지 않으므로 [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)의 화면 폴더 루트에
    화면·Feature·그들이 소유하는 값 타입 외의 선언이 생기지 않는다.
- 검토한 대안:
  - 판정 결과 enum `GenerationAvailability`와 판정 struct `GenerationAvailabilityCheck`를 두는 방식(초기 계획). 판정 결과가 Domain
    상태와 오류로 이미 표현되므로 제거했다.
  - 상태 조회 클로저만 추가하고 UseCase 전체 주입을 유지하는 방식(이전 계획). domain.md 말단 Feature 규칙을 어긴다(analyze D2).
  - `projectGeneration`만 클로저로 바꾸고 `externalRepository`는 유지하는 방식. 같은 규칙 위반을 남긴다.
  - Feature에 프로토콜을 정의하고 App이 채택하는 방식. 근거 A·B가 없다.
  - 하위 Feature에 판정 결과 클로저 `() async -> Bool`만 넘기는 방식. 확인 실패를 표현할 수 없다.
- 해석 기록: [feature.md](../../docs/package-rules/feature.md)의 "Domain UseCase·contract 프로토콜을 Feature 안에서 구현하지 않는다
  (프리뷰·테스트 포함)"는 Feature production target과 프리뷰를 대상으로 해석한다. [테스트 컨벤션 — 의존성 격리](../../docs/conventions/test/dependency-isolation.md)와
  [Feature와 TCA 테스트](../../docs/conventions/test/feature-tca.md)가 Feature 테스트에 Domain UseCase Test Double 주입을 요구하므로,
  루트 Feature 테스트의 기존 `ProjectGenerationUseCaseSpy`·`ExternalRepositoryUseCaseFixedResultStub`은 유지한다. 하위 Feature 테스트는
  클로저 대역을 쓴다. 두 문서의 문구 정리는 이 기능 범위가 아니며 별도 사용자 지시로 처리한다.

## R5. 공유 확장 화면 상태와 재시도

- 결정: `SharedRepositoryRegistrationFeature.State.Phase`에 `generationInProgress`와 `generationUnverified(retry: RetryTarget)`를 추가한다.
  - `validate`: 로그인 확인 뒤 `currentGenerationState()` → `hasRequestInProgress`면 `generationInProgress`, 오류면
    `generationUnverified(retry: .lookup)`, 그 밖에는 `lookUpRepository`로 저장소 조회.
  - `submit`: 로그인 확인 뒤 `currentGenerationState()` → `hasRequestInProgress`면 `generationInProgress`, 오류면
    `generationUnverified(retry: .registration)`, 그 밖에는 `requestGeneration`.
  - 판정은 기존 `validate`·`submit` Effect 안에서 수행하고, 차단 결과는 기존 Effect event `validationFinished(State.Phase)`로 보낸다.
    새 Action·Effect event case와 새 취소 ID를 추가하지 않는다(취소 ID는 기존 `validation`·`registration`).
  - `retry`는 `generationUnverified`에서도 동작해 대상에 맞게 `validate` 또는 `submit`을 다시 실행한다. 두 흐름 모두 판정부터 다시 한다.
  - 루트 `canRetry`는 `generationUnverified`에서 참이고, `generationInProgress`에서는 거짓이다. `canDismiss`는 바뀌지 않는다.
- 근거: 명확화(판정 시점 두 번, 확인 실패 시 재시도)와 FR-002·FR-003·FR-003a. 기존 `failed(reason:retry:)`와 분리해 문구·재시도
  유무·진단 로그를 구분한다. Action을 늘리지 않으므로 기존 exhaustive `TestStore` 테스트의 수신 순서가 바뀌지 않고, 바뀌는 것은 판정
  결과를 새 Phase로 받는 사례뿐이다([TCA Action](../../docs/conventions/tca/action.md)·[Effect](../../docs/conventions/tca/effect.md)).
- 검토한 대안:
  - 기존 `failed`에 사유 문구만 바꿔 넣는 방식. 생성 중 상태에서 재시도가 노출되고 테스트가 사유 문자열에 의존한다.
  - 판정 결과를 새 Effect event(`generationStateResolved` 등)로 받는 방식. 한 Effect 안에서 끝나는 판정에 Action이 늘고 기존 테스트
    전체의 수신 순서가 바뀐다.

## R6. 문구, 화면, 진단 로그

- 결정:
  - 문구 키 4개를 Feature 문구 카탈로그에 추가하고 `LocalizedText.ShareRegistration`의 `GenerationInProgress`(title, message),
    `GenerationUnverified`(title, reason)로 조회한다. 키는 경로와 같은 `ShareRegistration.GenerationInProgress.title` 형식이다
    ([현지화 — 키](../../docs/conventions/localization/key.md)). 생성 중 message에는 앱을 열면 최신 상태가 반영된다는 복구 안내를 포함한다.
  - 두 상태는 기존 `ShareRegistrationScreen.GuidanceView`를 재사용한다. Figma 노드 인덱스에 공유 확장 노드가 없으므로 구현 전
    `implement-figma-ui`로 노드 유무만 확인하고, 없으면 기존 안내 화면 구성을 따른다(명세 가정).
  - `ShareRegistrationDiagnosticEvent`에 `generationInProgressBlocked`, `generationStateUnverified`를 추가하고 App의
    `ShareRegistrationDiagnosticLog`가 기록한다(FR-007).
- 근거: [localization.md](../../docs/conventions/localization.md), [view.md](../../docs/conventions/view.md), 027 진단 로그 방식.

## R7. 새 공개 이름

| 이름 | 책임 문장 |
|---|---|
| `KeyValueStorageError` | 키 기반 값 저장소를 읽을 수 없는 이유(저장소 없음, 값 해석 불가)를 나타낸다 |
| `KeyValueStorage.verifiedValue(_:forKey:)` | 저장소를 쓸 수 있고 저장된 값을 요청 형식으로 해석할 수 있음을 확인한 값을 돌려준다 |
| `LocalPendingGenerationStore.verifiedState()` | 해석할 수 있음을 확인한 생성 기록을 돌려준다 |
| `PendingGenerationRepository.confirmedPendingState()` | 확인된 대기 생성 상태를 돌려준다 |
| `ProjectGenerationUseCase.currentState()` | 관찰을 시작하지 않고 현재 생성 상태를 한 번 돌려준다 |
| `ProjectGenerationError.stateUnavailable` | 생성 상태를 확인할 수 없음을 나타낸다 |
| `ProjectGenerationState.hasRequestInProgress` | 진행 중 단계의 생성 요청이 하나라도 있는지 알린다 |
| `SharedRepositoryRegistrationFeature.init` 인자 `lookUpRepository` | 공유된 저장소 주소로 저장소를 조회한다 |
| `SharedRepositoryRegistrationFeature.init` 인자 `requestGeneration` | 확인한 저장소의 학습 세트 생성을 요청한다 |
| `SharedRepositoryRegistrationFeature.init` 인자 `currentGenerationState` | 공유 확장 판정에 쓸 현재 생성 상태를 한 번 읽는다 |

근거:

- [naming.md](../../docs/conventions/naming.md)의 책임 우선·최소 문맥.
- 새 연산과 기존 연산(`value`, `state`, `pendingState`)은 시그니처가 `throws` 유무만 달라 Swift에서 같은 이름을 쓸 수 없다.
  [연산](../../docs/conventions/naming/operation.md)은 실패 가능성을 이름에 중복하지 않게 하므로, 실패 여부가 아니라 "판독 가능성을
  확인한 값을 돌려준다"는 책임을 `verified`(Data)·`confirmed`(Domain)로 드러낸다. 기존 연산은 판독 실패를 값 없음으로 흡수한다.
- Domain 계약은 [D-ARCH-004](../../docs/architecture.md#9-아키텍처-결정-기록)에 따라 `read`/`load`처럼 저장소 연산을 드러내는 동사를 쓰지
  않는다. `confirmed`는 저장 매체가 아니라 상태의 확인 여부를 나타낸다.
- `currentState()`는 관찰 연산 `states()`와 수명(일회 조회·관찰)이 달라 구분이 정당하다.
- 하위 Feature 클로저 인자는 기존 UseCase 연산(`repository(at:)`, `request(_:)`, `currentState()`)의 동작을 Feature 문맥의 동사로 드러낸다.
- 검토한 대안: `read` 접두어(이전 계획). 실패 가능성을 이름으로 구분하고 Domain에서 저장소 연산 동사가 되어 두 규칙을 어긴다
  (analyze D3). `current` 계열 통일. 기존 `value`·`state`와의 차이가 이름에 드러나지 않는다.

## R8. 테스트 설계

- Data `LocalKeyValueStorageTests`: 값이 없으면 `nil`, 손상된 값이면 `unreadable`. `UnavailableKeyValueStorage`는 `unavailable`.
- Data `LocalPendingGenerationStoreTests`: 기록 없음이면 빈 상태, 저장소 오류(`KeyValueStorageError`)는 그대로 전파.
- Composition `PendingGenerationRepositoryAdapterTests`: `confirmedPendingState()`가 만료 기록을 제외하고, 저장소 읽기 실패
  (`unavailable`, `unreadable`) 각각을 `ProjectGenerationError.stateUnavailable`로 바꿔 던지는지.
- Domain `ProjectGenerationTests`: `currentState()`가 관찰을 시작하지 않고 보관 기한 경과 기록을 제외해 돌려주는지, 저장소 계약이 던진
  `stateUnavailable`을 전달하고 그 밖의 오류도 `stateUnavailable`로 보는지. 새 `ProjectGenerationStateTests`: `hasRequestInProgress`의
  진행 중·완료·실패·빈 상태 판정.
- Feature `SharedRepositoryRegistrationFeatureTests`: 테스트 지원 함수가 `lookUpRepository`·`requestGeneration`·`currentGenerationState`
  클로저 대역을 주입한다. 조회 전·등록 직전 판정 각각의 생성 중·확인 불가·가능 흐름, 재시도, 진단 로그, 조회·등록 호출 0회.
  `currentGenerationState` 대역에 진행 중·완료만·실패만·빈 상태와 오류를 넣어 분기 결과를 확인한다(SC-004 공유 확장 쪽).
  루트 `ShareRegistrationFeature` 테스트: 루트가 UseCase 연산으로 세 클로저를 만들어 전달하는지(`currentState()` 호출), `canRetry`와 재시도 전달.
- App `AppRootFeatureTests`: 홈 잠금 판정이 기존과 같은 결과를 유지하는지(SC-004 앱 쪽).
- "생성 중" 규칙 정의 검색(SC-004)은 요청 목록 전체에 대한 진행 중 존재 판정만 규칙 정의로 본다. 단일 요청 단계 분기
  (`QuizGenerationProgressFeature`), 기록 상태↔단계 매핑(`PendingGenerationRepositoryAdapter`, `ProjectGeneration.phase(of:)`),
  같은 저장소 중복 검사(`GenerationState`)는 판정 규칙 정의가 아니다.

## R9. 공유 확장 흐름 배치 정리 (FR-012, 명확화 2026-09-29)

- 결정: 기능 구현 전에 Feature 단일 패키지 이동 단위를 둔다. `git mv`로 위치만 바꾸고 타입 이름·코드·동작·manifest는 바꾸지 않는다.

  | 현재 | 이동 후 |
  |---|---|
  | `Feature/ShareRegistration/ShareRegistrationScreen.swift` | `Feature/ShareRegistration/ShareRegistration/ShareRegistrationScreen.swift` |
  | `Feature/ShareRegistration/ShareRegistrationFeature.swift` | `Feature/ShareRegistration/ShareRegistration/ShareRegistrationFeature.swift` |
  | `Feature/ShareRegistration/SharedRepositoryRegistrationFeature.swift` | `Feature/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeature.swift` |
  | `Feature/ShareRegistration/ShareRegistrationDiagnosticEvent.swift` | `Feature/ShareRegistration/ShareRegistration/ShareRegistrationDiagnosticEvent.swift` |
  | `Feature/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift` | `Feature/ShareRegistration/ShareRegistration/SubViews/ShareRegistrationScreen+GuidanceView.swift` |
  | `Feature/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift` | `Feature/ShareRegistration/ShareRegistration/SubViews/ShareRegistrationScreen+LoadingView.swift` |
  | `Feature/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift` | `Feature/ShareRegistration/ShareRegistration/Previews/ShareRegistrationScreenPreviews.swift` |
  | `Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift` | `Feature/ShareRegistration/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift` |
  | `Feature/Tests/ShareRegistration/ShareRegistrationFeatureFailureTests.swift` | `Feature/Tests/ShareRegistration/ShareRegistration/ShareRegistrationFeatureFailureTests.swift` |
  | `Feature/Tests/ShareRegistration/ShareRegistrationFeatureStepTests.swift` | `Feature/Tests/ShareRegistration/ShareRegistration/ShareRegistrationFeatureStepTests.swift` |
  | `Feature/Tests/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift` | `Feature/Tests/ShareRegistration/ShareRegistration/SharedRepositoryRegistrationFeatureTests.swift` |
  | `Feature/Tests/ShareRegistration/TestDoubles/*.swift`(4개) | `Feature/Tests/ShareRegistration/ShareRegistration/TestDoubles/*.swift` |

- 근거:
  - [Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md): 흐름 1뎁스는 `Router/`·`<화면>/`·`Previews/`·`Shared/`·`Resources/`만
    허용하고, 화면 폴더는 화면 이름에서 `Screen`을 뗀 이름(`ShareRegistrationScreen` → `ShareRegistration/`)이며 화면과 그 화면이 조합하는
    Feature, 그들이 직접 소유하는 값 타입(`ShareRegistrationDiagnosticEvent`)을 루트에 둔다. 흐름의 화면은 하나라 `Router/`를 두지 않는다.
  - [View — 프리뷰](../../docs/conventions/view/preview.md): 화면 프리뷰는 그 화면 폴더의 `Previews/`에 둔다. 프리뷰 지원 타입도 이 화면만
    쓰므로 흐름 1뎁스 `Previews/`가 아니라 화면 `Previews/`에 둔다.
  - 테스트는 `Tests/<흐름>/<화면>/`을 미러링하고([Feature 흐름 배치](../../docs/conventions/directory-file/feature-layout.md)),
    둘 이상 파일에서 쓰는 더블은 그 역할 폴더의 `TestDoubles/`에 둔다([형태 어휘](../../docs/conventions/file-vocabulary/shape-vocabulary.md)).
  - `Feature` target의 `sourceDirectory`는 패키지 루트이므로 manifest 변경이 없다. `tuist generate`로 파생 project만 갱신한다.
  - 이동과 동작 변경을 한 커밋에 섞지 않는다([rename 분리](../../docs/conventions/naming/rename.md), Constitution 원칙 7).
- 검토한 대안:
  - 기존 배치를 유지하고 예외로 기록하는 방식(이전 계획). 원칙 11 위반을 남기며 사용자가 정리를 결정했다.
  - 기능 구현과 같은 커밋에서 옮기는 방식. 리뷰와 되돌리기가 어려워진다.
- 범위 밖: `RepositoryConfirmationFeature`는 `ProjectRegistration`과 `ShareRegistration` 두 흐름이 합성하므로 컨벤션상
  `Feature/Shared/Reducers/` 대상이지만, 다른 흐름의 파일이라 이 기능에서 옮기지 않는다(명세 가정).
