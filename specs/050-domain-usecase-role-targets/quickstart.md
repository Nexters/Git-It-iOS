# 빠른 시작: Domain 역할 target 재구성 검증

**기능**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md) | **계약**: [contracts/domain-targets.md](./contracts/domain-targets.md)

재구성이 명세를 충족하는지 확인하는 절차다. 모든 명령은 저장소 루트에서 실행한다. 세 build
명령은 `sources/DerivedData/PreCommit`을 공유하므로 순서대로 하나씩 실행한다.

## 사전 준비

```sh
make tuist
project_build_runner=$(./.tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

`make tuist`는 workspace와 project를 다시 만든다. 실행 전후 `git status`를 비교해 추적 파일이
바뀌지 않았는지 확인한다.

## 1. 규칙 문서가 구조보다 먼저 있다 (시나리오 1)

```sh
git log --oneline --reverse a4cc97c..HEAD -- docs/ sources/ .tools/
git show --stat --format='%h %s' 4d13a76 2c3ca6e
```

- 기대: `docs/`만 바꾼 커밋 `4d13a76`, `2c3ca6e`가 `sources/`나 `.tools/`를 바꾼 첫 커밋보다 앞에
  있다(SC-009). `2c3ca6e`가 함께 바꾼 `specs/` 파일은 이 기능의 명세다.
- [Domain 패키지 규칙](../../docs/package-rules/domain.md#역할별-타깃-구성)의 표를 읽고 새 관심사의
  모델, UseCase 계약, 주입 계약, UseCase 구현, 테스트가 놓일 경로를 정할 수 있는지 확인한다(SC-008).

## 2. Domain이 네 역할 target이다 (시나리오 2)

```sh
ls sources/Projects/Domain
grep -c '^Domain' .tools/package-dependencies/config/source-roots
```

- 기대: `Domain/` 아래 소스 폴더는 `UseCaseInterface`, `UseCaseDependency`, `UseCaseImplementation`,
  `Tests` 넷이다. `source-roots`의 Domain 행은 4개다(SC-001).

```sh
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

- 기대: 셋 다 통과한다. test 로그의 Domain 실행 테스트 수가 129 이상이고, test 소스 루트별 `@Test`
  선언 수가 [research.md R-09](./research.md#r-09-테스트-수-기준선)의 기준선과 같다(SC-002).

```sh
git diff --stat -M a4cc97c..HEAD -- sources/Projects/Domain
```

- 기대: Domain production 104개 파일이 모두 rename으로 잡히고, 내용이 바뀐 46개 파일의 변경은
  import 줄뿐이다(SC-006).

## 3. 사용하는 쪽이 필요한 역할에만 의존한다 (시나리오 3)

```sh
./.tools/package-dependencies/bin/run.sh
grep -n 'fromDomain' sources/Tuist/ProjectDescriptionHelpers/Projects/{App,Feature,Composition}ModuleName.swift
```

- 기대: 위반 0건이다(SC-003). `.fromDomain(…)` 선언이
  [계약의 표](./contracts/domain-targets.md#소비-target의-의존-선언)와 같고, `AppModuleName.swift`와
  `FeatureModuleName.swift`에 `DomainUseCaseImplementation`이 없다(SC-005).

## 4. 옛 target 이름이 남지 않는다

```sh
rg -l 'Domain(Identifier|Account|UserInfo|AppSetting|ExternalRepository|QuizDetail|Project|ProjectGeneration)(Tests)?\b' \
  sources/Projects sources/Tuist .tools docs/architecture.md docs/package-rules docs/conventions
```

- 기대: 결과가 없다(SC-004). `sources/Projects` 아래의 생성물(`Derived/`, `*.xcodeproj`)은
  `make tuist`가 다시 만들므로 검색 결과에 남으면 재생성 뒤 다시 확인한다.

## 5. 셸 회귀 테스트

```sh
./.tools/script-tests/bin/run.sh
```

- 기대: 모두 통과한다(SC-007).

## 실패했을 때

| 증상 | 조치 |
| --- | --- |
| import를 모두 지운 파일에서 Domain 타입을 찾지 못한다 | 오류가 가리키는 타입의 역할 모듈만 import한다([research.md R-05](./research.md#r-05-import-갱신-규칙)) |
| `ShareExtension`이 build되지 않는다 | 필요한 역할 target만 선언하고 해당 import를 추가한다([R-06](./research.md#r-06-소비-target의-domain-의존-선언)) |
| 역할 경계를 넘는 `internal` 접근 오류 | 해당 선언에 한해 접근 수준을 넓히고 목록과 이유를 PR에 기록한다(FR-007) |
| `DomainTests` 안에서 이름이 충돌한다 | 구현을 중단하고 사용자에게 확인한다([R-10](./research.md#r-10-여덟-test-target을-하나로-합칠-때의-이름-충돌)) |
| 규칙 문서와 다른 구조가 필요하다 | 구조를 바꾸기 전에 규칙 문서를 먼저 고친다(FR-019) |
