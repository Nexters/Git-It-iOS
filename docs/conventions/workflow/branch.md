# 브랜치 이름

[Git It iOS 작업 흐름 컨벤션](../workflow.md)의 규칙 문서입니다.

**작업 브랜치는 열린 issue에서 `feature/<issue 번호>-<도메인>-<내용>` 이름으로 냅니다.** Git-flow
네임스페이스와 접미사 형식은 [Constitution](../../../.specify/memory/constitution.md) 원칙 8이 소유하고,
이 문서는 `feature` 접미사의 구성만 정합니다.

- `도메인`은 [레인](./lane.md) 표의 `도메인` 열 값이고, `내용`은 소문자 kebab-case입니다.
- 브랜치는 `develop`에서 내고 PR도 `develop`으로 보냅니다.
- `main`과 `develop`에서는 직접 편집하지 않습니다.
- 닫힌 issue나 다른 결과의 issue에서 브랜치를 내지 않습니다.
- issue마다 레인 하나에 열린 브랜치는 하나입니다. 같은 레인의 브랜치가 남아 있으면 새로 내지 않고 그
  브랜치에서 잇습니다. 다른 레인의 브랜치는 경로가 겹치지 않으므로 함께 열 수 있습니다.
- 진행 중인지는 issue에 연결된 브랜치가 말하므로 진행 중 라벨을 두지 않습니다.
- 머지된 브랜치는 남기지 않습니다. 원격 브랜치는 저장소 설정 `delete_branch_on_merge`가 지우고, 로컬
  브랜치는 머지 뒤 `git branch -d <브랜치>`로 지웁니다. 지워진 원격의 추적 참조는 클론마다
  `git config fetch.prune true`를 두어 정리합니다.

이름 예: `feature/123-ios-sample-screen`, `feature/124-project-sample-tool`.
