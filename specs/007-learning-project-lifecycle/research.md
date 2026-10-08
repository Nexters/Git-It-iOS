# 조사: 학습 프로젝트 생명주기 UseCase 구현

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

spec.md에 `[NEEDS CLARIFICATION]` 표식은 남아 있지 않다(checklists/requirements.md 검증
결과: 전체 통과). 이 문서는 계획 단계에서 실제로 필요했던 설계 결정을 기록한다 — 요구사항
자체의 모호성이 아니라, `docs/architecture.md`·`package-rules/*.md`·
`Git-It-server-scheme.json`을 대조하며 확정해야 했던 구현 경계와 표현 방식이다.

## 결정 1: 패키지 경계는 `DomainLearningProject`/`DataLearningProject` 단일 쌍으로 한다

- **결정**: `FetchExternalRepository`(GitHub)와 나머지 4개 UseCase(Git-It 서버)를 하나의
  Domain/Data 패키지 쌍에 함께 둔다.
- **근거**: spec.md는 이 5개를 "학습 프로젝트 생명주기"라는 단일 시나리오 그룹으로
  다루고, `ExternalRepository`는 `CreateLearningProject`의 입력 재료로 직접 연결된다
  (data-model.md 006 "관계" 절). `DomainAuthentication`/`DataAuthentication`도 서로
  다른 기술 공급자(Apple 인증, 서버 세션)를 하나의 패키지 쌍에서 다뤘던 전례와 일치한다.
- **검토한 대안**: `DomainExternalRepository`/`DataExternalRepository`를 별도 패키지로
  분리하는 안 — 두 외부 시스템(GitHub API, Git-It 서버)의 기술적 이질성을 더 명확히
  드러내지만, 현재 이 경계를 넘어 재사용할 다른 소비자가 없어 패키지를 나눌 근거
  (naming.md "패키지 밖에서 충돌하거나 오해할 실제 근거")가 부족하다. 후속 스펙에서
  `ExternalRepository` 확인이 다른 맥락(예: 다른 등록 흐름)에서 독립적으로 재사용되면
  그때 분리를 재검토한다.

## 결정 2: `UseCases/` 폴더를 Domain에 새로 도입한다

- **결정**: `DomainLearningProject`에 `Contracts/`, `Models/`와 병렬로 `UseCases/` 폴더를
  추가하고, 5개 UseCase를 `callAsFunction`을 가진 `struct`로 구현한다.
- **근거**: FR-023이 "단일 책임의 실행 가능한 타입(프로토콜 또는 구조체/클래스)"을
  명시적으로 요구한다. `DomainAuthentication`은 현재 `Contracts`(protocol)·`Models`만
  가지고 있어 `UseCases` 폴더 전례가 실제로 존재하지는 않지만, `architecture.md` §3.2
  "명시적 의존성 주입" 예시(`GetProfile`/`UpdateProfile`을 initializer로 주입해 호출)가
  이미 이 형태의 실행 가능한 타입을 전제하고 있다.
- **검토한 대안**: `AuthenticationRepository`처럼 하나의 넓은 Repository 프로토콜에
  메서드를 모두 얹는 안 — FR-023이 "단일 책임"을 명시했고, 5개 UseCase가 서로 다른 오류
  타입(`ExternalRepositoryError` vs `LearningProjectError`)과 소비 시점을 가지므로
  단일 Repository에 얹으면 책임이 흐려진다. 대신 Repository 계약은 결정 3처럼 외부
  시스템 단위로만 나눈다.

## 결정 3: Repository 계약은 외부 시스템 단위로 2개만 정의한다

- **결정**: `ExternalRepositoryLookup`(GitHub, 1개 메서드)과 `LearningProjectRepository`
  (Git-It 서버, 4개 메서드 — register/fetchProjects/fetchProjectDetail/deleteProject)로
  나눈다. UseCase 대 계약을 1:1로 만들지 않는다.
- **근거**: `LearningProjectRepository`의 4개 오퍼레이션은 모두 같은 서버 리소스
  (`/api/v1/projects`)와 같은 오류 타입(`LearningProjectError`)을 공유한다.
  `AuthenticationRepository`도 인증이라는 하나의 외부 능력을 여러 메서드로 노출한다.
- **검토한 대안**: UseCase마다 별도 Repository 프로토콜 — Test Double 작성이 늘어나고
  같은 서버 리소스에 대한 계약이 5개로 파편화되어 후속 Composition Adapter 구현 시
  일관성 유지가 어려워진다.

## 결정 4: URL 파싱과 오류 분류의 책임 경계

- **결정**: GitHub Repository URL에서 소유자·저장소 이름을 파싱하는 로직(FR-001)은
  `FetchExternalRepository` UseCase가 Domain 내부에서 순수 함수로 직접 수행한다. 파싱에
  실패하면 `ExternalRepositoryLookup`을 호출하지 않고 즉시 `ExternalRepositoryError
  .invalidURLFormat`을 던진다. `오프라인`/`그 밖의 오류`(FR-004 나머지 두 케이스)는
  `ExternalRepositoryLookup`의 production 구현(Composition, 범위 밖)이 실제 네트워크
  신호(`URLError` 등)를 분류해 이미 분류된 `ExternalRepositoryError`를 던지는 형태로
  계약한다 — Domain UseCase는 그 오류를 그대로 다시 던질(rethrow) 뿐 재해석하지 않는다.
- **근거**: URL 파싱은 외부 의존성이 없는 순수 로직이라 Domain 계약 테스트만으로 실제
  동작을 100% 검증할 수 있다(SC-002). 반면 오프라인 여부 판별은 플랫폼 네트워크 스택
  (`URLSession`/`URLError`) 접근이 필요해 `domain.md` 제약("네트워크...같은 구체 기술을
  계약 이름이나 타입에 노출해서는 안 된다", "Infrastructure의 기술 API를 참조해서는 안
  된다")과 충돌한다. Domain은 이미 분류된 결과(계약의 반환/오류 타입)만 다루고, 분류
  자체는 Composition Adapter 몫으로 남긴다(spec.md가 이미 Composition DI 배선을 범위
  밖으로 명시).
- **검토한 대안**: Domain이 `Reachability` 같은 프로토콜을 별도로 주입받아 오프라인
  여부를 직접 판정 — `domain.md` "네트워크...같은 구체 기술을 계약 이름이나 타입에
  노출해서는 안 된다" 제약을 위반할 위험이 크고, `Reachability` 자체가 이미 Infrastructure
  기술 개념이라 기각한다.

## 결정 5: Domain UseCase·계약 테스트는 Test Double로 오류 전 경로를 커버한다

- **결정**: `DomainLearningProjectTests`는 `ExternalRepositoryLookup`/
  `LearningProjectRepository`의 Fake 구현을 주입해 UseCase가 성공 값과 각 오류 케이스를
  그대로 전달하는지 검증한다. 실제 GitHub API·Git-It 서버를 호출하는 통합 테스트는 만들지
  않는다.
- **근거**: `architecture.md` §5 "Domain: Repository와 외부 기능은 Domain 계약을 구현한
  Test Double로 주입", `domain.md` "Domain 계약은 Test Double로 대체할 수 있는 형태로
  설계해야 한다"를 그대로 따른다. spec.md의 "계약 테스트로 독립 검증"(시나리오 1·2·3
  "독립 테스트" 절)도 이 방식과 일치한다.
- **검토한 대안**: 실제 네트워크를 호출하는 통합 테스트 — Composition Adapter가 아직
  없어 실행 자체가 불가능하고, 있더라도 spec.md가 Composition 배선을 범위 밖으로 명시해
  기각한다.

## 결정 6: FR-024 "Data의 DTO↔Domain 변환" 요구는 계약·DTO 소유로 한정 해석한다

- **결정**: `DataLearningProject`는 `ExternalRepositoryRemote`/`LearningProjectRemote`
  계약과 DTO(서버·GitHub 응답 1:1 대응)만 소유한다. 실제 HTTP 호출 수행과 DTO→Domain
  모델 변환은 이 계획에서 구현하지 않으며, 그 책임은 Composition의 Domain↔Data Adapter·
  Data↔Infrastructure Adapter(둘 다 범위 밖)로 넘어간다.
- **근거**: `architecture.md` §7.1은 `Data → Infrastructure`, `Data → Domain`을 명시적으로
  금지한다. `data.md` 제약조건도 "Domain 타입을 참조하거나 Domain 모델로 변환하는 API를
  제공해서는 안 된다", "Domain Repository를 구현해서는 안 된다", "Data↔Infrastructure
  Adapter를 Data 내부에 구현해서는 안 된다"를 명시한다. Constitution "적용" 절은 이
  문서가 하위 산출물(기능 명세 포함)보다 우선하며 충돌 시 하위 문서를 이 문서에 맞게
  수정하라고 규정한다. 따라서 FR-024는 이 계획 범위에서 "Data가 서버 API 호출 계약과
  DTO를 소유해 후속 Adapter가 그대로 위임·변환할 수 있게 한다"로 실행한다.
- **검토한 대안**: Data 패키지가 Infrastructure에 대한 예외적 의존을 선언 — 아키텍처
  문서의 명시적 금지 목록을 위반하며, 이를 바꾸려면 아키텍처 문서 개정이 필요하다(이
  계획의 허용 수정 경로 밖). 기각한다.

## 결정 7: `CreateLearningProject` 응답의 `quizLevel`은 요청 값을 보존해 구성한다

- **결정**: `LearningProjectRegistration.quizLevel`은 `RegisterProjectResponse`가 실제로
  돌려주는 필드가 아니라, `CreateLearningProject` UseCase가 호출 시 전달받은 `quizLevel`
  입력을 그대로 보존해 구성한다.
- **근거**: `Git-It-server-scheme.json`의 `RegisterProjectResponse` 스키마는 `projectId`·
  `status`만 정의하고 `quizLevel`을 포함하지 않는다(FR-006과 일치). spec.md FR-007은
  "서버가 반환한 기존 `projectId`·`quizLevel`·`status`를 그대로 반환"이라고 서술하지만,
  서버 계약 자체가 재등록 시 `quizLevel`을 변경하지 않음을 보장하므로(계약 문서
  "재등록·다중 사용자 규칙" 표 — "난이도도 바뀌지 않습니다") 클라이언트가 보낸 값을
  그대로 보존해 노출해도 관찰 가능한 동작은 spec.md 의도와 동일하다. `LearningProjectRegistration`
  값 자체의 출처(서버 echo vs 클라이언트 보존)는 이 계획이 정의하는 Domain 모델의 필드
  존재만 확정하며, 실제 조합 방식은 Composition Adapter(범위 밖)의 구현 세부사항이다.
- **검토한 대안**: `LearningProjectRegistration`에서 `quizLevel` 필드를 아예 제거 —
  FR-006·FR-007이 요구하는 값을 UseCase 반환 타입에서 드러내지 못해 기각한다.

## 결정 8: `LearningProject` 응답 형태별로 별도 Domain 모델을 둔다

- **결정**: 목록(`LearningProjectSummary`), 상세(`LearningProjectDetail`), 등록 응답
  (`LearningProjectRegistration`)을 하나의 `LearningProject` 구조체로 합치지 않고 세
  타입으로 분리한다. 상세의 세트 요약은 `LearningProjectSetProgress`로 별도 타입화한다.
- **근거**: 세 응답의 필드 구성이 실제로 다르다(data-model.md 006 표 — `quizLevel`·
  `status`는 등록 응답에만, `repositoryUrl`·`starCount`·`sets`는 상세에만,
  `currentSetLabel`·`nextSetId`는 목록에만 존재). Constitution 원칙 10과 naming.md §3
  "하나의 모델 이름으로 외부 계약, 저장 모델과 Domain 모델을 동시에 표현하지 않는다"를
  따른다. 세 타입 모두 옵셔널 필드 없이 정확한 계약을 표현할 수 있다.
- **검토한 대안**: 모든 필드를 옵셔널로 가진 단일 `LearningProject` — 어떤 조회에서 어떤
  필드가 채워지는지 타입만으로 알 수 없어 후속 개발자가 실수하기 쉽다(spec.md SC-004
  "패키지 구조를 예측할 수 있다"는 목표와 충돌). 기각한다.

## 결정 9: 다음에 풀 세트 계산(FR-019)은 `LearningProjectDetail`의 계산 프로퍼티로 둔다

- **결정**: `sets[]`에서 `completedCount < problemCount`인 첫 세트를 찾는 로직을
  `LearningProjectDetail.nextSet`(계산 프로퍼티)으로 Domain 모델에 둔다. UseCase는 이
  계산을 직접 수행하지 않고 모델이 노출한 값을 그대로 반환한다.
- **근거**: 이 계산은 외부 의존성이 없는 순수 로직이며, 상세 응답 자체의 불변 속성(FR-019
  "서버 상세 응답에는 nextSetId가 없으므로 이 계산은 클라이언트 책임")이므로 UseCase보다
  모델이 스스로 소유하는 편이 책임을 더 명확히 드러낸다.
- **검토한 대안**: `FetchLearningProjectDetail` UseCase 내부에 계산 로직을 두는 안 —
  동작은 동일하지만 계산이 응답 데이터 자체의 속성이 아니라 호출 시점의 부수 로직처럼
  보여 재사용성이 떨어진다. 기각한다.

## 결정 10: 테스트 프레임워크와 명명 관례는 기존 Authentication 패키지를 그대로 따른다

- **결정**: `DomainLearningProjectTests`/`DataLearningProjectTests`는 Swift Testing
  (`import Testing`, `@Suite("한국어 설명")`, `@Test`, 백틱 한국어 함수 이름, `#expect`)을
  사용한다. Domain·Data 계약과 UseCase는 Swift 표준 `throws`를 사용하고(`HTTPClient`가
  쓰는 타입 throws는 채택하지 않음), 오류 enum은 `CaseIterable, Equatable, Error,
  Sendable`을 채택한다.
- **근거**: `DomainAuthenticationTests`/`DataAuthenticationTests`가 이미 이 관례를
  쓰고 있고, spec.md가 명시적으로 이 두 패키지와 "동일한 레이어 경계"를 요구한다. 타입
  throws는 `InfrastructureNetworkClient`(`HTTPClient`)에서만 쓰이고 있어 Domain/Data
  계층 전례와는 다르다.
- **검토한 대안**: 타입 throws(`async throws(LearningProjectError)`) 채택 — 오류 타입을
  시그니처로 강제할 수 있어 이론적으로 더 안전하지만, 이 기능이 직접 참조 대상으로 지정한
  `DomainAuthentication`/`DataAuthentication` 전례와 달라 일관성이 떨어진다. 후속으로
  Domain/Data 계층 전체가 타입 throws로 전환되면 그때 함께 반영한다.
