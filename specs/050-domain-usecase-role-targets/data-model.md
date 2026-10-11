# 데이터 모델: Domain 패키지 target의 UseCase 역할 기준 재구성

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **조사**: [research.md](./research.md)

이 변경은 런타임 데이터나 Domain 선언의 형태를 바꾸지 않는다. 여기서 모델은 빌드 구조의
엔터티(target, 관심사, 소비 target)와 그 사이의 관계다.

## 엔터티

### 역할 target

Domain 패키지의 빌드 단위다. 속성의 정본은
[Domain 패키지 규칙 — 역할별 타깃 구성](../../docs/package-rules/domain.md#역할별-타깃-구성)이다.

| 속성 | 설명 |
| --- | --- |
| 이름 | `DomainUseCaseInterface`, `DomainUseCaseDependency`, `DomainUseCaseImplementation`, `DomainTests` |
| 소스 루트 | 이름에서 패키지 접두어(와 test target의 `Tests` 접미어)를 뗀 폴더. test target은 `Tests/` |
| 소유하는 선언 | 역할 하나에 해당하는 선언 전체 |
| 허용 import | 아래 "관계"의 방향만 |

### 관심사

하나의 비즈니스 주제에 속한 선언의 묶음이다. `Account`, `AppSetting`, `ExternalRepository`,
`Identifier`, `Project`, `ProjectGeneration`, `QuizDetail`, `UserInfo`의 여덟이다. target을 만들지
않고 각 역할 target의 소스 루트 바로 아래 폴더로 표현된다.

| 관심사 | Interface | Dependency | Implementation | 테스트 |
| --- | --- | --- | --- | --- |
| `Account` | 17 | 4 | 1 | 7 |
| `AppSetting` | 7 | 3 | 1 | 3 |
| `ExternalRepository` | 4 | 2 | 1 | 3 |
| `Identifier` | 4 | — | — | 1 |
| `Project` | 10 | 1 | 1 | 2 |
| `ProjectGeneration` | 12 | 3 | 1 | 8 |
| `QuizDetail` | 17 | 3 | 1 | 5 |
| `UserInfo` | 9 | 1 | 1 | 2 |
| 합계 | 80 | 17 | 7 | 31 |

숫자는 Swift 파일 수다. `Identifier`는 식별자 `typealias`만 가지며 재구성 뒤에도
`UseCaseInterface/Identifier/Models/`에 식별자 외의 선언을 두지 않는다.

### 선언

Domain production의 최상위 선언이다. 형태 폴더가 역할을 정한다.

| 형태 폴더 | 선언 | 역할 target |
| --- | --- | --- |
| `Models/` | 모델, Value Object, 식별자 | `DomainUseCaseInterface` |
| `Errors/` | Domain 오류 | `DomainUseCaseInterface` |
| `UseCases/` 중 `protocol` | UseCase 계약 | `DomainUseCaseInterface` |
| `Contracts/` | 주입 계약 | `DomainUseCaseDependency` |
| `UseCases/` 중 `actor`·`struct` | UseCase 계약의 구현 | `DomainUseCaseImplementation` |

### 소비 target

Domain 역할 target에 의존을 선언하는 App·Composition·Feature의 target이다. target별 선언은
[contracts/domain-targets.md](./contracts/domain-targets.md#소비-target의-의존-선언)에 있다.

## 관계

```text
DomainUseCaseImplementation ──▶ DomainUseCaseDependency ──▶ DomainUseCaseInterface
            │                                                        ▲
            └────────────────────────────────────────────────────────┘

DomainTests ──▶ 위 세 target
```

- `DomainUseCaseInterface`는 다른 Domain target을 import하지 않는다.
- `DomainUseCaseDependency`는 `DomainUseCaseInterface`만 import한다.
- 소비 target → 역할 target: Feature와 App은 `DomainUseCaseImplementation`을 import하지 않는다.
  구현을 생성하는 곳은 Composition뿐이다.
- 관심사 사이의 import 제한은 없어진다. 한 모듈 안에서 모든 관심사가 서로 보이므로, 같은 개념을 두
  관심사가 각자 자기 모델로 소유하고 식별자만 공유한다는 규칙은 target 경계가 아니라
  [Domain 패키지 규칙](../../docs/package-rules/domain.md)과 리뷰가 지킨다.

## 검증 규칙

| 규칙 | 근거 | 확인 |
| --- | --- | --- |
| 모든 production 선언은 역할 target 하나에만 속한다 | FR-004 | 옮긴 뒤 옛 관심사 폴더가 비어 있고 `Domain/` 바로 아래에 역할 폴더 셋과 `Tests/`만 있다 |
| 한 target 안의 최상위 타입 이름은 유일하다 | FR-014 | production 충돌 0건, 테스트 충돌 0건([research.md R-03](./research.md#r-03-명세-전제의-검증), [R-10](./research.md#r-10-여덟-test-target을-하나로-합칠-때의-이름-충돌)) |
| 관심사 폴더 아래 구조는 `<형태>/[<타입 패밀리>/]`다 | FR-006 | 옮긴 뒤 관심사 세그먼트 아래 폴더 뎁스 2 이하 |
| 선언의 이름·시그니처·동작은 바뀌지 않는다 | FR-007 | Domain production diff가 경로 이동과 import 줄뿐이다 |

## 상태 전이

런타임 상태는 없다. 저장소 구조의 상태만 있다.

| 상태 | Domain target | 규칙 문서 | 비고 |
| --- | --- | --- | --- |
| 기준선 이전 | 관심사별 16개 | 관심사별 target 규정 | `a4cc97c` |
| U0 완료(현재) | 관심사별 16개 | 역할별 target 규정 | `4d13a76`, `2c3ca6e`. 기능 브랜치 안에서만 허용하는 불일치 |
| U1 완료 | 역할별 4개 | 역할별 target 규정 | 문서와 구조가 일치한다(FR-019) |
