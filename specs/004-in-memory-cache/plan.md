# 구현 계획: InMemoryCache

**Git-flow 유형**: `feature`

**브랜치**: `feature/in-memory-cache`

**날짜**: 2026-08-15 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/004-in-memory-cache/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

Infrastructure 패키지에 키-값을 프로세스 메모리 범위에서만 보관하는 범용 기술 API
`InMemoryCache<Key, Value>`를 추가한다. 저장·조회·개별 제거·전체 비우기 네 가지 연산만
제공하며, TTL·용량 제한·영속화는 범위 밖으로 둔다(spec.md `범위 밖`). 동시 접근 안전성은
Swift `actor`로 보장해 별도 lock 코드 없이 최소 구현으로 명세를 충족한다(research.md §1).
기존 `InfrastructureAuthentication`, `InfrastructureNetworkClient`와 같은 패턴으로 새
target `InfrastructureCache`를 추가한다(research.md §5).

## 기술 맥락

**언어/버전**: Swift(target `SWIFT_VERSION` 5.0, Swift Concurrency·`Sendable` 사용)

**주요 의존성**: Swift 표준 라이브러리(`Dictionary`)만 사용한다. 외부 패키지 의존성 없음(research.md §4).

**저장소**: N/A — 프로세스 메모리 범위에서만 값을 보관하며 디스크 등 영속 저장소를 사용하지 않는다(FR-009).

**테스트**: Swift Testing(`import Testing`, `@Suite`, `@Test`) — 기존 `InfrastructureNetworkClientTests`와 동일한 프레임워크(`sources/Projects/Infrastructure/NetworkClientTests/ConcurrencyIsolationTests.swift`).

**대상 플랫폼**: iOS 26.0+ (기존 Infrastructure target과 동일한 `deploymentTargets`)

**프로젝트 유형**: Tuist 다중 모듈 iOS 앱의 내부 기술 라이브러리 target(모바일 앱, `sources/Projects/Infrastructure/`)

**성능 목표**: 별도의 처리량·지연 목표는 없다. 핵심 목표는 동시 접근에서도 값이 손상·유실되지 않는 정확성이다(FR-008, SC-004).

**제약 조건**: 프로젝트 내부의 다른 패키지(Domain, Data 등)에 의존하지 않는다(FR-011). 값의 형태를 특정 Data 모델·DTO에 종속시키지 않는다(FR-010).

**규모/범위**: 공개 타입 1개(`InMemoryCache<Key, Value>`), 공개 연산 4개(저장·조회·제거·전체 비우기). Infrastructure 패키지에 새 target 1개 추가(contracts/in-memory-cache-api.md).

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

- **명시적인 경계(원칙 1)**: `InfrastructureCache`는 프로젝트 내부 다른 패키지에 의존하지
  않는다(FR-011). Infrastructure 규칙의 "target 하나당 범용 기술 기능 하나"에 따라 기존
  `InfrastructureAuthentication`, `InfrastructureNetworkClient`와 분리한다(research.md
  §5). 순환 의존은 발생하지 않는다. **통과**.
- **상태와 데이터 안전성(원칙 2)**: 유일한 가변 상태(`Dictionary`)는 `actor` 안에만
  존재하고 소유자와 격리 범위가 명확하다(research.md §1, data-model.md). 이 기능에는
  비동기 오류 경로가 없다 — 값 없음과 존재하지 않는 키 제거는 오류가 아니라 정상 흐름으로
  정의했다(FR-003, FR-007). 저장하는 값의 개인정보 여부는 사용하는 쪽이 판단할 책임이며
  Infrastructure는 값의 내용을 해석하지 않는다(FR-010). **통과**.
- **검증 가능한 변경(원칙 3)**: 동작 검증은 `InfrastructureCacheTests`와
  quickstart.md의 A~C 시나리오로 남긴다. 계획 단계에서 Git index나 작업 파일을 바꾸는
  명령을 실행하지 않았다. **통과**.
- **스킬별 수정 경로(원칙 4·5)**: 이 명령은 `specs/004-in-memory-cache/`의 `plan.md`,
  `research.md`, `data-model.md`, `quickstart.md`, `contracts/**`만 만들었다.
  `sources/**`와 Tuist 설정은 아래 "프로젝트 구조"에 경로만 기록하고 `tasks.md`가 실제
  변경을 배정한다. **통과**.
- **패키지 단위 구현 진행(원칙 7)**: 아래 "패키지 진행" 참조. 적용 대상 패키지는
  `Infrastructure` 하나다. **통과**.
- **한국어 Spec-Kit 산출물(원칙 6)**: 이 문서를 포함한 모든 계획 산출물을 한국어로
  작성했다. Swift 식별자, 명령어, 파일 경로만 원문을 유지한다. **통과**.
- **Git-flow 브랜치 네임스페이스(원칙 8)**: 등록된 `before_specify`/`before_plan` 훅이
  없어 명세·계획 단계에서는 브랜치를 자동 생성하지 않았고, 이후 사용자 요청에 따라
  `develop`에서 `feature/in-memory-cache` 브랜치를 수동으로 생성했다. `feature/`
  네임스페이스, kebab-case 접미사, 추가 `/` 없음 요건을 모두 만족한다. spec 디렉터리
  이름 `004-in-memory-cache`는 브랜치 이름과 독립적으로 유지한다. **통과**.
- **책임과 문맥에 따른 네이밍(원칙 10)**: 아래 "책임 기반 네이밍" 참조. **통과**.

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. 생성 훅이 실행되지 않았다면 실제 브랜치가
생성된 것처럼 기록하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 실제 문제가 발생하면 `/speckit-troubleshooting`, 여러 세션의 독립
근거에서 암묵적인 판단 기준을 해석하면 `/speckit-tacit-knowledge`가 각 전용 파일에
append-only로 기록한다. 두 파일은 계획 산출물이나 구현 작업이 아니며 조건을 충족하지
않으면 빈 파일을 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다. `sources/docs/naming.md`가 없으면
Constitution 원칙 10을 직접 적용하고, 문서가 작성된 뒤에는 세부 기준과 예외를 함께 참조한다.

이 기능에 적용한 판단은 다음과 같다([네이밍 가이드](../../sources/docs/naming.md) 기준).

| 결정 | 근거 |
| --- | --- |
| target 이름을 `InfrastructureCache`(소스 디렉터리 `Cache/`)로 함 | 범용 기술 기능(메모리 저장) 하나를 독립 target으로 제공하는 기존 패턴과 일치한다. naming.md "Target과 소스 폴더" 절 |
| 공개 타입 이름을 `InMemoryCache`로 하고 `Infrastructure` 접두어를 붙이지 않음 | Infrastructure는 감싸는 대상 기술을 직접 표현하는 경계이므로 저장 기술 용어(In-Memory)를 노출하는 것이 허용된다(naming.md §7: "특정 공급자나 기술 용어는 그 대상을 직접 감싸는 Infrastructure API … 책임상 필요한 경계에만 둔다"). `Infrastructure` 접두어는 패키지 이름 반복이라 §5가 금지한다 |
| 연산 이름을 `store(_:forKey:)`, `value(forKey:)`, `removeValue(forKey:)`, `removeAll()`로 함 | Swift 표준 라이브러리 `Dictionary`의 관용 이름과 맞춰 사용하는 개발자가 별도 학습 없이 동작을 예측할 수 있게 한다. §3.3(대상과 효과를 감추는 일반 동사는 더 구체적인 동사로 대체) |
| 별도 오류 타입을 만들지 않고 값 없음을 `nil`로 표현 | FR-003이 "오류 없이" 값 없음을 요구한다. 오류 타입을 추가하면 명세가 요구하지 않는 타입이 늘어난다(§2.1) |
| 제네릭 매개변수명을 `Key`, `Value`로 하고 `CacheKey`처럼 반복 수식어를 붙이지 않음 | 타입 이름 `InMemoryCache` 자체가 이미 캐시 문맥을 제공하므로 매개변수에 같은 문맥을 반복할 필요가 없다. §2.2 |

**패키지 진행**: 현재 명세가 변경하는 패키지를 식별하고 `Domain → Data → Infrastructure →
Composition → UI → Feature → App` 순서로 구현 경계를 계획한다. 적용되지 않는 패키지는
건너뛰며, 각 적용 대상 패키지는 구현·검증·결과 보고·사용자 승인 후에만 다음 패키지로
진행한다. 공용 구성 파일이 여러 패키지 선언을 바꿔야 하면 패키지별 작업으로 분리하고 각
변경을 해당 패키지 단계에 배치한다. 패키지에 속하지 않는 파일 변경은 그 변경을 최초로
필요로 하는 책임 패키지에 명시적으로 배정하며, 배정할 수 없으면 계획을 중단하고 경계를
명확히 한다.

**이 기능의 적용 대상 패키지는 `Infrastructure` 하나다.**

| 패키지 | 적용 | 근거 |
| --- | --- | --- |
| Domain | 제외 | 비즈니스 모델·정책을 바꾸지 않는다 |
| Data | 제외 | DTO·Data 계약을 정의하지 않는다(FR-010, FR-011) |
| **Infrastructure** | **적용** | 범용 기술 API(`InMemoryCache`) 신설. 이 명세의 전부 |
| Composition | 제외 | Data↔Infrastructure Adapter 구현은 범위 밖("Data가 정의한 캐시 관련 계약의 구현이나 Composition의 Data↔Infrastructure Adapter 작성") |
| UI / Feature / App | 제외 | 화면·상태·흐름을 바꾸지 않는다 |

따라서 `tasks.md`는 **Infrastructure 단계 하나**만 정의하고, 그 단계 끝에 검증·결과
보고·사용자 승인 게이트를 둔다. 다음 적용 대상 패키지가 없으므로 순서 위반 가능성 자체가
없다.

**패키지에 속하지 않는 파일의 배정**: 아래 두 Tuist 설정 파일은 `sources/Projects/<패키지>`
밖에 있지만, 이 변경을 최초로 필요로 하는 책임 패키지는 `Infrastructure`다. 두 파일 모두
`Infrastructure` 단계에 배정한다.

| 파일 | 변경 내용 | 배정 |
| --- | --- | --- |
| `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift` | `InfrastructureCache`·`InfrastructureCacheTests` 케이스와 target 정의 추가 | Infrastructure 단계 |
| `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift` | `case .Infrastructure`의 scheme 목록에 `InfrastructureCache` scheme 추가 | Infrastructure 단계 |

두 파일의 변경은 모두 `Infrastructure` 프로젝트의 선언만 바꾸며 다른 패키지의 선언을
건드리지 않는다. 따라서 원칙 7이 금지하는 "여러 패키지의 선언을 바꾸는 공용 파일 작업"에
해당하지 않고, 패키지별로 분리할 필요가 없다. 배정 불가로 계획을 중단해야 하는 파일은 없다.

### 1단계 설계 후 재점검

Phase 1 산출물(data-model.md, contracts/in-memory-cache-api.md, quickstart.md)을 반영해도
위 게이트는 모두 그대로 통과한다. 설계에서 새로 확인한 사항은 다음과 같다.

- 설계가 추가한 target은 `InfrastructureCache`와 `InfrastructureCacheTests` 둘뿐이며 모두
  `Infrastructure` 패키지 내부 산출물이다. 패키지 경계와 의존 방향이 바뀌지 않으므로
  `sources/docs/architecture.md`를 수정할 필요가 없다(원칙 3: 아키텍처 문서는 구조 결정이
  바뀔 때만 갱신).
- 공개 타입은 `InMemoryCache<Key, Value>` 하나, 공개 연산은 4개뿐이다. 별도 오류 타입,
  설정 타입, 프로토콜 추상화를 추가하지 않아 "최대한 심플하게"라는 사용자 요청과 원칙 3의
  범위 절제 취지에 부합한다.
- 정당화가 필요한 헌법 위반은 없다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/004-in-memory-cache/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/
│   └── in-memory-cache-api.md  # 1단계 산출물(/speckit-plan)
├── checklists/
│   └── requirements.md         # /speckit-specify 산출물(기존)
└── tasks.md             # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)

아래 경로는 `tasks.md`가 `Infrastructure` 단계에 배정할 대상이며, 계획 단계에서는
생성·수정하지 않는다. 파일 분할은 기존 `InfrastructureAuthentication`,
`InfrastructureNetworkClient`의 책임별 디렉터리 관례를 따른다.

```text
sources/Projects/Infrastructure/
├── Project.swift              # 기존 파일, 변경 없음(InfrastructureModuleName.targets 참조)
├── Cache/                     # 신규 framework target(InfrastructureCache)
│   └── InMemoryCache.swift    # actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable>
└── CacheTests/                # 신규 unitTests target(InfrastructureCacheTests)
    ├── StoreAndRetrieveTests.swift   # quickstart A-1~A-2
    ├── RemoveAndClearTests.swift     # quickstart B-1~B-4
    └── ConcurrentAccessTests.swift   # quickstart C-1~C-2
```

Tuist 설정 변경 대상(`Infrastructure` 단계에 배정):

```text
sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift
  - InfrastructureCache, InfrastructureCacheTests 케이스 추가
  - targets에 .module(name: "InfrastructureCache", sourceDirectory: "Cache", dependencies: [])
  - targets에 .testModule(name: "InfrastructureCacheTests", sourceDirectory: "CacheTests",
      productionTarget: .target(name: "InfrastructureCache"))
    ※ 이 enum은 CaseIterable이 아니다. 케이스만 추가하고 targets 배열에 넣지 않으면
      target이 생성되지 않는다

sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift
  - case .Infrastructure의 schemes에
      .module(name: "InfrastructureCache", testTarget: "InfrastructureCacheTests") 추가
    ※ Project.Options가 automaticSchemesOptions: .disabled이므로 이 등록이 없으면
      InfrastructureCache는 빌드도 테스트도 되지 않는다
    → testTarget: 인자를 반드시 함께 지정해야 project-build가 test 대상으로 인식한다
```

**구조 결정**: 템플릿의 단일 프로젝트/웹/모바일+API 선택지는 이 저장소에 해당하지 않으므로
실제 Tuist 다중 모듈 경로로 대체했다. 신규 패키지를 만들지 않고 기존 `Infrastructure`
패키지에 target 두 개(`InfrastructureCache`, `InfrastructureCacheTests`)를 추가한다.
공개 표면이 타입 1개·연산 4개로 작아 프로덕션 target 내부를 책임별 하위 디렉터리로 더
나누지 않는다.

## 복잡성 추적

> **헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다**

해당 없음 — 헌법 점검의 모든 게이트를 위반 없이 통과했다.

## 다음 단계

`/speckit-tasks`로 `tasks.md`를 생성한다. `tasks.md`가 반드시 반영해야 할 제약은 다음과
같다.

1. 모든 파일 변경 작업을 **Infrastructure 단계 하나**에 배정하고, 단계 끝에
   검증·보고·승인 게이트를 둔다(원칙 7). Tuist 설정 파일 2개도 Infrastructure 단계에
   포함한다.
2. 동시 접근 테스트(quickstart C-1, C-2)는 `actor` 격리를 검증하는 것이 목적이므로 벽시계
   경쟁이 아니라 `withTaskGroup`으로 여러 작업을 동시에 발행해 최종 상태를 확정적으로
   검증하도록 작성한다.
3. Tuist 설정 작업은 scheme 등록(`testTarget:` 포함)과 `targets` 배열 추가를 각각 별도
   확인 항목으로 둔다. 둘 중 하나만 해도 컴파일은 통과하지만 `InfrastructureCache`가
   빌드·테스트 대상에서 빠진다.
4. Composition의 Data↔Infrastructure Adapter 작성은 이 기능의 범위 밖이므로 tasks.md에
   포함하지 않는다(spec.md `범위 밖`).
