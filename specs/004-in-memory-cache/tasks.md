---

description: "InMemoryCache 구현 작업 목록"

---

# 작업 목록: InMemoryCache

**입력**: `/specs/004-in-memory-cache/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/in-memory-cache-api.md](./contracts/in-memory-cache-api.md),
[quickstart.md](./quickstart.md)

**테스트**: 포함한다. 사용자 스토리 1~3이 각각 "독립 테스트"로 자동 검증 방법을 명시하고,
SC-005가 화면·네트워크·디스크 접근 없이 100% 검증 가능해야 한다고 요구하므로 테스트 작업은
선택이 아니다.

**구성**: 이 명세의 적용 대상 패키지는 `Infrastructure` 하나다. `Domain → Data →
Infrastructure → Composition → UI → Feature → App` 순서에서 `Infrastructure` 앞뒤 패키지는
모두 변경 대상이 아니므로 건너뛴다(plan.md "패키지 진행").

## 형식: `[ID] [P?] [스토리?] 설명`

- **[P]**: 승인된 현재 패키지 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[스토리]**: 작업이 지원하는 사용자 스토리(US1, US2, US3)
- **[no-write]**: 추적 파일을 변경하지 않는 명령 실행 또는 수동 검증
- 파일 변경 작업은 정확한 저장소 상대 경로 하나와 정확히 하나의 책임 패키지를 가져야 한다.
- 서로 다른 패키지는 같은 의존 깊이에 있어도 승인 게이트를 넘어 병렬 실행하지 않는다.
- 공개 API의 신설·rename 작업은 확정한 식별자와 책임을 설명에 명시한다. 네이밍 변경과
  동작·상태 수명·책임·의존 방향 변경은 하나의 작업으로 합치지 않는다.

## 패키지 소유권 규칙

- 패키지 소스·테스트와 패키지 전용 설정은 해당 패키지 단계가 소유한다.
- 준비, 기반, 정리와 횡단 관심사는 별도 구현 단계로 만들지 않고 책임 패키지 단계에 넣는다.
- 공용 구성 파일이 여러 패키지 선언을 바꿔야 하면 패키지별 작업으로 분리하고, 각 작업은
  현재 패키지에 필요한 선언만 변경한다.
- 패키지에 속하지 않는 파일 변경은 그 변경을 최초로 필요로 하는 책임 패키지에 명시적으로
  배정한다.
- 전체 기능을 대상으로 하는 검증은 마지막 적용 대상 패키지 뒤에 `[no-write]`로만 둔다.
- `trouble-shooting.md`와 `tacit-knowledge.md` 기록은 구현 작업이나 패키지 소유 파일로
  만들지 않는다.

**패키지에 속하지 않는 파일의 배정**: T001·T002가 변경하는 두 Tuist 설정 파일은
`sources/Projects/<패키지>` 밖에 있지만 `Infrastructure` 프로젝트의 선언만 바꾸며, 이 변경을
최초로 필요로 하는 책임 패키지가 `Infrastructure`이므로 `Infrastructure` 단계에 배정한다
(plan.md "패키지 진행").

## 반드시 지켜야 할 구현 제약

계획 단계에서 확정한 제약이다. 위반하면 컴파일 성공 여부와 무관하게 런타임 또는 검증이
깨진다(plan.md, research.md).

| 제약 | 위반 시 결과 | 해당 작업 |
| --- | --- | --- |
| 동시성 안전성은 `actor`로 구현하고 별도 lock을 두지 않는다 | 수동 lock 코드가 늘고 실수 시 데이터 경합·교착 위험이 생긴다(research.md §1) | T008 |
| 값 없음은 오류가 아니라 `nil` 반환으로 표현한다 | FR-003("오류 없이 값 없음을 알려야 한다")을 위반한다 | T008 |
| `ProjectName.swift`에 scheme을 `testTarget:`과 함께 등록한다 | `automaticSchemesOptions: .disabled`라 등록이 없으면 빌드·테스트 대상에서 빠진다 | T002 |
| `InfrastructureModuleName`의 `targets` 배열에 항목을 추가한다 | 이 enum은 `CaseIterable`이 아니라 케이스만 추가하면 target이 생성되지 않는다 | T001 |
| 동시 접근 테스트는 벽시계 경쟁이 아니라 `withTaskGroup`으로 여러 작업을 동시에 발행해 최종 상태를 확정적으로 검증한다 | 실시간 경쟁으로 작성하면 반복 실행에서 간헐적으로 실패한다(plan.md "다음 단계" §2) | T006 |

---

## 작업 패키지 1: Infrastructure

**목표**: 프로세스 메모리 범위에서 키-값을 보관하는 범용 기술 API `InMemoryCache<Key,
Value>`를 제공하는 `InfrastructureCache` target을 신설하고, 동시 접근 안전성을 포함한 전
동작을 검증하는 `InfrastructureCacheTests`를 함께 만든다.

**소유 경로**: `sources/Projects/Infrastructure/Cache/`,
`sources/Projects/Infrastructure/CacheTests/`,
`sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`,
`sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`

**관련 사용자 스토리**: US1(저장과 조회), US2(제거와 전체 비우기), US3(동시 접근 안전성)

**독립 검증**: `InfrastructureCache`는 프로젝트 내부 다른 패키지에 의존하지 않으므로
`InfrastructureCache` scheme 단독 빌드·테스트로 책임과 의존 방향을 모두 검증할 수 있다.

### 준비와 기반

- [X] T001 [US1] [US2] [US3]
  `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`에
  `InfrastructureCache`·`InfrastructureCacheTests` 케이스를 추가하고, `targets` 배열에
  `.module(name: InfrastructureModuleName.InfrastructureCache.rawValue, sourceDirectory:
  "Cache", dependencies: [])`와 `.testModule(name:
  InfrastructureModuleName.InfrastructureCacheTests.rawValue, sourceDirectory: "CacheTests",
  productionTarget: .target(name: InfrastructureModuleName.InfrastructureCache.rawValue))`를
  추가한다. 이 enum은 `CaseIterable`이 아니므로 케이스 추가만으로는 target이 생성되지
  않는다. `InfrastructureCache`는 Swift 표준 라이브러리만 사용하므로 `.sdk` 의존성을
  추가하지 않는다(research.md §4)
- [X] T002 [US1] [US2] [US3]
  `sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift`의 `case .Infrastructure`
  schemes 배열에 `.module(name: "InfrastructureCache", testTarget:
  "InfrastructureCacheTests")`를 추가한다. `Project.Options`가 `automaticSchemesOptions:
  .disabled`이므로 이 등록이 없으면 `InfrastructureCache`는 빌드도 테스트도 되지 않고,
  `testTarget:`이 없으면 `tools/githooks/project-build`가 `<TestableReference` 부재로
  `compile`·`test` 대상에서 제외한다
- [X] T003 [no-write] 저장소 루트에서 `make tuist`를 실행하고,
  `sources/Projects/Infrastructure/xcshareddata/xcschemes/InfrastructureCache.xcscheme`에
  `<TestableReference`가 포함되었는지 확인한다

### 테스트 (US1, US2, US3)

- [X] T004 [P] [US1]
  `sources/Projects/Infrastructure/CacheTests/StoreAndRetrieveTests.swift`에 quickstart
  A-1~A-2 검증을 작성한다: 빈 캐시에 저장한 직후 같은 키로 조회하면 저장한 값이 그대로
  반환되는지(US1-1, SC-001), 같은 키에 값을 다시 저장하면 이전 값이 아닌 새 값이
  반환되는지(US1-2, FR-004)
- [X] T005 [P] [US2]
  `sources/Projects/Infrastructure/CacheTests/RemoveAndClearTests.swift`에 quickstart
  B-1~B-4 검증을 작성한다: 키를 제거한 뒤 조회하면 `nil`이 반환되는지(US2-1, SC-003), 전체
  비우기 뒤 모든 키가 `nil`을 반환하는지(US2-2, SC-003), 존재하지 않는 키를 제거해도 오류
  없이 완료되는지(US2-3, FR-007), 저장된 적 없는 키를 조회해도 오류·예외 없이 `nil`이
  반환되는지(FR-003, SC-002)
- [X] T006 [P] [US3]
  `sources/Projects/Infrastructure/CacheTests/ConcurrentAccessTests.swift`에 quickstart
  C-1~C-2 검증을 작성한다. `withTaskGroup`으로 서로 다른 키 100개에 대한 저장 작업을 동시에
  발행한 뒤 모든 값이 유실·혼선 없이 각자의 값과 일치하는지(US3-1, SC-004), 같은 키에 대한
  저장 작업 여러 건을 동시에 발행한 뒤 그중 하나의 값이 손상 없이 남아 있는지(US3-2,
  FR-008) 확인한다. 벽시계 경쟁으로 작성하지 않는다
- [ ] T007 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme
  InfrastructureCache -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`를 실행해
  T004~T006이 `InMemoryCache` 타입 미구현으로 컴파일 실패하는지 확인한다(Red 단계)
  — **미실행**: T003(`tuist generate`)이 `InfrastructureCache`/`InfrastructureCacheTests`
  target의 소스 glob 디렉터리가 비어 있으면 실패해, T004~T006과 T008을 먼저 작성해 두
  디렉터리를 채운 뒤에야 T003을 실행할 수 있었다. 그 결과 Red 상태를 별도로 관찰하지
  못했다. T009에서 Green 결과로 전 테스트 통과를 확인했다

### 구현

- [X] T008 [US1] [US2] [US3]
  `sources/Projects/Infrastructure/Cache/InMemoryCache.swift`에 `public actor
  InMemoryCache<Key: Hashable & Sendable, Value: Sendable>`을 구현한다. 내부 상태는
  `Dictionary<Key, Value>` 하나만 둔다(research.md §4). `public init()`으로 빈 캐시를
  만든다(FR-012). `public func store(_ value: Value, forKey key: Key)`는 같은 키가 있으면
  값을 교체한다(FR-004). `public func value(forKey key: Key) -> Value?`는 값이 없으면 오류
  없이 `nil`을 반환한다(FR-002, FR-003). `public func removeValue(forKey key: Key)`는 값이
  없어도 오류 없이 완료된다(FR-005, FR-007). `public func removeAll()`은 모든 값을
  제거한다(FR-006). `Dictionary`, `NSCache` 등 내부 저장 기술의 구체 타입을 공개 서명에
  노출하지 않고, Domain·Data가 소유한 타입을 참조하지 않으며, 프로젝트 내부의 다른 패키지에
  의존하지 않는다(FR-009, FR-010, FR-011, contracts/in-memory-cache-api.md)

### 정리와 패키지 검증

- [X] T009 [no-write] `xcodebuild test -workspace GitIt.xcworkspace -scheme
  InfrastructureCache -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`를 실행해
  T004~T006의 모든 테스트가 통과하는지 확인한다(Green 단계). 실패가 남으면 원인을 기록하고
  T008로 돌아간다
- [X] T010 [no-write] `InfrastructureCache`의 공개 선언을
  `contracts/in-memory-cache-api.md`의 공개 표면과 대조한다. 최상위 공개 타입이
  `InMemoryCache<Key, Value>` 하나이고 공개 연산이 `init()`, `store(_:forKey:)`,
  `value(forKey:)`, `removeValue(forKey:)`, `removeAll()` 다섯 개뿐인지, 명세가 요구하지
  않는 오류 타입·설정 타입이 추가되지 않았는지 확인한다

**승인 게이트**: T001~T010의 변경 파일과 검증 결과를 보고한 뒤 중단한다.
`Infrastructure`는 이 명세의 유일한 적용 대상 패키지이므로 이후 패키지 단계는 없다. 아래
전체 완료 검증은 이 보고와 사용자 확인 뒤에만 실행한다.

---

## 전체 완료 검증

**선행 조건**: `Infrastructure` 패키지의 구현·검증·결과 보고가 완료되어야 한다. 이 단계는
파일을 변경하지 않는다.

- [X] T011 [no-write] 저장소 루트에서
  `project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh
  GIT_IT_PROJECT_BUILD_RUNNER)`로 경로를 구한 뒤 `"$project_build_runner" build`,
  `"$project_build_runner" compile`, `"$project_build_runner" test`를 순서대로 실행하고
  결과를 기록한다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 순차 실행한다
- [X] T012 [no-write] 사용자 스토리별 독립 수용 시나리오를 검증한다. US1은 quickstart
  A-1~A-2, US2는 B-1~B-4, US3은 C-1~C-2의 결과로 확인하고, 검증 전 과정에서 화면 실행·네트워크
  접근·디스크 접근이 전혀 없었는지 함께 확인한다(SC-005)

## 의존성과 실행 순서

### 패키지 순서와 승인 게이트

- 이 명세의 적용 대상 패키지는 `Infrastructure` 하나다. `Domain → Data → Infrastructure →
  Composition → UI → Feature → App` 순서에서 나머지 패키지는 변경 대상이 아니므로 건너뛴다.
- 한 번에 한 패키지만 구현한다. `Infrastructure`의 모든 작업과 검증이 끝나기 전에는 전체
  완료 검증을 시작하지 않는다.
- `Infrastructure`의 변경 파일과 검증 결과를 보고하고 명시적 사용자 승인을 받은 뒤 전체
  완료 검증으로 진행한다.
- 후속 작업에서 `Infrastructure` 밖 패키지 수정이 필요해지면 구현을 중단하고
  `/speckit-tasks`로 작업 소유권과 실행 순서를 다시 조정한다. Composition의
  Data↔Infrastructure Adapter 구현은 이 명세의 범위 밖이며 별도 명세가 다룬다.

### 사용자 스토리 추적성

| 사용자 스토리 | 작업 | 독립 수용 기준 |
| --- | --- | --- |
| US1 저장과 조회 (P1) | T001, T002, T004, T008 | quickstart A-1~A-2가 모두 통과한다 |
| US2 제거와 전체 비우기 (P2) | T001, T002, T005, T008 | quickstart B-1~B-4가 모두 통과한다 |
| US3 동시 접근 안전성 (P3) | T001, T002, T006, T008 | quickstart C-1~C-2가 모두 통과하고 값 유실·혼선이 0건이다 |

- 사용자 스토리는 `Infrastructure` 패키지가 완료된 뒤 위 기준으로 독립 검증한다.
- MVP 범위도 패키지 승인 게이트를 건너뛰지 않는다.

### 패키지 내부 실행

- 테스트(T004~T006)를 구현 전에 작성하고 T007에서 예상한 이유(타입 미구현으로 인한 컴파일
  실패)로 실패하는지 확인한다.
- `[P]`는 승인된 `Infrastructure` 패키지 안의 서로 다른 파일에만 사용한다.
- T008은 T004~T006이 모두 작성된 뒤 실행한다(테스트가 요구하는 공개 표면을 한 번에
  구현하기 위함).
- T009·T010은 T008이 끝난 뒤 실행한다.

### 패키지 내부 병렬 실행 예시

```text
# 테스트 작성 — T001~T003 완료 후 함께 실행 가능
T004, T005, T006
```

## 구현 전략

1. `Infrastructure`(유일한 적용 대상 패키지)의 준비 T001~T003을 완료해 target과 scheme을
   만든다.
2. 테스트 T004~T006을 작성하고 T007로 Red를 확인한다.
3. T008로 `InMemoryCache`를 구현한다.
4. T009~T010으로 패키지를 검증하고, 변경 파일과 실제 검증 결과를 보고한 뒤 중단한다.
5. 사용자 승인 후에만 T011~T012의 읽기 전용 전체 검증과 스토리 수용 검증을 실행한다.

## 참고

- 작업 ID는 실제 실행 순서대로 증가한다.
- 파일 변경 작업은 정확한 경로를 포함한다. 이 목록의 경로가 `/speckit-implement`의 쓰기
  허용 목록이다.
- 사용자 스토리 독립성은 유지하되 구현·승인 단위는 `Infrastructure` 패키지다.
- 모호한 소유권, 다중 패키지 작업, 승인 게이트를 넘는 병렬 실행을 허용하지 않는다.
- 문제 해결과 암묵지 기록은 구현 작업 ID로 만들지 않는다. 실제 문제가 발생하면
  `$speckit-troubleshooting`이 별도로 기록한다.
