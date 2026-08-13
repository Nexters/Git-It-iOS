# 001-apple-social-login 암묵지 기록

**대상 기능**: `001-apple-social-login`

**기록 원칙**: 복수 근거에서 해석한 지식을 상태와 범위와 함께 append-only로 보존한다.

## TK-20260813-001: 문맥과 수명에 따른 공개 이름의 자족성

**기록일**: 2026-08-13
**상태**: 후보
**확신도**: 높음
**적용 범위**: `001-apple-social-login`의 Domain·Data 공개 타입, 계약, 저장 모델과 경계를 넘는 값의 네이밍 검토
**관련 항목**: T067, T089-T160

### 해석

공개 이름은 공통 접두어·축약형의 표면적 통일보다 선언이 맡은 책임과 독립적으로 읽힐 때 필요한 문맥을 우선하며, 같은 개념도 저장되어 경계를 넘는 값에는 발급 주체와 수명을 드러내고 타입·메서드가 이미 문맥을 제공하는 매개변수에서는 중복 수식어를 생략한다.

### 근거

- `세션 019ff8c5-3533-72b2-8f9f-c2bf3ece1abf`: Data 모델 저장 프로퍼티를 메서드 매개변수와 같은 `subjectReference`로 맞추는 변경과, 명세·후속 Composition 작업에 결합된 대규모 공개 타입 rename을 보류하는 판단이 함께 관찰되었다.
- `specs/001-apple-social-login/reviews/authentication-naming.md:26-82`: 후속 검토에서는 Domain 공개 타입의 일괄 `Auth*` 축약보다 책임 구분을 우선했고, 저장 모델에는 `providerSubjectReference`를 사용하면서 메서드 매개변수의 `subjectReference`는 선언 문맥이 충분하다는 이유로 유지했다.
- `specs/001-apple-social-login/data-model.md:40-58`, `specs/001-apple-social-login/contracts/authentication-boundary.md:58-64`, 커밋 `ebf5f38`: 설계와 구현은 저장·전달되는 모델의 필드를 `providerSubjectReference`로 표현하지만 `ExternalAuthenticationProvider` 연산의 매개변수는 `subjectReference`로 표현해, 동일 개념의 이름을 수명과 선언 문맥에 따라 달리 적용한다.

### 적용과 제외

- 적용: Domain·Data·Composition 경계에서 공개 타입, 프로토콜, 저장 프로퍼티 또는 장기간 유지되는 값의 후보 이름을 비교할 때 책임 구분, 경계 밖에서의 해석 가능성, 값의 발급 주체와 수명을 함께 평가한다.
- 제외: Apple·서버 등 외부 계약이 이름을 고정한 경우, target·패키지 자체의 이름을 정하는 경우, 한 선언 안에서만 사용되어 문맥이 사라지지 않는 지역 변수, 또는 네이밍을 넘어 동작과 책임을 바꾸는 설계 변경에는 이 해석만으로 결론 내리지 않는다.

### 반례와 불확실성

실제 타입 충돌이나 오해 사례가 발생하면 현재보다 강한 수식어가 필요할 수 있고, 짧은 지역 문맥에서는 전체 용어가 오히려 중복일 수 있다. 현재 인증 네이밍 변경은 작업 트리에서 진행 중이므로 개별 최종 이름은 달라질 수 있으며, 이 해석을 다른 기능이나 프로젝트 전체의 규칙으로 일반화한 근거는 아직 없다.

### 검증 또는 승격 조건

현재 Domain·Data 네이밍이 관련 계약 테스트와 후속 Composition 구현에서 같은 책임 구분을 유지한 채 확정되고, 별도의 비인증 기능 네이밍 검토에서도 같은 판단 기준이 재현되면 상태를 재평가한다. 프로젝트 공통 규칙으로 승격하려면 아키텍처 또는 패키지 규칙을 담당하는 별도 변경에서 적용 범위와 예외를 명시한다.

### 연결

없음

## TK-20260813-002: 실제 책임을 기준으로 한 인증 이름의 최소 문맥

**기록일**: 2026-08-13
**상태**: 검증됨
**확신도**: 높음
**적용 범위**: `001-apple-social-login`의 Domain·Data·Composition 인증 계약, 저장 경계, 모델과 연산의 네이밍 검토
**관련 항목**: T022-T035, T051, T072, T089-T112

### 해석

인증 공개 이름은 선언이 실제로 수행하는 책임을 식별하는 데 필요한 최소 문맥만 남기며, 인증 정보의 저장·정리 경계에는 저장 값의 형태나 공급자 내부 용어인 `Authorization`, `Reference`, `Subject`를 덧붙이지 않고 실제 authorization 상태를 조회·관찰하는 계약에만 `Authorization`을 유지한다.

### 근거

- `2026-08-13 사용자 확인`: `AuthenticationAuthorizationStorage`의 책임을 먼저 분리한 뒤 최종 이름을 `AuthenticationStorage`로 지정하고, `Subject`를 제거하며 다른 이름에도 같은 기준을 적용하도록 확인했다.
- `sources/Projects/Domain/DomainAuthentication/Contracts/AuthenticationRepository.swift:1-5`, `sources/Projects/Domain/DomainAuthentication/Contracts/LoginSessionRepository.swift:1-5`, `sources/Projects/Domain/DomainAuthentication/Models/AuthorizationStatus.swift:1-5`: 현재 Domain 계약은 로컬 인증 정보 정리를 `clearAuthentication()`으로, Git It 로그인 세션 경계를 `LoginSessionRepository`로 표현하면서 실제 공급자 authorization 조회·변경에는 `AuthorizationStatus`와 `authorizationChanges()`를 유지한다.
- `sources/Projects/Data/DataAuthentication/Contracts/AuthenticationProvider.swift:1-10`, `sources/Projects/Data/DataAuthentication/Contracts/LoginSessionStorage.swift:1-5`, `sources/Projects/Data/DataAuthentication/Models/StoredLoginSession.swift:3-27`: 현재 Data 변경도 불필요한 `External`을 제거한 인증 제공자 이름과, 일반적인 `Session`에 로그인 문맥을 보강한 저장 계약·모델 이름을 함께 사용해 단순한 접두어 삭제가 아니라 책임별 최소 문맥을 반복 적용한다.

### 적용과 제외

- 적용: 프로젝트가 소유하는 인증 계약·저장소·모델·연산 이름을 검토할 때, 먼저 책임을 한 문장으로 기술하고 그 책임에 없는 저장 형식, 내부 식별자 용어와 중복 문맥을 제거한다.
- 제외: 외부 API·서버 schema가 고정한 이름, 보안 속성을 구분하는 데 필요한 용어, 실제 공급자 authorization 상태의 조회·관찰, 또는 이름 변경을 넘어 저장 수명과 동작 자체를 바꾸는 설계 결정에는 이 해석만으로 이름을 정하지 않는다.

### 반례와 불확실성

`AuthenticationStorage`와 `Subject` 제거는 사용자가 확인했지만 현재 Data 구현에는 아직 반영되지 않았고, 저장 모델과 식별자 필드의 정확한 최종 이름은 Data 패키지 승인·검증 과정에서 달라질 수 있다. 활성 기능의 계획·작업 문서도 이전 이름을 포함하므로 이 항목만으로 해당 산출물이나 후속 Composition 이름을 자동 변경해서는 안 된다.

### 검증 또는 승격 조건

Data와 후속 Composition 구현에서 같은 책임 기준으로 최종 이름을 적용하고 계약 테스트와 패키지 검증을 통과해야 개별 이름까지 검증된 것으로 본다. 계획·작업 문서의 규범으로 승격하려면 각각 `$speckit-plan`, `$speckit-tasks`로 명시적인 이름과 변경 경로를 동기화한다.

### 연결

`TK-20260813-001`의 책임 우선 해석은 계승하되, 저장 값에 `providerSubjectReference`를 유지한다는 구체 판단은 이번 사용자 결정으로 폐기한다.
