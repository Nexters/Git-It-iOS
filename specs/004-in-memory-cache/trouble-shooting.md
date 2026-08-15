# 004-in-memory-cache 문제 해결 기록

**대상 기능**: `004-in-memory-cache`

**기록 원칙**: 실제 발생한 문제와 검증 근거를 append-only로 보존한다.

## TS-20260815-001: tuist generate가 빈 target 소스 디렉터리를 허용하지 않아 tasks.md의 Red→Green 순서를 지킬 수 없었다

**기록일**: 2026-08-15
**상태**: 완화
**발생 단계**: `/speckit-implement` — Infrastructure 패키지 단계, T003(`make tuist`)
**관련 항목**: T001, T002, T003, T004, T005, T006, T007, T008, T009,
`sources/Projects/Infrastructure/Cache/`, `sources/Projects/Infrastructure/CacheTests/`

### 증상

tasks.md에 기록된 순서(T001·T002로 Tuist target·scheme 설정 → T003 `make tuist` → T004~T006
테스트 작성 → T007 Red 확인 → T008 구현 → T009 Green 확인)대로 T001·T002만 마친 뒤 T003을
실행하자 `tuist generate`가 다음 오류로 실패했다.

```
✖ Error
  The target InfrastructureCache has the following invalid source files globs:
  - The directory "/Users/jerry/Desktop/Git-It-iOS/sources/Projects/Infrastructure/Cache" defined in the glob pattern "/Users/jerry/Desktop/Git-It-iOS/sources/Projects/Infrastructure/Cache/**" does not exist.
```

### 영향

T003이 통과해야 이후 xcodebuild 기반 T007(Red)·T009(Green) 검증을 실행할 수 있는데, T003
자체가 소스 디렉터리 부재로 막혀 계획된 TDD 순서(테스트 작성 → 컴파일 실패 관찰 → 구현 →
통과 관찰)를 그대로 수행할 수 없었다. 이후 다른 세션이 같은 순서를 그대로 따르면 같은
지점에서 막힌다.

### 근거

- `make tuist` 실행 로그(1차): `✖ Error / The target InfrastructureCache has the following
  invalid source files globs: ... does not exist.`
- `sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift`: 기존
  `InfrastructureAuthentication`·`InfrastructureNetworkClient`도 `.module(sourceDirectory:
  ...)` glob을 쓰며, 두 target 모두 이미 소스 파일이 있는 상태로 도입돼 이 제약이 지금까지
  드러나지 않았다.
- `sources/Projects/Infrastructure/Utility/Placeholder.swift`: 빈 target을 유지하기 위한
  placeholder 파일 관례가 이미 이 패키지 안에 존재한다.

### 원인

Tuist의 target 소스 glob(`Cache/**`, `CacheTests/**`)이 가리키는 디렉터리 자체가
파일시스템에 없으면(디렉터리가 있고 비어 있는 것과 달리) project graph 구성 단계에서 즉시
오류를 낸다. tasks.md는 "target·scheme 설정 → generate → 테스트 작성 → 구현" 순서를
전제했지만, 이 순서로는 generate 시점에 두 새 target의 소스 디렉터리가 아직 존재하지
않는다.

### 조치

계획된 순서를 재배치했다: T004~T006(테스트 파일)과 T008(`InMemoryCache.swift` 구현)을 먼저
작성해 `Cache/`, `CacheTests/` 두 디렉터리를 실제 파일로 채운 뒤 T003(`make tuist`)을
실행했다. tasks.md 자체는 다시 생성하지 않고 실행 순서만 이 세션에서 조정했다.

### 검증

- `make tuist`(2차, 디렉터리를 채운 뒤 실행): `✔ Success / Project generated.`
- `grep TestableReference
  sources/Projects/Infrastructure/Infrastructure.xcodeproj/xcshareddata/xcschemes/InfrastructureCache.xcscheme`:
  `<TestableReference`와 `InfrastructureCacheTests.xctest` 포함 확인
- `xcodebuild test -workspace GitIt.xcworkspace -scheme InfrastructureCache -destination
  'platform=iOS Simulator,name=iPhone 17 Pro'`: `Test run with 8 tests in 3 suites passed`,
  `** TEST SUCCEEDED **`

### 재발 방지

이 프로젝트에서 Tuist로 새 target을 신설하는 tasks.md를 작성할 때는 "준비(Tuist 설정) →
`tuist generate` → 테스트 작성 → Red 확인 → 구현 → Green 확인" 순서를 그대로 쓰지 않는다.
다음 중 하나를 준비 단계에 포함하는 편이 낫다.

- `tuist generate`를 테스트·구현 파일 작성 이후로 재배치한다(이번에 택한 방법. 단,
  컴파일 실패로 인한 Red 상태를 별도로 관찰할 기회를 잃는다).
- 또는 새 target 소스·테스트 디렉터리에 최소 placeholder 파일(이 패키지의
  `Utility/Placeholder.swift`와 같은 관례)을 준비 작업에 포함해 `tuist generate`를 먼저
  통과시킨 뒤, 이어서 테스트 작성 → Red 확인 → 구현 → Green 확인 순서를 그대로 유지한다.

`/speckit-tasks`가 Tuist 신설 target을 포함한 tasks.md를 생성할 때 위 판단 기준을 반영할지는
이 기록만으로 결정하지 않는다. 여러 세션에서 같은 패턴이 반복되면
`$speckit-tacit-knowledge`로 일반화할 근거가 된다.

### 연결

없음
