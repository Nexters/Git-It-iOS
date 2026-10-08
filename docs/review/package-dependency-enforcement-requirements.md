# 패키지 의존성 원칙 강제 요구사항

**상태**: 초안

**작성일**: 2026-09-15

**근거 시점**: branch `feature/screen-type-refactor`, commit `bee2388` + App→UIComponent 의존 제거 변경

**목적** — [아키텍처 3.1](../architecture.md)의 패키지 의존성 표를 사람이 아니라 도구가 검증하게 만들고, 표가 잡아내지 못하는 수렴점을 해소합니다.

**전제** — Feature는 단일 target을 유지합니다. Domain↔Data 경계 구조는 현행을 유지합니다.

## 1. 현상

### 1.1 위반은 발견 즉시 고쳐졌지만 재발을 막는 장치가 없습니다

`App`의 허용 의존성은 `Feature, Composition, Domain`인데 `GitIt` target이 `.fromUI(.UIComponent)`를 선언하고 `AppRootView.swift`가 `import UIComponent`를 하고 있었습니다. [app.md](../package-rules/app.md)가 이미 "공용 UI 구성요소를 소유하거나 UI 패키지에 직접 의존해서는 안 됩니다"를 명시하고 있었음에도 코드 리뷰에서 걸러지지 않았습니다.

같은 유형의 위반이 다시 들어와도 빌드는 성공합니다. 의존성 표를 검증하는 자동화가 없기 때문입니다.

### 1.2 검증을 걸 자리는 이미 마련되어 있습니다

- `tools/design-rules/` — `bin/` `core/` `config/` `tests/` 구조의 검사 도구 선례
- `tools/githooks/pre-commit.d/design-rules.sh` — 단계 스크립트 선례
- `tools/githooks/pre-commit.d/enabled` — 단계 등록 지점. **현재 모든 단계가 주석 처리되어 있습니다.**
- `tools/ci/bin/gate-evaluate.sh`, `.github/workflows/ci.yml` — CI 게이트

### 1.3 표가 잡아내지 못하는 수렴점

`CompositionAdapter` 단일 target이 12개 모듈에 의존합니다.

```text
DomainAuthentication, DomainLearningProject, DomainMember,
DataAuthentication, DataLearningProject, DataExternalRepository,
DataLegalConsent, DataMember,
InfrastructureNetworkClient, InfrastructureAuthentication,
InfrastructureStorage, InfrastructureLocalNotification
```

Domain·Data·Infrastructure 어느 모듈이 바뀌어도 `CompositionAdapter` 전체와 그 하위(`CompositionApp`, `CompositionShareExtension`, `GitIt`, `ShareExtension`)가 재컴파일됩니다. 의존성 표는 이를 위반으로 보지 않습니다.

## 2. 문제 정의

1. 의존성 규칙이 산문 문서에만 존재해 위반이 머지될 수 있습니다.
2. 위반 경로가 둘(Tuist manifest 선언, Swift `import`)인데 어느 쪽도 검사되지 않습니다.
3. 허용 표를 지켜도 단일 수렴 target 때문에 모듈 분리의 빌드 격리 이득이 사라집니다.

## 3. 요구사항

### FR-1 의존성 규칙의 기계 판독 가능한 정본

- 패키지별 허용 의존성을 기계가 읽을 수 있는 설정 파일로 둔다.
- 설정 파일은 [아키텍처 3.1](../architecture.md)의 표와 1:1로 대응해야 하며, 표와 설정이 다르면 검사가 실패한다.
- 설정은 **패키지 단위**로 표현한다. target 단위 예외를 허용하지 않는다.

### FR-2 Tuist manifest 검증

- `sources/Tuist/ProjectDescriptionHelpers/Projects/*ModuleName.swift`가 선언하는 `.from<패키지>(...)` 의존성이 FR-1 설정에 없는 조합이면 실패한다.
- 프로덕션 target과 test target을 구분해 검사한다. test target의 추가 의존성도 같은 표를 따른다.
- 실패 메시지는 위반한 target 이름, 선언 위치, 허용되지 않는 이유를 포함한다.

### FR-3 Swift import 검증

- `sources/Projects/<패키지>/**/*.swift`의 `import` 중 프로젝트 내부 모듈을 가리키는 것이 FR-1 설정에 없는 조합이면 실패한다.
- 프로젝트 내부 모듈 이름 목록은 FR-1 설정에서 유도한다. 외부 라이브러리와 시스템 프레임워크 import는 검사 대상이 아니다.
- manifest에 없는 import(전이 의존으로 우연히 컴파일되는 경우)도 위반으로 판정한다.

### FR-4 검사 도구 구성

- `tools/` 아래에 `bin/` `core/` `config/` `tests/` 구조의 독립 도구로 만든다. 구조와 의존 방향은 [셸 스크립트 아키텍처](../../.agents/skills/write-project-scripts/references/architecture.md)를 따른다.
- 공개 진입점 경로를 `tools/repository-paths/repository-paths.json`에 등록하고, 호출부는 하드코딩 경로를 쓰지 않는다.
- 도구 자신의 회귀 테스트를 `tests/`에 두고 `tools/script-tests/bin/run.sh`가 실행하도록 등록한다.
- ShellCheck·shfmt 정적 검사를 통과한다.

### FR-5 실행 지점 연결

- `tools/githooks/pre-commit.d/`에 단계 스크립트를 추가하고 단계 이름을 pre-commit 진입점의 허용 목록에 등록한다.
- **pre-commit 단계가 현재 전부 비활성화되어 있으므로, 이 검사는 CI 게이트에도 등록해 훅 활성화 여부와 무관하게 동작해야 한다.**
- 검사 실행 시간은 단독 실행 기준 5초를 넘지 않아야 한다. 빌드를 유발하지 않는 정적 검사로 구현한다.

### FR-6 현행 위반 0 확인

- 도구 도입 시점에 전체 저장소에 대해 검사를 실행해 위반이 0임을 확인한다.
- 위반이 남아 있는 상태로 예외 목록을 만들어 통과시키지 않는다. 남는 위반이 있다면 도구 도입 전에 코드를 고치거나 [아키텍처 3.1](../architecture.md)의 표를 고친다.

### FR-7 CompositionAdapter 수렴점 분할

- `CompositionAdapter`를 도메인 축으로 분할한다: Authentication, LearningProject, Member.
- 분할 후 각 target의 의존 모듈 수는 **6개 이하**여야 한다.
- 여러 도메인이 공유하는 조립 요소는 별도의 공용 target에 두되, 그 target은 Domain·Data 모듈에 의존하지 않는다.
- `CompositionApp`과 `CompositionShareExtension`은 자신이 실제로 사용하는 분할 target만 참조한다.

## 4. 비범위

- Feature target 분할 (단일 target 유지 결정)
- App이 Domain 타입을 직접 사용하는 것 — [아키텍처 3.1](../architecture.md)과 [app.md](../package-rules/app.md)가 명시적으로 허용
- 외부 라이브러리 의존성 정책
- Domain↔Data 경계 구조 변경

## 5. 수용 기준

- [ ] FR-1 설정 파일이 존재하고, [아키텍처 3.1](../architecture.md) 표의 7개 패키지 전부를 담는다.
- [ ] 허용되지 않는 `.from<패키지>(...)`를 manifest에 일부러 추가하면 검사가 실패하는 회귀 테스트가 있다.
- [ ] 허용되지 않는 프로젝트 내부 `import`를 일부러 추가하면 검사가 실패하는 회귀 테스트가 있다.
- [ ] 아키텍처 문서의 표와 설정 파일이 어긋나면 검사가 실패하는 회귀 테스트가 있다.
- [ ] 현재 저장소에서 검사가 위반 0으로 통과한다.
- [ ] 검사가 CI에서 실행되며, 실패 시 머지가 막힌다.
- [ ] `CompositionAdapter` 분할 후 어느 target도 6개를 초과하는 모듈에 의존하지 않는다.
- [ ] 분할 후 `tuist generate` 및 전체 scheme Debug 빌드가 성공한다.

## 6. 영향 범위

| 대상 | 영향 |
| --- | --- |
| `tools/` | 신규 검사 도구, `repository-paths.json`, `script-tests` 등록 |
| `tools/githooks/` | `pre-commit.d/` 단계 추가, 진입점 허용 목록 |
| `tools/ci/`, `.github/workflows/ci.yml` | 게이트 추가 |
| `sources/Tuist/ProjectDescriptionHelpers/` | `CompositionModuleName.swift` 분할, 참조하는 `AppModuleName.swift` |
| `sources/Projects/Composition/` | 폴더 구조와 target 경계 재배치 |
| `docs/architecture.md` | 표와 설정의 대응 관계 명시 |

**리스크** — FR-7은 Tuist 프로젝트 구조 변경이므로 `tuist generate` 이후 workspace·scheme·테스트 target 연결이 모두 유효한지 확인해야 합니다. `AllTests` scheme의 target 목록(`tools`가 아닌 `Tuist/ProjectDescriptionHelpers/AllTestsScheme.swift`)도 함께 갱신해야 합니다.

## 7. 작업 순서 제안

1. FR-1 ~ FR-4 — 검사 도구. FR-7과 독립이며 먼저 넣어야 FR-7 작업 중 위반이 생기지 않습니다.
2. FR-5, FR-6 — 실행 지점 연결과 위반 0 확인.
3. FR-7 — 수렴점 분할. [Composition 책임 정리 요구사항](./composition-responsibility-requirements.md)이 Composition에서 코드를 덜어낸 **뒤에** 수행하면 옮길 대상이 줄어듭니다.

## 관련 문서

- [아키텍처](../architecture.md)
- [App 패키지 규칙](../package-rules/app.md)
- [Composition 패키지 규칙](../package-rules/composition.md)
- [셸 스크립트 스킬](../../.agents/skills/write-project-scripts/)
- [Composition 책임 정리 요구사항](./composition-responsibility-requirements.md)
