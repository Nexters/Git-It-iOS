# 조사: Domain 패키지 target의 UseCase 역할 기준 재구성

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **기준 커밋**: `2c3ca6e`

이 문서는 계획 단계의 결정과 근거를 기록한다. 수치는 기준 커밋의 작업 트리에서 읽기 전용으로
계산했다. Swift 소스는 기준 커밋과 그 조상 `a4cc97c` 사이에 차이가 없다.

## R-01 역할 target 이름과 소스 루트

- **결정**: [Domain 패키지 규칙 — 역할별 타깃 구성](../../docs/package-rules/domain.md#역할별-타깃-구성)의
  표를 그대로 쓴다. `DomainUseCaseInterface`(`UseCaseInterface/`),
  `DomainUseCaseDependency`(`UseCaseDependency/`),
  `DomainUseCaseImplementation`(`UseCaseImplementation/`), `DomainTests`(`Tests/`).
- **근거**: 규칙 문서가 코드보다 먼저 확정됐고(FR-017) 구조는 그 문서와 일치해야 한다(FR-019).
  [Tuist 매니페스트와의 일치](../../docs/conventions/directory-file/tuist-manifest.md)는
  `sourceDirectory`를 target 이름에서 패키지 접두어를 떼어 계산하도록 한다. 네 이름 모두 이 계산으로
  표의 소스 루트가 나온다. `DomainTests`는 접두어와 `Tests` 접미어를 떼면 빈 문자열이 되고
  `Target.testModule`이 이를 `Tests`로 바꾼다. `FeatureTests`가 같은 방식이다.
- **검토한 대안**: `DomainUseCaseTests` + `Tests/` — 이름에서 계산한 경로가 `Tests/UseCase`여서
  매니페스트에 특수 분기가 필요하다. `DomainUseCaseTests` + `Tests/UseCase/` — 테스트 파일 31개를
  옮겨야 한다. 사용자가 `DomainTests` + `Tests/`로 결정했다(2026-10-05).

## R-02 선언의 역할 배정

- **결정**: 현재 형태 폴더로 배정한다. `sources/Projects/Domain/` 기준이다.

| 기존 경로 | 새 경로 | 파일 수 |
| --- | --- | --- |
| `<관심사>/Models/**` | `UseCaseInterface/<관심사>/Models/**` | 66 |
| `<관심사>/Errors/**` | `UseCaseInterface/<관심사>/Errors/**` | 7 |
| `<관심사>/UseCases/*UseCase.swift` | `UseCaseInterface/<관심사>/UseCases/` | 7 |
| `<관심사>/Contracts/**` | `UseCaseDependency/<관심사>/Contracts/**` | 17 |
| `<관심사>/UseCases/`의 나머지 | `UseCaseImplementation/<관심사>/UseCases/` | 7 |
| `Tests/**` | 이동 없음 | 31 |

- **근거**: `UseCases/`의 `*UseCase.swift` 7개는 각각 `protocol` 하나만 선언하고, 나머지 7개
  (`Account`, `AppSetting`, `ExternalRepositoryResolver`, `Project`, `ProjectGeneration`, `QuizDetail`,
  `UserInfo`)는 `actor` 또는 `struct` 하나를 선언한다. production 104개 파일 모두 최상위 선언이
  하나 이상 있고, 이 기준으로 역할이 정해지지 않는 파일은 없다. 관심사는 `Account`, `AppSetting`,
  `ExternalRepository`, `Identifier`, `Project`, `ProjectGeneration`, `QuizDetail`, `UserInfo`의
  여덟이고 `Identifier`는 `Models/`만 가진다.
- 관심사 아래 구조(`<형태>/[<타입 패밀리>/]`)는 그대로 옮긴다. 옮긴 뒤에도 소스 루트 아래 관심사
  세그먼트를 뺀 폴더 뎁스가 2를 넘는 파일은 없다.

## R-03 명세 전제의 검증

명세 가정의 전제 여섯 개를 기준 커밋에서 확인했다.

| 전제 | 결과 | 확인 방법 |
| --- | --- | --- |
| 최상위 타입 이름이 관심사 사이에 충돌하지 않는다 | 충돌 0건 | production 104개 파일의 최상위 `struct`·`class`·`enum`·`actor`·`protocol`·`typealias` 이름 대조 |
| 모델·오류와 UseCase 계약이 주입 계약의 타입을 참조하지 않는다 | 참조 0건 | 역할별로 파일이 이름으로 참조하는 Domain 최상위 타입의 역할을 집계. Interface → Dependency, Interface → Implementation, Dependency → Implementation 방향이 모두 0건 |
| 역할 경계를 넘는 `internal` 접근이 없다 | 최상위 선언은 전부 `public`. 멤버 수준은 U1의 build-for-testing으로 확정 | 최상위 선언의 접근 수준 대조 |
| Feature의 공유 등록 흐름이 주입 계약 하나를 직접 쓴다 | `ExternalRepositoryLocator` 하나. production 2개, 테스트 대역 1개 파일 | R-06의 import 계산 |
| Composition의 모듈 한정 Domain 참조가 7곳이다 | 7곳, 파일 3개 | `Domain<모듈>.<타입>` 형태 검색 |
| Data·Infrastructure·UI는 Domain 모듈을 import하지 않는다 | import 0건 | Domain import가 있는 파일의 패키지 집계 |

허용 방향의 참조는 Dependency → Interface 16개 파일, Implementation → Interface 7개 파일,
Implementation → Dependency 7개 파일이다. FR-005의 허용 의존과 일치한다.

## R-04 실행 단위

- **결정**: 실행 단위는 둘이다. U0(규칙 문서 개정)은 이미 끝났다. U1은 파일 이동, Tuist 매니페스트,
  모든 import 갱신과 검사 설정 갱신을 하나로 묶은 다중 패키지 integration unit이다.
- **U0의 근거**: 커밋 `4d13a76`과 `2c3ca6e`가 규칙 문서 다섯 개만 바꿨다(`2c3ca6e`는 이 기능의
  `spec.md` 가정도 함께 정정했다). 두 커밋의 pre-commit에서 프로젝트 셸 회귀 테스트와 패키지
  의존성 검사(target 59, 위반 0)가 통과했다. FR-017·FR-018과 SC-009를 충족한다.
- **U1을 나눌 수 없는 이유**: 옛 target을 지우면 그 모듈을 import하는 모든 파일이 compile되지
  않고, 새 target을 선언하려면 소스가 새 소스 루트에 있어야 한다.
  `.tools/package-dependencies/config/source-roots`는 매니페스트와 1:1이 아니면 의존성 검사가
  실패한다. 목적은 "Domain target 재구성" 하나다.
- **검토한 대안**: 역할별 단계 이전 — 각 단계가 여전히 Domain·Composition·Feature·App을 함께 바꾸고
  같은 파일의 import를 여러 번 고치며, 관심사 target과 역할 target이 섞인 중간 배치는 어떤 규칙
  문서도 설명하지 않는다. 새 target을 나란히 추가한 뒤 전환 — 같은 타입이 두 모듈에 존재해 두
  모듈을 함께 보는 파일에서 이름이 모호해진다.
  [Constitution 원칙 7](../../.specify/memory/constitution.md)의 제거 예외 — 이 변경은 선언 제거가
  아니라 이동이므로 해당하지 않는다.

## R-05 import 갱신 규칙

- **결정**: 파일이 이름으로 참조하는 Domain 최상위 타입이 속한 역할 모듈만 import한다. 기존 Domain
  import는 모두 지운다. 같은 모듈 안의 타입을 위한 import는 두지 않는다.
- **`@testable`**: 원래 `@testable import`였던 파일은 `DomainUseCaseInterface`와
  `DomainUseCaseImplementation`을 `@testable`로, `DomainUseCaseDependency`를 일반 import로 둔다.
  `DomainUseCaseDependency`는 `public` 프로토콜과 그 보조 선언만 가진다. 원래 `@testable`이었던
  파일은 Domain 테스트 30개와 Composition 테스트 13개다.
- **정렬**: import 블록은 기존 관행(일반 import 알파벳순, 그 뒤 `@testable` 알파벳순)을 유지한다.
- **계산 방법**: 주석과 문자열 리터럴을 제거한 본문에서 대문자로 시작하고 앞에 `.`이 없는 식별자를
  뽑아 R-02의 타입 색인과 대조한다. 모듈 한정 참조(`Domain<모듈>.<타입>`)는 `<타입>`의 참조로 센다.
- **규모**: import가 바뀌는 Swift 파일은 278개다.

| 범위 | 파일 수 | 내용 |
| --- | --- | --- |
| Domain production — Interface | 23 | 기존 Domain import 삭제(같은 모듈이 됨) |
| Domain production — Dependency | 16 | `import DomainUseCaseInterface` (기존 import가 있던 파일 5, 없던 파일 11) |
| Domain production — Implementation | 7 | `DomainUseCaseInterface`, `DomainUseCaseDependency` (기존 import가 있던 파일 4, 없던 파일 3) |
| Domain 테스트 | 30 | 역할 모듈로 교체 |
| Composition production / 테스트 | 24 / 14 | 역할 모듈로 교체 |
| Feature production / 테스트 | 72 / 74 | 역할 모듈로 교체 |
| App production / 테스트 | 5 / 13 | 역할 모듈로 교체 |

- 내용이 바뀌지 않고 경로만 옮겨지는 Domain production 파일은 58개다(Interface 57, Dependency 1).
- import를 지운 뒤 Domain import가 하나도 남지 않는 소비 파일은 26개다(App production 2, App 테스트
  4, Composition 테스트 1, Feature production 4, Feature 테스트 15). Domain 타입을 이름으로 쓰지
  않고 추론된 값의 멤버만 쓰거나 기존 import가 쓰이지 않던 파일이다. 이 파일들에서 compile 오류가
  나면 오류가 가리키는 타입의 역할 모듈만 import한다.
- 모듈 한정 참조 7곳의 치환은 [contracts/domain-targets.md](./contracts/domain-targets.md#모듈-한정-참조)에
  있다.

## R-06 소비 target의 Domain 의존 선언

실제 import를 기준으로 선언한다. 전체 표는
[contracts/domain-targets.md](./contracts/domain-targets.md#소비-target의-의존-선언)에 있다.

- Feature가 `DomainUseCaseDependency`에 의존하는 이유는 공유 등록 흐름
  (`ShareRegistrationFeature`, `SharedRepositoryRegistrationFeature`)과 테스트 대역
  `StubRepositoryURLParser`가 주입 계약 `ExternalRepositoryLocator`를 직접 쓰기 때문이다. FR-010에
  따라 그대로 둔다.
- `ShareExtension` target은 Domain 타입을 이름으로 참조하지 않는다. `ShareViewController.swift`의
  `import DomainAccount`는 쓰이지 않는다. import가 남지 않으므로 Domain 의존을 선언하지 않는다
  (FR-008). 이 제거는 U1의 App scheme build로 검증한다. build가 실패하면 필요한 역할 target만
  선언하고 해당 import를 추가한다.
- `GitItTests`는 지금처럼 자기 블록에 Domain 의존을 직접 선언한다. `FeatureTests`와 Composition
  test target은 지금처럼 production target을 통해 Domain 모듈을 보고 별도 Domain 의존을 선언하지
  않는다. 패키지 의존성 검사는 test target이 `productionTarget`의 선언을 물려받는 것으로 판정한다.
- Feature와 App의 어떤 target도 `DomainUseCaseImplementation`을 import하지 않는다(FR-009). 구현을
  import하는 곳은 Composition의 `CompositionLearningProject`(2개 파일), `CompositionMember`(1개),
  `CompositionApp`(1개)뿐이다.
- [Composition 패키지 규칙](../../docs/package-rules/composition.md)의 "다른 패키지 모듈 의존 6개
  이하"는 기준 커밋에서 네 target이 넘는다. 재구성으로 Domain 선언 수가 줄어 초과 target이 넷에서
  셋으로 줄고 늘어나는 target은 없다. 남는 초과는 Data 모듈 선언 수에서 오며 이 명세의 범위
  밖이다.

| Composition target | 기준 | 재구성 뒤 |
| --- | --- | --- |
| `CompositionAuthentication` | 5 | 5 |
| `CompositionLearningProject` | 10 | 7 |
| `CompositionMember` | 7 | 6 |
| `CompositionApp` | 15 | 9 |
| `CompositionShareExtension` | 9 | 7 |

## R-07 접근 수준

- **결정**: 접근 수준을 바꾸지 않는다.
- **근거**: Domain production의 최상위 선언은 전부 `public`이다. 역할 경계는 기존 형태 폴더 경계와
  같아서, 한 관심사 안에서 형태 폴더를 넘어 `internal` 멤버를 쓰는 곳이 있을 때만 문제가 된다.
  U1의 build-for-testing에서 예외가 발견되면 FR-007에 따라 해당 선언에 한해 접근 수준을 넓히고
  선언 목록과 이유를 PR에 기록한다.
- **검토한 대안**: Data처럼 `-package-name`을 주고 `package` 접근 수준을 쓰는 방법. 필요한 선언이
  확인되지 않아 도입하지 않는다.

## R-08 검사 도구와의 호환

- `.tools/package-dependencies/core/manifest.sh`는 `<패키지>ModuleName` enum의 case, target switch의
  `case .<target>:` 블록, `.target(name: …ModuleName.<m>.rawValue)`와 `.from<패키지>(.<m>)` 선언을
  읽는다. 새 매니페스트는 같은 형식을 유지한다.
- `.tools/package-dependencies/config/source-roots`의 Domain 16행을 4행으로 바꾼다. Swift 파일은
  접두어가 일치하는 가장 긴 루트에 속하므로 `Domain/Tests`와 `Domain/UseCase…` 사이에 모호함이 없다.
- `.tools/script-tests/core/testable-schemes.sh`는 `sourceDirectory`를 연산 프로퍼티로 넘긴 test
  target의 경로를 target 이름에서 계산하고 `DomainTests`를 `Tests`로 해석한다. 도구를 고치지 않는다.
- `.tools/package-dependencies/tests/`와 `.tools/script-tests/tests/`의 fixture는 가상의 target
  이름을 쓰므로 고치지 않는다.
- 옛 Domain target 이름이 남는 곳은 Swift 소스 밖에서 일곱 파일이다. Tuist 매니페스트 여섯 개와
  `source-roots`이며 모두 U1이 고친다. `.github/`, `Makefile`, `.tools/`의 스크립트에는 없다.

## R-09 테스트 수 기준선

- **결정**: U1 시작 전에 `@Test` 선언 수를 test 소스 루트별로 세어 기준선으로 삼고, 재구성 뒤 같은
  수가 나오는지와 전체 test가 통과하는지로 SC-002를 판정한다.
- **기준선**: Domain 129(Account 24, AppSetting 4, ExternalRepository 2, Identifier 1, Project 19,
  ProjectGeneration 66, QuizDetail 9, UserInfo 4), Feature 421, Composition 59, App 70, Data 195,
  Infrastructure 59, UI 126.
- **근거**: 테스트 파일은 import만 바뀌고 옮기지 않으므로 선언 수가 같으면 실행 대상이 같다. 여덟
  test target이 하나로 합쳐지지만 모든 파일이 `Tests/**` 아래에 그대로 있어 scheme에서 빠지는
  테스트가 없다. Domain scheme의 실행 테스트 수는 재구성 뒤 test 로그의 합계가 129 이상인지로
  확인한다(매개변수 테스트는 선언 하나가 여러 번 실행된다).
- **검토한 대안**: 기준 커밋에서 전체 test를 한 번 더 실행해 실행 수를 직접 비교. 정확하지만 전체
  실행을 한 번 더 요구한다. 구현 단계에서 시간이 허용하면 추가 근거로 실행할 수 있다.

## R-10 여덟 test target을 하나로 합칠 때의 이름 충돌

- **결정**: 테스트 선언의 이름을 바꾸지 않는다.
- **근거**: 지금은 관심사마다 test target이 달라 같은 이름의 테스트 타입이나 Test Double이 있어도
  compile되지만, 하나의 `DomainTests` 모듈이 되면 충돌한다. 기준 커밋의 `Tests/**` 31개 파일을
  대조한 결과 둘 이상의 관심사가 선언한 모듈 범위 최상위 이름은 0건이고, 같은 파일 이름이나 같은
  타입에 대한 extension이 관심사 사이에 겹치는 곳도 없다.
- U1의 build-for-testing에서 충돌이 발견되면 구현을 중단하고 해소 방법을 사용자에게 확인한다.
  명세는 테스트 내용을 바꾸지 않는다고 가정하므로 이름 변경은 범위 확대다.
