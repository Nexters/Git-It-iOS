# AGENTS.md

이 문서는 이 저장소에서 작업하는 AI 코딩 에이전트를 위한 진입점입니다. 아래 문서들이
실제 규칙을 정의하며, 이 문서는 그 위치와 우선순위를 안내합니다. 내용이 충돌하면
아래 "우선순위" 순서를 따릅니다.

## 우선순위

1. [Constitution](.specify/memory/constitution.md) — 모든 문서보다 우선하는 상위 원칙
2. [아키텍처 문서](sources/docs/architecture.md),
   [네이밍 가이드](sources/docs/naming.md),
   [테스트 작성 컨벤션](sources/docs/test-conventions.md)과
   [패키지별 규칙](sources/docs/package-rules/) — 모듈 책임, 의존성, 테스트와 공개 이름 규칙
3. [`.github/COMMIT_CONVENTION.md`](.github/COMMIT_CONVENTION.md) — 커밋 메시지 규칙
4. [README](README.md) — 초기화·빌드·훅 설치 절차
5. 이 문서

Constitution과 하위 문서가 충돌하면 하위 문서를 Constitution에 맞게 수정합니다.

## 프로젝트 개요

- Git It의 iOS 클라이언트. iOS 26.0 이상, SwiftUI, TCA(The Composable
  Architecture), Tuist 기반 멀티 패키지 구조.
- 실제 소스는 `sources/` 아래에만 있습니다. 저장소 루트의 `GitIt.xcworkspace`는
  `sources/GitIt.xcworkspace`를 가리키는 심볼릭 링크입니다.
- 패키지: `App`, `Composition`, `Feature`, `Domain`, `Data`, `Infrastructure`, `UI`.
  각 패키지의 책임과 허용 의존 방향은 [아키텍처 문서](sources/docs/architecture.md)의
  표를 따릅니다. Domain/Data/Core는 프로젝트 내부 패키지에 의존하지 않습니다.

## 셋업

```sh
make init
```

`tuist install && tuist generate`로 workspace를 만들고 Git 훅을 설치합니다. 이미
설치되어 있으면 `make tuist` 또는 `make hooks`로 개별 실행할 수 있습니다.
`make help`로 전체 명령을 확인합니다.

## 빌드·테스트

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build     # 모든 공유 scheme Debug 빌드
"$project_build_runner" compile   # 테스트 scheme build-for-testing
"$project_build_runner" test      # test-without-building
```

workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행합니다. 기본 테스트
destination은 `platform=iOS Simulator,name=iPhone 17 Pro`이며
`GIT_IT_TEST_DESTINATION`으로 덮어씁니다. 세 명령은 순차 실행을 전제로
`sources/DerivedData/PreCommit`을 공유합니다.

셸 스크립트를 변경했다면 다음도 실행합니다.

```sh
./tools/script-tests/bin/run.sh                  # 프로젝트 셸 회귀 테스트
./tools/script-verification/bin/prepare-tools.sh # ShellCheck·shfmt 준비 (최초 1회)
./tools/script-verification/bin/run.sh           # 정적 검사·회귀 테스트
```

pre-commit 훅이 위 검증을 순서대로 실행하므로 커밋 전 로컬에서 실패를 미리 잡을 수
있습니다. 훅을 우회하지 마세요(`--no-verify` 금지).

## 코딩 규칙

- **의존성 방향을 지킵니다.** 특히 Domain/Data/Core는 서로 및 App/Feature/UI에
  의존하지 않습니다. 금지된 의존성 목록은
  [아키텍처 문서 7.1](sources/docs/architecture.md)을 참고합니다.
- **의존성은 생성자 주입**으로 전달합니다. `@Dependency` 키, Service Locator, 전역
  mutable container를 production 의존성 전달 수단으로 쓰지 않습니다.
- **공개 이름은 책임과 필요한 최소 문맥을 드러냅니다.** 일괄 접두어·접미어·축약을
  적용하지 않고 외부 고정 명칭과 공급자 중립 경계를 구분하며, 세부 기준은
  [네이밍 가이드](sources/docs/naming.md)를 따릅니다.
- **Target과 폴더 이름을 구분합니다.** target은 패키지 문맥을 포함할 수 있지만,
  `sources/Projects/<패키지>/` 안의 source·test 폴더는 역할만 사용합니다. 새 target은
  `sourceDirectory`를 명시해 target 이름의 패키지 접두어를 폴더에 반복하지 않습니다.
- **테스트 함수 이름은 한국어 동작 문장으로 작성하고 Swift Testing을 기본으로
  사용합니다.** XCTest는 UI 자동화처럼 필요한 플랫폼 기능으로 제한하며, 세부 기준은
  [테스트 작성 컨벤션](sources/docs/test-conventions.md)을 따릅니다.
- 패키지별 세부 규칙은 수정 전에 해당 문서를 확인합니다:
  [App](sources/docs/package-rules/app.md) ·
  [Composition](sources/docs/package-rules/composition.md) ·
  [Feature](sources/docs/package-rules/feature.md) ·
  [Domain](sources/docs/package-rules/domain.md) ·
  [Data](sources/docs/package-rules/data.md) ·
  [Infrastructure](sources/docs/package-rules/infrastructure.md) ·
  [UI](sources/docs/package-rules/ui.md)
- Swift 포맷팅은 빌드 시 Swift Style의 `FormatSwift` 플러그인이 자동 적용합니다.
  별도로 포맷 도구를 수동 실행할 필요는 없지만, staged 파일과 포맷 결과가 다르면
  pre-commit이 커밋을 막습니다 — 변경 파일을 다시 stage하세요.
- POSIX 셸 스크립트는 `.agents/skills/write-project-scripts`의
  [아키텍처](.agents/skills/write-project-scripts/references/architecture.md)와
  [컨벤션](.agents/skills/write-project-scripts/references/conventions.md)을
  따릅니다.

## 커밋 메시지

제목 형식은 `[Tag] Message`입니다 (예: `[Fix] 로그인 취소 시 로딩 상태가 유지되는
문제 수정`). Tag 종류와 선택 기준은
[COMMIT_CONVENTION.md](.github/COMMIT_CONVENTION.md)를 따릅니다. `commit-msg` 훅이
제목 형식을 강제합니다.

## Spec-Kit 작업 범위

이 저장소는 `.agents/skills/speckit-*` 스킬로 기능 명세·계획·작업을 관리합니다.
**각 스킬은 정해진 경로만 수정할 수 있습니다** — 범위 밖 파일은 읽기만 하고, 수정이
필요하면 해당 스킬을 실행하거나 사용자에게 직접 확인받습니다.

| 스킬 | 허용 수정 경로 |
| --- | --- |
| `speckit-specify` | `specs/<feature>/**`, `.specify/feature.json` |
| `speckit-clarify` | `specs/<feature>/spec.md`, `specs/<feature>/checklists/requirements.md` |
| `speckit-plan` | `specs/<feature>/plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**` |
| `speckit-tasks` | `specs/<feature>/tasks.md` |
| `speckit-checklist` | `specs/<feature>/checklists/**` |
| `speckit-analyze` | 없음 (읽기 전용) |
| `speckit-converge` | `specs/<feature>/tasks.md` 끝에 새 단계 추가만 |
| `speckit-implement` | 활성 `tasks.md`에 명시된 파일, `tasks.md`의 완료 표시 |
| `speckit-taskstoissues` | 로컬 파일 없음; 확인된 원격 저장소의 GitHub 이슈만 생성 |
| `speckit-constitution` | `.specify/memory/constitution.md`, 연동 템플릿, `.agents/skills/speckit-*/SKILL.md` |

기능 명세는 사용자에게 관찰되는 동작 변경뿐 아니라 내부 품질·구조·운영·개발 경험,
리팩터링·스타일·의존성 갱신에도 작성할 수 있습니다. 작성 여부는 변경의 위험·범위·협업
비용과 검증 필요성으로 결정하며, 내부 변경은 최종 사용자 가치를 꾸며내지 않고 실제
이해관계자와 검증 가능한 결과를 명시합니다. 전체 원칙은
[Constitution](.specify/memory/constitution.md)을 참고합니다.

<!-- init-speckit-ko:start -->
## 한국어 Spec Kit 운영 지침

- 사용자와의 대화, 진행 상황, 최종 답변을 한국어로 작성한다.
- Spec Kit으로 만드는 헌법, 기능 명세, 구현 계획, 조사 문서, 데이터 모델, 계약 설명, 빠른 시작, 작업 목록을 한국어로 작성한다.
- 코드 식별자, 명령어, 파일 경로, 프로토콜 이름, 외부 API의 고유 명칭은 원문을 유지한다.
- 요구사항은 검증 가능한 문장으로 작성하고, 모호한 번역보다 기술적 정확성을 우선한다.
- `$speckit-constitution` → `$speckit-specify` → `$speckit-plan` → `$speckit-tasks` → `$speckit-implement` 순서를 기본 워크플로로 사용한다.
<!-- init-speckit-ko:end -->

## PR 작성

PR은 [PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md) 형식을
따릅니다. 실제로 실행한 검증만 기록하고, 수행하지 않은 검증을 수행한 것처럼
작성하지 않습니다. 원칙의 예외를 적용했다면 이유·영향·미검증 범위를 PR에 남깁니다
(Constitution 원칙 3).

## 저장소 구조

```text
.
├── sources/            # iOS 앱, Tuist workspace, 아키텍처 문서
├── .specify/           # Spec Kit 설정과 Constitution
├── .agents/skills/     # 프로젝트 전용 에이전트 스킬 (Spec-Kit, 셸 스크립트)
├── specs/              # 기능 명세 (speckit-specify 산출물)
├── .github/            # CI, 커밋 컨벤션, PR 템플릿
└── tools/
    ├── githooks/            # Git Hook 및 저장소 자동화
    ├── repository-paths/    # 저장소 공용 경로 관리
    ├── script-tests/        # 프로젝트 셸 회귀 테스트 실행
    ├── script-verification/ # POSIX 셸 정적·회귀 검증
    └── swift-style/         # Swift 포맷·린트 도구
```
