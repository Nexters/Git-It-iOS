# Git It iOS

Git It의 iOS 애플리케이션 저장소입니다.

## 기술 구성

- iOS 26.0 이상
- SwiftUI
- Tuist

## 주요 명령어

프로젝트 설정 및 개발 편의를 위해 Makefile 스크립트를 제공합니다. 처음 내려받은 후 `make init`을 실행하세요.

| 명령어 | 설명 |
| --- | --- |
| `make init` | **저장소 초기화** (Tuist 앱·편집 workspace, Git 훅, Claude 링크, VS Code workspace 설정) |
| `make tuist` | Tuist 패키지 해결·생성 및 심볼릭 링크 갱신 |
| `make clean` | Tuist 로컬 캐시 및 아티팩트 정리 |
| `make hooks` | Git Hook 경로(`tools/githooks`) 지정 및 권한 설정 |
| `make format` | 현재 변경된 Swift 소스 파일만 포매팅 |
| `make verify-tools` | 셸 스크립트 검증 도구(ShellCheck, shfmt) 다운로드 및 준비 |

`make hooks`는 커밋 메시지 형식 검사와 검증 훅을 설치합니다. 현재는 빌드·컴파일·테스트·린트·포맷 검증을 기본 비활성화했습니다.
커밋 전 검증은 `tools/githooks/pre-commit.d/enabled`에서 필요한 단계의 주석을 풀어 다시 켭니다.
push 전 검증은 `GIT_IT_PRE_PUSH_VALIDATION_ENABLED=true git push`로 다시 켤 수 있습니다.
CI 검증 job은 GitHub Actions repository variable `GIT_IT_CI_VALIDATION_ENABLED`가 정확히 `true`일 때만 실행됩니다.
이 변수를 삭제하거나 다른 값으로 바꾸면 다시 비활성화되며, 변경 분류와 최종 gate job은 검증 job이 생략된 상태로 성공합니다.

`make init`은 Tuist package를 설치하고 앱용 `sources/GitIt.xcworkspace`와 manifest 편집용
`sources/Manifests.xcworkspace`를 생성합니다. 이어서 저장소 루트에 각각
`GitIt.xcworkspace`와 `Edit-Tuist.xcworkspace` 심볼릭 링크를 만들고, `CLAUDE.md`,
`.claude` 링크도 갱신합니다. `specs/`와 `docs/`를 폴더로 등록한
`Documents-Workspace.code-workspace`도 저장소 루트에 생성합니다.
링크 위치에 일반 파일이나 디렉터리가 있으면 자동으로 삭제하지 않고 초기화를 중단합니다.

## 저장소 구조

```text
.
├── sources/            # iOS 앱 소스와 Tuist 패키지
├── docs/               # 아키텍처·컨벤션·패키지 규칙 및 세션 기록
├── specs/              # 기능 명세 및 계획 산출물 (Spec Kit)
├── .specify/           # Spec Kit 설정과 상위 원칙(Constitution)
├── .agents/            # 프로젝트 전용 에이전트 스킬 (커스텀 툴)
├── .github/            # GitHub CI/CD 및 커밋·PR 규칙
└── tools/              # 저장소 자동화 도구
```
