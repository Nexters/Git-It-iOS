# 라벨

[Git It iOS 작업 흐름 컨벤션](../workflow.md)의 규칙 문서입니다.

**카테고리마다 접두사를 붙이고, 한 카테고리에서는 issue 하나에 라벨 하나만 답니다.** 카테고리의 색은
하나이며, 아래 표는 `.tools/issue-workflow/`가 읽는 정본입니다.

| 카테고리 | 라벨 | 뜻 |
| --- | --- | --- |
| `type:` (파랑, 필수) | `type: decision` | 원칙·선택이 필요합니다 |
| | `type: mismatch` | 문서·컨벤션·코드가 서로 다릅니다 |
| | `type: bug` | 동작이 틀렸습니다 |
| | `type: feature` | 새 기능·스펙 작업입니다 |
| | `type: chore` | 동작 그대로 구조·이름·위생을 고칩니다 |
| | `type: tooling` | 개발 도구·에이전트 설정·저장소 설정을 고칩니다 |
| `priority:` (빨강 → 노랑, 필수) | `priority: high` | 지금 하는 작업을 막거나 다음 작업의 전제입니다 |
| | `priority: medium` | 이번 단계 안에 합니다 |
| | `priority: low` | 기회가 있을 때 합니다 |
| `status:` (회색, 선택) | `status: on-hold` | 지금 하지 않습니다 |
| | `status: blocked` | 선행 issue가 끝나야 합니다. 본문에 그 번호를 적습니다 |

- GitHub 기본 라벨은 쓰지 않습니다. `duplicate`·`question`·`wontfix`만 닫는 사유로 씁니다.
- 영역(레인) 라벨은 두지 않습니다. 레인은 본문의 `범위(경로)`와 브랜치 이름이 말합니다.
