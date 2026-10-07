# UseCase 통합 요구사항

**상태**: 초안

**작성일**: 2026-09-15

**근거 시점**: branch `feature/screen-type-refactor`, commit `bee2388`

**목적** — 26개로 분해된 Domain UseCase의 분해 기준을 하나로 정하고, 기준에 맞지 않는 분해를 통합해 Feature·App의 주입 배관을 줄입니다.

**전제** — Domain↔Data 경계 구조는 현행을 유지합니다. Feature는 단일 target을 유지합니다.

## 1. 현상

### 1.1 규모

`sources/Projects/Domain/**/UseCases/` 아래 프로토콜 26개 + 구현 26개, 폴더 26개. 구현 본문은 19~38줄이 대부분입니다.

### 1.2 분해 기준이 세 갈래로 갈라져 있습니다

| 형태 | 해당 UseCase | 비고 |
| --- | --- | --- |
| 단일 동작 (`callAsFunction` 1개) | 23개 | 다수가 저장소 단일 호출 위임 |
| 다중 메서드 서비스 | `PolicyConsentUseCase`(5), `RequestGenerationReminderUseCase`(3), `TrackGenerationProgressUseCase`(3) | "1 UseCase = 1 동작"과 불일치 |
| 순수 위임 | `ObserveGenerationOutcomes`, `FetchMemberProfile`, `DeleteLearningProject`, `FetchLearningProjectDetail`, `FetchBookmarkedQuestions`, `RegisterMemberDevice`, `VerifyAccessToken` 등 | 저장소 호출을 그대로 반환 |

세 번째 갈래의 극단은 `ObserveGenerationOutcomes`로, 본문이 `await repository.outcomes()` 한 줄입니다.

### 1.3 분해가 새 타입을 만들어냈습니다

같은 저장소에 대한 변경 UseCase를 나눈 결과, 그들 사이의 직렬화를 위해 별도 타입이 필요해졌습니다.

- `Domain/Member/UseCases/MemberMutationSerializer.swift` (42줄) — `UpdateMemberPosition`, `UpdateMemberCareerLevel`, `CompleteCuration` 공유
- `Domain/LearningProject/UseCases/SetQuestionBookmark/QuestionMutationSerializer.swift` (42줄)

### 1.4 주입 배관이 상위로 전가됩니다

- `MainShellRouterFeature.init`이 UseCase 14개를 받습니다(`Feature/MainShell/Router/MainShellRouterFeature.swift`).
- `AppComposition`이 `public let`으로 노출하는 UseCase가 25개입니다.
- `AppRootFeature`(518줄)의 상당 부분이 이 전달 배관입니다.

## 2. 문제 정의

1. 분해 기준이 문서화되어 있지 않아 새 UseCase를 추가할 때 단일 동작으로 쪼갤지 서비스에 메서드를 더할지 판단할 근거가 없습니다.
2. 정책이 없는 위임 전용 UseCase는 저장소 계약을 한 번 더 복제할 뿐이며, 그 복제가 Feature 주입 개수를 그대로 늘립니다.
3. 같은 저장소에 대한 변경 연산을 분해한 탓에 직렬화 책임이 UseCase 밖으로 새어 나갔습니다.

## 3. 요구사항

### FR-1 분해 기준 확정과 문서화

- UseCase를 **독립 타입으로 둘 기준**을 다음으로 정하고 `docs/package-rules/domain.md`에 명시한다.
  - 저장소 호출 외에 판단·조율·보상·동시성 제어 중 하나 이상을 수행한다.
  - 또는 둘 이상의 계약을 조합한다.
- 위 기준에 해당하지 않으면 독립 타입으로 두지 않는다.

### FR-2 능력 단위 계약으로 통합

- 기준에 해당하지 않는 UseCase는 도메인 능력 단위 계약으로 통합한다. 통합 계약은 모듈당 1개를 기본으로 한다.
  - `DomainLearningProject` — 프로젝트 조회·삭제, 학습 세트 조회, 북마크 조회
  - `DomainMember` — 프로필 조회, 기기 등록
  - `DomainAuthentication` — 토큰 검증
- 통합 계약의 이름은 [네이밍 컨벤션](../conventions/naming.md)을 따르며 일괄 접미어를 적용하지 않는다.

### FR-3 독립 유지 대상 확정

- 다음은 FR-1 기준을 충족하므로 독립 타입으로 유지한다.
  - 조율·보상: `SignIn`, `SignOut`, `RestoreSession`, `DeleteMemberAccount`
  - 동시성: `RefreshSession`
  - 사전 검증: `FetchExternalRepository`, `SubmitChoiceAnswer`, `SubmitEssayAnswer`
  - 조건부 효과: `FetchLearningProjects`, `RequestGenerationReminder`
  - 상태 수명: `CreateLearningProject`, `PolicyConsent`
- `AuthenticationOutcomes`, `ObserveGenerationOutcomes`, `TrackGenerationProgress`의 처리는 [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md)의 FR-1·FR-4를 따른다.

### FR-4 변경 연산 재통합과 직렬화 내재화

- 같은 저장소를 변경하는 연산은 하나의 계약으로 묶고, 직렬화를 그 계약 구현 내부에서 보장한다.
  - `UpdateMemberPosition` + `UpdateMemberCareerLevel` + `CompleteCuration` → 하나로 통합
  - `SetQuestionBookmark`의 직렬화를 구현 내부로 이동
- 통합 후 `MemberMutationSerializer`와 `QuestionMutationSerializer`를 제거한다.
- 통합 전 각 UseCase 테스트가 보장하던 동시 호출 순서 보장은 통합 후에도 테스트로 유지한다.

### FR-5 주입 표면 축소

- `MainShellRouterFeature`가 받는 Domain 의존성 개수를 **5개 이하**로 줄인다.
- `AppComposition`이 노출하는 Domain 의존성 개수를 **12개 이하**로 줄인다.
- 상위 Feature가 하위 Feature에 전달할 때 하위가 사용하는 최소 subset만 전달한다는 [Feature 패키지 규칙](../package-rules/feature.md)의 제약은 그대로 유지한다. 통합 계약을 하위에 통째로 넘기는 것이 이 제약을 우회하는 수단이 되어서는 안 된다.

### FR-6 파일 배치 정리

- 통합으로 사라지는 UseCase의 프로토콜 파일·구현 파일·폴더를 남기지 않는다.
- 남는 UseCase는 [디렉터리·파일 컨벤션](../conventions/directory-file.md)의 형태 1뎁스·관심사 2뎁스 규칙을 계속 따른다.

## 4. 비범위

- Domain 모델·오류 타입 변경
- Domain↔Data Adapter 구조 변경
- Feature target 분할 (단일 target 유지 결정)
- Feature의 화면 구성·State 구조 변경

## 5. 수용 기준

- [ ] `docs/package-rules/domain.md`에 FR-1의 분해 기준이 검증 가능한 문장으로 기록되어 있다.
- [ ] `find sources/Projects/Domain -path "*UseCases*" -name "*.swift" -not -path "*/Tests/*"` 결과가 현재의 절반 이하다.
- [ ] `MainShellRouterFeature.init`의 Domain 의존성 파라미터가 5개 이하다.
- [ ] `MemberMutationSerializer`와 `QuestionMutationSerializer`가 존재하지 않는다.
- [ ] 회원 정보 변경 연산의 동시 호출 순서 보장 테스트가 통합 계약 기준으로 통과한다.
- [ ] 북마크 변경의 동시 호출 순서 보장 테스트가 통과한다.
- [ ] 기존 UseCase별 테스트가 보장하던 동작이 통합 계약 테스트로 모두 이관되었고, 누락된 보장이 없다.

## 6. 영향 범위

| 패키지 | 영향 |
| --- | --- |
| Domain | UseCase 26개 전수, `*Serializer` 2개 |
| Composition | `AuthenticationAssembly`, `LearningProjectAssembly`, `MemberAssembly`, `ExternalRepositoryAssembly`, `AppComposition`, `ShareExtensionComposition` |
| Feature | 모든 Router Feature의 초기화 인자와 하위 전달 경로 |
| App | `AppRootFeature`, `AppRootView` 프리뷰 Noop 구현, `ShareViewController` |

**리스크** — Feature 초기화 인자가 광범위하게 바뀌므로 Feature 테스트와 App 테스트의 테스트 더블이 함께 변경됩니다. FR-4는 동시성 보장이 걸린 부분이므로 통합 전후 테스트 동치성을 개별 확인해야 합니다.

## 7. 작업 순서 제안

1. FR-1 — 기준 문서화. 나머지 모든 판단의 근거입니다.
2. FR-3 — 독립 유지 대상 확정. 통합 대상 목록이 여기서 확정됩니다.
3. FR-4 — 변경 연산 통합. 범위가 좁고 동시성 보장 검증이 독립적입니다.
4. FR-2, FR-5, FR-6 — 조회 계열 통합과 주입 표면 축소.

[AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md)의 FR-1(죽은 경로 제거)을 먼저 끝내면 이 문서의 대상이 3개 줄어듭니다.

## 관련 문서

- [Domain 패키지 규칙](../package-rules/domain.md)
- [Feature 패키지 규칙](../package-rules/feature.md)
- [Domain UseCase 의도 점검표](./domain-usecase-review.md)
- [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md)
