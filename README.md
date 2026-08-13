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
| `make init` | **저장소 초기화** (Tuist 워크스페이스 생성 및 Git 훅 설치) |
| `make tuist` | Tuist 패키지 해결·생성 및 심볼릭 링크 갱신 |
| `make hooks` | Git Hook 경로(`tools/githooks`) 지정 및 권한 설정 |
| `make format` | 프로젝트 내 모든 Swift 소스 파일 포매팅 |
| `make verify-tools` | 셸 스크립트 검증 도구(ShellCheck, shfmt) 다운로드 및 준비 |

## 저장소 구조

```text
.
├── sources/            # 실제 iOS 앱 소스, Tuist 패키지와 아키텍처 문서
├── specs/              # 기능 명세 및 계획 산출물 (Spec Kit)
├── .specify/           # Spec Kit 설정과 상위 원칙(Constitution)
├── .agents/            # 프로젝트 전용 에이전트 스킬 (커스텀 툴)
├── .github/            # GitHub CI/CD 및 커밋·PR 규칙
└── tools/              # 저장소 자동화 도구
```