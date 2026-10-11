# 빠른 검증: 패키지 의존성 기계 검증과 CompositionAdapter 도메인 축 분할

모든 명령은 저장소 루트에서 실행한다. 도구 계약은 [contracts/README.md](./contracts/README.md),
규칙 정의와 배치 표는 [data-model.md](./data-model.md)를 참고한다.

## 준비

```sh
paths=./tools/repository-paths/bin/repository-paths.sh
```

U3 전에는 공개 경로 키가 없으므로 `tools/package-dependencies/bin/run.sh`를 직접 실행한다.
U3 뒤에는 `"$("$paths" GIT_IT_PACKAGE_DEPENDENCY_RUNNER)"`를 쓴다.

## 시나리오 1: 허용되지 않는 의존이 막힌다 (S1, SC-001·SC-002)

```sh
./tools/package-dependencies/tests/test-package-dependencies.sh
```

기대: 종료 0. 회귀 테스트가 manifest 선언, 패키지 import, 미선언 import, 표 불일치, 주석·문자열
안의 import, `#if` 안의 import, 접두어 없는 모듈, test target 상속 경우를 모두 확인한다.

수동 확인(작업 트리를 되돌릴 것):

1. `FeatureModuleName.swift`의 `Feature` 블록에 `.fromData(.DataMember)`를 추가한다.
2. 도구를 실행한다. 기대: 종료 1, `[manifest-package]`, 해당 파일과 줄.
3. 되돌린다.

## 시나리오 2: 설정과 아키텍처 표가 대응한다 (S2, SC-003)

```sh
./tools/package-dependencies/bin/run.sh
```

- U1 직후 기대: 종료 1, `[import-undeclared]` 6건(research 4절 목록과 일치).
- I2 뒤 기대: 종료 0, `위반=0`.

표 불일치 확인: `docs/architecture.md` 3.1 표의 `UI | — |`를 `UI | Domain |`으로 임시 변경 후
실행. 기대: 종료 1, `[table-mismatch]`. 되돌린다.

## 시나리오 3: 훅이 꺼져 있어도 검사가 돈다 (S3, SC-004·SC-005)

```sh
time "$("$paths" GIT_IT_PACKAGE_DEPENDENCY_RUNNER)"
./tools/script-tests/bin/run.sh
./tools/script-verification/bin/run.sh
./tools/githooks/hook-management/tests/test-pre-commit.sh
./tools/ci/tests/test-gate-evaluate.sh
rg -n 'package-dependencies' .github/workflows/ci.yml tools/githooks/pre-commit tools/githooks/pre-commit.d/enabled
```

기대: 도구 실행 5초 이하, 나머지 종료 0. `ci.yml`에 `package-dependencies` job과
`needs.package-dependencies.result` 전달이 있다. `enabled`의 단계는 주석 처리 상태다.

## 시나리오 4: CompositionAdapter 분할 (S4, SC-006~SC-009)

### 4.1 의존 수

```sh
awk '
  /case \.Composition[A-Za-z]*:/ { name = $2; sub(/^\./, "", name); sub(/:$/, "", name) }
  /\.from(Domain|Data|Infrastructure|UI|Feature|App|Composition)\(/ && name != "" { count[name]++ }
  END { for (n in count) printf "%s %d\n", n, count[n] }
' sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift | sort
```

기대: 모든 값이 6 이하. `CompositionShared`는 `InfrastructureNetworkClient` 하나만 선언한다.
분할 target에 `.fromDomain`·`.fromData`가 있는지 확인:

```sh
sed -n '/case .CompositionShared:/,/case .CompositionSharedTests:\|case .CompositionAuthentication:/p' \
  sources/Tuist/ProjectDescriptionHelpers/Projects/CompositionModuleName.swift | rg -c 'fromDomain|fromData' || true
```

기대: 0(출력 없음 또는 `0`).

### 4.2 남은 참조

```sh
rg -n 'CompositionAdapter' sources tools .github docs/package-rules docs/architecture.md
find sources/Projects/Composition/Adapter sources/Projects/Composition/Tests/Adapter -name '*.swift' 2>/dev/null | wc -l
```

기대: 첫 명령 출력 없음, 둘째 `0`.

### 4.3 생성·빌드·테스트

```sh
cd sources && tuist generate --no-open && cd ..
project_build_runner=$("$paths" GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
```

기대: 생성과 전체 공유 scheme Debug 빌드 성공. `AllTests` scheme에
`CompositionAuthenticationTests`, `CompositionLearningProjectTests`, `CompositionMemberTests`가
있고 `CompositionAdapterTests`가 없다.

```sh
xcodebuild test -workspace sources/GitIt.xcworkspace -scheme Composition \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath sources/DerivedData/PreCommit
```

기대: 분할 전과 같은 테스트 수가 통과한다. 테스트 수는 target별로 나뉠 뿐 합계가 같다.

### 4.4 사용자 관찰 동작 (SC-009)

`AppTests`와 `Composition` scheme의 성공·실패 목록이 명세 시작 전과 같다. `AppTests`의 기존
실패(`AppRootFeature root 전환` 19건)는 기준선으로 본다.
