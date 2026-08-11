<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0
- Modified principles: 없음
- Added principles: 6. Spec-Kit 산출 문서의 한국어 고정
- Added sections: 없음
- Removed sections: 없음
- Templates requiring updates: ⚠ 보류 — `.specify/templates/plan-template.md`
- Templates requiring updates: ⚠ 보류 — `.specify/templates/spec-template.md`
- Templates requiring updates: ⚠ 보류 — `.specify/templates/tasks-template.md`
- Templates requiring updates: ⚠ 보류 — `.specify/templates/checklist-template.md`
- Templates requiring updates: ⚠ 보류 — `.specify/templates/constitution-template.md`
- Commands requiring updates: ⚠ 보류 — 사용자 지정 정책 문서 단일 수정 범위
- Follow-up TODOs: 없음
-->

# Git-It Constitution

**상태**: Ratified<br>
**버전**: 1.1.0<br>
**비준일**: 2026-08-08<br>
**최종 수정일**: 2026-08-11

## 원칙

### 1. 명시적인 경계

- 모듈은 책임과 공개 API를 명확히 구분합니다.
- 의존성은 Tuist에 명시하고 순환 의존을 허용하지 않습니다.
- 모듈 설계와 의존 관계는 [아키텍처 문서](../../sources/docs/architecture.md)를 기준으로 합니다.

### 2. 상태와 데이터 안전성

- 변경 가능한 상태에는 소유자와 수명 범위를 둡니다.
- 비동기 작업은 오류와 취소 경로를 처리합니다.
- 개인정보는 기능에 필요한 범위에서만 사용하고 외부 입력은 사용 전에 검증합니다.

### 3. 검증 가능한 변경

- 동작 변경에는 관련 빌드나 테스트 결과를 남깁니다.
- 문서는 정의된 범위만 다루며, 아키텍처 문서는 구조 결정이 바뀔 때만 갱신합니다.
- 원칙의 예외는 이유, 영향과 검증하지 못한 범위를 PR에 기록합니다.

### 4. 스킬별 수정 경로

- 수정 권한은 세션의 전역 디렉터리가 아니라 실행한 Spec-Kit 스킬의 허용 경로로
  결정합니다. 허용 목록 밖의 파일은 읽을 수만 있으며 수정하려면 해당 책임을 가진
  스킬 또는 별도 사용자 지시가 필요합니다.
- `/speckit-implement`는 활성 `tasks.md`에 정확히 명시된 파일과 `tasks.md`의 완료
  표시만 수정할 수 있습니다. `sources/**`는 구현 대상의 기본 위치일 뿐, 유일한
  허용 경로가 아닙니다.
- 하나의 변경은 한 스킬의 허용 경로 안에서 완료합니다. 다른 스킬의 산출물 또는
  허용되지 않은 경로가 필요하면 중단하고 적절한 스킬을 실행하거나 사용자 승인을
  받습니다.
- 기능 명세는 사용자가 관찰할 수 있는 동작이 바뀌는 변경에만 작성합니다. 외부 동작이
  없는 리팩터링, 스타일과 의존성 갱신에는 작성하지 않습니다.

### 5. Spec-Kit 범위

- Spec-Kit 스킬은 아래 허용 경로만 수정합니다. `<feature>`는 활성 기능 디렉터리입니다.

| 스킬 | 허용 수정 경로 |
| --- | --- |
| `speckit-specify` | `specs/<feature>/**`, `.specify/feature.json` |
| `speckit-clarify` | `specs/<feature>/spec.md`, `specs/<feature>/checklists/requirements.md` |
| `speckit-plan` | `specs/<feature>/plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**` |
| `speckit-tasks` | `specs/<feature>/tasks.md` |
| `speckit-checklist` | `specs/<feature>/checklists/**` |
| `speckit-analyze` | 없음(읽기 전용) |
| `speckit-converge` | `specs/<feature>/tasks.md` 끝에 새 Convergence 단계 추가만 |
| `speckit-implement` | 활성 `tasks.md`에 정확히 적힌 파일, `specs/<feature>/tasks.md`의 완료 표시 |
| `speckit-taskstoissues` | 로컬 파일 없음; 확인된 원격 저장소의 GitHub 이슈 생성만 |
| `speckit-constitution` | `.specify/memory/constitution.md`, 연동 템플릿, `.agents/skills/speckit-*/SKILL.md` |
- 각 스킬 문서는 위 표와 같은 범위를 자체적으로 명시해야 합니다. 경로를 와일드카드로
  넓히거나 새 경로를 추가하려면 constitution 개정이 필요합니다.

### 6. Spec-Kit 산출 문서의 한국어 고정

- Spec-Kit 스킬이 생성하거나 수정하는 모든 사람이 읽는 산출물은 한국어로 작성해야
  합니다(`MUST`). 이 규칙은 헌법, 기능 명세, 계획, 조사, 데이터 모델, 계약 설명,
  빠른 시작 안내, 작업 목록, 체크리스트, 분석·완료 보고와 GitHub 이슈의 제목·본문에
  적용합니다.
- 제목, 섹션명, 표 머리글, 요구사항·시나리오·작업 설명, 체크리스트 항목, 주석과
  사용자용 안내 문구도 한국어로 작성해야 합니다(`MUST`). 영문 템플릿을 사용한 경우
  독자용 영문 골격과 예시 문구를 최종 산출물에 남겨서는 안 됩니다(`MUST NOT`).
- 코드 식별자, API·타입·스키마·필드 이름, 파일 경로, 명령어, 브랜치 이름, 표준화된
  식별자(`FR-001`, `SC-001`, `T001`, `[P]`, `[US1]`), 규범 키워드(`MUST`,
  `SHOULD`, `MAY`, `MUST NOT`), 기술·제품의 공식 고유명사와 실행 가능한 구문은 원문을
  유지합니다. 외국어 원문 인용이 정확성에 필요하면 인용문을 유지할 수 있지만 바로 이어
  한국어 설명을 제공해야 합니다(`MUST`).
- 각 Spec-Kit 스킬은 완료 전에 산출물의 독자용 문구를 검사해야 합니다. 허용된 예외가
  아닌 외국어 문구가 남아 있으면 헌법 위반으로 처리하고 완료를 보고해서는 안 됩니다
  (`MUST NOT`).

## 적용

이 문서는 기능 명세, 구현 계획과 작업 문서보다 우선합니다. 하위 문서가 이 문서와
충돌하면 이 문서에 맞게 하위 문서를 수정합니다.

**개정 절차**: 원칙을 추가, 삭제 또는 재정의하려면 변경 이유와 영향 범위를 PR
설명에 기록하고, 저장소 관리자(코드 소유자)의 승인을 받아야 합니다. 기존 원칙과
충돌하는 진행 중인 작업이 있다면 개정과 함께 이관 계획을 명시합니다.

**버전 정책**: 버전은 MAJOR.MINOR.PATCH 형식을 따릅니다. 기존 원칙의 삭제나 하위
호환되지 않는 재정의는 MAJOR, 원칙 신설이나 지침의 실질적 확장은 MINOR, 표현 수정과
같은 비의미적 변경은 PATCH로 표기합니다.

**준수 검토**: 모든 PR과 리뷰는 이 문서의 원칙 준수 여부를 확인합니다. 원칙의 예외를
적용한 경우 원칙 3에 따라 이유, 영향과 검증하지 못한 범위를 PR에 기록해야 하며,
기록이 없는 예외는 병합할 수 없습니다.
