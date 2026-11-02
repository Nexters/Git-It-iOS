# 작업 흐름 도구

[Git It iOS 작업 흐름 컨벤션](../workflow.md)의 규칙 문서입니다.

**issue 생성과 브랜치 시작은 `.tools/issue-workflow/bin/`의 공개 명령으로 합니다.** 에이전트는 이 순서를
담은 `/write-issue` 스킬을 씁니다. 모든 명령은 `gh` 인증이 필요합니다.

| 하는 일 | 명령 |
| --- | --- |
| issue 만들기 | `create-issue.sh --title <목적 문장> --label <라벨> … [--template task\|mismatch] [--body-file <경로>]` |
| 브랜치 시작 | `start-branch.sh <번호> --domain <도메인> --topic <내용> [--check]` |
| issue 문맥 읽기 | `read-issue.sh [--branch <이름>]` |
| 편집 전 검사 | `check-branch.sh [--branch <이름>] [--file <경로>]` |
| 실제 흐름 측정 | `measure-flow.sh --branch <이름> [--repeat <횟수>] [--label-probe] [--summary <파일>]` |

- `create-issue.sh`는 제목 길이와 [라벨](./label.md) 규칙을 검사합니다. `--body-file`이 없으면 템플릿 본문의
  `목적`을 제목으로 채웁니다.
- `start-branch.sh`는 열린 issue에서만 브랜치를 내고, 그 브랜치를 issue에 연결합니다. 시작 기준은
  [라벨](./label.md)과 [브랜치 이름](./branch.md)이 소유하며, 어기면 브랜치를 내지 않습니다. `--check`는 같은
  기준으로 판정만 하고 브랜치를 내지 않습니다.
- `read-issue.sh`는 브랜치 이름의 issue가 열려 있고 [라벨](./label.md) 기준에 맞는지 확인한 뒤 번호, 제목,
  라벨과 본문을 출력합니다. 브랜치를 지정하지 않으면 현재 브랜치를 읽습니다.
- 두 명령은 `gh` 실패로 상태를 확인할 수 없으면 멈춥니다. 이 검사는 잠금이 아니므로 거의 동시에 시작한
  브랜치까지 막지는 못합니다.
- `measure-flow.sh`는 실제 `gh`로 위 명령의 판정과 소요 시간을 잽니다. 예산은 `gh` 1회 조회의 중앙값에 명령이
  부르는 호출 수를 곱하고 1초를 더한 값입니다. 브랜치는 내지 않으며, `--label-probe`를 주면 판정이 모두 맞을
  때만 issue에 `status:` 라벨을 잠깐 달았다가 뗍니다. `issue-workflow`를 고친 PR에서는
  `.github/workflows/issue-workflow.yml`이 이 명령을 실행하고 표를 run 요약에 남깁니다.

## 편집 전 hook

`.agents/settings.json`의 PreToolUse hook이 편집 도구를 실행하기 전에 `check-branch.sh`를 호출합니다.

- 다음 경우 편집을 막습니다: `main`·`develop`, detached HEAD, 이름 형식이 틀린 브랜치, 없거나 닫힌 issue의
  브랜치, 브랜치 도메인과 다른 [레인](./lane.md)의 경로.
- `hotfix/`·`release/` 브랜치, Git이 무시하는 파일, 저장소 밖 파일은 막지 않습니다.
- `gh` 실패로 issue 상태를 확인할 수 없으면 막지 않고 경고만 남깁니다. 확인한 상태는 10분간 재사용합니다.
- hook은 편집 도구만 봅니다. 셸 명령이나 사람의 직접 편집은 막지 않으므로 규칙은 리뷰에서도 확인합니다.
