# 계층 과잉 축소 요구사항

**상태**: 초안

**작성일**: 2026-09-15

**근거 시점**: branch `feature/screen-type-refactor`, commit `bee2388`

**목적** — 변화를 흡수하지 않는 추상화 계층을 걷어내, 하나의 기능 변경이 건드려야 하는 파일 수를 줄입니다.

**전제** — Domain↔Data 경계 구조(Domain 계약 ← Composition Adapter → Data API)는 현행을 유지합니다. 이 문서는 그 경계를 유지한 채 **경계 안쪽의 중복 추상화**만 다룹니다.

## 1. 현상

### 1.1 호출 하나가 통과하는 계층

```text
Feature
  → UseCase 프로토콜 → UseCase 구현            (Domain)
  → Repository 프로토콜                        (Domain)
  → Adapter                                    (Composition)
  → Remote 프로토콜 → HTTP Remote 구현         (Data)
  → HTTPClient → HTTPTransport                 (Infrastructure)
```

9단계이며 이 중 **단일 구현만 존재하는 프로토콜이 4개**입니다.

프로덕션 Swift 파일 513개, 프로덕션 프로토콜 58개.

### 1.2 Data Remote 프로토콜은 테스트 더블 목적이 이미 대체되어 있습니다

`Data/**/Contracts/` 아래 Remote·Store 계약 11개가 있고, 각각 구현이 하나씩입니다.

한편 Data 테스트는 이미 전송 계층에 스텁을 주입하는 방식을 갖고 있습니다.

- `Data/Tests/Authentication/TestDoubles/StubHTTPTransport.swift`
- `Data/Tests/ExternalRepository/TestDoubles/StubHTTPTransport.swift`
- `Data/Tests/LearningProject/TestDoubles/StubHTTPTransport.swift`
- `Data/Tests/Member/TestDoubles/StubHTTPTransport.swift`

즉 `HTTPProjectRemote` 등의 동작은 `HTTPTransport` 스텁으로 검증되고 있으며, `ProjectRemote` 프로토콜은 Composition Adapter가 주입받는 타입 자리 외에는 역할이 없습니다.

### 1.3 Adapter가 흡수하는 변화량이 작습니다

`Composition/Adapter/Adapters/AnswerRepositoryAdapter.swift`의 변환은 DTO 필드를 Domain 모델 필드로 1:1 복사하는 것과, `DataLearningProjectError`를 `LearningProjectError`로 재매핑하는 것입니다. 오류 case 이름은 `invalidRequest`, `unauthorized`, `questionUnavailable`, `learningSetUnavailable`, `temporarilyUnavailable`로 대부분 동일합니다.

### 1.4 변경 비용

서버 응답에 필드 하나가 추가되면 DTO, Adapter 매핑, Domain 모델, UseCase 시그니처, Feature State 다섯 지점을 수정해야 합니다.

## 2. 문제 정의

1. 프로토콜이 "교체 가능성" 또는 "테스트 더블 필요"라는 근거 없이 계층 관례로 생성되고 있습니다.
2. Data 내부의 Remote 프로토콜은 두 근거 중 어느 것도 충족하지 않으면서 파일 수와 주입 배관을 늘립니다.
3. 추상화 생성 기준이 문서화되어 있지 않아 새 기능마다 같은 계층이 반복 생성됩니다.

## 3. 요구사항

### FR-1 프로토콜 생성 기준 확정과 문서화

- 프로젝트가 소유한 타입에 프로토콜을 두는 근거를 다음 둘로 한정하고 [공통 컨벤션](../conventions/README.md)에 기록한다.
  1. 패키지 경계를 넘는 계약이다.
  2. 그 경계를 넘지 않더라도 구현을 교체하는 지점이 프로덕션에 실재한다.
- 테스트 더블 제공만을 근거로 프로토콜을 두지 않는다. 테스트는 그 타입이 의존하는 **경계 계약**에 더블을 주입한다.

### FR-2 Data Remote·Store 프로토콜 제거

- `Data/**/Contracts/` 아래 Remote·Store 계약 중 프로덕션 구현이 하나뿐이고 패키지 경계를 넘지 않는 것을 제거하고, Composition Adapter가 구체 타입을 직접 받도록 한다.
- 대상: `AuthenticationRemote`, `ExternalRepositoryRemote`, `AnswerRemote`, `BookmarkRemote`, `LearningSetRemote`, `ProjectRemote`, `MemberRemote`, `GenerationProgressStore`, `PolicyConsentStore`.
- `QuizGenerationOutcomeSource`는 [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md) FR-4의 결과에 따라 처리한다. 그 전에는 제거하지 않는다.
- 제거로 삭제되는 `*Contracts/*ContractTests.swift`가 보장하던 동작은 대응하는 `HTTP*RemoteTests`로 이관한다. **보장 항목이 줄어들면 안 된다.**

### FR-3 위임 전용 UseCase 계층 제거

- 저장소 호출을 그대로 반환하는 UseCase는 두지 않는다. 구체 방침과 대상 목록은 [UseCase 통합 요구사항](./usecase-consolidation-requirements.md)이 소유하며, 이 문서는 중복 정의하지 않는다.

### FR-4 오류 타입 중복 정리

- Data 오류와 Domain 오류의 case가 1:1로 대응하고 의미 차이가 없는 구간을 식별한다.
- 의미 차이가 없는 case는 Data 오류 쪽을 통합하거나 제거해 Adapter의 재매핑 분기를 줄인다.
- Domain 오류 타입은 유지한다. Domain이 Data 오류를 그대로 노출하게 만들지 않는다.

### FR-5 파일 수 기준 설정

- FR-2, FR-3 적용 후 프로덕션 Swift 파일 수와 프로덕션 프로토콜 수를 기록하고, 이후 기능 추가 시 그 증가가 FR-1 기준에 부합하는지 PR에서 확인한다.

## 4. 비범위

- Domain↔Data 경계 구조 변경 (현행 유지)
- `HTTPClient`·`HTTPTransport` 등 Infrastructure 계약 (패키지 경계를 넘으므로 FR-1 기준 충족)
- UI·Feature 계층의 타입 수
- Domain 모델 구조 변경

## 5. 수용 기준

- [ ] [공통 컨벤션](../conventions/README.md)에 FR-1의 프로토콜 생성 기준이 기록되어 있다.
- [ ] `find sources/Projects/Data -path "*Contracts*" -name "*.swift" -not -path "*/Tests/*"` 결과에 FR-2 대상 9개가 없다.
- [ ] Data 테스트의 총 검증 항목 수가 FR-2 적용 전보다 줄지 않았다.
- [ ] Composition Adapter가 주입받는 Data 타입이 구체 타입이며, Adapter 테스트는 `HTTPTransport` 스텁으로 구성된다.
- [ ] Adapter의 오류 재매핑 분기 수가 FR-4 적용 전보다 줄었다.
- [ ] 프로덕션 프로토콜 수가 기록되어 있고, 남은 프로토콜 각각이 FR-1의 두 근거 중 하나에 대응된다.

## 6. 영향 범위

| 패키지 | 영향 |
| --- | --- |
| Data | `**/Contracts/**` 9개, 그에 대응하는 `Tests/**/Contracts/**`, `TestDoubles/*Probe.swift` |
| Composition | 모든 Adapter의 초기화 인자 타입, Assembly 4개 |
| Domain | 위임 전용 UseCase (FR-3, 별도 문서 소유), 오류 타입 (FR-4) |

**리스크** — FR-2는 테스트 보장을 옮기는 작업이 본체입니다. 계약 테스트를 지우고 구현 테스트를 추가하지 않으면 커버리지가 조용히 줄어듭니다. 대상 계약 하나마다 "이관 전 보장 항목 → 이관 후 보장 항목" 대조표를 남깁니다.

## 7. 작업 순서 제안

1. FR-1 — 기준 문서화.
2. FR-4 — 오류 정리. 범위가 좁고 Adapter 코드가 바로 줄어듭니다.
3. FR-2 — 계약 제거. 모듈 단위(Authentication → ExternalRepository → Member → LearningProject)로 나눠 진행합니다.
4. FR-5 — 기준선 기록.

FR-3은 [UseCase 통합 요구사항](./usecase-consolidation-requirements.md)의 일정에 따릅니다.

## 관련 문서

- [아키텍처](../architecture.md)
- [Data 패키지 규칙](../package-rules/data.md)
- [UseCase 통합 요구사항](./usecase-consolidation-requirements.md)
- [AsyncStream 재설계 요구사항](./async-stream-redesign-requirements.md)
