# 기능 명세: 패키지 의존성 원칙 강제

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/package-dependency-enforcement`

**브랜치 상태**: `생성`

**생성일**: 2026-09-16

**상태**: 초안

**입력**: 사용자 설명: "docs/review/package-dependency-enforcement-requirements.md 의 요구사항을 기능 명세로 정의한다. 아키텍처 3.1의 패키지 의존성 표를 기계가 검증하게 만들고, CompositionAdapter 수렴점을 도메인 축으로 분할한다."

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 허용되지 않는 의존성이 머지되지 못한다 (우선순위: P1)

개발자가 [아키텍처 3.1](../../docs/architecture.md)이 허용하지 않는 패키지 의존성을
manifest나 Swift `import`로 들여오면, 사람이 코드 리뷰에서 찾아내기 전에 자동 검사가
그 조합과 위치를 지목하고 실패한다.

**주요 행위자**: 저장소에 변경을 올리는 개발자와 CI

**우선순위 이유**: 지금은 규칙이 산문 문서에만 있어 위반이 빌드를 통과한다. 실제로
`App`이 `UIComponent`를 참조한 위반이 리뷰를 통과해 들어왔고, 같은 유형이 다시 들어와도
막을 장치가 없다. 이 시나리오 하나만 있어도 재발이 멈춘다.

**독립 테스트**: 허용되지 않는 `.from<패키지>(...)` 한 줄과 허용되지 않는 프로젝트 내부
`import` 한 줄을 각각 일부러 넣고 검사를 실행해 둘 다 실패하는지, 그리고 되돌린 뒤
위반 0으로 통과하는지 확인한다.

**수용 시나리오**:

1. **전제** 저장소가 현재 상태이고 검사 도구가 설치돼 있다, **실행** 검사를 실행한다,
   **결과** 위반 0으로 통과하고 예외 목록을 쓰지 않는다.
2. **전제** `FeatureModuleName.swift`에 `.fromComposition(...)`을 추가했다,
   **실행** 검사를 실행한다, **결과** 위반한 target 이름, 선언 위치, 허용되지 않는
   이유를 담은 메시지와 함께 실패한다.
3. **전제** `sources/Projects/Domain` 아래 Swift 파일에 `import DataMember`를 추가했다,
   **실행** 검사를 실행한다, **결과** 그 파일과 import 대상을 지목하며 실패한다.
4. **전제** manifest에는 없지만 전이 의존으로 컴파일되는 `import`가 있다,
   **실행** 검사를 실행한다, **결과** 위반으로 판정한다.

---

### 시나리오 2 - 규칙 정본이 하나이고 문서와 어긋나지 않는다 (우선순위: P1)

패키지별 허용 의존성이 기계가 읽는 설정 파일 하나에 있고, 그 내용이
[아키텍처 3.1](../../docs/architecture.md)의 표와 어긋나면 검사가 실패한다. 규칙을 바꾸려면
표와 설정을 함께 고쳐야 한다.

**주요 행위자**: 아키텍처 의존 방향을 바꾸려는 개발자

**우선순위 이유**: 정본이 둘이 되면 검사는 통과하는데 문서는 다른 상태가 되고, 다음
사람이 어느 쪽을 믿어야 할지 알 수 없게 된다. 시나리오 1의 검사 결과를 신뢰하려면 이
대응 관계가 먼저 보장돼야 한다.

**독립 테스트**: 설정 파일의 한 항목을 표와 다르게 바꾸고 검사를 실행해 실패하는지
확인한다.

**수용 시나리오**:

1. **전제** 설정 파일과 아키텍처 표가 일치한다, **실행** 검사를 실행한다,
   **결과** 대응 검사가 통과한다.
2. **전제** 설정 파일에서 `Feature`의 허용 목록에 `Data`를 추가했다,
   **실행** 검사를 실행한다, **결과** 표와 어긋난다는 이유로 실패한다.
3. **전제** 설정 파일을 읽는다, **결과** 아키텍처 표의 7개 패키지가 모두 들어 있고
   target 단위 예외가 없다.

---

### 시나리오 3 - 훅이 꺼져 있어도 검사가 동작한다 (우선순위: P2)

검사가 pre-commit 단계와 CI 게이트 양쪽에 등록돼, pre-commit 단계가 전부 비활성화된
현재 상태에서도 CI에서 실행되고 실패 시 머지가 막힌다.

**주요 행위자**: CI와 저장소 관리자

**우선순위 이유**: 이 저장소의 pre-commit 단계는 현재 전부 주석 처리돼 있다. 훅에만
등록하면 검사는 만들었지만 아무도 실행하지 않는 상태가 된다.

**독립 테스트**: 위반을 넣은 브랜치로 pull request를 만들어 CI가 실패하는지, 그리고
로컬에서 훅을 켜면 커밋이 막히는지 확인한다.

**수용 시나리오**:

1. **전제** pre-commit 단계가 모두 비활성화돼 있다, **실행** 위반이 있는 변경으로 CI를
   돌린다, **결과** 게이트가 실패한다.
2. **전제** pre-commit `enabled`에서 이 단계의 주석을 푼다, **실행** 위반이 있는 변경을
   커밋한다, **결과** 커밋이 막힌다.
3. **전제** 저장소가 위반 0 상태다, **실행** 검사를 단독 실행한다,
   **결과** 5초 이내에 끝나고 빌드를 유발하지 않는다.

---

### 시나리오 4 - 조립 경계의 수렴점이 사라진다 (우선순위: P3)

`CompositionAdapter` 하나가 12개 모듈에 의존해 Domain·Data·Infrastructure 어느 모듈이
바뀌어도 그 하위 전체가 재컴파일되는 상태를 도메인 축 분할로 해소한다.

**주요 행위자**: 한 모듈만 고치고 빌드를 기다리는 개발자

**우선순위 이유**: 의존성 표를 지켜도 남는 문제이고, 검사 도구가 먼저 들어와야 분할
작업 중 새 위반이 생기지 않는다. 앞의 세 시나리오 없이 이것만 해도 재발 방지는 되지
않는다.

**독립 테스트**: 분할 후 각 target의 의존 모듈 수를 세고, `tuist generate`와 전체 공유
scheme Debug 빌드가 성공하는지 확인한다.

**수용 시나리오**:

1. **전제** 분할을 마쳤다, **실행** Composition의 각 target 의존 모듈 수를 센다,
   **결과** 어느 target도 6개를 초과하지 않는다.
2. **전제** 분할을 마쳤다, **실행** 공용 조립 target의 의존성을 확인한다,
   **결과** Domain·Data 모듈에 의존하지 않는다.
3. **전제** 분할을 마쳤다, **실행** `CompositionApp`과 `CompositionShareExtension`의
   의존성을 확인한다, **결과** 각자 실제로 쓰는 분할 target만 참조한다.
4. **전제** 분할을 마쳤다, **실행** `tuist generate` 후 전체 공유 scheme을 Debug 빌드한다,
   **결과** 성공하고 `AllTests` scheme의 target 목록이 유효하다.

---

### 예외·경계 사례

- 외부 라이브러리와 시스템 프레임워크 `import`는 검사 대상이 아니다. 프로젝트 내부
  모듈 이름 목록은 manifest의 모듈 선언에서 유도하므로, 목록에 없는 이름은 검사하지
  않는다.
- 패키지 접두어가 없는 내부 모듈(`GitIt`, `DesignSystem` 등)도 내부 모듈로 인식해야
  한다. 이 모듈을 import하는 위반이 접두어가 없다는 이유로 빠지면 안 된다.
- 모듈 이름이 조건부 컴파일(`#if`) 안에 있는 `import`도 선언으로 간주한다.
- 주석과 문자열 안의 `import`처럼 보이는 텍스트는 위반이 아니다.
- test target의 의존성도 같은 표를 따른다. 프로덕션 target과 구분해 검사하되 허용
  목록을 완화하지 않는다.
- 설정 파일이 없거나 읽을 수 없으면 통과가 아니라 실패로 처리한다.
- 아키텍처 표의 형식이 바뀌어 대응 검사가 표를 읽지 못하면 통과가 아니라 실패로
  처리한다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: 패키지별 허용 의존성을 기계가 읽을 수 있는 설정 파일 하나에 둔다. 설정은
  패키지 단위로 표현하며 target 단위 예외를 허용하지 않는다.
- **FR-002**: 설정 파일의 내용과 [아키텍처 3.1](../../docs/architecture.md) 표가 1:1로
  대응하는지 검사하고, 어긋나면 실패한다.
- **FR-003**: `sources/Tuist/ProjectDescriptionHelpers/Projects/*ModuleName.swift`가 선언하는
  `.from<패키지>(...)` 의존성이 FR-001 설정에 없는 조합이면 실패한다. 프로덕션 target과
  test target을 구분해 검사하되 허용 조합은 같다.
- **FR-004**: `sources/Projects/<패키지>/**/*.swift`의 `import` 중 프로젝트 내부 모듈을
  가리키는 것이 FR-001 설정에 없는 패키지 조합이면 실패한다. 내부 모듈 이름과 소속
  패키지는 manifest의 모듈 선언에서 유도한다.
- **FR-005**: 패키지 조합은 허용되더라도, 파일이 속한 target의 manifest가 선언하지 않은
  내부 모듈을 import하면 실패한다. 전이 의존으로 우연히 컴파일되는 import를 막기 위한
  규칙이다.
- **FR-006**: 실패 메시지는 위반한 target 또는 파일 이름, 선언 위치, 허용되지 않는
  이유를 포함한다.
- **FR-007**: 검사 도구는 `tools/` 아래에 `bin/` `core/` `config/` `tests/` 구조의 독립
  도구로 둔다. 구조와 의존 방향은
  [셸 스크립트 아키텍처](../../.agents/skills/write-project-scripts/references/architecture.md)를
  따른다.
- **FR-008**: 공개 진입점 경로를 `tools/repository-paths/repository-paths.json`에 등록하고
  호출부는 하드코딩 경로를 쓰지 않는다.
- **FR-009**: 도구의 회귀 테스트를 `tests/`에 두고 `tools/script-tests/bin/run.sh`가
  실행하도록 등록한다. 회귀 테스트는 허용되지 않는 manifest 선언, 허용되지 않는 내부
  import, 표와 설정의 불일치 각각에 대해 검사가 실패하는 것을 확인한다.
- **FR-010**: 도구는 ShellCheck·shfmt 정적 검사를 통과한다.
- **FR-011**: `tools/githooks/pre-commit.d/`에 단계 스크립트를 추가하고 단계 이름을
  pre-commit 진입점의 허용 목록에 등록한다.
- **FR-012**: 검사를 CI 게이트에 등록해, pre-commit 단계 활성화 여부와 무관하게 실행되고
  실패 시 머지가 막힌다.
- **FR-013**: 검사는 빌드를 유발하지 않는 정적 검사로 구현하며 단독 실행 기준 5초를
  넘지 않는다.
- **FR-014**: 도구 도입 시점에 전체 저장소에 대해 검사를 실행해 위반이 0임을 확인한다.
  위반이 남은 상태로 예외 목록을 만들어 통과시키지 않는다.
- **FR-015**: `CompositionAdapter`를 Authentication, LearningProject, Member의 도메인 축으로
  분할한다.
- **FR-016**: 분할 후 Composition의 어느 target도 6개를 초과하는 모듈에 의존하지 않는다.
- **FR-017**: 여러 도메인이 공유하는 조립 요소는 별도의 공용 target에 두되, 그 target은
  Domain·Data 모듈에 의존하지 않는다.
- **FR-018**: `CompositionApp`과 `CompositionShareExtension`은 자신이 실제로 사용하는 분할
  target만 참조한다.
- **FR-019**: 분할 후 `tuist generate`와 전체 공유 scheme Debug 빌드가 성공하고,
  `AllTests` scheme의 target 목록이 분할 결과를 반영한다.

### 핵심 엔터티

- **의존성 규칙 설정**: 패키지 이름과 그 패키지가 참조해도 되는 패키지 목록의 대응.
  아키텍처 3.1 표의 7개 패키지(App, Composition, Feature, Domain, Data, Infrastructure, UI)를
  모두 담는다.
- **모듈 선언**: manifest가 target별로 선언하는 `.from<패키지>(<모듈>)` 항목. 소속 패키지,
  대상 패키지, 대상 모듈, 선언 위치를 갖는다.
- **내부 import**: Swift 파일의 `import <모듈>` 중 대상이 프로젝트 내부 모듈인 것. 소속
  패키지, 대상 패키지, 파일 경로, 줄 번호를 갖는다.
- **위반**: 규칙 설정에 없는 (소속 패키지, 대상 패키지) 조합 하나와 그것을 만든 선언의
  위치.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: 현재 저장소에서 검사가 위반 0으로 통과한다. 예외 목록 항목 수는 0이다.
- **SC-002**: 허용되지 않는 manifest 선언, 허용되지 않는 내부 import, 표와 설정의 불일치
  세 경우 각각에 대해 검사 실패를 확인하는 회귀 테스트가 존재하고 통과한다.
- **SC-003**: 설정 파일이 아키텍처 3.1 표의 7개 패키지를 모두 담는다.
- **SC-004**: 검사의 단독 실행 시간이 5초 이하다.
- **SC-005**: 검사가 CI에서 실행되며, 위반이 있는 pull request에서 게이트가 실패한다.
- **SC-006**: Composition의 target별 의존 모듈 수 최댓값이 12에서 6 이하로 줄어든다.
- **SC-007**: 공용 조립 target의 Domain·Data 모듈 의존 수가 0이다.
- **SC-008**: 분할 후 `tuist generate`와 전체 공유 scheme Debug 빌드가 성공한다.
- **SC-009**: 사용자에게 보이는 앱 동작이 변하지 않는다. 분할 전후로 각 테스트 scheme의
  실패 목록이 늘지 않는다.

## 기준선 측정값

이 명세를 쓰는 시점(`a9021ec`, 명세 030·031·032·033 적용 후)의 실측값이다. 리뷰 문서의
근거 시점(`bee2388`) 이후 값이 바뀌었을 수 있어 다시 셌다.

| 항목 | 값 |
| --- | --- |
| `CompositionAdapter` 의존 모듈 수 | 12 |
| `CompositionApp` 의존 모듈 수 | 9 |
| `CompositionShareExtension` 의존 모듈 수 | 8 |
| Composition target 의존 모듈 수 최댓값 | 12 |
| `Composition/Adapter` 아래 Swift 파일 수 | 26 (Adapters 19, Assemblies 5, Codings 1, Factories 1) |
| 의존성 검사 도구 | 없음 |
| 활성화된 pre-commit 단계 수 | 0 (5개 전부 주석 처리) |

`CompositionAdapter`가 의존하는 12개 모듈은 다음과 같다.

```text
DomainAuthentication, DomainLearningProject, DomainMember,
DataAuthentication, DataLearningProject, DataExternalRepository,
DataLegalConsent, DataMember,
InfrastructureNetworkClient, InfrastructureAuthentication,
InfrastructureStorage, InfrastructureLocalNotification
```

## 범위 밖

- Feature target 분할. 단일 target을 유지한다.
- App이 Domain 타입을 직접 사용하는 것. [아키텍처 3.1](../../docs/architecture.md)과
  [app.md](../../docs/package-rules/app.md)가 명시적으로 허용한다.
- 외부 라이브러리 의존성 정책.
- Domain↔Data 경계 구조 변경.
- pre-commit 단계를 다시 활성화하는 결정. 이 명세는 단계를 등록만 하고, 켜는 시점은
  저장소 관리자의 판단이다.

## 가정

- 검사 도구는 POSIX 셸로 작성한다. 저장소의 기존 검사 도구(`tools/design-rules/`)가
  같은 구조와 언어를 쓰고 있고, FR-007이 그 아키텍처 문서를 따르라고 지정한다.
- 아키텍처 3.1 표는 현재의 마크다운 표 형식을 유지한다. 대응 검사는 그 표를 읽는다.
- 모듈이 속한 패키지는 이름 접두어로 판별하지 않는다. App의 `GitIt`·`ShareExtension`과
  UI의 `DesignSystem`·`notoSansKR`·`plusJakartaSans`처럼 접두어가 없는 모듈이 있기
  때문이다. 모듈의 소속은 그 모듈을 선언한 `<패키지>ModuleName.swift` 파일로 판별한다.
- `CompositionAdapter` 분할의 도메인 축은 리뷰 문서가 지정한 Authentication,
  LearningProject, Member 셋이다. `ExternalRepository`와 생성 리마인드 관련 조립을 어느
  축에 둘지는 계획 단계에서 6개 이하 제약과 함께 결정한다.
- CI 게이트 등록 방식은 기존 `tools/ci/bin/gate-evaluate.sh`와
  `.github/workflows/ci.yml`의 구조를 따른다.
