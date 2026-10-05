# 기능 명세: Domain 패키지 target의 UseCase 역할 기준 재구성

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/domain-usecase-role-targets`

**브랜치 상태**: `생성`

**생성일**: 2026-10-05

**상태**: 초안

**입력**: 사용자 설명: "아래의 방향성에 따라 문서를 업데이트한 뒤, 실제 진행합니다. Domain 패키지의 타겟들을 관심사에 따라 나누지 말고 아래의 역할에 따라 나눕니다. 1. UseCase Implement 2. UseCase Interface 3. UseCase Dependency 4. UseCase Test"

**입력 해석**: 이 변경은 최종 사용자가 관찰하는 동작을 바꾸지 않는 내부 구조 변경이다.
이해관계자는 이 저장소에서 작업하는 개발자와 AI 코딩 에이전트다. 사용자가 든 네 항목은
Domain 패키지가 가져야 하는 target 전체이며 예시가 아니다. 관심사(Account, Project 등)는
없어지지 않고, target 경계에서 각 역할 target 안의 폴더 경계로 내려간다.

"문서를 업데이트한 뒤, 실제 진행합니다"는 순서 제약이다. 규칙 문서가 새 구조를 먼저 규정하고,
코드 재구성은 그 문서를 기준으로 뒤따른다.

이 명세를 쓰면서 사용자가 확정한 사항은 다음과 같다(2026-10-05).

- 모델·Value Object·식별자·오류는 UseCase Interface target이 소유한다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 규칙 문서가 네 역할 target 구조를 먼저 규정한다 (우선순위: P1)

개발자나 에이전트가 Domain 패키지 규칙을 읽으면 target이 관심사가 아니라 네 역할로 나뉜다는
것과, 각 target이 무엇을 소유하고 무엇에 의존할 수 있는지를 알 수 있다. 이 문서 개정은 코드
재구성보다 먼저 끝나 있고, 코드 재구성은 이 문서를 기준으로 진행한다.

**주요 행위자**: 개발자, AI 코딩 에이전트

**우선순위 이유**: 사용자가 정한 순서의 첫 단계다. 규칙이 먼저 확정돼야 뒤따르는 재구성이 무엇을
기준으로 옳은지 판정할 수 있다. 문서가 옛 구조를 설명한 채로 남으면 다음 작업이 다시 관심사
target을 만든다.

**독립 테스트**: Domain 패키지 규칙, 디렉터리·형태 어휘 컨벤션, Composition 패키지 규칙을 읽어 네
역할 target의 목록·소유·허용 의존이 적혀 있는지 확인하고, 변경 이력에서 문서 개정이 코드
재구성보다 앞에 있는지 확인한다.

**수용 시나리오**:

1. **전제** 문서 개정이 끝난 저장소, **실행** Domain 패키지 규칙을 읽는다, **결과** 네 역할
   target의 목록, 각 target이 소유하는 선언, target 사이에 허용하는 의존이 적혀 있고 "관심사
   하나는 자기 타깃을 갖는다"는 규칙과 식별자 전용 타깃 규칙은 없다.
2. **전제** 새 관심사의 모델, UseCase 계약, 주입 계약, UseCase 구현, 테스트를 추가하려는 개발자,
   **실행** 규칙 문서와 형태 어휘 표를 읽는다, **결과** 다섯 선언 각각의 경로를 target을 새로
   만들지 않고 정할 수 있다.
3. **전제** 문서 개정이 끝난 저장소, **실행** 디렉터리 컨벤션과 형태 어휘 표에서 Domain의 소스
   루트를 확인한다, **결과** 소스 루트가 역할이고 관심사가 그 아래 폴더라고 규정돼 있다.
4. **전제** 이 기능의 변경 이력, **실행** 규칙 문서 개정과 코드 재구성의 순서를 확인한다,
   **결과** 문서 개정이 독립된 변경 단위로 먼저 기록돼 있고 그 단위는 문서만 바꾼다.
5. **전제** 문서 개정만 끝나고 코드가 아직 관심사 target 구조인 저장소, **실행** 프로젝트 셸 회귀
   테스트와 패키지 의존성 검사를 실행한다, **결과** 모두 통과한다.

---

### 시나리오 2 - Domain이 네 역할 target으로 구성되고 동작은 그대로다 (우선순위: P2)

개발자가 Domain 패키지를 열면 target이 UseCase 구현, UseCase Interface, UseCase Dependency,
UseCase Test의 넷이다. 관심사 이름을 가진 target은 없다. 앱과 모든 테스트는 재구성 전과 같은
결과를 낸다.

**주요 행위자**: 개발자, AI 코딩 에이전트

**우선순위 이유**: 이 명세의 본체다. 시나리오 1이 정한 규칙을 실제 구조로 옮긴다. 시나리오 3은 이
구조가 있어야 성립한다.

**독립 테스트**: Domain 패키지의 target 목록을 확인하고 전체 build, build-for-testing, test를
실행해 재구성 전과 같은 테스트가 모두 통과하는지 확인한다.

**수용 시나리오**:

1. **전제** 재구성이 끝난 저장소, **실행** Domain 패키지의 target 목록을 확인한다, **결과**
   production target은 UseCase 구현, UseCase Interface, UseCase Dependency의 셋이고 test target은
   UseCase Test 하나다. 관심사 이름을 가진 target과 식별자 전용 target은 없다.
2. **전제** 재구성이 끝난 저장소, **실행** 임의의 Domain production 선언이 속한 target을
   확인한다, **결과** 그 선언은 자기 역할에 해당하는 target 하나에만 속한다.
3. **전제** 재구성이 끝난 저장소, **실행** 전체 build, build-for-testing, test를 순서대로
   실행한다, **결과** 모두 통과하고 실행된 테스트 수가 재구성 전과 같다.
4. **전제** 재구성이 끝난 저장소, **실행** 한 관심사의 선언을 찾는다, **결과** 각 역할 target의
   소스 루트 아래에서 그 관심사 이름의 폴더로 찾을 수 있다.
5. **전제** 재구성이 끝난 저장소, **실행** 시나리오 1의 규칙 문서에 적힌 target 목록·소유·허용
   의존을 실제 target 구성과 대조한다, **결과** 어긋나는 항목이 없다.

---

### 시나리오 3 - 사용하는 쪽이 필요한 역할에만 의존한다 (우선순위: P3)

UseCase를 호출하는 쪽은 UseCase Interface만 보고, UseCase 구현은 조립을 맡는 쪽만 본다. 역할을
target으로 나눈 이유가 빌드 그래프에 그대로 드러난다.

**주요 행위자**: 개발자, AI 코딩 에이전트

**우선순위 이유**: 역할로 나눈 효과가 실제로 강제되는지 확인하는 시나리오다. 시나리오 2 없이는
검증할 수 없다.

**독립 테스트**: App·Composition·Feature의 Domain 의존 선언을 확인하고 패키지 의존성 검사를
실행한다.

**수용 시나리오**:

1. **전제** 재구성이 끝난 저장소, **실행** Feature와 App의 Domain 의존 선언을 확인한다,
   **결과** UseCase 구현 target에 대한 의존 선언이 없다.
2. **전제** 재구성이 끝난 저장소, **실행** 각 소비 target의 Domain 의존 선언과 그 target의
   소스가 실제로 import하는 Domain 모듈을 비교한다, **결과** 선언된 역할 target은 모두 실제로
   쓰이고, 쓰이지 않는 역할 target은 선언돼 있지 않다.
3. **전제** 재구성이 끝난 저장소, **실행** 패키지 의존성 검사를 실행한다, **결과** 위반이 0건이다.
4. **전제** 재구성이 끝난 저장소, **실행** Domain 역할 target 사이의 의존 선언을 확인한다,
   **결과** UseCase Interface target은 다른 Domain target에 의존하지 않고, UseCase Dependency
   target은 UseCase Interface target에만 의존한다.

---

### 예외·경계 사례

- 문서 개정이 끝나고 코드가 아직 관심사 target 구조인 중간 상태가 기능 브랜치 안에 생긴다. 이
  상태에서 규칙 문서는 아직 없는 구조를 설명한다. 이 불일치는 기능 브랜치 안에서만 허용하고,
  기능이 끝나는 시점에는 문서와 구조가 일치해야 한다. 문서 개정 단위는 검사 설정을 바꾸지
  않으므로 중간 상태에서도 기존 검사가 통과해야 한다.
- 선언의 역할은 현재 형태 폴더로 판정한다. 모델·오류는 UseCase Interface, 주입 계약은 UseCase
  Dependency, UseCase 계약은 UseCase Interface, UseCase 계약의 구현은 UseCase 구현에 속한다. 이
  기준으로 역할이 정해지지 않는 선언이 발견되면 그 선언과 배정 근거를 계획 산출물에 기록한다.
- UseCase 계약이나 모델이 주입 계약의 타입을 참조하는 선언이 발견되면 UseCase Interface가 UseCase
  Dependency에 의존해야 해서 허용 의존과 충돌한다. 이 경우 의존 방향을 뒤집지 않고, 해당 선언과
  해소 방법을 사용자에게 확인한 뒤 진행한다.
- 서로 다른 관심사가 같은 이름의 최상위 타입을 가지면 한 모듈 안에서 충돌한다. 현재는 충돌이
  없다. 이후 추가되는 선언에 적용할 유일성 규칙을 Domain 패키지 규칙에 남긴다.
- 재구성으로 target 경계가 생긴 자리에서 `internal` 선언에 접근해야 하는 경우가 발견되면, 접근
  수준을 필요한 선언에 한해 넓히고 그 목록과 이유를 계획 산출물에 기록한다. 이름·시그니처·동작은
  바꾸지 않는다.
- Feature가 주입 계약을 직접 쓰는 곳이 있다. 이 사용은 그대로 두고 Feature가 UseCase Dependency
  target에 의존하도록 선언한다. 이 사용을 없애는 일은 이 명세의 범위가 아니다.
- 모듈 이름으로 한정한 참조(`DomainAccount.AuthenticationRepository` 형태)는 그 선언이 옮겨 간
  역할 target의 모듈 이름으로 바꾼다. 한정이 필요했던 이유(다른 패키지의 같은 이름 타입과의
  구분)는 유지된다.
- 식별자만 담던 전용 target은 UseCase Interface target의 한 관심사 폴더가 된다. 그 폴더가 식별자
  외의 선언을 갖지 않는다는 기존 제약은 유지한다.
- `@testable import`로 Domain 관심사 target을 보던 테스트는 재구성 뒤에도 같은 선언에 접근할 수
  있어야 한다.
- 하나의 test target이 모든 관심사의 테스트를 담으므로 빈 test target은 생기지 않는다. 테스트
  파일과 Test Double의 폴더 배치는 바꾸지 않는다.
- 과거 결정과 조사를 기록한 문서(`docs/review/`, `docs/spec-kit/`, `docs/retrospective/`와 다른
  기능의 `specs/` 산출물)에는 옛 target 이름이 남는다. 이 문서들은 당시의 기록이므로 고치지
  않는다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: Domain 패키지의 production target은 다음 셋이어야 한다. UseCase 구현(UseCase 계약의
  구현), UseCase Interface(UseCase 계약과 모델·Value Object·식별자·오류), UseCase
  Dependency(Repository 등 UseCase 구현이 생성자로 주입받는 계약).
- **FR-002**: Domain 패키지의 test target은 UseCase Test 하나여야 하고, 재구성 전의 모든 테스트와
  Test Double을 담아야 한다.
- **FR-003**: 관심사 이름을 가진 target과 식별자 전용 target은 남아 있지 않아야 한다.
- **FR-004**: 모든 Domain production 선언은 FR-001의 세 target 중 자기 역할에 해당하는 하나에만
  속해야 한다.
- **FR-005**: Domain target 사이의 의존은 다음만 허용해야 한다. UseCase Interface target은 다른
  Domain target에 의존하지 않는다. UseCase Dependency target은 UseCase Interface target에만
  의존한다. UseCase 구현 target은 UseCase Interface target과 UseCase Dependency target에 의존할 수
  있다. test target은 세 production target에 의존할 수 있다.
- **FR-006**: 관심사는 각 역할 target의 소스 루트 아래 폴더로 유지해야 하고, 그 아래의 형태 폴더와
  파일당 타입 하나 규칙은 현재 컨벤션을 그대로 따라야 한다.
- **FR-007**: 재구성은 Domain 선언의 이름, 시그니처와 동작을 바꾸지 않아야 한다. Domain production
  소스 파일의 내용 변경은 import 선언에 한정해야 하며, 예외·경계 사례의 접근 수준 확대가
  필요하면 그 선언만 예외로 기록한다.
- **FR-008**: App·Composition·Feature의 각 target은 실제로 사용하는 Domain 역할 target에만 의존을
  선언해야 한다.
- **FR-009**: Feature와 App의 어떤 target도 UseCase 구현 target에 의존을 선언하지 않아야 한다.
- **FR-010**: Feature가 현재 직접 사용하는 주입 계약은 그대로 사용할 수 있어야 하며, 이 명세는 그
  사용을 추가하거나 제거하지 않는다.
- **FR-011**: 저장소의 모든 Swift 소스에서 Domain 모듈 import와 모듈 이름으로 한정한 참조는 새
  역할 target의 모듈 이름을 가리켜야 한다.
- **FR-012**: Domain 패키지 공유 scheme은 하나로 유지하고 세 production target을 빌드 대상으로,
  test target을 테스트 대상으로 연결해야 한다. 전체 테스트 scheme도 새 test target을 연결해야
  한다.
- **FR-013**: 패키지 의존성 검사의 target·소스 루트 대응표는 재구성 뒤의 target과 1:1로 대응해야
  한다.
- **FR-014**: Domain 패키지 규칙은 네 역할 target의 목록, 각 target이 소유하는 선언, target 사이에
  허용하는 의존, 한 모듈 안에서의 최상위 타입 이름 유일성을 규정해야 하고, 관심사별 target이나
  식별자 전용 target을 전제로 한 규칙을 남기지 않아야 한다.
- **FR-015**: 디렉터리 컨벤션과 형태 어휘 표는 Domain의 소스 루트가 역할이고 관심사가 그 아래
  폴더라는 배치를 규정해야 한다.
- **FR-016**: Composition 패키지 규칙에서 Domain 관심사 target을 가리키는 표현은 관심사를 가리키는
  표현으로 바꿔야 한다. Composition target의 구성 자체는 바꾸지 않는다.
- **FR-017**: FR-014~FR-016의 규칙 문서 개정은 Swift 소스, Tuist 매니페스트와 검사 설정의 변경보다
  먼저 완료해야 하고, 문서만 바꾸는 독립된 변경 단위로 기록해야 한다.
- **FR-018**: 규칙 문서 개정만 적용된 상태에서 프로젝트 셸 회귀 테스트와 패키지 의존성 검사가
  통과해야 한다.
- **FR-019**: 재구성이 끝난 시점에 규칙 문서가 규정한 target 목록, 소유와 허용 의존은 실제 target
  구성과 일치해야 한다. 재구성 중 문서와 다른 구조가 필요해지면 문서를 먼저 고친 뒤 구조를
  바꾼다.
- **FR-020**: [아키텍처 문서](../../docs/architecture.md)의 패키지 간 허용 의존성 표와 패키지 책임은
  바꾸지 않아야 한다.
- **FR-021**: 과거 기록 문서(`docs/review/`, `docs/spec-kit/`, `docs/retrospective/`, 다른 기능의
  `specs/` 산출물)는 수정하지 않아야 한다.

### 핵심 엔터티

- **역할 target**: 선언이 맡는 역할(UseCase 구현, UseCase Interface, UseCase Dependency, UseCase
  Test) 하나를 담는 Domain 패키지의 빌드 단위다. 다른 역할 target과의 허용 의존이 정해져 있다.
- **UseCase Interface**: UseCase를 호출하는 쪽이 보는 표면이다. UseCase 계약과, 그 계약과 주입
  계약이 함께 쓰는 모델·Value Object·식별자·오류를 소유한다.
- **주입 계약**: UseCase 구현이 생성자로 주입받는 외부 기능 계약(Repository 등)이다. UseCase
  Dependency target이 소유하고 production 구현은 Domain 밖에 있다.
- **관심사**: 하나의 비즈니스 주제(Account, Project 등)에 속한 선언의 묶음이다. 재구성 뒤에는
  target이 아니라 각 역할 target 안의 폴더로 표현된다.
- **소비 target**: Domain 역할 target에 의존을 선언하는 App·Composition·Feature의 target이다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: Domain 패키지의 target 수가 16개(관심사 production 8, 관심사 test 8)에서 4개(역할
  production 3, test 1)로 바뀐다.
- **SC-002**: 전체 build, build-for-testing, test가 모두 통과하고, 실행된 테스트 수가 재구성 전과
  같다.
- **SC-003**: 패키지 의존성 검사의 위반이 0건이다.
- **SC-004**: Swift 소스, Tuist 매니페스트, 검사 설정과 현행 규칙 문서(`docs/architecture.md`,
  `docs/package-rules/`, `docs/conventions/`)에서 없어진 target 이름의 참조가 0건이다.
- **SC-005**: Feature와 App의 매니페스트에서 UseCase 구현 target에 대한 의존 선언이 0건이다.
- **SC-006**: Domain production 소스 파일의 변경이 경로 이동과 import 선언 변경뿐임을 변경 내역
  대조로 확인한다. FR-007의 예외가 있으면 그 선언 목록과 일치한다.
- **SC-007**: 프로젝트 셸 회귀 테스트가 문서 개정 직후와 재구성 완료 뒤에 모두 통과한다.
- **SC-008**: 새 관심사의 모델, UseCase 계약, 주입 계약, UseCase 구현, 테스트가 놓일 경로를 규칙
  문서와 형태 어휘 표만으로 정할 수 있다.
- **SC-009**: 변경 이력에서 규칙 문서 개정 단위가 첫 코드 재구성 단위보다 앞에 있고, 그 단위가
  바꾼 파일은 100% 문서다.
- **SC-010**: 규칙 문서가 규정한 target 목록·소유·허용 의존과 재구성 뒤 실제 target 구성 사이의
  불일치가 0건이다.

## 가정

- 역할 target의 이름은 계획 단계에서 확정한다. 사용자가 쓴 역할 어휘(Implement, Interface,
  Dependency, Test)를 유지하되 프로젝트의 축약 금지 규칙과 target 이름 규칙을 적용한다. 기본안은
  `DomainUseCaseImplementation`, `DomainUseCaseInterface`, `DomainUseCaseDependency`,
  `DomainUseCaseTests`다.
- 폴더 배치의 기본안은 `Domain/<역할>/<관심사>/<형태>/`다. 기존 디렉터리 컨벤션의 관심사 세그먼트
  규칙을 Domain에 적용한 것이다.
- 개정 대상 규칙 문서의 기본안은 `docs/package-rules/domain.md`,
  `docs/conventions/directory-file.md`, `docs/conventions/directory-file/concern-segment.md`,
  `docs/conventions/file-vocabulary/shape-vocabulary.md`, `docs/package-rules/composition.md`다.
  계획 단계에서 옛 구조를 전제로 한 다른 현행 규칙 문서가 확인되면 같은 개정 단위에 포함한다.
- 검사 설정(패키지 의존성 검사의 target·소스 루트 대응표)은 매니페스트와 1:1이어야 하므로 문서
  개정 단위가 아니라 코드 재구성과 함께 바꾼다.
- 테스트의 폴더 배치(`Tests/<관심사>/…`)와 테스트 내용은 바꾸지 않는다.
- 이 기능 브랜치는 `feature/generation-list-completion`의 `a4cc97c`에서 분기했다. 기준선의
  Domain은 관심사별 16개 target 구조다.
- 진행 중인 다른 기능 명세(047~049)의 산출물이 옛 target 이름을 언급하더라도 이 명세가 고치지
  않는다.
- 이 명세는 다음을 전제한다. 계획 단계에서 검증하고, 어긋나면 예외·경계 사례의 처리 방법을
  따른다.
  - Domain의 최상위 타입 이름은 관심사 사이에 충돌이 없다.
  - 모델·오류와 UseCase 계약은 주입 계약의 타입을 참조하지 않는다.
  - 역할 target 경계를 넘어 `internal` 선언에 접근해야 하는 곳이 없어 접근 수준을 바꾸지 않고
    컴파일된다.
  - Feature의 공유 등록 흐름이 주입 계약 하나를 직접 사용한다.
  - Composition에 모듈 이름으로 한정한 Domain 참조가 7곳 있다.
  - Data·Infrastructure·UI는 Domain 모듈을 import하지 않는다.
