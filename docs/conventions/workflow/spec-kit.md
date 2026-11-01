# Spec Kit 연결

[Git It iOS 작업 흐름 컨벤션](../workflow.md)의 규칙 문서입니다.

**Spec Kit 작업도 issue에서 시작합니다.** issue 브랜치를 낸 뒤 그 브랜치에서 `$speckit-specify`를
실행하므로, 일반 기능의 브랜치는 `$speckit-specify`가 아니라 [작업 흐름 도구](./tooling.md)가 만듭니다.
기능의 canonical identity와 브랜치 검증은 [Constitution](../../../.specify/memory/constitution.md) 원칙 8이
소유합니다.

- spec 하나는 브랜치 하나에 연결됩니다. 한 결과가 여러 spec을 낳으면 같은 issue에서 브랜치를 여럿 내며,
  같은 레인의 브랜치는 [한 번에 하나](./branch.md)입니다.
- issue의 완료 조건은 결과 기준이고 `tasks.md`의 작업은 그 결과를 만드는 실행 단위입니다. 작업을 issue로
  옮기지 않습니다.
- `specs/`와 `docs/spec-kit/`은 어느 [레인](./lane.md)에도 속하지 않아 기능 브랜치에서 그대로 수정합니다.

Spec Kit 단계는 issue를 읽기만 합니다. issue 체크, 다시 열기와 닫기는 PR 단계에서 합니다.

| 단계 | issue 연결 |
| --- | --- |
| `$speckit-specify` | `read-issue.sh`로 issue를 확인하고, 목적·범위·완료 조건 안에서 명세를 씁니다. spec의 `연결 issue`에 번호를 남깁니다 |
| `$speckit-analyze` | 요구사항이나 작업과 대응되지 않는 완료 조건, 범위를 벗어난 요구사항과 작업을 보고합니다 |
| `$speckit-implement` | 커밋 메시지에 `Refs: #<번호>`를 넣습니다 |
| `$speckit-converge` | PR에 `Closes`와 `Refs` 중 무엇을 쓸지 알려 줍니다 |
