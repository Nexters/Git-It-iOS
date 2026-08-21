# 기능 명세: Feature → Domain UseCase 의존과 App 소유 의존성 주입

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/feature-usecase-app-di`

**생성일**: 2026-08-21

**상태**: 초안

**입력**: 사용자 설명: "private/architecture-refactor.md 문서를 입력으로 사용한다. 기능: Feature는 Domain 패키지에 정의된 UseCase Protocol에만 의존하고, production 의존성 주입은 App 패키지가 수행한다(D-ARCH-003). Composition은 Infrastructure·Data·Domain↔Data Adapter·Domain UseCase 구현을 생성해 App에 Domain Protocol 타입으로 제공하며, Feature·Store·View를 생성하지 않는다. FeatureTests는 Domain UseCase Protocol의 local Test Double만 사용한다. 상위 문서는 ARCH-DI-001."

## 명확화

### 세션 2026-08-21

- 질문: 이 기능의 Feature 구현 범위 → 답변: Feature production 소스 구현은 제외한다.
- 질문: Data 패키지의 이번 범위 → 답변: Data에 Infrastructure 기반 concrete Remote 구현과 target 의존성을 추가한다 (이 명세 범위에 포함).
- 질문: 경계 규칙 검사(자동 검증)의 구현 수단 → 답변: 자동 검사 신설은 범위에서 제외한다. 규칙 준수는 코드 리뷰와 기존 빌드·테스트로 확인한다.
- 질문: Composition이 조립할 기능 범위 → 답변: Domain 계약이 있는 `Authentication`, `LearningProject`, `ExternalRepository` 전부.
- 질문: App 패키지의 이번 범위 → 답변: App 변경을 이번 범위에서 제외한다. App 관련 요구는 후속 규범으로 남긴다.
- 질문: Infrastructure 패키지의 이번 범위 → 답변: Infrastructure를 명시적 변경 대상 패키지로 포함해 필요한 기술 API를 선제 보완한다.
- 질문: `docs/architecture.md` 의존성 표 개정(`Data → Infrastructure` 허용)의 처리 방식 → 답변: 이 명세의 명시적 요구사항으로 포함하고, 표 개정을 Domain 단계보다 먼저 수행하는 선행 작업으로 배치한다.
- 질문: 네이밍 규약 위반 rename의 처리 방식 → 답변: rename 3건(표준 약어 표기, `CompositionAdepter` 철자, `ObserveAuthorizationChanges` 이름)을 모두 이 명세 범위에 포함한다.
- 질문: `ObserveAuthorizationChanges`의 새 이름 → 답변: `ObserveAuthenticationOutcomes` / `ObserveAuthenticationOutcomesUseCase`.

## 변경 시나리오와 테스트 *(필수)*

<!--
  이 기능의 변경 대상 패키지는 Domain, Data, Infrastructure, Composition이다. Feature와 App은
  변경하지 않는다. 산출물은 Domain UseCase 계약의 완비, Data의 실행 가능한 구현, Composition의
  live 실행 그래프, 그리고 이후 Feature·App 구현이 따라야 할 경계 규칙의 문서화다.
-->

### 시나리오 1 - Domain이 UseCase 계약을 완비한다 (우선순위: P1)

Domain 개발자는 Feature가 호출하게 될 모든 비즈니스 작업을 Domain이 소유한 UseCase Protocol로 노출하고, 기존 concrete UseCase가 그 Protocol을 구현하도록 정리한다.

**주요 행위자**: Domain 개발자

**우선순위 이유**: Protocol 계약이 없으면 Composition이 노출할 타입도, 이후 Feature가 의존할 대상도 정의되지 않아 나머지 모든 단계가 성립하지 않는다.

**독립 테스트**: Domain target의 UseCase 선언을 검토해 Protocol 존재와 conformance를 확인하고, Protocol 시그니처에 Domain 외부 타입이 없는지 확인한다.

**수용 시나리오**:

1. **전제** `Authentication`의 `SignIn`, `SignOut`, `RestoreSession`, `ObserveAuthorizationChanges`에 대응 Protocol이 없다(마지막 항목은 `ObserveAuthenticationOutcomes`로 rename), **실행** UseCase 계약을 정비한다, **결과** 각 concrete UseCase가 대응 Protocol을 구현한다.
2. **전제** `LearningProject`와 `ExternalRepository`의 UseCase를 검토한다, **실행** Protocol과 구현의 대응을 확인한다, **결과** Protocol 없이 노출된 UseCase가 0건이다.
3. **전제** UseCase Protocol을 검토한다, **실행** 입력·출력·오류 타입을 확인한다, **결과** DTO, HTTP 타입, Infrastructure 타입, 외부 SDK 타입이 0건이다.
4. **전제** UseCase가 실패할 수 있다, **실행** 오류 경로를 확인한다, **결과** 호출자에게 전달되는 오류가 Domain 오류로 정규화돼 있다.

---

### 시나리오 2 - Data가 Infrastructure 기반 실행 구현을 제공한다 (우선순위: P1)

Data 개발자는 Data가 소유한 Remote Protocol의 concrete 구현을 Infrastructure의 기술 API 위에 만들고, Data target에 Infrastructure 의존성을 명시한다.

**주요 행위자**: Data 개발자

**우선순위 이유**: 현재 Data에는 Protocol, DTO, Endpoint만 있고 실행 구현이 없다. 구현이 없으면 Composition이 조립할 재료 자체가 존재하지 않는다.

**독립 테스트**: Data target의 의존성 선언을 확인하고, concrete 구현을 Infrastructure 대역과 함께 실행해 요청 구성·응답 변환·오류 변환을 검증한다.

**수용 시나리오**:

1. **전제** `ProjectRemote`, `AuthenticationRemote`, `ExternalRepositoryRemote` 등 Data Protocol이 존재한다, **실행** Infrastructure 기반 구현을 추가한다, **결과** 각 Protocol에 실행 가능한 구현이 존재한다.
2. **전제** Data가 Infrastructure의 기술 API를 사용한다, **실행** Tuist 의존성 선언을 확인한다, **결과** 필요한 Infrastructure target이 명시적으로 선언돼 있다.
3. **전제** 외부 호출이 실패한다, **실행** 오류 경로를 실행한다, **결과** 기술 오류가 Data가 소유한 오류 타입으로 변환된다.
4. **전제** Data 소스를 검토한다, **실행** 의존 방향을 확인한다, **결과** Data가 Domain, Composition, Feature, App, UI를 의존하지 않는다.

---

### 시나리오 3 - Infrastructure가 Data에 필요한 기술 API를 제공한다 (우선순위: P1)

Infrastructure 개발자는 Data 구현이 요구하는 네트워크·보안 저장소·캐시 기술 API를 확인하고 부족한 부분을 보완한다.

**주요 행위자**: Infrastructure 개발자

**우선순위 이유**: Data 구현이 시작된 뒤 기술 API 부족이 드러나면 Data 단계가 중단되고 패키지 순서가 무너진다.

**독립 테스트**: Data 구현이 요구하는 기술 API 목록과 Infrastructure 공개 API를 대조하고, 보완한 API를 Infrastructure 테스트로 검증한다.

**수용 시나리오**:

1. **전제** Data 구현에 필요한 기술 API를 식별한다, **실행** Infrastructure 공개 API와 대조한다, **결과** 부족한 API가 목록으로 확정된다.
2. **전제** 부족한 기술 API가 있다, **실행** 최소 범위로 보완한다, **결과** 보완한 API에 대응하는 Infrastructure 테스트가 통과한다.
3. **전제** Infrastructure 소스를 검토한다, **실행** import를 확인한다, **결과** Data, Domain, Composition, Feature, App, UI import가 0건이다.

---

### 시나리오 4 - Composition이 live 실행 그래프를 조립한다 (우선순위: P1)

Composition은 Infrastructure 객체, Data 구현, Domain↔Data Adapter와 Domain UseCase 구현을 생성해 Domain Protocol 타입으로만 노출한다.

**주요 행위자**: App 개발자, 코드 리뷰어

**우선순위 이유**: 현재 `Composition` target은 placeholder이며 Domain·Data·Infrastructure 의존성조차 선언돼 있지 않다. 실행 그래프가 없으면 이후 App이 주입할 대상이 존재하지 않는다.

**독립 테스트**: Composition의 live 그래프 생성을 테스트로 실행하고, 공개 API 타입 목록과 Feature·Store·View 생성 코드 유무를 검토한다.

**수용 시나리오**:

1. **전제** production 설정이 주어진다, **실행** `Authentication`, `LearningProject`, `ExternalRepository`의 live 그래프를 생성한다, **결과** 생성이 성공하고 노출 property가 모두 Domain UseCase Protocol 타입이다.
2. **전제** Domain Repository Protocol과 Data Remote Protocol이 서로 다른 모델을 사용한다, **실행** Composition의 Adapter를 실행한다, **결과** Data 오류와 DTO가 Domain 오류와 Domain 모델로 변환된다.
3. **전제** Composition 소스를 검토한다, **실행** Feature·Store·SwiftUI View 생성 코드를 찾는다, **결과** 해당 코드가 0건이다.
4. **전제** 내부 Adapter와 Infrastructure 객체가 존재한다, **실행** Composition의 공개 API를 확인한다, **결과** 내부 구현 타입이 공개 API에 노출되지 않는다.
5. **전제** 공유 수명이 필요한 Repository·세션 객체가 있다, **실행** 그래프를 생성한다, **결과** 해당 객체가 중복 생성되지 않는다.

---

### 시나리오 5 - 아키텍처 문서가 새 의존 규칙과 경계를 확정한다 (우선순위: P1, 선행)

문서 담당자는 구현에 착수하기 전에 아키텍처 문서의 패키지 의존성 표를 `D-ARCH-003`에 맞게 개정하고, 이후 Feature·App 구현이 따라야 할 경계 규칙을 함께 남긴다.

**주요 행위자**: 아키텍처 문서 담당자, 후속 Feature·App 개발자, 코드 리뷰어

**우선순위 이유**: 현행 아키텍처 문서는 `Data → Infrastructure`를 금지하는데 이 명세는 그 의존을 요구한다. Constitution 원칙 7은 의존성 표와 계획된 구현 순서가 어긋나면 구현을 시작하지 못하게 하므로, 이 작업은 다른 모든 패키지 작업의 선행 조건이다. 또한 Feature·App 구현이 범위 밖이고 자동 검사도 신설하지 않으므로, 규범이 문서로 남지 않으면 후속 구현에서 경계가 즉시 무너진다.

**독립 테스트**: 개정한 의존성 표와 금지 목록을 이 명세의 요구사항과 대조하고, 결정 기록에 `D-ARCH-003`이 존재하는지 확인한다.

**수용 시나리오**:

1. **전제** 아키텍처 문서가 `Data → Infrastructure`를 금지하고 Data의 허용 의존성을 비워 두고 있다, **실행** 의존성 표와 금지 목록을 개정한다, **결과** Data의 허용 의존성에 Infrastructure가 포함되고 금지 목록에서 해당 항목이 제거된다.
2. **전제** 의존성 표 개정이 끝나지 않았다, **실행** 패키지 구현 착수 여부를 판단한다, **결과** 어떤 패키지 구현 작업도 시작되지 않는다.
3. **전제** `D-ARCH-003` 결정이 필요하다, **실행** 결정 기록을 확인한다, **결과** Feature 의존 대상, Composition 책임, App 주입 위치, FeatureTests 정책이 기록돼 있다.
4. **전제** 아키텍처 문서를 검토한다, **실행** 패키지 책임과 의존 방향 설명을 확인한다, **결과** 이 명세와 모순되는 서술이 0건이다.
5. **전제** 후속 개발자가 Feature를 추가한다, **실행** 문서의 규칙을 따른다, **결과** 추가 결정 없이 initializer 주입과 Test Double 소유 방식을 확정할 수 있다.

---

### 시나리오 6 - 네이밍 규약 위반을 해소한다 (우선순위: P2)

개발자는 `docs/conventions/naming.md`가 정한 표준 약어 표기와 책임 기반 이름 규칙을 위반하는 기존 공개 이름을 규칙에 맞게 바꾼다. 동작, 상태 수명, 책임, 의존 방향과 외부 계약은 바꾸지 않는다.

**주요 행위자**: Domain 개발자, 코드 리뷰어

**우선순위 이유**: 이 기능이 Domain UseCase 계약을 정본으로 확정하고 Composition Adapter를 새로 만드는 시점이다. 지금 바로잡지 않으면 규칙 위반 이름이 새 계약과 Adapter에 그대로 고정되고, Data(준수)와 Domain(위반) 사이에 표기가 뒤집히는 변환 지점이 남는다.

**독립 테스트**: rename 전후로 Domain 테스트와 전체 빌드를 실행해 동작이 동일한지 확인하고, 변경한 식별자를 규칙과 대조한다.

**수용 시나리오**:

1. **전제** `DomainLearningProject`가 `projectId`, `githubRepoUrl`, `nextSetId`, `nextQuestionId`, `setId`를 사용한다, **실행** 표준 약어 표기 규칙에 맞게 rename한다, **결과** 해당 식별자가 `projectID`, `githubRepoURL`, `nextSetID`, `nextQuestionID`, `setID`가 되고 Domain 테스트가 통과한다.
2. **전제** `ObserveAuthorizationChanges`의 이름이 반환 타입 `AsyncStream<AuthenticationOutcome>`과 어긋난다, **실행** `ObserveAuthenticationOutcomes`로 rename한다, **결과** 구현 본문과 동작이 변하지 않고 기존 테스트가 통과한다.
3. **전제** Tuist target 이름 `CompositionAdepter`에 철자 오류가 있다, **실행** `CompositionAdapter`로 rename한다, **결과** manifest, source 폴더, 테스트 target과 App 의존성 선언이 함께 갱신되고 `tuist generate`와 빌드가 성공한다.
4. **전제** rename을 수행한다, **실행** 변경 내용을 검토한다, **결과** 연산 집합, 상태, 저장 위치, 값의 수명, 비동기·오류·취소 동작, 패키지 책임, 의존 방향, 외부 API·schema mapping이 모두 그대로다.
5. **전제** Data는 이미 규칙을 지킨다, **실행** rename 후 Adapter를 구현한다, **결과** Domain과 Data 사이에 표기를 뒤집는 변환이 필요하지 않다.

---

### 예외·경계 사례

- rename은 순수 rename으로 유지한다. 이름과 그 참조, 테스트 이름과 관련 문서만 바꾸고 연산 집합, 상태, 값의 수명, 비동기·오류·취소 동작, 패키지 책임, 의존 방향, 외부 API mapping을 함께 바꾸지 않는다.
- Data DTO의 `CodingKeys`가 보존하는 서버 원문 키(`"githubRepoUrl"`, `"repositoryUrl"`, `"nextQuestionId"` 등)와 테스트의 JSON fixture 문자열은 외부 고정 명칭이므로 rename 대상이 아니다.
- `DomainAuthentication`, `Domain`의 `ExternalRepository`, Data, Infrastructure는 이미 표준 약어 규칙을 지키므로 rename 대상이 아니다.
- 아키텍처 문서의 패키지 의존성 표 개정은 다른 모든 패키지 작업의 선행 조건이다. 표와 계획된 구현 순서가 어긋난 상태에서는 구현을 시작하지 않는다(Constitution 원칙 7).
- 이 기능은 Feature production 소스와 App wiring을 구현하지 않는다. 두 패키지 관련 요구사항은 후속 구현이 따라야 하는 규범이며, 이 기능의 완료 판정은 Domain·Data·Infrastructure·Composition 산출물과 문서 동기화로 한다.
- 경계 규칙을 강제하는 자동 검사는 신설하지 않는다. 규칙 준수는 Tuist 의존성 선언 검토, 코드 리뷰와 기존 빌드·테스트로 확인한다.
- Data의 `Member` 모듈은 대응 Domain 계약이 없으므로 이번 조립 대상에서 제외한다. Domain 계약이 생기기 전에 Composition이 노출해서는 안 된다.
- Infrastructure 보완은 Data 구현이 실제로 요구하는 범위로 제한하며, 소비처 없는 API를 선제적으로 만들지 않는다.
- 화면 전용 순수 계산과 표시 형식 변환은 UseCase 경계를 만들지 않고 Feature가 소유한다.
- 비즈니스 규칙이나 외부 데이터 접근이 포함된 작업은 Feature private helper로 숨기지 않고 Domain UseCase 경계를 사용한다.
- parent Feature는 App이 주입한 interface를 child Feature에 전달할 수 있으나, 구현 선택·생성·live와 sample 분기는 할 수 없다.
- SwiftUI Preview와 UI layout harness는 sample 구현을 직접 주입할 수 있으나, production 그래프와 소스가 분리돼야 하고 App 주입 완료 근거로 사용하지 않는다.
- 플랫폼 생명주기 이벤트 자체는 App이 소유하되, Feature에 전달되는 비즈니스 작업은 Domain UseCase로 변환한다.

## 요구사항 *(필수)*

### 기능 요구사항

#### Domain UseCase 인터페이스

- **FR-001**: Feature가 호출하는 모든 비즈니스 작업은 Domain이 소유한 UseCase Protocol을 통해 노출돼야 한다.
- **FR-002**: UseCase Protocol은 해당 기능을 소유하는 Domain target 안에 위치해야 한다.
- **FR-003**: UseCase Protocol의 입력·출력·오류는 Domain 모델, Value Object 또는 언어 표준 타입만 사용해야 한다.
- **FR-004**: UseCase Protocol은 DTO, HTTP 요청·응답, Data 오류 또는 Infrastructure 타입을 노출해서는 안 된다.
- **FR-005**: UseCase Protocol 이름은 구현 타입명이나 공급자명이 아니라 비즈니스 행위를 표현해야 한다.
- **FR-006**: 비동기 UseCase Protocol은 필요한 `Sendable`과 actor isolation 계약을 선언해야 한다.
- **FR-007**: 하나의 UseCase Protocol에 서로 관련 없는 비즈니스 작업을 편의상 합쳐서는 안 된다.
- **FR-008**: `Authentication`의 `SignIn`, `SignOut`, `RestoreSession`, `ObserveAuthenticationOutcomes`(rename 후 이름)를 포함해 Protocol이 없는 기존 concrete UseCase에 대응 Protocol을 추가하고 conformance를 선언해야 한다.
- **FR-009**: Domain은 Data, Infrastructure, Composition, Feature, App, UI를 의존하거나 import해서는 안 된다.

#### 네이밍 규약 정합성

- **FR-062**: `DomainLearningProject`의 `projectId`, `githubRepoUrl`, `nextSetId`, `nextQuestionId`, `setId`를 각각 `projectID`, `githubRepoURL`, `nextSetID`, `nextQuestionID`, `setID`로 rename해야 한다. 대상은 Repository 계약, UseCase Protocol, UseCase 구현, Domain 모델과 Domain 테스트의 모든 선언과 참조다.
- **FR-063**: `ObserveAuthorizationChanges`와 신설 Protocol을 각각 `ObserveAuthenticationOutcomes`, `ObserveAuthenticationOutcomesUseCase`로 명명해야 한다.
- **FR-064**: Tuist target `CompositionAdepter`와 `CompositionAdepterTests`를 각각 `CompositionAdapter`, `CompositionAdapterTests`로 rename하고, manifest 선언·source 폴더·테스트 폴더를 함께 갱신해야 한다.
- **FR-064a**: FR-064의 rename에 따라 App target의 Composition 의존성 선언에 남은 옛 target 이름 참조를 갱신해야 한다. 이는 App 소스 변경이 아니라 target 이름 참조 갱신이며, App의 소스 파일과 실행 동작은 바꾸지 않는다.
- **FR-065**: rename은 순수 rename이어야 한다. 연산 집합, 타입의 상태, 저장 위치, 값의 수명과 소유자, 비동기·오류·취소 동작, 패키지 책임, 의존 방향, 외부 API·schema mapping을 함께 바꿔서는 안 된다.
- **FR-066**: Data DTO의 `CodingKeys`가 보존하는 서버 원문 키와 테스트 JSON fixture의 문자열은 rename해서는 안 된다.
- **FR-067**: rename 전후로 동일한 테스트가 통과해 동작이 보존됐음을 확인해야 한다.
- **FR-068**: 이 명세가 `docs/conventions/naming.md` §8(rename과 설계·동작 변경 분리)의 예외를 적용한 이유, 영향과 미검증 범위를 PR에 기록해야 한다.

#### Infrastructure 기술 API

- **FR-010**: Data 구현이 요구하는 네트워크, 보안 저장소, 캐시 기술 API를 식별하고 Infrastructure 공개 API와 대조해야 한다.
- **FR-011**: 부족한 기술 API는 Data 구현이 실제로 요구하는 최소 범위로 보완해야 한다.
- **FR-012**: 보완한 Infrastructure API에는 대응하는 Infrastructure 테스트가 있어야 한다.
- **FR-013**: Infrastructure는 Data, Domain, Composition, Feature, App, UI를 의존하거나 import해서는 안 된다.
- **FR-014**: 소비처가 없는 기술 API를 선제적으로 추가해서는 안 된다.

#### Data 실행 구현

- **FR-015**: Data가 소유한 Remote Protocol에는 Infrastructure 기술 API 위에서 동작하는 concrete 구현이 있어야 한다.
- **FR-016**: Data target은 사용하는 Infrastructure target을 Tuist에 명시적으로 선언해야 한다.
- **FR-017**: Data 구현은 외부 시스템의 기술 오류를 Data가 소유한 오류 타입으로 변환해야 한다.
- **FR-018**: Data 구현은 DTO와 Data 모델의 경계를 유지하고 Domain 모델을 노출해서는 안 된다.
- **FR-019**: Data는 Domain, Composition, Feature, App, UI를 의존하거나 import해서는 안 된다.
- **FR-020**: Data 구현에는 요청 구성, 응답 변환과 오류 변환을 검증하는 테스트가 있어야 한다.

#### Composition 책임

- **FR-021**: Composition은 `Authentication`, `LearningProject`, `ExternalRepository`에 대해 Infrastructure 객체, Data 구현, Domain↔Data Adapter와 Domain UseCase 구현을 생성해야 한다.
- **FR-022**: Composition이 외부에 노출하는 기능은 Domain UseCase Protocol 타입이어야 한다.
- **FR-023**: Composition의 Domain↔Data Adapter는 Data DTO와 Data 오류를 Domain 모델과 Domain 오류로 변환해야 한다.
- **FR-024**: Composition은 Feature reducer, Feature dependency 묶음, Store 또는 View를 생성해서는 안 된다.
- **FR-025**: Composition은 `Feature`, `App` 또는 UI target을 의존성으로 선언해서는 안 된다.
- **FR-026**: Composition은 navigation 결정이나 Feature delegate를 해석해서는 안 된다.
- **FR-027**: Composition은 production 객체의 설정과 수명을 소유하되, Feature 주입은 App에 맡겨야 한다.
- **FR-028**: 외부에 노출할 필요가 없는 내부 Adapter와 Infrastructure 객체는 Composition의 공개 API에 노출해서는 안 된다.
- **FR-029**: Composition target은 사용하는 Domain, Data, Infrastructure target을 Tuist에 명시적으로 선언해야 한다.
- **FR-030**: Composition은 대응 Domain 계약이 없는 Data 모듈(`Member`)을 조립 대상에 포함해서는 안 된다.
- **FR-031**: Composition에는 live 실행 그래프 생성과 Adapter 변환을 검증하는 테스트가 있어야 한다.

#### 후속 Feature 구현 규범 *(이 기능에서는 문서화만 수행)*

- **FR-032**: Feature는 필요한 UseCase Protocol을 initializer 또는 명시적 immutable dependency 값으로 전달받아야 한다.
- **FR-033**: Feature가 저장하거나 요구하는 production dependency 타입은 Domain UseCase Protocol이어야 하며 concrete 구현 타입이어서는 안 된다.
- **FR-034**: Feature는 Domain Repository Protocol을 직접 호출해서는 안 된다.
- **FR-035**: Feature는 Data의 Remote·Storage·DTO·Adapter를 직접 사용해서는 안 된다.
- **FR-036**: Feature는 Infrastructure의 client, 보안 저장소, transport 또는 외부 SDK를 직접 사용해서는 안 된다.
- **FR-037**: Feature는 Composition 또는 App의 타입을 import해서는 안 된다.
- **FR-038**: Feature 내부에서 UseCase의 production 구현을 생성해서는 안 된다.
- **FR-039**: Feature는 Service Locator, singleton, 전역 mutable container 또는 ambient dependency로 UseCase를 resolve해서는 안 된다.
- **FR-040**: 필수 UseCase에 기본 live 값을 제공하는 initializer로 App 주입을 우회해서는 안 된다.
- **FR-041**: Feature dependency 누락은 런타임 fallback이 아니라 컴파일 오류로 드러나야 한다.
- **FR-042**: App이 주입한 UseCase interface를 parent Feature가 child Feature에 전달하는 것은 허용하되, 전달 과정에서 구현을 교체하거나 새로 생성해서는 안 된다.
- **FR-043**: child Feature에는 자신이 사용하는 최소 UseCase subset만 전달해야 하며, 전역 dependency 묶음을 무조건 전달해서는 안 된다.
- **FR-044**: Feature production 소스가 추가되는 시점에 대응하는 테스트 target을 Tuist 테스트 대상으로 선언해야 한다.
- **FR-045**: FeatureTests는 Domain UseCase Protocol을 구현하는 local Mock·Stub·Spy를 소유해야 하며, 그 Test Double이 production Feature target에 포함돼서는 안 된다.
- **FR-046**: FeatureTests target은 Data, Infrastructure, Composition을 의존성으로 선언해서는 안 된다.
- **FR-047**: Feature reducer 테스트는 UseCase 호출 횟수, 입력값, 취소 처리와 결과 상태를 검증해야 하며, 입력으로 HTTP 상태 코드나 DTO fixture가 아니라 Domain 결과와 Domain 오류를 사용해야 한다.

#### 후속 App 구현 규범 *(이 기능에서는 문서화만 수행)*

- **FR-048**: App은 production 실행 객체 그래프를 생성하는 유일한 최종 진입점이어야 하며, production Composition을 정확히 1회 생성해야 한다.
- **FR-049**: App은 Composition이 제공한 실행 객체를 Domain UseCase Protocol 타입으로 Feature에 전달해야 한다.
- **FR-050**: App은 root Feature와 root Store를 생성하고, 세션·온보딩 판정 결과에 따라 root 경로를 선택해야 한다.
- **FR-051**: App은 각 Feature에 그 Feature가 실제로 사용하는 UseCase만 전달해야 하며, Composition 컨테이너 전체를 전달해서는 안 된다.
- **FR-052**: App은 DTO 변환, Repository 정책 또는 HTTP 요청 로직을 구현해서는 안 된다.
- **FR-053**: production App은 sample, preview 또는 test 구현을 주입해서는 안 된다.
- **FR-054**: App wiring에 필요한 Domain target 의존성은 Tuist에 명시적으로 선언해야 하며 transitive 접근에 의존해서는 안 된다.

#### 문서 동기화

- **FR-055**: 결정 `D-ARCH-003`을 프로젝트 아키텍처 문서의 결정 기록에 남겨야 한다.
- **FR-056**: 아키텍처 문서의 패키지 책임, 의존 방향, 의존성 주입 위치, 제어 흐름과 Feature 테스트 정책 설명이 이 명세와 일치해야 한다.
- **FR-057**: 이 명세가 상위 문서 `ARCH-DI-001`의 Composition 정의를 대체하는 범위를 문서에 명시해야 한다.
- **FR-058**: FR-032~FR-054의 후속 구현 규범을 아키텍처 문서에 남겨, 이 명세를 읽지 않아도 후속 개발자가 판단할 수 있게 해야 한다.
- **FR-059**: 아키텍처 문서의 프로젝트 내부 패키지 의존성 표에서 Data의 허용 의존성에 Infrastructure를 추가하고, 금지 의존성 목록에서 `Data → Infrastructure` 항목을 제거해야 한다.
- **FR-060**: FR-059의 의존성 표 개정은 이 명세의 어떤 패키지 구현 작업보다 먼저 완료돼야 한다.
- **FR-061**: 아키텍처 문서에서 `Data↔Infrastructure` Adapter를 Composition 책임으로 서술한 부분을 개정된 의존 방향에 맞게 정정해야 한다.

### 핵심 엔터티

- **UseCase Protocol**: Domain이 소유하는 비즈니스 작업 계약. 입력·출력·오류가 모두 Domain 경계 안에 있으며, Feature가 의존하는 유일한 비즈니스 타입이다.
- **UseCase 구현**: UseCase Protocol을 구현하고 Domain Repository Protocol을 사용하는 실행 타입.
- **Data Remote 구현**: Data가 소유한 Remote Protocol을 Infrastructure 기술 API 위에서 구현하며, DTO와 Data 오류 경계를 유지한다.
- **Domain↔Data Adapter**: Composition이 소유하며 Domain Repository Protocol을 Data 구현으로 충족하고 모델·오류를 변환한다.
- **Composition 실행 그래프**: Infrastructure·Data·Adapter·UseCase 구현을 조립한 결과이며, 외부에는 Domain Protocol 타입만 노출한다.
- **App Composition Root**: 후속 구현 대상. production 그래프 생성, 환경 선택, Feature 주입, root Store 생성과 route 연결을 담당하는 단일 지점.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: Domain이 노출하는 UseCase 중 대응 Protocol이 없는 건수가 0건이며, 각 concrete UseCase가 그 Protocol을 구현한다.
- **SC-002**: UseCase Protocol 시그니처에 등장하는 DTO, HTTP, Infrastructure, 외부 SDK 타입이 0건이다.
- **SC-003**: `Authentication`, `LearningProject`, `ExternalRepository`의 Data Remote Protocol 중 실행 구현이 없는 건수가 0건이다.
- **SC-004**: Data target이 사용하는 Infrastructure target을 명시적으로 선언하며, Data가 Domain·Composition·Feature·App·UI를 의존한 건수가 0건이다.
- **SC-005**: Data 구현의 요청 구성, 응답 변환, 오류 변환에 대한 테스트가 통과한다.
- **SC-006**: Infrastructure에 추가된 API의 100%가 Data 구현의 실제 요구에 대응하며, 대응 테스트가 통과한다.
- **SC-007**: Composition의 live 실행 그래프 생성이 `Authentication`, `LearningProject`, `ExternalRepository`에 대해 성공한다.
- **SC-008**: Composition이 외부에 노출하는 property의 100%가 Domain UseCase Protocol 타입이며, 내부 Adapter·Infrastructure 타입 노출이 0건이다.
- **SC-009**: Composition 소스에 Feature, Store 또는 View를 생성하는 코드가 0건이고, Composition이 Feature·App·UI를 의존성으로 선언한 건수가 0건이다.
- **SC-010**: Composition이 공유 수명을 요구하는 Repository·세션 객체를 중복 생성하는 건수가 0건이다.
- **SC-011**: Composition이 대응 Domain 계약 없이 노출하는 기능이 0건이다.
- **SC-012**: 패키지 의존성 그래프의 순환이 0건이며 `tuist generate`와 전체 공유 scheme Debug 빌드가 성공한다.
- **SC-013**: Domain, Data, Infrastructure, Composition의 테스트가 모두 통과한다.
- **SC-014**: 사용자 관찰 동작과 외부 API 소비 의미의 변경이 0건이다.
- **SC-015**: 후속 Feature·App 개발자가 아키텍처 문서와 결정 기록만으로 Feature 의존 대상, 주입 위치, Test Double 소유 규칙을 확인할 수 있으며, 문서와 이 명세 사이의 모순 서술이 0건이다.
- **SC-016**: 아키텍처 문서의 패키지 의존성 표와 금지 목록이 `Data → Infrastructure`를 허용하도록 개정되며, 이 개정이 첫 패키지 구현 작업보다 먼저 완료된다.
- **SC-017**: 아키텍처 문서의 의존성 표와 이 명세가 계획한 패키지 구현 순서 사이의 불일치가 0건이다.
- **SC-018**: `DomainLearningProject`에 `projectId`, `githubRepoUrl`, `nextSetId`, `nextQuestionId`, `setId` 표기가 0건 남는다.
- **SC-019**: 저장소의 Swift 선언에서 `Url`, `Id`, `Http` 절충 표기가 0건이다. Data `CodingKeys`의 서버 원문 키 문자열과 테스트 JSON fixture는 집계에서 제외한다.
- **SC-020**: rename 전후로 동일한 테스트 집합이 통과하며, 연산 집합·상태·수명·오류·취소 동작·의존 방향·외부 mapping의 변경이 0건이다.
- **SC-021**: `CompositionAdepter` 표기가 manifest, 폴더 경로, target 이름과 의존성 선언에 0건 남고 `tuist generate`와 전체 빌드가 성공한다. App의 변경은 target 이름 참조 1건으로 한정되고 App 소스 파일 변경은 0건이다.
- **SC-022**: Composition의 Domain↔Data Adapter에서 식별자·URL 필드의 표기를 뒤집는 변환이 0건이다.

## 가정

- 사용자 결정에 따라 이 기능의 변경 대상 패키지는 Domain, Data, Infrastructure, Composition이다. Feature와 App의 **소스 파일과 실행 동작**은 변경하지 않는다.
- 예외로 `CompositionAdapter` target rename(FR-064)은 App target의 의존성 선언에 있는 옛 target 이름 참조 1건을 갱신하게 한다. 이는 빌드 그래프의 이름 참조 갱신이며 App 소스나 동작 변경이 아니다. 해당 변경은 Composition 단계에 배정한다.
- 사용자 결정에 따라 경계 규칙을 강제하는 자동 검사는 신설하지 않는다. 규칙 준수는 Tuist 의존성 선언 검토, 코드 리뷰와 기존 빌드·테스트로 확인한다.
- 상위 문서 `ARCH-DI-001`은 현재 저장소에 파일로 존재하지 않으므로, 이 명세는 그 결정을 전제로 하되 검증은 저장소의 아키텍처 문서와 실제 소스를 기준으로 한다.
- 현재 `Domain`의 `LearningProject`에는 UseCase Protocol과 구현이 존재하지만, `Authentication`의 `SignIn`, `SignOut`, `RestoreSession`, `ObserveAuthorizationChanges`에는 대응 Protocol이 없다. 마지막 항목은 rename 대상이기도 하다.
- 현재 `Data`에는 Remote Protocol, DTO, Endpoint만 있고 concrete 구현이 없으며, Data target은 Infrastructure 의존성을 선언하지 않았다.
- 현재 `Infrastructure`에는 `NetworkClient`(Client·HTTP·Transport), `Authentication`(Keychain·AppleAuthentication·RandomGenerator), `Cache`, `Utility`가 존재한다.
- 현재 `Composition` target은 placeholder만 가지고 있고 Domain·Data·Infrastructure 의존성을 선언하지 않았다.
- 현재 `Feature` target은 placeholder 소스만 가지고 있고 테스트 target 선언이 없으며, `App`의 root는 `ContentView` 수준이다. 이 상태는 이 기능에서 변경하지 않는다(FR-064a의 target 이름 참조 갱신 제외).
- 사용자 결정에 따라 네이밍 규약 위반 rename 3건을 이 명세 범위에 포함한다. `docs/conventions/naming.md` §8은 rename과 설계·동작 변경의 분리를 요구하지만, 이 기능이 Domain UseCase 계약을 정본으로 확정하고 Composition Adapter를 신설하는 시점이라 지금 바로잡지 않으면 위반 이름이 새 계약에 고정된다. 예외 근거는 Constitution 원칙 3에 따라 PR에 기록한다(FR-068).
- rename 대상은 `DomainLearningProject`의 표준 약어 표기, `ObserveAuthorizationChanges`의 이름, `CompositionAdepter` target 철자다. `DomainAuthentication`, Domain의 `ExternalRepository`, Data, Infrastructure는 이미 규칙을 지켜 대상이 아니다.
- 서버 endpoint, DTO 스키마와 사용자 관찰 화면 요구사항은 변경하지 않는다. Data DTO의 `CodingKeys` 서버 원문 키도 그대로 유지한다.
- 구현은 Constitution 원칙 7(버전 4.0.0)에 따라 의존성 위상 순서로 진행하며, 피의존 패키지를 먼저 구현하고 각 패키지마다 승인 게이트를 거친다. UI, Feature, App은 이 명세의 변경 대상 패키지가 아니다.
- 개정된 의존 규칙에서 Domain과 Infrastructure는 서로 의존하지 않는 leaf이고, Data는 Infrastructure에, Composition은 Domain·Data·Infrastructure에 의존한다. 따라서 Data는 Infrastructure보다 뒤, Composition은 마지막이며, Domain과 Infrastructure의 상대적 순서는 `tasks.md`가 근거와 함께 확정한다.
- 아키텍처 문서의 의존성 표 개정(FR-059)이 완료되기 전에는 패키지 구현을 시작하지 않는다.

## 범위 밖

- Feature production 소스, 화면 동작, reducer, Store와 FeatureTests 구현
- App의 Composition 생성, Feature initializer 주입, root Store 생성과 route 분기 구현(FR-064a의 target 이름 참조 갱신은 제외 대상이 아님)
- 경계 규칙을 강제하는 자동 검사 스크립트, Tuist 규칙 검증 또는 검사용 테스트 target 신설
- Data `Member` 모듈의 조립과 대응 Domain 계약 신설
- Domain이 Data를 직접 의존하는 구조와 Feature가 Repository를 직접 사용하는 구조
- Feature별 Service Locator, 전역 dependency registry 기반 production 해결
- Composition에서 Feature 또는 Store를 생성하는 구조
- 모든 UseCase를 하나의 통합 interface로 합치는 구조
- UI 컴포넌트에 UseCase를 직접 주입하는 구조
- 서버 endpoint 또는 DTO 변경, 사용자 관찰 요구사항 변경
- rename 대상이 아닌 경계(`DomainAuthentication`, Domain의 `ExternalRepository`, Data, Infrastructure, UI)의 이름 변경
- 서버 원문 키, JSON fixture 문자열과 외부 API 필드명 변경
- `ObserveAuthenticationOutcomes`의 책임 분리(관찰과 세션 복원의 분리) 등 rename을 넘는 설계 변경
- App navigation 정책 전면 재설계, Domain 패키지 통합 또는 모듈 재분할
