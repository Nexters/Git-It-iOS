# 조사 결과: GitHub CI 및 프리커밋 검증 개선

## 현재 저장소 구조 및 병목 분석

### 결정: 저장소 구조 유지하면서 CI/프리커밋 계층만 변경
- **근거**: 기존 `tools/` 하위 스크립트 아키텍처, `repository-paths` 중앙 경로 관리, Tuist 멀티 패키지 구조를 그대로 활용한다. 새 스크립트와 CI 구성만 추가한다.
- **검토한 대안**: 전면 재구성(risk 과다), 외부 CI 도구 도입(저장소 기존 패턴과 불일치)

---

## 현재 CI 구조 분석

### 결정: 단일 `build-and-test` job을 역할별 job으로 분리
- **근거**: 현재 `ci.yml`은 3개 job(`script-tests`, `lint`, `build-and-test`)으로 구성되며, `build-and-test`가 Tuist 설치부터 전체 빌드·테스트까지 60분 timeout의 단일 monolithic job이다. PR 변경 범위와 무관하게 항상 전체 실행된다.
- **검토한 대안**: job 내부 step만 조건부 실행(job 자체를 생략할 수 없어 macOS runner 시간 소모 지속)

### 현재 scheme·test target 목록

| 패키지 | Scheme | Build Targets | Test Targets | UI Test |
|--------|--------|--------------|-------------|---------|
| App | App | GitIt | GitItTests | - |
| Composition | Composition | CompositionAdepter | CompositionAdepterTests | - |
| Feature | Feature | Feature | FeatureTests | - |
| Domain | Domain | DomainAuthentication, DomainLearningProject | DomainAuthenticationTests, DomainLearningProjectTests | - |
| Data | Data | DataAuthentication, DataLearningProject | DataAuthenticationTests, DataLearningProjectTests | - |
| Infrastructure | Infrastructure | InfrastructureAuthentication, InfrastructureNetworkClient, InfrastructureCache | InfrastructureAuthenticationTests, InfrastructureNetworkClientTests, InfrastructureCacheTests | - |
| UI | UI | DesignSystem, UIComponent, UIComponentLayoutHarness | DesignSystemTests, UIComponentTests, **UIComponentUITests** | ✅ |

**핵심 발견**: `UIComponentUITests`가 유일한 `.uiTests` product이며, 현재 `UI` scheme의 `testTargets`에 unit test와 함께 포함되어 있다.

---

## Xcodebuild 병렬도 분석

### 결정: `-jobs 1`을 환경변수 제어로 교체
- **근거**: `xcodebuild.sh`의 62번 줄에 `-jobs 1`이 하드코딩되어 있다. 또한 `xcodebuild_all()`이 `xargs -0 -n 1`로 scheme을 직렬 실행한다. CI runner(macOS-26)는 일반적으로 4코어 이상이므로 병렬도를 높일 여지가 있다.
- **검토한 대안**: `xargs -P` 병렬 scheme 실행(DerivedData 충돌 위험으로 기각 — aggregate scheme이 더 안전)

---

## Swift lint 배치 분석

### 결정: `xargs -0 -n 1` 대신 batch xargs로 변경
- **근거**: `swift-format/bin/run.sh`의 128번 줄에서 `xargs -0 -n 1 style_adapter_format_one`으로 파일마다 Swift-Style 도구를 개별 호출한다. `style_adapter_format_one()`은 매번 도구 프로세스를 기동한다. SwiftPM 기반 도구는 cold start가 느리므로 batch 전달로 프로세스 수를 줄인다.
- **검토한 대안**: 도구를 사전 빌드해 바이너리로 캐시(Swift-Style 서브모듈 관리와 충돌)

### 변경 방법
- `style_adapter_format_one` → `style_adapter_format_batch`: 여러 파일을 하나의 도구 invocation에 전달
- Swift-Style의 `scripts/format.sh`와 `scripts/lint.sh`가 여러 파일 인자를 수용하는지 확인 필요
- batch 크기 기본값 100, `GIT_IT_LINT_BATCH_SIZE`로 조절 가능

---

## 프리커밋 구조 분석

### 결정: 기존 dispatcher를 확장하고 새 단계를 추가
- **근거**: 현재 `pre-commit`는 `script-tests`, `swift-format`, `build`, `compile`, `test` 5개 단계만 허용하는 고정 허용 목록을 가진다(38~44행). 실행 순서도 코드에 고정(52행). `enabled`에는 `script-tests`만 활성화되어 있다. `staged-sanity`, `script-verification` 단계가 추가되어야 한다.
- **검토한 대안**: 별도 pre-commit 진입점(기존 dispatcher 구조를 활용하지 못함)

### 프리커밋 단계 설계

| 순서 | 단계 | 내용 | 차단 여부 |
|:---:|------|------|:---:|
| 1 | `staged-sanity` | `git diff --cached --check`, conflict marker, 금지 산출물 | 차단 |
| 2 | `script-verification` | staged `.sh` 파일의 ShellCheck/shfmt | 차단 |
| 3 | `swift-format` | staged Swift 포맷 검사, 변경 시 재-stage 안내 (lint 비차단) | 차단(포맷)/비차단(lint) |
| 4 | `script-tests` | 기존 셸 회귀 테스트 | 차단 |

---

## 변경 분류기 설계

### 결정: 셸 스크립트 기반 분류기
- **근거**: CI에서 `ubuntu-latest` runner에서 실행 가능하고, 저장소의 기존 셸 스크립트 패턴과 일치한다. GitHub Action의 경로 필터(`on.pull_request.paths`)는 workflow 전체를 생략할 수 있어 gate를 보장할 수 없으므로 사용하지 않는다.
- **검토한 대안**: dorny/paths-filter action(제3자 의존성 추가, SHA 고정 관리 부담), TypeScript action(오버엔지니어링)

### 분류 규칙

| 카테고리 | 경로 패턴 |
|----------|-----------|
| docs | `**/*.md`, `docs/**`, `specs/**`, `**/*.png` (docs 전용), `**/*.svg`, `LICENSE` |
| scripts | `tools/**`, `**/*.sh`, `tools/githooks/**` |
| swift | `sources/**/*.swift`, `sources/Tuist/ProjectDescriptionHelpers/**/*.swift` |
| ui | `sources/Projects/UI/**`, UI 관련 Tuist helper |
| project_config | `**/Project.swift`, `Workspace.swift`, `sources/Tuist/**`, `sources/Tuist/Package.swift`, `sources/Tuist/Package.resolved`, `.gitmodules` |
| workflow | `.github/workflows/**` |
| tests | `**/Tests/**`, `**/UITests/**` |

---

## Aggregate Unit Test 설계

### 결정: Tuist에서 CI 전용 aggregate scheme 생성
- **근거**: 기존 `ProjectName.swift`의 scheme 생성 패턴을 확장해 CI 전용 scheme을 `Workspace.swift` 수준에서 추가한다. UI test(`UIComponentUITests`)를 제외한 모든 unit test target을 하나의 scheme에 통합한다.
- **검토한 대안**: Xcode test plan(.xctestplan) — Tuist의 test plan 지원이 불완전할 수 있어 scheme 기반이 안전

### Unit Test Targets (aggregate 포함)
1. `GitItTests`
2. `CompositionAdepterTests`
3. `FeatureTests`
4. `DomainAuthenticationTests`
5. `DomainLearningProjectTests`
6. `DataAuthenticationTests`
7. `DataLearningProjectTests`
8. `InfrastructureAuthenticationTests`
9. `InfrastructureNetworkClientTests`
10. `InfrastructureCacheTests`
11. `DesignSystemTests`
12. `UIComponentTests`

### UI Test Targets (별도 scheme)
1. `UIComponentUITests`

---

## 캐시 분리 설계

### 결정: 3개 캐시로 분리
- **근거**: 현재 `build-and-test`의 캐시는 `~/.tuist/Cache`, Tuist `.build`, 루트 `.build`, Swift-Style `.build`를 하나의 key로 묶고 있다. 목적별로 분리하면 무효화 범위를 좁힐 수 있다.
- **검토한 대안**: DerivedData 캐시 추가(크기 대비 효과 불확실, 명세에서 기본 범위 제외)

| 캐시 | 경로 | Key 구성 |
|------|------|----------|
| Tuist/SwiftPM 의존성 | `~/.tuist/Cache`, `sources/Tuist/.build`, `.build` | OS, arch, Xcode, Tuist 버전, `Package.resolved`, `Package.swift`, `Workspace.swift`, `**/Project.swift` hash |
| Swift-Style 도구 | `tools/swift-style/.build` | OS, arch, Swift-Style `Package.resolved`, `Package.swift` hash |
| mise/Tuist 실행 도구 | `~/.local/share/mise` | OS, arch, Tuist 버전 |

---

## ShellCheck/shfmt CI 연결 설계

### 결정: 기존 `prepare-tools.sh` + `run.sh` 재사용
- **근거**: `tools/script-verification`에 이미 checksum 고정 도구 준비(`prepare-tools.sh`), 정적 검사 + 회귀 테스트(`run.sh`)가 구현되어 있다. `tools.lock`에 ShellCheck 0.11.0과 shfmt 3.13.1이 darwin-arm64, darwin-x86_64용으로 고정되어 있다. CI에서는 도구 artifact를 캐시하고 `run.sh`를 실행하면 된다.
- **검토한 대안**: `brew install shellcheck shfmt`(캐시 없이 매번 설치, 버전 고정 불확실)
