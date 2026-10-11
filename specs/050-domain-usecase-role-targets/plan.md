# 구현 계획: Domain 패키지 target의 UseCase 역할 기준 재구성

**Git-flow 유형**: `feature`

**브랜치**: `feature/domain-usecase-role-targets`

**날짜**: 2026-10-05 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/050-domain-usecase-role-targets/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

Domain 패키지의 target 16개(관심사 production 8, 관심사 test 8)를 역할 target 4개
(`DomainUseCaseInterface`, `DomainUseCaseDependency`, `DomainUseCaseImplementation`,
`DomainTests`)로 재구성한다. 관심사는 각 역할 target의 소스 루트 아래 폴더로 내려간다. 선언의
이름·시그니처·동작은 바꾸지 않고, Domain production 104개 파일을 옮기고 278개 파일의 import를
역할 모듈로 바꾼다.

규칙 문서 개정(U0)은 커밋 `4d13a76`, `2c3ca6e`로 이미 끝났다. 남은 구현은 파일 이동, Tuist
매니페스트, import 갱신과 검사 설정 갱신을 묶은 integration unit(U1) 하나다. 결정과 근거는
[research.md](./research.md), 재구성 뒤의 target·의존 계약은
[contracts/domain-targets.md](./contracts/domain-targets.md)에 있다.

## 기술 맥락

**언어/버전**: Swift 6.3 툴체인(Xcode 26.6), target의 `SWIFT_VERSION`은 5.0

**주요 의존성**: Tuist 4.202(매니페스트는 `sources/Tuist/ProjectDescriptionHelpers`). 외부 라이브러리
변경 없음

**저장소**: N/A

**테스트**: Swift Testing. 프로젝트 build 실행기(`GIT_IT_PROJECT_BUILD_RUNNER`)의 `build`, `compile`,
`test`

**대상 플랫폼**: iOS 26.0 이상

**프로젝트 유형**: 모바일 앱(Tuist 멀티 패키지)

**성능 목표**: N/A — 런타임 동작을 바꾸지 않는다

**제약 조건**: 선언의 이름·시그니처·동작 불변(FR-007). 구조는 규칙 문서와 일치(FR-019).
`sourceDirectory`는 target 이름에서 계산. 훅을 우회하지 않는다

**규모/범위**: Domain production 104개 파일 이동(그중 46개는 import도 변경), 그 밖의 Swift 파일
232개 import 변경, Tuist 매니페스트 6개, 검사 설정 1개

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

| 원칙 | 판정 | 근거 |
| --- | --- | --- |
| 1. 명시적인 경계 | 통과 | 패키지 간 의존성 표는 그대로다. Domain 안의 target 사이 의존은 단방향이고 순환이 없다([data-model.md](./data-model.md#관계)) |
| 2. 상태와 데이터 안전성 | 해당 없음 | 런타임 상태와 데이터를 바꾸지 않는다 |
| 3. 검증 가능한 변경 | 통과 | U1 끝에 build, build-for-testing, test, 패키지 의존성 검사, 셸 회귀 테스트를 실행한다([quickstart.md](./quickstart.md)) |
| 4·5. 스킬별 수정 경로 | 통과 | 이 계획은 이 기능의 계획 산출물만 만든다. 규칙 문서 개정은 사용자의 직접 지시로 계획 전에 끝났다 |
| 6. 한국어 산출물 | 통과 | 모든 산출물을 한국어로 썼다 |
| 7. 위험 기반 실행 단위 | 통과(다중 패키지 단위 1개) | 아래 "실행 단위 진행"과 [research.md R-04](./research.md#r-04-실행-단위) |
| 8. Git-flow 네임스페이스 | 통과 | `feature/domain-usecase-role-targets`. `/speckit-specify`가 직접 생성했다 |
| 9. 세션 지식 기록 | 해당 없음 | 기록 조건을 충족한 사건이 없다 |
| 10. 책임과 문맥에 따른 네이밍 | 통과 | 새 공개 이름은 target 네 개뿐이고 규칙 문서가 이미 정했다. 타입·프로토콜·연산의 이름은 바꾸지 않는다 |
| 11. 컨벤션 근거 | 통과 | 아래 "적용 컨벤션". 계획 중 발견한 충돌 하나는 사용자 결정으로 규칙 문서를 먼저 고쳐 해소했다 |

**브랜치 네임스페이스**: `feature/domain-usecase-role-targets`는 헌법 개정 후 `/speckit-specify`가
`a4cc97c`에서 직접 생성했다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정했다. 구현 파일의 정확한 경로는 `tasks.md`가 기록한다.

**세션 지식 기록**: 적용 여부와 문턱은 Constitution 원칙 9를 정본으로 따른다.

**Git 실행 직렬화**: U1의 `git mv`, 포맷 훅, commit은 한 체인으로 실행한다. build 실행기의 세
명령도 같은 DerivedData를 쓰므로 순서대로 하나씩 실행한다.

**커밋 단위 구현**: U1은 다중 패키지 단위 하나이고 커밋도 하나다. 대규모 파일 이동과 import 변경을
나누면 중간 커밋이 compile되지 않는다. 마지막 단위이므로 전체 읽기 전용 검증과 필수
`after_implement` hook(Swift 포맷)을 실행·재검증한 뒤 commit한다.

**컨벤션 근거**: `.specify/memory/constitution.md`, `docs/conventions/README.md`와 아래 표의 문서,
`docs/package-rules/{domain,composition,feature,app}.md`, `docs/architecture.md`를 읽었다. 문서 루트는
`GIT_IT_DOCS_ROOT` 판독 결과인 `docs`다.

**책임 기반 네이밍**: 새 이름은 `DomainUseCaseInterface`, `DomainUseCaseDependency`,
`DomainUseCaseImplementation`, `DomainTests`다. 패키지 문맥 `Domain`과 역할을 담고 축약을 쓰지
않는다. 이름 변경과 함께 바뀌는 동작이나 책임은 없다.

**실행 단위 진행**:

| 단위 | 목적 | 패키지·파일 | 상태 |
| --- | --- | --- | --- |
| U0 | 규칙 문서가 네 역할 target 구조를 규정한다 | `docs/package-rules/domain.md`, `docs/package-rules/composition.md`, `docs/conventions/directory-file.md`, `docs/conventions/directory-file/concern-segment.md`, `docs/conventions/file-vocabulary/shape-vocabulary.md` | 완료(`4d13a76`, `2c3ca6e`) |
| U1 | Domain target을 역할 기준으로 재구성한다 | Domain, Composition, Feature, App의 Swift 소스와 `sources/Tuist/ProjectDescriptionHelpers`의 매니페스트 6개, `.tools/package-dependencies/config/source-roots` | 미착수 |

- **U1을 다중 패키지 integration unit으로 두는 근거**: 옛 Domain target을 지우면 그 모듈을
  import하는 Composition·Feature·App의 모든 파일이 compile되지 않고, 새 target은 소스가 새 소스
  루트에 있어야 선언할 수 있다. `source-roots`는 매니페스트와 1:1이어야 의존성 검사가 통과한다.
  패키지별로 나눈 어떤 중간 상태도 build되지 않는다.
- **U1 안의 순서**: 의존성 위상 순서(Domain → Composition·Feature → App)로 작업한다.
  [아키텍처 문서 3.1](../../docs/architecture.md)에서 Composition과 Feature는 Domain에, App은 셋
  모두에 의존한다. Composition과 Feature는 서로 의존하지 않으며 상대 순서는 `tasks.md`가 정한다.
  1. Domain: production 파일 이동, Domain 매니페스트와 scheme, Domain 소스와 테스트의 import
  2. Composition: 매니페스트의 Domain 선언, import와 모듈 한정 참조
  3. Feature: 매니페스트의 Domain 선언, import
  4. App: 매니페스트의 Domain 선언, import
  5. 공용: `AllTestsScheme.swift`, `source-roots`
- **U1의 통합 검증**: `make tuist` 뒤 build 실행기의 `build`, `compile`, `test`, 패키지 의존성 검사,
  프로젝트 셸 회귀 테스트. 절차와 기대 결과는 [quickstart.md](./quickstart.md)에 있다.
- **제거 예외**: 적용하지 않는다. 이 변경은 공개 선언의 제거가 아니라 이동이다.
- **패키지에 속하지 않는 파일**: `sources/Tuist/ProjectDescriptionHelpers/**`와
  `.tools/package-dependencies/config/source-roots`는 target 구성의 정본과 그 대응표이므로 U1이
  소유한다.
- **명시적 승인이 필요한 경우**: 테스트 선언의 이름 변경, 접근 수준 확대 범위가 FR-007의 예외를
  넘는 경우, 규칙 문서와 다른 구조가 필요한 경우. 그 밖에는 반복 승인 없이 진행한다.

### 설계 후 재점검

1단계 설계 뒤 다시 점검했다. 판정은 위 표와 같다. 조사로 확인한 내용은 다음과 같다.

- 명세의 전제 여섯 개가 기준 커밋에서 성립한다([research.md R-03](./research.md#r-03-명세-전제의-검증)).
  Interface → Dependency 방향의 참조가 0건이어서 FR-005의 허용 의존대로 compile된다.
- 여덟 test target을 하나로 합쳐도 테스트 선언 이름이 충돌하지 않는다([R-10](./research.md#r-10-여덟-test-target을-하나로-합칠-때의-이름-충돌)).
- 계획 중 발견한 컨벤션 충돌: 처음 규칙 문서에 적은 `DomainUseCaseTests` + `Tests/`는 이름에서
  `sourceDirectory`를 계산하는 규칙과 맞지 않았다. 사용자가 `DomainTests` + `Tests/`로 결정했고
  `2c3ca6e`가 규칙 문서와 명세 가정을 정정했다. 남은 충돌은 없다.

## 적용 컨벤션

| 문서 | 이번 설계에 부과한 제약 |
| --- | --- |
| [docs/architecture.md](../../docs/architecture.md) §3.1, §7.1 | 패키지 간 허용 의존성 표를 바꾸지 않는다. Domain은 프로젝트 내부 패키지에 의존하지 않는다. U1 안의 작업 순서는 이 표의 위상 순서를 따른다 |
| [docs/package-rules/domain.md](../../docs/package-rules/domain.md) | target 네 개의 이름, 소스 루트, 소유 선언과 허용 import의 정본이다. 식별자는 `UseCaseInterface/Identifier/`에 두고 그 폴더에 다른 선언을 두지 않는다. target 안의 최상위 타입 이름은 유일해야 한다 |
| [docs/package-rules/composition.md](../../docs/package-rules/composition.md) | Composition target의 구성은 바꾸지 않는다. 다른 패키지 모듈 의존 수는 늘리지 않는다(아래 복잡성 추적) |
| [docs/package-rules/feature.md](../../docs/package-rules/feature.md) | Feature는 Domain contract의 production 구현을 소유하거나 공개 표면에 포함하지 않는다. 이 설계에서 Feature는 `DomainUseCaseImplementation`을 선언하지 않는다 |
| [docs/package-rules/app.md](../../docs/package-rules/app.md) | App은 Navigation과 조립에 필요한 Domain 타입만 직접 쓴다. 이 설계에서 App이 선언하는 Domain target은 `DomainUseCaseInterface`뿐이다 |
| [docs/conventions/directory-file.md](../../docs/conventions/directory-file.md) §3, [concern-segment.md](../../docs/conventions/directory-file/concern-segment.md) | Domain의 소스 루트는 역할이고 관심사는 그 아래 한 단계 세그먼트다. 경로는 `Domain/<역할>/<관심사>/<형태>/[<타입 패밀리>/]`다 |
| [docs/conventions/directory-file/path-structure.md](../../docs/conventions/directory-file/path-structure.md), [shape-rules.md](../../docs/conventions/directory-file/shape-rules.md) | 관심사 세그먼트 아래 폴더는 최대 2뎁스다. 형태 폴더는 파일이 하나뿐이어도 둔다 |
| [docs/conventions/directory-file/tuist-manifest.md](../../docs/conventions/directory-file/tuist-manifest.md) | `sourceDirectory`는 target 이름에서 계산하고 문자열로 우회하지 않는다. 폴더 이동과 매니페스트 갱신은 같은 커밋에 담는다. source glob은 `/**` 하나로 유지한다 |
| [docs/conventions/file-vocabulary/shape-vocabulary.md](../../docs/conventions/file-vocabulary/shape-vocabulary.md) | 역할별 소스 루트가 쓸 수 있는 형태 폴더는 Interface `UseCases/`·`Models/`·`Errors/`, Dependency `Contracts/`, Implementation `UseCases/`다. 새 형태 폴더를 만들지 않는다 |
| [docs/conventions/naming/target-source-folder.md](../../docs/conventions/naming/target-source-folder.md), [abbreviation.md](../../docs/conventions/naming/abbreviation.md) | target 이름은 패키지 문맥을 담고 폴더는 역할만 쓴다. `Impl` 같은 축약을 쓰지 않는다 |
| [docs/conventions/test/test-folder-target.md](../../docs/conventions/test/test-folder-target.md) | 패키지 전체 test target은 `Tests`를 소스 루트로 쓸 수 있다. 빈 test target을 scheme에 연결하지 않는다 |
| [docs/conventions/test/scheme.md](../../docs/conventions/test/scheme.md) | Domain 공유 scheme은 하나다. Build Action에 production 세 target, Test Action에 `DomainTests`를 연결한다 |
| [.github/COMMIT_CONVENTION.md](../../.github/COMMIT_CONVENTION.md) | U1의 커밋은 `[Refactor]` 하나다. 대규모 파일 이동과 로직 변경을 섞지 않는다 — 이 단위에 로직 변경은 없다 |

TCA, View, UIComponent, 현지화, 추상화 컨벤션은 적용 대상이 아니다. 이 변경은 선언의 내용과
Feature·UI 구현을 바꾸지 않는다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/050-domain-usecase-role-targets/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/
│   └── domain-targets.md
├── checklists/
│   └── requirements.md
└── tasks.md             # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)

```text
sources/Projects/Domain/
├── UseCaseInterface/<관심사>/{UseCases,Models,Errors}/        # 80개 파일
├── UseCaseDependency/<관심사>/Contracts/                      # 17개 파일
├── UseCaseImplementation/<관심사>/UseCases/                   # 7개 파일
└── Tests/<관심사>/…                                           # 31개 파일, 이동 없음

sources/Tuist/ProjectDescriptionHelpers/
├── ProjectName.swift                  # Domain scheme의 build·test target
├── AllTestsScheme.swift               # Domain test target 항목
└── Projects/
    ├── DomainModuleName.swift         # target 네 개
    ├── CompositionModuleName.swift    # Domain 의존 선언
    ├── FeatureModuleName.swift        # Domain 의존 선언
    └── AppModuleName.swift            # Domain 의존 선언

sources/Projects/{Composition,Feature,App}/**   # import와 모듈 한정 참조만 변경

.tools/package-dependencies/config/source-roots # Domain 16행 → 4행
```

**구조 결정**: 기존 Tuist 멀티 패키지 구조를 유지하고 Domain 패키지 안의 소스 루트만 관심사에서
역할로 바꾼다. 관심사 아래의 형태·타입 패밀리 구조는 그대로 옮기므로 이동 규칙은
[research.md R-02](./research.md#r-02-선언의-역할-배정)의 표 하나로 정해진다. 테스트는 옮기지 않는다.
`<관심사>`는 `Account`, `AppSetting`, `ExternalRepository`, `Identifier`, `Project`,
`ProjectGeneration`, `QuizDetail`, `UserInfo`다.

## 복잡성 추적

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| 다중 패키지 integration unit 1개(U1) | 옛 target 제거, 새 target 선언, import 갱신과 `source-roots` 갱신이 함께 있어야 build된다 | 패키지별 분할과 역할별 단계 이전은 중간 상태가 compile되지 않거나 규칙 문서가 설명하지 않는 혼합 구조를 만든다([research.md R-04](./research.md#r-04-실행-단위)) |
| Composition target 셋의 다른 패키지 모듈 의존 수가 6을 넘는다(7, 9, 7) | 기준 커밋에서 이미 네 target이 넘는다(10, 7, 15, 9). 이 변경은 Domain 선언 수를 줄여 초과를 줄일 뿐이다 | 남는 초과는 Data 모듈 선언 수에서 오며 Composition target 구성을 바꿔야 해소된다. FR-016이 그 구성을 바꾸지 않도록 한다([research.md R-06](./research.md#r-06-소비-target의-domain-의존-선언)) |
