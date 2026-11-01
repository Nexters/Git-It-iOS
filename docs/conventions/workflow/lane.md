# 레인

[Git It iOS 작업 흐름 컨벤션](../workflow.md)의 규칙 문서입니다.

**feature 브랜치는 레인 하나의 경로만 고치고, PR 하나에 두 레인을 담지 않습니다.** 아래 표는
`.tools/issue-workflow/`가 읽는 정본이며 `도메인` 열이 브랜치 이름의 `<도메인>`입니다.

| 레인 | 도메인 | 얻으려는 것 | 경로 |
| --- | --- | --- | --- |
| 프로젝트 규칙·도구 | `project` | Constitution·에이전트·저장소 설정·개발 도구 | `AGENTS.md` · `Makefile` · `README.md` · `.agents/` · `.editorconfig` · `.github/` · `.gitignore` · `.gitmodules` · `.specify/` · `.tools/` · `.vscode/` |
| iOS 앱 | `ios` | 앱과 패키지 구현 | `sources/` · `.tools/design-rules/config/` · `.tools/package-dependencies/config/` |

- 경로는 저장소 루트 기준이며 백틱으로 씁니다. 빗금으로 끝나면 폴더, 아니면 파일입니다. 여러 경로에
  걸리면 가장 긴 경로의 레인입니다.
- `.tools/`의 두 `config/`는 소스 구조를 옮겨 적은 값이어서 `sources/`와 함께 바뀌므로 `ios`에 둡니다.
- `docs/`와 `specs/`는 어느 레인에도 속하지 않습니다. 규칙 문서와 Spec Kit 산출물은 구현과 함께 바뀌므로
  어느 레인의 브랜치에서든 고칠 수 있습니다.
- `sources/` 안에서 패키지를 어떻게 나눌지는 레인이 정하지 않습니다. 다중 패키지 단위는
  [Constitution](../../../.specify/memory/constitution.md) 원칙 7이 소유합니다.
- 다른 레인의 경로를 고쳐야 하면 그 레인의 브랜치에서 따로 합니다.
- 두 레인을 함께 고쳐야 깨지지 않는 변경도 PR을 나눕니다. 앞 PR이 이전 형식과 새 형식을 함께 받게 하고,
  다음 PR이 다른 레인에서 바꾸고, 마지막 PR이 이전 형식을 지웁니다.
