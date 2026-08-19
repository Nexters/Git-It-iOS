# 008-network-composition-adapters 암묵지 기록

**대상 기능**: `008-network-composition-adapters`

**기록 원칙**: 복수 근거에서 해석한 지식을 상태와 범위와 함께 append-only로 보존한다.

## TK-20260820-001: Composition Adapter의 실제 프로덕션 구현은 이 저장소에서 매번 후속 작업으로 미뤄진다

**기록일**: 2026-08-20
**상태**: 후보
**확신도**: 높음
**적용 범위**: Composition 패키지에 실제 프로덕션 Adapter(Domain↔Data, Data↔Infrastructure)를 추가하는 모든 향후 스펙
**관련 항목**: 없음

### 해석

이 저장소에서 "Composition Adapter의 실제 구현"은 Domain·Data 계약 정의와 분리된, 별도로
명시적 승인을 받아야 하는 독립적인 작업 단계로 취급되는 것이 반복된 관례다 — 지금까지의
모든 스펙이 계약만 정의하고 실제 Adapter 구현은 예외 없이 후속 스펙으로 미뤘다.

### 근거

- `specs/001-apple-social-login/plan.md:82`: "실제 서버 미확정 | HTTP 형식 대신 공급자
  중립 `SessionRemote`와 분리된 인증·세션 Mock을 정의한다. 실제 endpoint Adapter는 같은
  계약을 구현하는 후속 작업으로 제한한다."
- `specs/003-http-client/plan.md:194`: "Composition | 제외 | Data↔Core Adapter 구현은
  명세 범위 제외("실제 서버 연동을 위한 경계 변환 구현과 그 배치")"
- `specs/007-learning-project-lifecycle/research.md` 결정 6: Data 패키지가 계약·DTO만
  소유하고 "실제 HTTP 호출 수행과 DTO→Domain 모델 변환은... Composition의 Domain↔Data
  Adapter·Data↔Infrastructure Adapter(둘 다 범위 밖)로 넘어간다"고 명시.
- 코드 상태 교차 확인(2026-08-20 세션에서 직접 확인): `sources/Projects/Composition/Composition/`에
  `Placeholder.swift` 외 실제 구현 파일이 없고, 저장소 전체에서 `HTTPClient(`를 프로덕션
  코드로 생성하는 지점이 0건이었다 — 001·003·007 세 스펙이 각각 독립적으로 문서화한
  "후속으로 미룸" 의도가 실제 코드 상태와 정확히 일치했다.

### 적용과 제외

- 적용: Composition 패키지에 실제 프로덕션 Adapter를 추가하려는 모든 향후 스펙을 계획할
  때, "이 저장소는 계약과 실제 구현을 분리된 승인 단계로 다룬다"는 전제를 기본값으로
  삼는다.
- 제외: Domain·Data 계약 자체의 설계(계약 시그니처, DTO, 오류 타입 정의)에는 적용하지
  않는다 — 그 부분은 매 스펙이 실제로 완료해왔다.

### 반례와 불확실성

지금까지 관찰된 3개 스펙(001, 003, 007) 모두 같은 패턴을 보였지만, 이는 스펙 작성자들이
독립적으로 같은 판단을 내린 결과일 수도 있고, `architecture.md`의 패키지 의존성 순서
원칙(원칙 7)이 강하게 유도한 결과일 수도 있다 — 후자라면 이는 암묵적 관례가 아니라
Constitution이 이미 명시한 규칙의 자연스러운 귀결에 더 가깝다. 008이 이 패턴을 처음으로
깨는 스펙이므로, 008 완료 후에도 후속 스펙들이 계속 이 패턴을 따르는지 재확인이 필요하다.

### 검증 또는 승격 조건

008이 실제로 구현되어 Composition에 처음으로 프로덕션 Adapter가 생긴 뒤, 그다음 스펙
(예: 인증 Composition Adapter)이 이 전례를 실제로 참조하는지 확인되면 `검증됨`으로
승격할 수 있다.

### 연결

없음

---

## TK-20260820-002: 새 Composition 관심사는 기존 Data 계약이 같은 책임을 충족하면 새 프로토콜을 만들지 않고 재사용한다

**기록일**: 2026-08-20
**상태**: 후보
**확신도**: 중간
**적용 범위**: Composition Adapter가 다른 패키지의 기존 Data·Domain 계약으로 충족 가능한
책임을 새로 필요로 할 때
**관련 항목**: 없음

### 해석

Composition Adapter를 설계할 때 필요한 책임(예: "호출 시점의 유효한 액세스 토큰 조회")이
이미 다른 패키지의 기존 계약으로 정확히 충족된다면, 표면적 편의를 위해 새 프로토콜을
정의하지 않고 기존 계약을 그대로 소비하는 것이 이 저장소에 맞는 판단 기준이다.

### 근거

- `sources/Projects/Data/DataAuthentication/Contracts/LoginSessionStorage.swift`(001에서
  이미 병합): `func load() async throws -> StoredLoginSession?`이 `StoredLoginSession
  .accessToken`을 담고 있어, 008이 필요로 한 "호출 시점 유효 액세스 토큰 조회" 책임과
  정확히 일치함을 확인했다.
- `sources/docs/naming.md:167`: "대규모 공개 API rename은 이름이 더 짧거나 통일돼 보인다는
  이유만으로 수행하지 않습니다... 책임 불일치가 근거로 확인된 범위만 변경합니다" — 반대
  방향(새 이름을 만들지 않고 기존 것을 재사용하는 판단)에도 같은 "책임 일치 여부가
  근거"라는 기준을 적용할 수 있다고 해석했다.

### 적용과 제외

- 적용: 새로 필요한 책임이 기존 계약의 책임과 이름·시그니처 수준에서 실질적으로 같을 때
  (예: "현재 세션의 액세스 토큰을 읽는다").
- 제외: 책임이 실제로 다르거나(예: GitHub 인증 흐름과 Git-It 세션은 다른 외부 시스템),
  기존 계약을 재사용하려면 계층 경계(Domain↔Data, Data↔Infrastructure 구분)를 위반해야
  하는 경우는 이 판단 기준을 적용하지 않는다.

### 반례와 불확실성

이 판단은 008 단일 세션에서 처음 내려졌다. "기존 계약 재사용 우선"이 이 저장소에 별도로
명문화된 원칙은 아니며, `naming.md:167`은 원래 rename 맥락(기존 이름 변경 자제)을
다루는 문장이라 재사용 판단에 그대로 적용하는 것은 유추다. 향후 다른 세션이 비슷한
상황에서 새 프로토콜을 만드는 쪽을 택한다면 이 해석과 충돌할 수 있다.

### 검증 또는 승격 조건

008이 실제로 구현되어 `LoginSessionStorage` 재사용이 실제 코드에서 문제 없이 동작함이
확인되거나, 이후 다른 세션이 같은 상황에서 동일한 재사용 판단을 독립적으로 내리면
`검증됨`으로 승격할 수 있다.

### 연결

없음
