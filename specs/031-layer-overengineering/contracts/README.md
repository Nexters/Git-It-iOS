# 경계 계약 변경: 값을 더하지 않는 계층과 간접 참조 제거

이 명세는 새 계약을 만들지 않는다. 기존 계약 중 경계를 넘지 않는 것을 제거하고, 그 자리를 이미 존재하는 구체 타입이 대신한다.

## 1. 제거하는 계약

| 계약 | 소유 | 제거 이유 |
| --- | --- | --- |
| `AuthenticationRemote` | Data/Authentication | Data 안에서만 쓰이고 프로덕션 구현이 하나다 (FR-003) |
| `ExternalRepositoryRemote` | Data/ExternalRepository | 같음 |
| `AnswerRemote` | Data/LearningProject | 같음 |
| `BookmarkRemote` | Data/LearningProject | 같음 |
| `LearningSetRemote` | Data/LearningProject | 같음 |
| `ProjectRemote` | Data/LearningProject | 같음 |
| `QuizGenerationRemote` | Data/LearningProject | 프로덕션 구현이 없다. 테스트 더블과 계약 테스트만 참조한다 |
| `MemberRemote` | Data/Member | Data 안에서만 쓰이고 프로덕션 구현이 하나다 |
| `PolicyConsentStore` | Data/LegalConsent | 같음 |

## 2. 공개 범위가 바뀌는 타입

제거한 계약이 하던 "Composition에 노출되는 타입" 역할을 구체 타입이 그대로 이어받는다. 이미 `public`이면 변화가 없고, 아니면 `public`으로 올린다.

| 타입 | 소유 | 역할 |
| --- | --- | --- |
| `HTTPAuthenticationRemote` | Data/Authentication | `LoginSessionRepositoryAdapter`·`AuthenticationRepositoryAdapter`가 직접 받는다 |
| `HTTPExternalRepositoryRemote` | Data/ExternalRepository | `ExternalRepositoryLookupAdapter`가 직접 받는다 |
| `HTTPAnswerRemote` | Data/LearningProject | `AnswerRepositoryAdapter`가 직접 받는다 |
| `HTTPBookmarkRemote` | Data/LearningProject | `BookmarkRepositoryAdapter`가 직접 받는다 |
| `HTTPLearningSetRemote` | Data/LearningProject | `LearningSetRepositoryAdapter`가 직접 받는다 |
| `HTTPProjectRemote` | Data/LearningProject | `LearningProjectRepositoryAdapter`가 직접 받는다 |
| `HTTPMemberRemote` | Data/Member | `MemberRepositoryAdapter`가 직접 받는다 |
| `LocalPolicyConsentStore` | Data/LegalConsent | `PolicyConsentRepositoryAdapter`가 직접 받는다 |

## 3. 바뀌지 않는 계약

| 계약 | 사유 |
| --- | --- |
| Domain의 Repository·UseCase 계약 | Domain↔Data 경계 구조를 유지한다. Composition 어댑터가 계속 채택한다 |
| `HTTPClient`·`HTTPTransport` | Infrastructure ↔ Data 경계를 넘는다 |
| `GenerationStateStore`·`QuizGenerationOutcomeSource` | 앞선 명세가 소유한다 (FR-011) |
| Domain 오류 타입 | 유지한다. Domain이 Data 오류를 노출하지 않는다 (FR-009) |

## 4. 오류 계약

Data 오류 타입은 유지하되 Domain 오류와 항등으로 대응하는 case 구간의 재매핑 분기를 줄인다. 같은 입력에 대해 어댑터가 던지는 Domain 오류는 변경 전후 동일해야 한다. 서버 HTTP 상태·오류 코드에서 Data 오류로 가는 매핑은 바꾸지 않는다.

## 5. 문서 계약

`docs/conventions/README.md`의 문서 표에 프로토콜 생성 기준 항목이 추가되고, 그 인덱스와 규칙 문서가 새로 생긴다. 이 표는 이후 작업에서 규칙 근거를 찾는 진입점이다.
