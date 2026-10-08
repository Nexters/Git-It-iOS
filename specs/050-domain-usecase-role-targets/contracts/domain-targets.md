# 계약: Domain 역할 target과 소비 target의 의존 선언

**기능**: [spec.md](../spec.md) | **계획**: [plan.md](../plan.md) | **조사**: [research.md](../research.md)

이 문서는 재구성 뒤 빌드 그래프가 지켜야 하는 계약이다. target의 목록·소유·허용 import의 정본은
[Domain 패키지 규칙 — 역할별 타깃 구성](../../../docs/package-rules/domain.md#역할별-타깃-구성)이고,
이 문서는 그 표를 매니페스트와 소비 target의 선언으로 옮긴 결과만 적는다.

## Domain target 선언

`sources/Tuist/ProjectDescriptionHelpers/Projects/DomainModuleName.swift`의 `DomainModuleName`은 아래
네 case만 가진다.

| case | 종류 | `sourceDirectory` 계산 결과 | 선언하는 의존 |
| --- | --- | --- | --- |
| `DomainUseCaseInterface` | `Target.module` | `UseCaseInterface` | 없음 |
| `DomainUseCaseDependency` | `Target.module` | `UseCaseDependency` | `.target` `DomainUseCaseInterface` |
| `DomainUseCaseImplementation` | `Target.module` | `UseCaseImplementation` | `.target` `DomainUseCaseInterface`, `DomainUseCaseDependency` |
| `DomainTests` | `Target.testModule` | 빈 문자열(→ `Tests`) | `productionTarget` `DomainUseCaseImplementation`, 추가 의존 `DomainUseCaseInterface`, `DomainUseCaseDependency` |

- `sourceDirectory`는 지금처럼 `rawValue`에서 패키지 접두어를 뗀 값이고, test target은 거기서
  `Tests` 접미어를 뗀다. 문자열 리터럴 경로를 쓰지 않는다.
- `fromDomain(_:)`의 형식은 그대로 둔다.

## scheme

| 선언 위치 | 재구성 뒤 |
| --- | --- |
| `ProjectName.swift`의 Domain `.package` scheme | `buildTargets`는 production 세 target, `testTargets`는 `DomainTests` |
| `AllTestsScheme.swift` | Domain 항목 여덟 개를 `DomainTests` 하나로 교체 |

Domain 공유 scheme은 하나로 유지한다(FR-012).

## 소비 target의 의존 선언

`I` = `DomainUseCaseInterface`, `D` = `DomainUseCaseDependency`, `M` = `DomainUseCaseImplementation`.
괄호 안은 그 모듈을 import하는 파일 수다.

| 매니페스트 | target | 기준 Domain 선언 수 | 재구성 뒤 선언 |
| --- | --- | --- | --- |
| `AppModuleName.swift` | `GitIt` | 8 | `I`(3) |
| | `GitItTests` | 8 | `I`(9) |
| | `ShareExtension` | 4 | 없음 |
| `FeatureModuleName.swift` | `Feature` | 8 | `I`(68), `D`(2) |
| `CompositionModuleName.swift` | `CompositionAuthentication` | 2 | `I`(4), `D`(3) |
| | `CompositionLearningProject` | 6 | `I`(12), `D`(11), `M`(2) |
| | `CompositionMember` | 4 | `I`(5), `D`(4), `M`(1) |
| | `CompositionApp` | 8 | `I`(2), `M`(1) |
| | `CompositionShareExtension` | 4 | `I`(1), `D`(1) |

- `FeatureTests`와 Composition test target은 Domain 의존을 직접 선언하지 않고 `productionTarget`의
  선언을 물려받는다. 각 test target이 import하는 역할 모듈은 모두 자기 production target의 선언
  안에 있다(`FeatureTests`: `I` 59, `D` 1 / `CompositionLearningProjectTests`: `I` 9, `D` 1 / 나머지
  Composition test target: `I`만).
- Feature와 App의 target은 `M`을 선언하지 않는다(FR-009, SC-005).
- 선언과 실제 import는 1:1이다. 위 표에 없는 역할 모듈을 import하는 파일은 없다(FR-008).

## 모듈 한정 참조

| 파일 (`sources/Projects/Composition/` 기준) | 기존 | 재구성 뒤 |
| --- | --- | --- |
| `Authentication/Adapters/AuthenticationRepositoryAdapter.swift` | `DomainAccount.AuthenticationRepository` | `DomainUseCaseDependency.AuthenticationRepository` |
| `LearningProject/Adapters/ExternalRepositoryLocatorAdapter.swift` | `DomainExternalRepository.ExternalRepositoryLocator` | `DomainUseCaseDependency.ExternalRepositoryLocator` |
| | `DomainExternalRepository.ExternalRepositoryLocation` (2곳) | `DomainUseCaseInterface.ExternalRepositoryLocation` |
| `LearningProject/Adapters/ExternalRepositoryLookupAdapter.swift` | `DomainExternalRepository.ExternalRepositoryLookup` | `DomainUseCaseDependency.ExternalRepositoryLookup` |
| | `DomainExternalRepository.ExternalRepository` (2곳) | `DomainUseCaseInterface.ExternalRepository` |

한정이 필요한 이유(다른 패키지의 같은 이름 타입과의 구분)는 그대로다.

## 검사 설정

`.tools/package-dependencies/config/source-roots`의 Domain 행은 아래 넷이다.

```text
DomainUseCaseInterface Domain/UseCaseInterface
DomainUseCaseDependency Domain/UseCaseDependency
DomainUseCaseImplementation Domain/UseCaseImplementation
DomainTests Domain/Tests
```

`.tools/package-dependencies/config/allowed-dependencies`는 패키지 단위 표이므로 바꾸지 않는다.

## 계약 검증

| 계약 | 검증 |
| --- | --- |
| Domain target이 넷이다 | `DomainModuleName`의 case 수, `source-roots`의 Domain 행 수 |
| target 사이 의존이 표와 같다 | 패키지 의존성 검사 위반 0건, 전체 build 통과 |
| 소비 target의 선언이 표와 같다 | 세 매니페스트의 `.fromDomain(…)` 선언 대조, 패키지 의존성 검사 |
| 옛 target 이름이 남지 않는다 | Swift 소스, Tuist 매니페스트, `source-roots`, 현행 규칙 문서 검색 0건 |
