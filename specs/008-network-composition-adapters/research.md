# 조사: GitHub·Git-It 프로젝트 API Composition Adapter 구축

**날짜**: 2026-08-20 | **명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

spec.md에 `[NEEDS CLARIFICATION]` 표식은 없다(`/speckit-clarify` 세션 2026-08-20, 재시도·로깅 2건
해소). 이 문서는 계획 단계에서 실제로 필요했던 설계 결정을 기록한다.

## 결정 0: 007의 Domain·Data 패키지가 아직 구현되지 않은 상태에서 계획을 진행한다

- **결정**: `sources/Projects/Domain/DomainLearningProject/`·`sources/Projects/Data/DataLearningProject/`가
  저장소에 아직 존재하지 않음을 확인했다(`/speckit-implement`가 007에서 아직 실행되지 않음,
  007 tasks.md 전 항목 미완료). 이 계획은 007의 `data-model.md`·`contracts/`에 문서화된
  타입 이름·시그니처를 근거로 설계를 진행하되, `tasks.md`에는 007의 Domain·Data 패키지
  구현·검증·승인이 008의 Composition 작업보다 먼저 끝나야 한다는 선행 조건을 명시한다.
- **근거**: Constitution 원칙 7(패키지 단위 구현 진행)의 `Domain → Data → Infrastructure →
  Composition → ...` 순서에 따르면 Composition은 자신이 의존하는 Domain·Data 패키지가 이미
  구현된 뒤에만 실제로 구현할 수 있다. 계획 자체는 문서 조사만으로 가능하므로 지금 진행하되,
  구현 순서 위반을 방지하기 위해 선행 조건을 명시적으로 기록한다.
- **검토한 대안**: 007이 구현될 때까지 008의 계획 자체를 미룬다 — `/speckit-plan`은 소스
  코드를 직접 참조하지 않고 이미 확정된 `spec.md`/`data-model.md`/`contracts/` 문서만으로도
  설계를 완성할 수 있어 미루면 불필요한 지연이 생긴다. 기각한다.

## 결정 1: Composition은 GitHub·Git-It 서버 각각에 Domain↔Data Adapter 1개 + Data↔Infrastructure Adapter 1개, 총 4개 Adapter 타입으로 구성한다

- **결정**: `ExternalRepositoryLookupAdapter`(Domain↔Data, `ExternalRepositoryLookup` 구현)
  · `ExternalRepositoryRemoteAdapter`(Data↔Infrastructure, `ExternalRepositoryRemote` 구현)
  · `LearningProjectRepositoryAdapter`(Domain↔Data, `LearningProjectRepository` 구현)
  · `LearningProjectRemoteAdapter`(Data↔Infrastructure, `LearningProjectRemote` 구현)로 나눈다.
- **근거**: `sources/docs/package-rules/composition.md`가 "Data 모델·DTO·오류와 Domain
  모델·오류 사이의 변환은 Domain↔Data Adapter가", "Data 계약의 요청·응답과 Infrastructure
  API 사이의 변환은 Data↔Infrastructure Adapter가" 담당해야 한다고 명시적으로 분리한다.
  하나의 Adapter에 두 책임을 합치면 이 정책을 위반한다.
- **검토한 대안**: 시스템(GitHub/Git-It)마다 단일 Adapter로 합쳐 4개 대신 2개만 만드는 안 —
  package-rules/composition.md의 명시적 책임 분리 정책과 직접 충돌해 기각한다.

## 결정 2: 액세스 토큰 공급 지점은 새 프로토콜을 만들지 않고 `DataAuthentication`의 기존 `LoginSessionStorage`를 재사용한다

- **결정**: `LearningProjectRemoteAdapter`는 매 요청 전 `LoginSessionStorage.load()`를 호출해
  `StoredLoginSession.accessToken`을 `Authorization: Bearer` 헤더로 첨부한다. 이 기능은 새
  토큰 공급 프로토콜을 정의하지 않는다.
- **근거**: `DataAuthentication`(001, 이미 병합됨)이 이미 `LoginSessionStorage: Sendable { func
  load() async throws -> StoredLoginSession? }`를 정의했고 `StoredLoginSession.accessToken`을
  담고 있어, spec.md 가정 절이 요구하는 "호출 시점에 유효한 액세스 토큰을 얻을 수 있는
  지점"과 정확히 일치한다. 새 프로토콜을 만들면 같은 책임(현재 세션의 액세스 토큰 조회)을
  중복 정의하게 되어 `naming.md`의 "표면적인 통일만을 위한" 중복 회피 원칙과 어긋난다.
- **주의**: `LoginSessionStorage`의 프로덕션 구현(Keychain-backed Data↔Infrastructure
  Adapter)은 spec.md가 범위 밖으로 명시한 "로그인·세션 Composition Adapter" 작업의 일부다.
  이 기능은 `LoginSessionStorage`를 소비만 하며 구현하지 않는다 — 테스트는 Fake
  `LoginSessionStorage`로 대체한다. 프로덕션에서 실제로 토큰을 반환하는 구현이 없으면
  `load()`가 `nil`을 반환하거나 아직 정의되지 않아, Git-It 서버 Adapter는 토큰 없이 요청을
  보내 서버의 401을 그대로 받는다(spec.md 예외·경계 사례, 수용 시나리오 2-6과 일치).
- **검토한 대안**: 이 기능이 직접 `AccessTokenProviding` 같은 새 프로토콜을 정의 —
  `LoginSessionStorage`가 이미 같은 책임을 지므로 불필요한 중복이라 기각한다.

## 결정 3: base URL은 Adapter 생성자 파라미터로 주입받으며, 실제 프로덕션 값 결정은 이 계획의 범위 밖이다

- **결정**: `ExternalRepositoryRemoteAdapter`/`LearningProjectRemoteAdapter`는 각각 `HTTPClient`
  인스턴스를 생성자로 주입받는다(Adapter 자신이 `HTTPClient`를 생성하지 않는다). GitHub의
  base URL(`https://api.github.com`)은 고정값으로 다루되, Git-It 서버의 실제 프로덕션 base
  URL 값은 이 계획이 결정하지 않는다.
- **근거**: `Git-It-server-scheme.json`의 `servers` 필드는 생성기 자리표시자
  (`https://example.com`)만 담고 있어 실제 프로덕션 URL을 이 저장소 문서에서 확인할 수
  없다. `sources/Projects/Config/*.xcconfig`에도 API base URL 항목이 없어 기존 환경별 구성
  전례가 없다. `HTTPClient`를 외부에서 주입받는 구조로 만들면 실제 URL 값 결정(환경별 구성
  전략)을 App 조립 시점으로 미루면서도 Adapter 자체는 지금 완성해 테스트할 수 있다.
- **검토한 대안**: Adapter 내부에 프로덕션 URL을 하드코딩 — 실제 값을 모르는 상태에서
  추측한 URL을 하드코딩하면 잘못된 값을 프로덕션으로 오인할 위험이 있어 기각한다.

## 결정 4: Domain↔Data Adapter와 Data↔Infrastructure Adapter의 오류 매핑 경계

- **결정**: `HTTPClientError`와 HTTP 상태 코드 → `DataExternalRepositoryError`/
  `DataLearningProjectError`(007이 이미 정의) 매핑은 Data↔Infrastructure Adapter가 수행한다.
  `DataExternalRepositoryError`/`DataLearningProjectError` → `ExternalRepositoryError`/
  `LearningProjectError`(007이 이미 정의) 매핑은 Domain↔Data Adapter가 수행한다.
- **근거**: 007이 이미 두 계층의 오류 타입을 1:1 대응하도록 설계해뒀다(007 data-model.md
  §1·§2 오류 케이스 표). 이 기능은 007이 정의한 타입을 재정의하지 않고 그 사이를 잇는
  변환 코드만 추가한다.
- **검토한 대안**: Data↔Infrastructure Adapter가 곧바로 Domain 오류를 던지게 해 한 단계로
  줄이는 안 — 결정 1의 책임 분리(Data 계층은 Domain 타입을 참조하지 않는다,
  `sources/docs/package-rules/data.md`)를 Adapter 내부에서 위반하게 되어 기각한다.

## 결정 5: `HTTPClientError`의 typed throws를 표준 `throws`로 브리지하는 지점

- **결정**: `HTTPClient.send(...)`는 `async throws(HTTPClientError)`(typed throws)를 쓴다.
  Data↔Infrastructure Adapter가 이 값을 받아 표준 `throws`인 `ExternalRepositoryRemote`/
  `LearningProjectRemote` 프로토콜 시그니처에 맞게 즉시 변환한다 — 이 경계를 넘어 typed
  throws를 전파하지 않는다.
- **근거**: 007 research.md 결정 10이 "Domain·Data 계약과 UseCase는 Swift 표준 throws를
  사용하고(HTTPClient가 쓰는 타입 throws는 채택하지 않음)"라고 이미 확정했다. 이 계획은 그
  경계를 그대로 따른다.
- **검토한 대안**: 없음 — 007이 이미 결정한 사항을 그대로 계승한다.

## 결정 6: 폴더 배치 — Composition 단일 타깃 내부에 `LearningProjectLifecycle/` 하위 폴더를 새로 도입한다

- **결정**: `sources/Projects/Composition/Composition/LearningProjectLifecycle/`에 4개
  Adapter를 배치하고, `sources/Projects/Composition/CompositionTests/LearningProjectLifecycle/`에
  대응 테스트를 배치한다.
- **근거**: `Composition`은 Domain/Data와 달리 기능별 Tuist target이 아니라 앱 전체가
  공유하는 단일 target이다(`CompositionModuleName.swift` 확인 — `Composition`/
  `CompositionTests` 2개 케이스만 존재). 지금까지 `Placeholder.swift` 외 실제 구현이 없어
  참고할 하위 폴더 전례가 없으므로, 이 기능이 007의 기능 이름을 그대로 딴 하위 폴더 전례를
  새로 만든다. 후속 기능(인증 Composition Adapter 등)도 같은 방식으로 자신의 폴더를 추가할
  수 있다.
- **검토한 대안**: `Composition/Composition/` 바로 아래 4개 파일을 평평하게 배치 — 후속
  기능이 추가될수록 평평한 구조가 어떤 파일이 어떤 외부 시스템에 대응하는지 구분하기
  어려워져 기각한다.

## 결정 7: `Composition` Tuist target에 `DomainLearningProject`·`DataLearningProject`·
`InfrastructureNetworkClient` 의존성을 추가한다

- **결정**: `CompositionModuleName.swift`의 `.Composition`/`.CompositionTests` 케이스에
  `.fromDomain(.DomainLearningProject)`, `.fromData(.DataLearningProject)`,
  `.fromInfrastructure(.InfrastructureNetworkClient)`를 기존 Authentication 의존성 옆에
  추가한다.
- **근거**: 현재 `Composition`은 `DomainAuthentication`/`DataAuthentication`/
  `InfrastructureAuthentication`만 의존성으로 선언하고 있어(확인됨), 이 기능이 참조할
  `DomainLearningProject`·`DataLearningProject`·`HTTPClient`(`InfrastructureNetworkClient`)를
  빌드할 수 없다. `architecture.md` §3.1 표는 Composition이 Domain·Data·Infrastructure
  모두에 의존할 수 있다고 허용한다.
- **검토한 대안**: 없음 — Tuist 의존성 선언 없이는 빌드 자체가 불가능하다.
