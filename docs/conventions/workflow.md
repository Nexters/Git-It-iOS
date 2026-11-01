# Git It iOS 작업 흐름 컨벤션

**상태**: 초안

**작성일**: 2026-10-30

**최종 수정일**: 2026-10-30 (최초 작성)

## 목적

이 문서는 작업을 GitHub issue에서 시작해 브랜치와 PR로 끝내는 흐름을 통일합니다. 결과 하나를
issue 하나로 정의하고 그 issue에서 리뷰할 수 있는 크기의 브랜치와 PR을 내어, 무엇을 왜 바꾸는지와
어디까지 끝났는지를 저장소 밖 기억 없이 추적할 수 있게 합니다.

커밋 메시지는 [커밋 컨벤션](../../.github/COMMIT_CONVENTION.md)이, Git-flow 네임스페이스와 기능 식별은
[Constitution](../../.specify/memory/constitution.md) 원칙 8이, 문서 우선순위와 구조는
[컨벤션 공통 원칙](./common/README.md)이 소유합니다.

## 1. 적용 범위

- 저장소의 모든 변경 작업과 그 issue·브랜치·PR
- `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`
- 작업 흐름 도구 `.tools/issue-workflow/`와 편집 전 hook

`hotfix/`·`release/` 브랜치의 규칙은 Constitution 원칙 8이 소유합니다. 패키지 단위의 실행 순서와
다중 패키지 단위는 Constitution 원칙 7이 소유합니다.

## 2. issue

issue는 작업의 시작점이자 진행 상황의 정본입니다. 레인이나 PR 크기가 아니라 얻으려는 결과로 나누고,
남은 일과 범위 밖 문제도 별도 문서가 아니라 issue에 둡니다.

### 2.1 issue 작성

→ [issue 작성](./workflow/issue.md)

### 2.2 라벨

→ [라벨](./workflow/label.md)

### 2.3 어긋남

→ [어긋남](./workflow/mismatch.md)

## 3. 브랜치

브랜치는 issue에서 내며, 이름만으로 어느 issue의 어느 레인 작업인지 드러나야 합니다. 레인은 성격이
다른 변경이 한 PR에 섞이지 않게 하는 경로 묶음입니다.

### 3.1 브랜치 이름

→ [브랜치 이름](./workflow/branch.md)

### 3.2 레인

→ [레인](./workflow/lane.md)

## 4. PR

PR은 issue의 항목 일부를 맡아 끝내는 단위입니다. 실제로 수행한 검증만 남겨, 리뷰어가 issue와 PR만
보고 범위와 근거를 판단할 수 있어야 합니다.

### 4.1 PR 작성과 머지

→ [PR 작성과 머지](./workflow/pull-request.md)

## 5. Spec Kit

Spec Kit은 issue가 정한 결과를 구현으로 옮기는 실행 체계입니다. issue는 결과를, spec과 `tasks.md`는 그
결과를 만드는 설계와 실행 단위를 소유합니다.

### 5.1 Spec Kit 연결

→ [Spec Kit 연결](./workflow/spec-kit.md)

## 6. 도구

규칙의 값은 이 컨벤션의 표가 소유하고, 도구는 표를 읽어 적용합니다. 도구에 규칙을 옮겨 적지 않습니다.

### 6.1 작업 흐름 도구

→ [작업 흐름 도구](./workflow/tooling.md)

## 7. 검토 체크리스트

- [ ] 작업이 열린 issue에서 시작했고, 같은 결과의 issue가 이미 있지 않은가?
- [ ] issue 제목이 공백 포함 50자 이내의 목적 한 문장인가?
- [ ] issue 본문이 `목적`·`범위(경로)`·`완료 조건` 세 절로 되어 있는가?
- [ ] 카테고리마다 라벨이 하나이고 `type:`·`priority:` 라벨이 모두 있는가?
- [ ] 브랜치 이름이 `feature/<issue 번호>-<도메인>-<내용>` 형식인가?
- [ ] PR이 레인 하나의 경로만 고치는가?
- [ ] 이 PR이 맡지 않은 문제를 고치지 않고 issue 항목으로 남겼는가?
- [ ] 마지막 PR에만 `Closes`를 쓰고, 앞선 PR 머지 뒤 issue를 다시 열었는가?
- [ ] PR 검사 절에 실제로 실행한 검증만 있고, 미검증 범위와 원칙의 예외가 기록되었는가?

## 관련 문서

- [Constitution](../../.specify/memory/constitution.md)
- [커밋 컨벤션](../../.github/COMMIT_CONVENTION.md)
- [PR 템플릿](../../.github/PULL_REQUEST_TEMPLATE.md)
- [아키텍처](../architecture.md)

## 문서 변경 기준

issue 단위·본문 구성, 라벨, 브랜치 이름, 레인 경로, PR 본문·머지 방식 또는 Spec Kit과의 연결이 바뀌면
수정합니다. 레인 표와 라벨 표는 도구가 읽으므로 형식을 바꾸면 `.tools/issue-workflow/`와 그 회귀
테스트를 함께 갱신합니다. Git-flow 네임스페이스가 바뀌면 이 문서보다 Constitution 원칙 8을 먼저
개정합니다.
