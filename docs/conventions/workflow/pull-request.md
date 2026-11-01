# PR 작성과 머지

[Git It iOS 작업 흐름 컨벤션](../workflow.md)의 규칙 문서입니다.

**PR은 브랜치마다 하나를 `develop`으로 내고, 본문은
[PR 템플릿](../../../.github/PULL_REQUEST_TEMPLATE.md)을 따릅니다.** 제목 형식은
[커밋 컨벤션](../../../.github/COMMIT_CONVENTION.md)의 `[Tag] Message`를 씁니다.

- 본문에 issue 번호와 그 PR이 맡은 항목을 적고, 끝낸 항목을 issue에서 체크합니다.
- **완료 조건이 다 체크되는 마지막 PR만 `Closes #<번호>`를 씁니다.** 앞선 PR은 `Refs #<번호>`를 씁니다.
  `develop`이 기본 브랜치여서 `Closes`가 머지 즉시 issue를 닫기 때문입니다.
- **issue에 연결된 브랜치의 PR은 `Closes`가 없어도 머지되면 issue를 닫습니다.** 마지막이 아닌 PR을 머지한
  뒤에는 `gh issue reopen <번호> --comment "#<PR> 머지. 남은 항목: …"`로 바로 다시 엽니다.
- **`검사`에는 실제로 실행한 검증만 적습니다.** 명령과 결과를 그대로 쓰고, 실패하면 출력을 붙입니다.
  검증 명령은 [`AGENTS.md`](../../../AGENTS.md)의 빌드·테스트 절을 따릅니다.
- **`미검증·예외`에는 실행하지 않은 검증과 원칙의 예외를 적습니다.** 예외의 이유·영향·검증하지 못한
  범위를 남기는 규칙은 [Constitution](../../../.specify/memory/constitution.md) 원칙 3이 소유합니다.
- 머지는 `gh pr merge <번호> --merge --delete-branch`로 합니다.
