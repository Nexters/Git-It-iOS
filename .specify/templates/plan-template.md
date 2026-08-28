# 구현 계획: [FEATURE]

**Git-flow 유형**: `[feature | hotfix | release]`

**브랜치**: `[speckit-specify가 직접 생성 또는 재사용을 확인한 type/short-name]`

**날짜**: [DATE] | **명세**: [link]

**입력**: `/specs/[###-feature-name]/spec.md`의 기능 명세

**참고**: 이 템플릿은 `/speckit-plan`이 채운다. 스킬 정의에는 실행 흐름이 설명되어 있다.

## 요약

[기능 명세의 핵심 요구사항과 조사에서 도출한 기술 접근 방식을 요약]

## 기술 맥락

<!--
  조치 필요: 이 섹션의 내용을 프로젝트의 기술 세부 사항으로 교체한다.
  여기의 구조는 반복 과정을 안내하기 위한 권고 형식이다.
-->

**언어/버전**: [예: Python 3.11, Swift 5.9, Rust 1.75 또는 NEEDS CLARIFICATION]

**주요 의존성**: [예: FastAPI, UIKit, LLVM 또는 NEEDS CLARIFICATION]

**저장소**: [해당하는 경우, 예: PostgreSQL, CoreData, 파일 또는 N/A]

**테스트**: [예: pytest, XCTest, cargo test 또는 NEEDS CLARIFICATION]

**대상 플랫폼**: [예: Linux 서버, iOS 15+, WASM 또는 NEEDS CLARIFICATION]

**프로젝트 유형**: [예: 라이브러리/CLI/웹 서비스/모바일 앱/컴파일러/데스크톱 앱 또는 NEEDS CLARIFICATION]

**성능 목표**: [도메인별 목표, 예: 1000 req/s, 10k lines/sec, 60 fps 또는 NEEDS CLARIFICATION]

**제약 조건**: [도메인별 제약, 예: <200ms p95, <100MB 메모리, 오프라인 지원 또는 NEEDS CLARIFICATION]

**규모/범위**: [도메인별 규모, 예: 사용자 1만 명, 100만 LOC, 화면 50개 또는 NEEDS CLARIFICATION]

## 헌법 점검

*게이트: 0단계 조사 전에 통과해야 하며 1단계 설계 후 다시 점검한다.*

[헌법 파일을 바탕으로 결정한 게이트]

**브랜치 네임스페이스**: 이 헌법 개정 후 새로 생성한 브랜치는 `feature/`, `hotfix/`,
`release/` 중 목적에 맞는 네임스페이스를 사용해야 한다. 개정 전에 생성된 기존 브랜치는
소급해 바꾸지 않고 기존 브랜치임을 기록한다. `/speckit-specify`는 명세 산출물을 만들기
전에 현재 HEAD에서 검증된 브랜치를 직접 생성하거나 이미 현재인 동일 브랜치를 재사용해야
하며, branch 생성에 실패한 명세로 계획을 진행하지 않는다. `before_specify` hook은 브랜치
생성이나 전환을 대신 수행하지 않는다.

**허용 수정 경로**: 이 명령은 이 기능의 `plan.md`, `research.md`, `data-model.md`,
`quickstart.md`, `contracts/**`만 수정할 수 있다. 이 산출물 밖의 구현 파일은 정확한
경로를 `tasks.md`에 기록하며 계획 단계에서는 수정하지 않는다.

**세션 지식 기록**: 적용 여부와 문턱은 Constitution 원칙 9를 정본으로 따른다. 기록 조건을
충족하면 해당 전용 스킬을 별도로 사용하며 계획 산출물이나 구현 작업으로 만들지 않는다.

**Git 실행 직렬화**: 같은 checkout에서 `git commit`, pre-commit과 staged formatter처럼
Git index, 작업 파일 또는 공유 formatter cache를 사용하는 변경 체인은 하나만 실행한다.
기존 체인의 종료와 결과를 확인하기 전에는 재시도하지 않으며, 중복 실행을 발견하면 실행
소유자와 index·작업 파일 상태를 확인하고 사용자 승인 없이 임의로 종료하지 않는다. 읽기
전용 Git 조회, 서로 다른 checkout과 실행별로 격리된 build·test 경로는 이 제한에서 제외한다.

**커밋 단위 구현**: `/speckit-implement`는 미완료 작업을 실행 시점에 논리적이고 독립적으로
되돌릴 수 있는 커밋 단위로 설계한다. 단일 패키지가 기본이며, 분리하면 compile되지 않는
공개 API 이전이나 공용 manifest 변경은 근거와 통합 검증을 가진 다중 패키지 단위로 묶는다.
각 단위는 작업 ID, 정확한 파일,
검증과 커밋 메시지를 명시하고, 구현·검증·`tasks.md` 완료 표시·정확한 staging·commit 성공
확인을 마친 뒤에만 다음 단위로 진행한다. 훅을 우회하거나 무관한 변경을 포함하거나 amend,
rebase, push하지 않는다. 마지막 적용 패키지의 마지막 단위는 전체 읽기 전용 검증과 필수
`after_implement` hook까지 실행·재검증한 뒤 최종 commit한다. 시작 전 tasks.md의 일반 변경은
blob hash와 전체 diff로 기준선을 고정하며 별도 commit은 선택 사항이다. 확정된 기능 범위의
후속 단위와 읽기 전용 전체 검증은 반복 승인 없이 진행하고 새 권한이 필요한 경우에만 중단한다.

**책임 기반 네이밍**: 프로젝트가 소유하는 공개 API와 경계를 넘는 값은 실제 책임과 필요한
최소 문맥을 드러내야 한다. 표면적인 통일만을 위한 공통 접두어·접미어·축약은 적용하지 않고,
저장·전달되는 값은 독립적으로 목적을 식별할 수 있게 계획한다. 외부 계약의 고정 이름은
보존하고 공급자 중립 경계에는 특정 공급자나 저장 기술의 용어를 노출하지 않는다. 네이밍과
설계·동작 변경이 함께 필요하면 범위와 검증을 분리한다. `docs/conventions/naming.md`가 없으면
Constitution 원칙 10을 직접 적용하고, 문서가 작성된 뒤에는 세부 기준과 예외를 함께 참조한다.

**실행 단위 진행**: 현재 명세가 변경하는 패키지를 식별하고 의존성 위상 순서로 구현 경계를
계획한다. 단일 패키지 단위를 기본으로 하되 분리하면 중간 상태가 깨지는 경우에는 불가분한
다중 패키지 integration unit을 사용한다. 각 단위의 변경 파일과 검증 결과를 진행 상황으로
보고하며 같은 기능 범위의 다음 단위는 반복 승인 없이 진행한다. 공용 구성 파일이나 공개 API
이전이 여러 패키지를 함께 바꿔야 안전하면 분리 불가 근거, 정확한 경로와 통합 검증을 기록한다.
패키지에 속하지 않는 파일도 책임 단위에 배정하며, 배정할 수 없으면 계획을 중단한다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/[###-feature]/
├── plan.md              # 이 파일(/speckit-plan 산출물)
├── research.md          # 0단계 산출물(/speckit-plan)
├── data-model.md        # 1단계 산출물(/speckit-plan)
├── quickstart.md        # 1단계 산출물(/speckit-plan)
├── contracts/           # 1단계 산출물(/speckit-plan)
└── tasks.md             # 2단계 산출물(/speckit-tasks, /speckit-plan이 생성하지 않음)
```

### 소스 코드(저장소 루트)
<!--
  조치 필요: 아래 자리표시자 트리를 이 기능의 실제 구조로 바꾼다. 사용하지 않는 선택지는
  삭제하고 선택한 구조에는 실제 경로(예: apps/admin, packages/something)를 확장해 적는다.
  완성된 계획에는 선택지 라벨을 남기지 않는다.
-->

```text
# [사용하지 않으면 제거] 선택지 1: 단일 프로젝트(기본)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [사용하지 않으면 제거] 선택지 2: 웹 애플리케이션("frontend" + "backend"가 있는 경우)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [사용하지 않으면 제거] 선택지 3: 모바일 + API("iOS/Android"가 있는 경우)
api/
└── [위 backend와 동일한 구조]

ios/ 또는 android/
└── [플랫폼별 구조: 기능 모듈, UI 흐름, 플랫폼 테스트]
```

**구조 결정**: [선택한 구조를 설명하고 위에 기록한 실제 디렉터리를 참조]

## 복잡성 추적

> **헌법 점검에서 정당화해야 하는 위반이 있을 때만 작성한다**

| 위반 | 필요한 이유 | 더 단순한 대안을 기각한 이유 |
|------|-------------|-------------------------------|
| [예: 네 번째 프로젝트] | [현재 필요] | [세 프로젝트로 부족한 이유] |
| [예: Repository 패턴] | [구체적인 문제] | [직접 DB 접근으로 부족한 이유] |
