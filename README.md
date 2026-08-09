# Git It iOS

Git It의 iOS 애플리케이션 저장소입니다.

## 기술 구성

- iOS 26.0 이상
- SwiftUI
- Tuist

## 프로젝트 초기화

저장소를 처음 내려받은 후 다음 명령으로 Tuist 프로젝트 생성과 Git 훅 설치를 함께
실행합니다.

```sh
make init
```

`make help`로 각 단계를 개별 실행하는 명령을 확인할 수 있습니다. Makefile은 각 기능의
공개 `bin/` 명령만 순서대로 호출하며 별도 정책을 갖지 않습니다.

`tuist generate`는 `sources/GitIt.xcworkspace`를 생성합니다. `make tuist`(또는
`make init`)는 이어서 저장소 루트에 같은 워크스페이스를 가리키는 심볼릭 링크
`GitIt.xcworkspace`를 만들어 루트에서 바로 Xcode로 열 수 있게 합니다. 실제 파일은
`sources/` 아래에만 있으므로 Projects·Tuist 상대경로 참조가 깨지지 않으며, 빌드
스크립트가 사용하는 `GIT_IT_WORKSPACE_PATH`도 `sources/GitIt.xcworkspace`를 그대로
가리킵니다.

## 프로젝트 생성

```sh
cd sources
tuist install
tuist generate
```

각 패키지 타깃을 빌드하면 빌드 전 단계에서
[Swift Style](https://github.com/0-jerry/Swift-Style)의 `FormatSwift`
플러그인이 Xcode가 전달한 적격 Swift 입력을 자동으로 포매팅합니다. 프로젝트 검증은 다음
세 공개 명령으로 분리됩니다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

`build`는 모든 공유 scheme을 Debug iOS Simulator 대상으로 일반 빌드합니다. `compile`은
테스트가 연결된 scheme을 `build-for-testing`하고, `test`는 같은 Derived Data에서
`test-without-building`으로 테스트 코드를 실행합니다. 테스트 scheme이 없으면 compile/test는
명시적으로 건너뜁니다. 한 scheme이 실패해도 같은 단계의 나머지를 계속 시도하고 마지막에
성공·실패 대상을 요약합니다.

기본 테스트 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`이며 환경에 맞게
`GIT_IT_TEST_DESTINATION`으로 덮어쓸 수 있습니다. 세 명령은 순차 실행을 전제로 하나의
`sources/DerivedData/PreCommit`을 공유하며 `GIT_IT_DERIVED_DATA_PATH`로 경로를 바꿀 수
있습니다. workspace가 없다면 `sources`에서 `tuist generate`를 먼저 실행합니다. package
의존성은 자동으로 해결하지 않으므로 `tuist install`도 사전에 완료해야 합니다.

## Swift 포매팅

pre-commit에서는 staged Swift 파일만 포매팅하고 결과가 Git index와 달라지면 커밋을
중단합니다. 변경 파일을 다시 stage한 뒤 커밋하면 포매팅 검증을 통과합니다.

## 저장소 구조

```text
.
├── sources/            # iOS 앱, Tuist 작업 공간과 아키텍처 문서
├── .specify/           # Spec Kit 설정과 Constitution
├── .agents/            # 프로젝트 전용 에이전트 스킬
├── .github/            # CI와 협업 정책
└── tools/
    ├── githooks/       # Git Hook 및 저장소 자동화
    ├── repository-paths/ # 저장소 공용 경로 관리
    ├── script-verification/ # POSIX 셸 정적·회귀 검증
    └── swift-style/    # Swift 포맷·린트 도구
```

프로젝트의 구조 설계와 의존 규칙은 [아키텍처 문서](sources/docs/architecture.md)를 기준으로
합니다. 상위 개발 원칙은 [Constitution](.specify/memory/constitution.md)에 정의되어
있습니다. 셸 자동화는 프로젝트 전용 `write-project-scripts` 스킬의
[스크립트 아키텍처](.agents/skills/write-project-scripts/references/architecture.md)와
[POSIX 셸 컨벤션](.agents/skills/write-project-scripts/references/conventions.md)을 따릅니다.

## 저장소 경로 환경

저장소에서 사용하는 공용 경로는
[`tools/repository-paths/repository-paths.json`](tools/repository-paths/repository-paths.json)에
저장소 상대경로로 정의합니다. `tools/githooks`, CI와 로컬 자동화는 값을 직접 복제하지 않고 다음
공용 명령으로 읽습니다.

```sh
./tools/repository-paths/bin/repository-paths.sh
./tools/repository-paths/bin/repository-paths.sh GIT_IT_IOS_ROOT
```

인자 없이 실행하면 CI가 적재할 수 있는 `KEY=value` 목록을 출력하며, 키 하나를 전달하면 해당
상대경로만 출력합니다. 로컬 실행에서 같은 이름의 환경변수를 명시하면 JSON 기본값보다 우선합니다.

## Git 훅 설정

저장소를 처음 내려받은 후 다음 명령을 실행합니다. `make init` 또는 `make hooks`로도 같은
명령을 실행할 수 있습니다.

```sh
./tools/githooks/hook-management/bin/install.sh
```

이 명령은 현재 저장소 local `core.hooksPath`만 `tools/githooks`로 설정하고 `commit-msg`와
`pre-commit` 훅의 실행 권한 및 실제 설정을 재확인합니다. `commit-msg` 훅은 다른 프로젝트
스크립트를 호출하지 않는 독립 실행 파일이며 `.github/COMMIT_CONVENTION.md`의
`[Tag] Message` 제목 계약만 검사합니다.

`pre-commit` 훅은 다음 순서로 공개 명령을 실행하며 한 단계가 실패하면 즉시 중단합니다.

1. staged Swift 포매팅과 재스테이징 확인
2. 전체 공유 scheme 일반 빌드
3. 테스트 scheme 컴파일
4. 컴파일된 테스트 실행

## 스크립트 공용 검증

`tools/githooks`, `tools/repository-paths`, `tools/script-verification`의 셸 스크립트는 다음
명령으로 정적 검사와 회귀 테스트를 실행합니다. ShellCheck와 shfmt가 없으면 준비 명령을 먼저
실행합니다. 준비 명령은 `make verify-tools`로도 실행할 수 있습니다.

```sh
./tools/script-verification/bin/prepare-tools.sh
./tools/script-verification/bin/run.sh
```

도구 의존성의 version 갱신·artifact 복구 절차는
[검증 도구 의존성 문서](.agents/skills/write-project-scripts/references/dependencies.md)를 참고합니다.
