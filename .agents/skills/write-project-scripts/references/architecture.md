# 프로젝트 스크립트 아키텍처

저장소 자동화는 사용자 목적에 따라 `project-build`, `swift-format`, `hook-management`, `script-tests` 네 기능 모듈로 나눈다. 기술 종류가 아니라 함께 변경되는 정책과 실패 복구 계약이 기능 경계를 결정한다. 커밋 컨벤션은 Git이 직접 실행하는 `tools/githooks/commit-msg` 하나가 소유하며 일반 자동화 모듈과 분리한다. `tools/githooks/pre-commit`은 셸 회귀, 포매팅, 일반 빌드, 테스트 컴파일과 테스트 실행 공개 명령을 순서대로 조합한다. 정적 검증은 `tools/script-verification` 모듈이 소유한다.

## 계층과 의존 방향

각 기능은 다음 책임을 가진다.

- `bin/`: 공개 입력을 검증하고 유스케이스와 구체 port를 조립하며 결과와 진단을 출력한다.
- `core/*-policy.sh`: 명시적 argv만 받아 decision과 상태 token을 반환하는 순수 정책이다.
- `core/`의 유스케이스 함수: 함수명으로 주입된 port를 정해진 순서로 실행한다.
- `core/`의 adapter 함수: Git, 파일 시스템, Xcode와 외부 프로세스를 구체적으로 호출한다.
- `tests/`: 순수 정책 표 테스트와 격리된 외부 계약 회귀를 소유한다.

의존 방향은 `bin → core`다. 순수 정책은 외부 상태를 알지 못하고, 유스케이스 함수는 구체 명령 대신 주입된 port에만 의존한다. adapter는 입력을 관찰하거나 외부 명령을 실행하지만 정책을 다시 정의하지 않는다.

## 기능 간 호출

기능 모듈은 다른 기능의 `core/`를 source하지 않는다. 필요한 교차 기능은 공개 `bin/` 명령으로만 실행한다. `pre-commit`도 각 기능의 공개 `bin/`만 실행하고 내부 계층을 source하지 않는다. 스킬의 검증기는 프로젝트 셸을 정적 검사 입력으로만 읽으며, 설정된 정적 입력 루트를 찾기 위해 `repository-paths` 공개 판독기만 한 번 실행할 수 있다. 기능 명령, 기능 테스트 또는 프로젝트 빌드를 실행하거나 source하지 않는다.

`shared/core/`에는 둘 이상의 기능이 같은 의미와 계약으로 사용하는 실행 환경 중립 정책만 둔다. 현재 경로 포함 관계, Git 상태 분류와 결과/진단 상태가 해당한다. 한 기능의 target 선별, scheme, commit message나 hook 정책은 공유하지 않는다. 저장소 경로 기본값은 `GIT_IT_PATHS_FILE`이 가리키는 `tools/repository-paths/repository-paths.json`이 소유하고, `tools/repository-paths/bin/repository-paths.sh`만 이 JSON을 읽어 공개 환경변수 값을 제공한다. JSON 파일명과 판독기 자신의 물리 위치는 설정을 읽기 위한 최소 부트스트랩 예외이며, 다른 스크립트는 JSON의 구체 경로값이나 basename을 복제하지 않는다.

## 공개 계약

사용자와 저장소 연동점은 각 기능의 `bin/`, 저장소 경로를 제공하는 `tools/repository-paths/bin/repository-paths.sh`, Git이 직접 호출하는 `tools/githooks/commit-msg`와 `tools/githooks/pre-commit`, 스킬이 제공하는 검증 명령뿐이다. 내부 파일 경로와 함수명은 공개 API가 아니다. `commit-msg`는 커밋 메시지 파일 외의 프로젝트 스크립트나 기능 모듈에 의존하지 않는다. `pre-commit`은 `script-tests/bin/run.sh`, `swift-format/bin/run.sh staged`, `project-build/bin/run.sh build`, `project-build/bin/run.sh compile`, `project-build/bin/run.sh test`를 fail-fast 순서로 실행한다. `compile`은 테스트가 연결된 공유 scheme을 `build-for-testing`하고 `test`는 같은 Derived Data로 `test-without-building`한다. 새 공개 경로로 전환할 때 `tools/githooks`, Tuist, README와 스킬 참조 문서를 함께 갱신하고 이전 wrapper나 symlink를 남기지 않는다.
