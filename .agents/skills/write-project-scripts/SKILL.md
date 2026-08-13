---
name: write-project-scripts
description: 프로젝트가 소유한 POSIX sh 스크립트와 Git 훅을 작성·수정·리팩터링·리뷰하고, 기능 중심 계층 구조·의존 방향·경로 안전성·rollback·진단 규칙을 적용하며 ShellCheck와 shfmt 검증을 수행한다. 프로젝트의 `tools/githooks/`, 셸 아키텍처, 스크립트 컨벤션, 검증 도구 의존성을 변경하거나 새 자동화 스크립트를 추가할 때 사용한다.
---

# 프로젝트 스크립트 작성

## 필수 참조

작업 전에 다음 문서를 모두 읽는다.

- [아키텍처](references/architecture.md): 기능 경계, 계층 책임과 의존 방향
- [작성 컨벤션](references/conventions.md): POSIX sh, 경로 전달, 오류 처리와 rollback

ShellCheck·shfmt 버전, checksum, 준비 또는 복구를 변경할 때만 [검증 도구 의존성](references/dependencies.md)을 추가로 읽는다.

## 작업 절차

1. 저장소의 `AGENTS.md`, Git 상태, 대상 스크립트와 인접 테스트를 확인한다.
2. 변경 책임을 하나의 기능 모듈에 배치하고 `bin → core` 방향을 유지한다. 다른 기능의 내부 계층을 source하지 않는다.
3. 동작 변경이면 격리된 POSIX sh 회귀 테스트를 먼저 추가하거나 수정한다. 경로에는 공백·한글·개행이 올 수 있다고 가정하고 Git 경로는 NUL 경계를 보존한다.
4. `apply_patch`로 구현한다.
5. 모든 스크립트 작성 시 과도한 복잡성을 피하고 단순화된 Clean Architecture(bin, core, tests)를 유지하며, 코드의 주요 동작과 단계마다 간단한 주석을 의무적으로 작성한다.
6. Bash 전용 문법, 암묵적 전역 상태, 중요 생산 명령의 상태를 잃는 pipeline을 사용하지 않는다.
7. 변경한 기능의 `tests/test-*.sh`를 `/bin/sh`로 직접 실행한다. 스킬의 검증기는 다른 기능 테스트를 대신 실행하지 않는다.
8. [아키텍처](references/architecture.md)와 [작성 컨벤션](references/conventions.md)을 변경 범위에 맞게 검토한다. 구조적 예외가 생기면 이유, 영향과 검증하지 못한 범위를 변경의 자연어 문서에 기록한다.
9. 저장소 루트에서 다음 공용 검증을 실행한다.

```sh
./tools/script-verification/bin/run.sh
```

검증기는 프로젝트 셸과 Git 훅을 입력으로 읽어 `/bin/sh -n`, ShellCheck, shfmt를 수행하고 자체 회귀와 체크리스트를 검사한다. 다른 프로젝트 스크립트, 기능 테스트 또는 프로젝트 빌드를 실행하거나 source하지 않는다.

10. 프로젝트 빌드가 필요한 변경이면 해당 기능의 공개 빌드 명령을 별도로 실행한다. 검증기 인자로 빌드를 요청하지 않는다.

## 검증 도구 준비

검증 도구가 누락되거나 lock과 다를 때만 다음 명시적 준비 명령을 실행한다.

```sh
./tools/script-verification/bin/prepare-tools.sh
```

공용 검증 중에는 네트워크 접근, 자동 설치 또는 `.build/` 변경을 허용하지 않는다. `.build/`의 생성 artifact를 직접 편집하거나 Git에 추가하지 않는다.

## 완료 조건

- 대상 기능의 직접 회귀가 통과한다.
- 스킬의 공용 검증이 통과한다.
- 다른 기능 내부 계층에 새 의존이 없다.
- 작업 트리와 Git index에 의도하지 않은 변경이 없다.
- 공개 경로나 책임이 바뀌면 사용자 문서와 이 스킬의 참조 문서를 함께 갱신한다.
