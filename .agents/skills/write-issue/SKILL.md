---
name: write-issue
description: 작업을 시작할 때 쓴다. 목적 문장으로 issue를 찾거나 만들고, 그 issue에서 feature 브랜치를 낸다. 규칙은 다시 적지 않고 순서와 명령만 적는다.
---

# issue 작성

규칙의 정본은 [작업 흐름 컨벤션](../../../docs/conventions/workflow.md)이다. 이 스킬은 순서만 적는다.

## 순서

1. **얻으려는 결과를 목적 문장으로 쓴다.** 형식은 [issue 작성](../../../docs/conventions/workflow/issue.md)을 따른다.
2. **같은 결과의 issue가 있는지 본다.** `gh issue list --state open`으로 확인한다. 있으면 시작한 issue여도 그 issue의 완료 조건에 항목을 더하고 4로 간다.
3. **없으면 만든다.** 라벨은 [라벨](../../../docs/conventions/workflow/label.md) 표에서 카테고리마다 하나를 고른다.

   ```bash
   .tools/issue-workflow/bin/create-issue.sh --title "<목적 문장>" --label "type: <…>" --label "priority: <…>"
   ```

   본문(범위·완료 조건)은 만든 뒤 `gh issue edit <번호> --body-file <파일>`로 채운다. 어긋남 점검표는 `--template mismatch`를 쓴다.
4. **브랜치를 낸다.** 이번 PR이 맡을 항목의 레인으로 하나 낸다. 도메인은 [레인](../../../docs/conventions/workflow/lane.md) 표의 `도메인` 열이다.

   ```bash
   .tools/issue-workflow/bin/start-branch.sh <번호> --domain <도메인> --topic <내용>
   ```

   issue 상태 때문에 막히면 메시지를 따른다. 기준은 [라벨](../../../docs/conventions/workflow/label.md)과 [브랜치 이름](../../../docs/conventions/workflow/branch.md)이 소유한다. 메시지가 알린 브랜치가 이번 작업이 아니거나 라벨을 떼야 하면 사용자에게 묻는다.
5. **시작한다.** 기능 명세가 필요하면 이 브랜치에서 `$speckit-specify`를 실행한다. 편집 전 hook이 브랜치와 고치려는 파일의 레인을 검사하며, 막히면 그 메시지대로 1~4를 다시 한다.

## 하지 않는 것

- `develop`·`main`에서 편집하지 않는다.
- 닫힌 issue나 다른 결과의 issue에서 브랜치를 내지 않는다.
- 상태 검사를 피하려고 `start-branch.sh` 없이 브랜치를 내지 않는다.
- 규칙 원문을 여기나 스크립트에 옮겨 적지 않는다.
