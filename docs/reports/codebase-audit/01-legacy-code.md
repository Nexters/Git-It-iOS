# 01. 레거시 코드 분석

작성일: 2026-09-06 · 기준: `feature/share-extension-repository-link` HEAD `7f3d0b7` + 미커밋 작업 트리 · 상위 문서: [README](./README.md)

## 1. 판정 기준

이 문서에서 "레거시"는 다음 네 가지 중 하나에 해당하는 코드와 설정을 뜻합니다.

| 분류 | 정의 | 판정 방법 |
|---|---|---|
| 죽은 코드 | production·test 어디에서도 참조되지 않는 선언 | `grep -rlw <타입>` 결과가 선언 파일만인 경우 |
| 중복 | 같은 책임의 코드가 둘 이상의 target·파일에 복제된 경우 | `diff`로 바이트 동일 또는 6줄 이하 차이 |
| 이행 잔재 | 리팩터링·기능 교체가 끝난 뒤 남은 골격, 호환 생성자, 빈 폴더, 조건 없는 이전 코드 | 커밋 이력(`git log -S`)과 현재 참조 대조 |
| 문서 drift | 규칙 문서가 존재하지 않는 폴더·API·패키지를 가리키는 경우 | 문서 인용 대상을 `find`·`grep`으로 확인 |

모든 항목은 finder 탐색 뒤 별도 검증에서 **CONFIRMED / PLAUSIBLE** 판정을 받은 것만 남겼습니다. REFUTED 항목은 §5에 사유와 함께 기록했습니다. 빌드·테스트는 실행하지 않았습니다.

## 2. 요약

| ID | 항목 | 분류 | 심각도 | 판정 |
|---|---|---|---|---|
| L-01 | Data 3개 target에 바이트 동일한 응답 봉투 타입 4종과 테스트 복제 | 중복 | 높음 | CONFIRMED |
| L-02 | `AllTests` scheme과 Infrastructure scheme이 새 target을 반영하지 않음 | 이행 잔재(설정) | 높음 | CONFIRMED |
| L-03 | HTTP 메서드 열거형 4중 정의와 매핑 코드 | 중복 | 중간 | PLAUSIBLE(인용 1건 수정) |
| L-04 | `StubHTTPTransport`·`JSONBodyCoding` 테스트 더블 4중 복제 | 중복(테스트) | 중간 | CONFIRMED |
| L-05 | `QuizGenerationRemote` 계약·엔드포인트·DTO·테스트만 있고 구현이 없음 | 이행 잔재 | 중간 | CONFIRMED |
| L-06 | `refreshSession`·`verifyAccessToken`이 조립·공개되지만 소비자가 없음 | 죽은 코드 | 중간 | CONFIRMED |
| L-07 | `LegalDocument`·`LegalAcceptanceRecord` 미참조 | 죽은 코드 | 중간 | CONFIRMED |
| L-08 | `ResetAllButton`은 주석 코드에서만 참조되고 `AppDebug`는 조건 없이 링크됨 | 죽은 코드·이행 잔재 | 중간 | CONFIRMED |
| L-09 | UI 컴포넌트 3개가 어느 Feature에서도 사용되지 않음 | 죽은 코드 | 중간 | CONFIRMED |
| L-10 | `AppEndpointHost`·`ShareExtensionEndpointHost` 로직 동일 | 중복 | 중간 | CONFIRMED |
| L-11 | `AppRootView` 프리뷰 지원 Noop 23개와 App/Feature 테스트 mock 중복, 미참조 Noop 1개 | 중복·죽은 코드 | 중간 | PLAUSIBLE(세부 수정) |
| L-12 | `ShareRegistrationPreviewSupport`만 실제 Reducer와 Domain 프로토콜 구현을 사용 | 이행 잔재 | 중간 | CONFIRMED |
| L-13 | 규칙 문서 6곳이 존재하지 않는 폴더·API·패키지를 가리킴 | 문서 drift | 중간 | CONFIRMED |
| L-14 | `InfrastructureCache` target을 사용하는 production target이 없음 | 죽은 코드(target) | 낮음 | CONFIRMED |
| L-15 | Mutation 직렬화 actor 3종이 근사 중복 | 중복 | 낮음 | CONFIRMED |
| L-16 | `RubricResponseDTO`의 호환 생성자가 테스트에서만 사용됨 | 이행 잔재 | 낮음 | CONFIRMED |
| L-17 | `ResourceImage.Asset.Icon` 미사용 case 15개와 raw 문자열 아이콘 2곳 | 죽은 코드 | 낮음 | CONFIRMED(수치 수정) |
| L-18 | `SessionKeychainMigration`이 매 실행 무조건 호출됨 | 이행 잔재 | 낮음 | PLAUSIBLE |
| L-19 | `Infrastructure/PushMessaging/Local/` 빈 미추적 폴더 | 이행 잔재 | 낮음 | CONFIRMED |
| L-20 | 사용되지 않는 Tuist helper 3개 | 죽은 코드(매니페스트) | 낮음 | CONFIRMED |

## 3. 상세

### L-01. Data 3개 target에 바이트 동일한 응답 봉투 타입 4종 복제 — 높음

- **위치**: `sources/Projects/Data/{Authentication,Member,LearningProject}/DTOs/APIResponse/APIResponseDTO.swift`, `…/DTOs/APIResponse/FieldErrorDTO.swift`, `…/DTOs/EmptyResponseData.swift`, `…/Errors/ServerAPIError.swift` (총 12파일). 대응 테스트도 세 target에 복제되어 import와 데이터 리터럴만 다릅니다.
- **근거**: 6쌍 `diff` 결과 모두 exit 0(바이트 동일). 사용처는 `HTTPAuthenticationRemote.swift:91,104,112`, `HTTPMemberRemote.swift:96,109,117`, `LearningProjectHTTPExecutor.swift:70,83,91`.
- **왜 생겼나**: Data 패키지 규칙이 target 간 의존을 두지 않는 방향으로 설계되어 공용 타입을 둘 곳이 없었고, 각 target이 서버 응답 봉투를 각자 복제했습니다.
- **비용**: 서버 응답 형식(예: `fieldErrors` 구조)이 바뀌면 3곳을 동시에 수정해야 하고, 한 곳만 고치면 target별 동작이 갈립니다. 테스트도 3배로 유지합니다.
- **제안**: [04 §2.1](./04-refactoring-and-design-review.md) — Data 패키지 안에 공용 target(예: `DataServerAPI` 또는 `InfrastructureNetworkClient`의 서버 봉투 확장)을 도입해 단일 정의로 모읍니다. 이름 규칙 관점은 [02 N-16](./02-type-naming.md)을 함께 참고합니다.

### L-02. `AllTests`·Infrastructure scheme이 새 target을 반영하지 않음 — 높음

- **위치**: `sources/Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift:23` — Composition에서 `CompositionAdapterTests`만 연결. `ProjectName.swift:128-132` — Infrastructure scheme `buildTargets`에 `InfrastructureLocalNotification` 없음, `testTargets`에 PushMessaging·LocalNotification 없음(테스트 target 자체가 없음).
- **근거**: `CompositionModuleName.swift:6-11`에는 `CompositionAppTests`·`CompositionShareExtensionTests`가 있고 `ProjectName.swift:72-76` Composition scheme에는 연결돼 있으나 `AllTests`에는 없음. `tools/githooks/project-build/core/scheme-policy.sh:28-29`가 `unit:true:AllTests) eligible`, `unit:true:*) ineligible`로 unit 스코프를 `AllTests`로 한정합니다.
- **비용**: 미커밋 작업에서 `Composition/Tests/App/**`으로 이동한 `AppCompositionTests`·`AppCompositionSharedLifetimeTests`·`SharedLifetimeTests`와 새 `ShareExtensionCompositionTests`가 CI unit 스코프에서 실행되지 않습니다. 공유 세션 수명 보장이 사실상 검증에서 빠집니다.
- **제안**: `AllTestsScheme.swift`에 두 test target 추가, `ProjectName.swift` Infrastructure scheme에 `InfrastructureLocalNotification` build target 추가. PushMessaging·LocalNotification 테스트 target 신설은 [03 §4](./03-convention-and-rules.md)에서 다룹니다.

### L-03. HTTP 메서드 열거형 4중 정의 — 중간

- **위치**: `Infrastructure/NetworkClient/Models/HTTPMethod.swift:3-23`(정본), `Data/LearningProject/Models/HTTPMethod.swift:1-5`, `Data/Authentication/Endpoints/AuthenticationEndpoint.swift:3` `enum Method`, `Data/Member/Endpoints/MemberEndpoint.swift:3` `enum Method`. 매핑: `HTTPMemberRemote.swift:88`, `LearningProjectHTTPExecutor.swift:62`, `HTTPAuthenticationRemote.swift:80-84`(인라인 삼항연산자).
- **판정 보충**: finder는 세 번째 매핑도 함수라고 인용했지만 검증에서 `HTTPAuthenticationRemote.swift`에는 별도 함수가 없고 인라인 분기만 있음이 확인됐습니다. 중복 자체는 유효합니다.
- **비용**: Data는 이미 `InfrastructureNetworkClient`에 의존하므로 자체 열거형이 필요 없습니다. 새 메서드(PATCH 등) 추가 시 4곳을 갱신합니다.
- **제안**: Data 세 target의 `Method`/`HTTPMethod`를 제거하고 Infrastructure `HTTPMethod`를 직접 사용합니다.

### L-04. `StubHTTPTransport`·`JSONBodyCoding` 테스트 더블 4중 복제 — 중간

- **위치**: `Data/Tests/{Authentication,Member,LearningProject,ExternalRepository}/TestDoubles/StubHTTPTransport.swift`(37줄), `…/JSONBodyCoding.swift`(15줄). `Composition/Tests/Adapter/TestDoubles/RecordingHTTPTransport.swift:1-26`은 성공 경로만 있는 부분집합.
- **근거**: 4개 쌍 `diff` 모두 exit 0.
- **제안**: `InfrastructureNetworkClient`에 테스트 지원 target(예: `InfrastructureNetworkClientTestSupport`)을 두거나, 규칙이 허용하지 않으면 최소한 Data 패키지 공용 test target으로 모읍니다. `RecordingHTTPTransport`는 `StubHTTPTransport`로 대체 가능합니다.

### L-05. `QuizGenerationRemote` 계약만 존재 — 중간

- **위치**: `Data/LearningProject/Contracts/QuizGenerationRemote.swift`, 대응 `Endpoints/`·`DTOs/`·`Data/Tests/LearningProject/Contracts/QuizGenerationRemoteContractTests.swift`.
- **근거**: `grep -rn 'QuizGenerationRemote'` 결과 production 구현체(`HTTP*Remote`) 없음, Composition Adapter 없음. 유일한 conformance는 테스트 더블 `LearningProjectRemoteProbe`.
- **비용**: 계약·DTO·테스트가 유지되지만 어느 UseCase도 도달하지 않습니다. 서버 스펙이 바뀌면 검증되지 않은 코드를 갱신하게 됩니다.
- **제안**: 퀴즈 생성 API가 `CreateLearningProject` 흐름(`HTTPProjectRemote`)으로 통합된 것이면 계약·엔드포인트·DTO·테스트를 삭제합니다. 별도 API가 예정이면 [04 §3](./04-refactoring-and-design-review.md)의 미완성 기능 목록에 이슈로 남기고 코드는 제거합니다.

### L-06. `refreshSession`·`verifyAccessToken` 소비자 없음 — 중간

- **위치**: `Composition/Adapter/Assemblies/AuthenticationAssembly.swift:59-60,75-76`(생성·공개), `Composition/App/Assemblies/AppComposition.swift:31-32,146-147`(재노출). App·Feature production에서 `refreshSession`/`verifyAccessToken`/`RefreshSessionUseCase`/`VerifyAccessTokenUseCase` 참조 0건.
- **근거**: `grep -rlw` 결과가 두 Assembly 파일과 테스트만. 관련해서 `LoginSessionRepositoryAdapter.refresh()`(`:93-95`)는 서버에 갱신 엔드포인트가 없어 항상 `LoginSessionError.temporarilyUnavailable`을 던지고, 이를 고정하는 `RefreshSessionReleaseBlockerTests`가 있습니다.
- **비용**: 세션 갱신이 "있는 것처럼" 조립돼 있어 독자가 갱신 정책이 동작한다고 오해할 수 있습니다. `SessionAvailabilityResolver`의 만료 검사(`:34-39`)도 `accessTokenExpiresAt`이 항상 nil이어서 도달하지 않습니다.
- **제안**: 서버 갱신 API가 확정될 때까지 두 UseCase·Adapter 메서드·공개 프로퍼티를 제거하고, 만료 정책은 [04 §3.2](./04-refactoring-and-design-review.md)에서 설계 항목으로 다룹니다.

### L-07. `LegalDocument`·`LegalAcceptanceRecord` 미참조 — 중간

- **위치**: `Domain/Authentication/Models/Consent/LegalDocument.swift:1`, `LegalAcceptanceRecord.swift:3`.
- **근거**: 전체 소스에서 선언 줄 외 참조 0건. 같은 역할은 `PolicyDocument`·`PolicyConsentRecord`가 20여 곳에서 사용합니다.
- **제안**: 두 파일 삭제.

### L-08. `ResetAllButton` 주석 코드 참조와 `AppDebug` 무조건 링크 — 중간

- **위치**: `App/Debug/ResetAllButton.swift:5`; 사용처는 `App/GitIt/Screens/AppRootView.swift:40-44`의 주석 처리된 코드만. `sources/Tuist/ProjectDescriptionHelpers/Projects/AppModuleName.swift:81`에서 `.target(name: AppModuleName.AppDebug.rawValue)`가 조건 없는 dependencies 배열에 포함.
- **근거**: `resetAllTapped` 전송은 `AppRootFeatureTests.swift:155,170,239`만. `GitItApp.swift:9-11,33-42`와 `AppRootView.swift:9-11`은 `#if DEBUG`로 import를 감싸지만 링크 자체는 Release에도 남습니다. `docs/package-rules/app.md:16`은 디버그 전용 코드가 Release 빌드에 포함되지 않아야 한다고 명시합니다.
- **제안**: 버튼을 다시 쓸 계획이 없으면 `AppDebug` target과 `ResetAllUseCase`, `AppRootFeature`의 `resetAllTapped` 경로(`:133,262`)를 함께 제거합니다. 유지하려면 Tuist에서 Debug configuration 조건부 의존으로 바꿉니다.

### L-09. 사용되지 않는 UI 컴포넌트 3개 — 중간

- **위치**: `UI/Component/CollectionItems/ChoiceResultRow.swift`, `UI/Component/Controls/SelectableSettingRow/`, `UI/Component/Controls/TextField.swift`.
- **근거**: App·Feature·Composition production에서 세 타입 참조 0건. `LabeledTextField.swift:42`는 커스텀 `TextField` 대신 `SwiftUI.TextField`를 직접 사용합니다. 세 컴포넌트는 `docs/conventions/ui-component.md` §3.4 배치 표에는 정본으로 등재돼 있습니다.
- **제안**: 디자인 시스템 카탈로그로 유지할 컴포넌트라면 표에 "미사용(카탈로그 보관)" 표기를 추가하고, 아니면 삭제합니다. `SelectableSettingRow`는 `SettingRow`와 책임이 겹치므로 통합 대상입니다.

### L-10. `AppEndpointHost`·`ShareExtensionEndpointHost` 로직 동일 — 중간

- **위치**: `App/GitIt/Configurations/AppEndpointHost.swift:1-18`, `App/ShareExtension/ShareExtensionEndpointHost.swift:1-24`.
- **근거**: case·guard·URL 조합이 동일하고 주석과 `fatalError` 문구만 다릅니다.
- **제안**: 두 target이 모두 링크하는 `CompositionAdapter`(또는 신설 공용 target)에 `EndpointHost` 하나를 두고 `Bundle`을 주입받게 합니다.

### L-11. `AppRootView` 프리뷰 지원 Noop 23개와 테스트 mock 중복 — 중간

- **위치**: `App/GitIt/Screens/AppRootView.swift:79-305` `private enum AppRootPreviewSupport`(Noop struct 23개, 약 227줄, 파일의 74%). `App/Tests/GitIt/TestDoubles/NoopFetchMemberProfileUseCase.swift`는 참조 0건. `SignOutUseCaseMock`·`RestoreSessionUseCaseMock`은 `App/Tests/GitIt/TestDoubles/`와 `Feature/Tests/AppEntry/TestDoubles/`에 중복.
- **판정 보충**: finder가 지목한 `FetchMemberProfileUseCaseMock`의 App/Tests 중복은 사실이 아니어서(App/Tests에는 `NoopFetchMemberProfileUseCase`만 존재) 세부를 수정했습니다.
- **제안**: `NoopFetchMemberProfileUseCase.swift` 삭제. 프리뷰 지원은 `AppRootViewPreviews.swift`로 분리하고 `EmptyReducer()`를 사용해 Noop 구현 자체를 없앱니다([03 D-19/T-18](./03-convention-and-rules.md)).

### L-12. `ShareRegistrationPreviewSupport`만 실제 Reducer 사용 — 중간

- **위치**: `Feature/ShareRegistration/Previews/ShareRegistrationPreviewSupport.swift:16-23`(실 Reducer로 Store 생성), `:28,34,40`(Domain 프로토콜 구현).
- **근거**: 다른 프리뷰 23개는 `EmptyReducer()`를 사용합니다. `docs/package-rules/feature.md:76-77`은 프리뷰에서도 Domain 프로토콜 구현을 금지합니다.
- **제안**: `EmptyReducer()`로 교체하고 구현체 3개 삭제. 컨벤션 관점은 [03 T-1](./03-convention-and-rules.md)에서 다룹니다.

### L-13. 규칙 문서 drift 6곳 — 중간

| 문서 | 내용 | 실제 |
|---|---|---|
| `docs/conventions/file-vocabulary.md:172,177` | `UI/ComponentPreviewApp/`, `App/GitIt/AppDelegates/` 소스 루트 | 두 폴더 모두 없음(`AppDelegates/`는 `Infrastructure/PushMessaging/Remote/`에만 존재) |
| `docs/conventions/file-vocabulary.md:151-155` | `Composition/Adapter/` 형태 폴더 5개 | 실제 8개(`Migrations/`, `Models/`, `Resolvers/` 추가), `Composition/App/`·`Composition/ShareExtension/` 행 없음 |
| `CLAUDE.md:27,70`, `docs/package-rules/app.md:26` | "Domain/Data/Core" | `ProjectName` enum에 `Core` 패키지 없음(7개 패키지) |
| `docs/conventions/view.md:298` | `catalogPreviewFrame()` | 소스 참조 0건, 소스 이력 없음(문서 추가 커밋 84e1702만) |
| `docs/architecture.md:115` | `AppComposition.live()` 인자 없는 예시, `getProfile`/`updateProfile` | 실제 시그니처는 `live(_:keychainStore:transport:)`, 호출부 `GitItApp.swift:22-28` |
| `docs/conventions/ui-component.md` §3.4 | `Controls/` 행 `PressOverlayStyle` | UI에 선언 없음 |

- **제안**: 각 문서를 현재 트리에 맞게 갱신합니다. 형태 폴더 표는 [03 D-6/D-21](./03-convention-and-rules.md)의 결정(추가 vs 재분류)에 따라 갱신합니다.

### L-14. `InfrastructureCache` 소비자 없음 — 낮음

- **위치**: `Infrastructure/Cache/` (`InMemoryCache<Key, Value>` actor), Tuist `InfrastructureModuleName.swift:49,54,93,100`.
- **근거**: `import InfrastructureCache`는 `Infrastructure/Tests/Cache/**` 3개 테스트 파일에만 있고 production target 의존 선언에 없음.
- **제안**: 캐시 정책이 계획에 없으면 target·테스트·scheme 연결을 제거합니다. 계획이 있으면 [04 §3](./04-refactoring-and-design-review.md)에 소비자와 정책을 명시합니다.

### L-15. Mutation 직렬화 actor 3종 근사 중복 — 낮음

- **위치**: `Domain/LearningProject/UseCases/SetQuestionBookmark/QuestionMutationSerializer.swift`(42줄, 제네릭 `run<Value>`), `Domain/Member/UseCases/MemberMutationSerializer.swift`(42줄, `Void` 전용), `Domain/Authentication/UseCases/RefreshSession/SingleFlightCoordinator.swift`(26줄).
- **근거**: 앞 두 파일 `diff`는 타입 이름과 제네릭 시그니처 6줄만 다릅니다. 사용처는 `SetQuestionBookmark.swift:11,36`, `UpdateMemberCareerLevel.swift:7,24`, `UpdateMemberPosition.swift:7,24`, `RefreshSession.swift:9,42`.
- **비용**: Domain target 간 의존이 없어 공유가 어렵지만, 세 곳의 취소·재진입 처리가 따로 진화합니다.
- **제안**: Domain 패키지 안에 공용 target(`DomainSupport` 등)을 둘지, 아니면 의도적 복제로 문서화할지 [04 §2.3](./04-refactoring-and-design-review.md)에서 결정합니다.

### L-16. `RubricResponseDTO` 호환 생성자 — 낮음

- **위치**: `Data/LearningProject/DTOs/…/RubricResponseDTO.swift:5-10` `init(score:feedback:)`가 `RubricCriterionResponseDTO(text: feedback, points: score)` 하나를 만드는 이전 형식 호환 생성자.
- **근거**: 사용처는 `Composition/Tests/Adapter/Adapters/AnswerRepositoryAdapterTests.swift:33`, `Data/Tests/LearningProject/TestDoubles/LearningProjectRemoteProbe.swift:112`, `Data/Tests/LearningProject/Contracts/AnswerRemoteContractTests.swift:29`만.
- **제안**: 테스트 3곳을 새 형식으로 바꾸고 생성자를 삭제합니다.

### L-17. `ResourceImage.Asset.Icon` 미사용 case와 raw 문자열 아이콘 — 낮음

- **위치**: `UI/Component/Resources/ResourceImage.swift:39-63` 미사용 case 15개(전체 icon case 53개 중). raw 문자열 사용 `Feature/MainShell/Router/MainShellTab.swift:32 "ic-file-text"`, `UI/Component/CollectionItems/ProjectRow/ProjectRow.swift:99 "ic-play-1"`.
- **판정 보충**: finder의 "imageset 45개"는 실측 34개로 수정했습니다.
- **제안**: raw 문자열 2곳을 case로 바꾸고, 미사용 case는 디자인 카탈로그 유지 여부를 결정한 뒤 정리합니다.

### L-18. `SessionKeychainMigration` 매 실행 호출 — 낮음(PLAUSIBLE)

- **위치**: `Composition/App/Assemblies/AppComposition.swift:184-189`, `Composition/Adapter/Migrations/SessionKeychainMigration.swift`.
- **근거**: 첫 커밋 `d4c371f`(2026-09-05), `MARKETING_VERSION 1.0.0`. 앱스토어·TestFlight 배포 이력은 저장소에서 확인할 수 없어 "배포 전이면 이전 코드 자체가 불필요"라는 결론은 PLAUSIBLE로 둡니다.
- **관련 결함**: 이 이전 코드의 정확성 문제(Apple 사용자 ID·기기 ID 미이전, 접근 그룹 없는 삭제)는 [03 §5 B-1/B-2](./03-convention-and-rules.md)에서 다룹니다.
- **제안**: 배포 전이면 이전 코드를 제거하고 공유 그룹만 사용합니다. 배포 후라면 1회 실행 마커를 두고 이전 완료 뒤 코드를 제거할 버전을 정합니다.

### L-19. `Infrastructure/PushMessaging/Local/` 빈 미추적 폴더 — 낮음

- **근거**: `git ls-files Infrastructure/PushMessaging/Local/` 결과 없음. 커밋 `72b7f36`이 4개 파일을 `LocalNotification/`으로 이동한 뒤 빈 `Clients/`·`Models/`만 남았습니다.
- **제안**: 폴더 삭제. `Remote/` 세그먼트가 하나뿐인 문제는 [03 D-17](./03-convention-and-rules.md)을 참고합니다.

### L-20. 사용되지 않는 Tuist helper 3개 — 낮음

- **위치**: `sources/Tuist/ProjectDescriptionHelpers/Target+Module.swift:35 internalStaticModule`, `:91 resourceBundle`, `:113 testModule(dependencies:)` 오버로드.
- **근거**: `grep -rn` 호출 0건. 모든 `.testModule(` 호출은 `:62` `productionTarget:` 오버로드만 사용합니다.
- **제안**: 삭제.

## 4. 잘 정리된 부분

- 최근 리팩터링의 잔존 참조가 없습니다. `SharedRepositoryLink`·`SharedURLExtractor`·`SharedRepositoryLinkContainer`·`pendingSharedLink`·`initialRepositoryURL`·`pendingAutomaticValidation` 참조 0건.
- `PushNotificationAppDelegate`는 `Composition/App/Factories/`로 내용 변경 없이 이동됐고 옛 경로 참조가 없습니다.
- `ShareViewController`는 `Info.plist`의 `NSExtensionPrincipalClass`로 사용되므로 죽은 코드가 아닙니다.
- `AppEntryFeature`와 `AppRootFeature`는 책임이 겹치지 않습니다(진입 결정 vs 루트 라우팅).
- `ExternalRepositoryLocation`의 Data/Domain 양쪽 정의는 계층 분리를 위한 의도적 중복입니다.

## 5. 검토했지만 제외한 항목

| 후보 | 사유 |
|---|---|
| `AuthenticationOutcomesUseCase`·`TrackGenerationProgressUseCase` "Feature 미사용" | Feature는 쓰지 않지만 `AppRootFeature`가 직접 주입받아 사용(App 사용은 허용 경계) |
| `RegisterMemberDeviceUseCase` "Feature 미사용" | `AppComposition.bootstrap`(`:84-91`)이 사용 |
| `MemberRepository` 구현 2개 | `CurationRepositoryAdapter`는 장식자(decorator)로 설계 의도가 있음 → [04 §3](./04-refactoring-and-design-review.md) |
