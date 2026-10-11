# 조사: 값을 더하지 않는 계층과 간접 참조 제거

## 1. 프로토콜 생성 기준을 어느 문서가 소유하는가

**결정**: `docs/conventions/abstraction.md`를 인덱스로 새로 만들고, 구체 규칙을 `docs/conventions/abstraction/` 아래 문서로 둔다. `docs/conventions/README.md`의 표에 항목을 추가한다.

**근거**: 컨벤션 디렉터리는 "인덱스(`##` 추상 원칙 + `###` 링크) + 같은 이름의 하위 디렉터리(규칙 하나당 문서 하나)" 구조를 정본으로 쓴다. 프로토콜 생성 기준은 패키지 하나가 아니라 전 패키지를 가로지르는 작성 규칙이므로 `package-rules/`가 아니라 `conventions/`가 소유한다. 기존 `naming.md`·`file-vocabulary.md`와 같은 층위다.

**검토한 대안**:

- `docs/conventions/common/`에 넣기 — 공통 원칙은 "문서를 어떻게 쓰는가"를 다루는 메타 규칙 모음이다. 코드 작성 규칙을 섞으면 그 경계가 흐려진다.
- `docs/architecture.md`에 절 추가 — 아키텍처 문서는 패키지 책임과 의존 방향을 소유한다. 타입 수준의 작성 판단은 층위가 다르다.
- `docs/package-rules/data.md`에만 기록 — 기준이 Data에만 적용되는 것처럼 읽힌다. Composition·Domain에도 같은 판단이 필요하다.

## 2. 계약을 제거할 때 Composition 어댑터가 무엇을 받는가

**결정**: 어댑터 초기화 인자를 `any <Contract>`에서 Data의 구체 타입(`HTTPAuthenticationRemote`, `HTTPProjectRemote`, `LocalPolicyConsentStore` 등)으로 바꾼다. 그 구체 타입은 `public`을 유지한다.

**근거**: 어댑터는 Composition에, 구현은 Data에 있어 패키지 경계를 넘는다. 경계를 넘는 것은 타입 자체이지 프로토콜이 아니다. Data가 구체 타입을 `public`으로 노출하면 Composition이 그대로 받을 수 있고, 프로토콜 한 겹이 사라진다. 아키텍처 3.1의 `Composition → Data` 허용 의존을 벗어나지 않는다.

**검토한 대안**:

- 구체 타입을 `struct`에서 `final class`로 바꾸기 — 수명·공유 의미를 바꿀 이유가 없다. 현행 선언 종류를 유지한다.
- 어댑터를 제네릭으로 만들기(`Adapter<Remote>`) — 타입 파라미터가 조립 코드에 전파돼 오히려 복잡해진다. 구현이 하나뿐이므로 얻는 것이 없다.
- 어댑터를 없애고 Data 타입이 Domain 계약을 직접 채택하기 — Domain↔Data 경계 구조를 바꾸는 일이라 이 명세의 전제 밖이다.

## 3. 어댑터 테스트가 무엇에 더블을 주입하는가

**결정**: 어댑터 테스트는 Data 구체 Remote를 실제로 만들고, 그 아래 `HTTPTransport`에 스텁을 주입한다. `LocalPolicyConsentStore`처럼 전송이 아닌 저장 기반 타입은 그 타입이 받는 `UserDefaultsStore`에 격리된 suite를 주입한다.

**근거**: Data 테스트가 이미 `StubHTTPTransport`로 Remote 동작을 검증하고 있다. 어댑터 테스트도 같은 경계에 더블을 주입하면 계약 프로토콜 없이 같은 범위를 덮을 수 있고, DTO 디코딩까지 함께 지나므로 검증 범위가 오히려 넓어진다.

**검토한 대안**:

- 어댑터 테스트만 유지하고 스텁을 구체 타입 상속으로 만들기 — `struct` 기반 Remote에는 상속이 없고, `class`로 바꾸는 것은 대안 2에서 배제했다.
- 어댑터 테스트를 지우고 Data 구현 테스트에만 의존하기 — 어댑터의 DTO→Domain 변환과 오류 재매핑은 Data 테스트가 덮지 않는다. 검증 항목이 줄어 FR-005를 위반한다.

## 4. 계약 테스트의 보장 항목을 어디로 옮기는가

**결정**: `Data/Tests/**/Contracts/*ContractTests.swift`가 보장하던 항목을 같은 모듈의 `HTTP*RemoteTests`로 옮긴다. 대응하는 구현 테스트가 없으면 먼저 만들고 나서 계약 테스트를 지운다. 계약 하나마다 대조표 한 줄을 남긴다.

**근거**: 계약 테스트는 "프로토콜을 채택한 probe가 선언한 메서드를 갖는가"와 "호출이 기록되는가"를 주로 보장한다. 앞쪽은 프로토콜과 함께 사라지는 보장이고, 뒤쪽은 구현 테스트가 `StubHTTPTransport`의 요청 기록으로 더 강하게 보장한다. 대조표는 이 판단을 리뷰에서 재확인할 수 있게 한다.

**검토한 대안**:

- 계약 테스트를 그대로 두고 프로토콜만 지우기 — 컴파일되지 않는다.
- 대조표 없이 일괄 삭제 — 커버리지가 조용히 줄 수 있다. 근거 문서가 이 위험을 명시적으로 지목했다.

## 5. 오류 중복을 어디까지 정리하는가

**결정**: Data 오류에서 서버 응답 코드 구분에 쓰이지 않으면서 Domain 오류와 이름·의미가 같은 case만 대상으로 삼는다. 어댑터의 `switch`가 항등 매핑만 남기는 구간은 매핑 함수를 값 하나로 줄인다. Domain 오류 타입과 그 case 집합은 바꾸지 않는다.

**근거**: `DataLearningProjectError`는 `invalidRequest`·`unauthorized`·`temporarilyUnavailable`·`questionUnavailable`·`learningSetUnavailable`를 `LearningProjectError`와 같은 이름으로 갖는다. 반면 `transport`·`decoding`·`unexpectedStatus`는 Domain에서 모두 `unexpected`로 접히고, `projectUnavailable`은 `notFound`로 바뀐다. 전자는 분기를 줄일 수 있고 후자는 실제 변환이므로 남긴다.

**검토한 대안**:

- Data 오류 타입을 통째로 없애고 Domain 오류를 Data가 던지기 — Data가 Domain에 의존하게 돼 아키텍처 3.1의 의존 방향을 어긴다.
- Domain 오류 case를 Data에 맞춰 늘리기 — Domain이 전송 계층 어휘를 갖게 된다. FR-009를 위반한다.
- 서버 오류 코드 매핑까지 손보기 — 명세의 가정에서 불변으로 두었다.

## 6. 기준선을 어떻게 세고 어디에 기록하는가

**결정**: 프로덕션 Swift 파일 수는 `find sources/Projects -name "*.swift" -not -path "*/Tests/*"`, 프로덕션 프로토콜 수는 같은 목록에서 `^[[:space:]]*(public )?protocol ` 행 수로 센다. 적용 전후 값과 남은 프로토콜별 존치 근거를 `docs/conventions/abstraction/` 아래 기준선 문서에 기록한다.

**근거**: 세는 방법이 문서에 함께 있어야 다음 PR에서 같은 방식으로 재현할 수 있다. 수치만 남기면 비교가 불가능해진다.

**검토한 대안**:

- `specs/031-layer-overengineering/`에만 기록 — 명세 디렉터리는 이 작업의 기록이지 이후 PR이 참조하는 정본이 아니다.
- 자동 검사 스크립트를 추가 — 이 명세의 범위를 넘고, 기준 자체가 아직 한 번도 적용되지 않았다. 수치 기록이 먼저다.
