# 데이터 모델: 값을 더하지 않는 계층과 간접 참조 제거

이 명세는 런타임 값 구조를 새로 만들지 않는다. 다루는 대상은 타입 사이의 참조 형태와 문서가 소유하는 판단 기준이다.

## 1. 프로토콜 생성 기준

문서가 소유하는 판단 규칙이다. 코드 타입이 아니다.

| 항목 | 내용 |
| --- | --- |
| 근거 A | 패키지 경계를 넘는 계약이다 |
| 근거 B | 경계를 넘지 않더라도 구현을 교체하는 지점이 프로덕션에 실재한다 |
| 배제 규칙 | 테스트 더블 제공만을 근거로 프로토콜을 두지 않는다 |
| 배제 시 대안 | 그 타입이 의존하는 경계 계약에 더블을 주입한다 |

판정은 A 또는 B 중 하나를 충족하면 통과, 둘 다 아니면 구체 타입 하나만 둔다.

## 2. 제거 대상 계약

| 계약 | 소유 모듈 | 프로덕션 구현 | 대체할 구체 타입 |
| --- | --- | --- | --- |
| `AuthenticationRemote` | Data/Authentication | 1 | `HTTPAuthenticationRemote` |
| `ExternalRepositoryRemote` | Data/ExternalRepository | 1 | `HTTPExternalRepositoryRemote` |
| `AnswerRemote` | Data/LearningProject | 1 | `HTTPAnswerRemote` |
| `BookmarkRemote` | Data/LearningProject | 1 | `HTTPBookmarkRemote` |
| `LearningSetRemote` | Data/LearningProject | 1 | `HTTPLearningSetRemote` |
| `ProjectRemote` | Data/LearningProject | 1 | `HTTPProjectRemote` |
| `QuizGenerationRemote` | Data/LearningProject | 0 | 없음 — 계약과 그 참조를 함께 제거 |
| `MemberRemote` | Data/Member | 1 | `HTTPMemberRemote` |
| `PolicyConsentStore` | Data/LegalConsent | 1 | `LocalPolicyConsentStore` |

## 3. 유지 대상 계약

| 계약 | 유지 근거 |
| --- | --- |
| `GenerationStateStore` | 앞선 명세가 소유한다. 이 명세의 판단 대상이 아니다 (FR-011) |
| `QuizGenerationOutcomeSource` | 같음 (FR-011) |
| `HTTPClient`·`HTTPTransport` | 패키지 경계를 넘는다. 근거 A 충족 |
| Domain의 Repository·UseCase 계약 | 패키지 경계를 넘는다. 근거 A 충족 |

## 4. 참조 형태의 전이

어댑터 하나가 겪는 변화다. 값이 아니라 타입 참조가 바뀐다.

| 지점 | 전 | 후 |
| --- | --- | --- |
| 어댑터 저장 프로퍼티 | `private let remote: <Contract>` | `private let remote: HTTP<Module>Remote` |
| 어댑터 초기화 인자 | `init(remote: <Contract>)` | `init(remote: HTTP<Module>Remote)` |
| 조립 호출부 | 변화 없음 | 변화 없음 — 이미 구체 타입을 만들어 넘기고 있다 |
| 어댑터 테스트 | 계약을 채택한 Stub 주입 | 구체 Remote + `StubHTTPTransport` 주입 |

## 5. 오류 case 대응

`DataLearningProjectError`를 예로 든 분류다. 다른 모듈도 같은 기준으로 분류한다.

| Data case | Domain case | 분류 |
| --- | --- | --- |
| `invalidRequest` | `invalidRequest` | 항등 |
| `unauthorized` | `unauthorized` | 항등 |
| `temporarilyUnavailable` | `temporarilyUnavailable` | 항등 |
| `questionUnavailable` | `questionUnavailable` | 항등 |
| `learningSetUnavailable` | `learningSetUnavailable` | 항등 |
| `projectUnavailable` | `notFound` | 실제 변환 — 유지 |
| `transport` | `unexpected` | 접힘 — 유지 |
| `decoding` | `unexpected` | 접힘 — 유지 |
| `unexpectedStatus` | `unexpected` | 접힘 — 유지 |
| `generationRetryUnavailable` | (대응 없음) | 사용처 확인 후 판단 |

항등으로 분류한 구간만 정리 대상이다. 접힘과 실제 변환은 어댑터가 계속 수행한다.

## 6. 구조 기준선

| 항목 | 적용 전 | 적용 후 |
| --- | --- | --- |
| 프로덕션 Swift 파일 수 | 497 | 구현 후 기록 |
| 프로덕션 프로토콜 수 | 56 | 구현 후 기록 |
| Data 프로덕션 Contracts 파일 수 | 11 | 구현 후 기록 |
| Composition 어댑터 오류 재매핑 분기 수 | 구현 전 기록 | 구현 후 기록 |

남은 프로덕션 프로토콜은 각각 근거 A 또는 B에 대응시켜 기록한다.
