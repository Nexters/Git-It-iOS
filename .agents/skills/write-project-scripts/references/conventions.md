# POSIX 셸 작성 컨벤션

## 함수와 상태 격리

source되는 공개 함수는 `name() ( ... )` 형태의 subshell 함수로 작성해 `cd`, `set --`, 변수와 trap이 호출자를 오염시키지 않게 한다. 순수 정책 함수는 외부 I/O, `exit`, `trap`, `mktemp`를 사용하지 않고 입력에 대한 안정 token만 출력한다. 유스케이스 함수는 주입된 port만 호출하며, adapter 함수가 Git·파일·프로세스 I/O를 담당한다. Bash 배열, `[[ ]]`, `local`, process substitution과 `pipefail`은 사용하지 않는다.

## 경로와 Git 상태

Git 경로 collection은 `-z` 결과를 NUL 파일로 유지하고 `xargs -0`에서 각 경로를 argv로 복원한다. 경로 목록을 command substitution이나 줄 단위 문자열로 저장하지 않는다. 실제 파일은 물리 경로로 정규화한 뒤 `shared/core/path-policy.sh`의 포함 관계로 허용 경계를 판정한다.

성공 여부가 중요한 생산 명령은 pipeline 앞에 두지 않는다. 결과를 호출별 임시 디렉터리에 기록하고 생산자 상태를 확인한 다음 소비한다. pipeline이 불가피한 읽기 전용 표시 작업은 앞 단계 실패가 결과 안전성에 영향을 주지 않는 경우에만 사용한다.

## 임시 자원과 rollback

한 invocation은 하나의 `mktemp -d` 경계를 소유한다. 정상 종료와 HUP·INT·TERM에서 임시 경계를 정리하고 신호 종료 상태 129·130·143을 보존한다. Git 훅의 staged formatter는 전체 대상을 실행하기 전에 원본 바이트와 metadata를 backup하고 NUL ledger로 원본 경로와 연결한다. 전체 성공에서만 ledger를 해제하며 실패·중단에서는 처리한 모든 대상을 복원한다. Git index에는 쓰지 않는다.

## 결과와 진단

정상 결과는 stdout, 실패와 복구 조치는 stderr에 출력한다. 예상 가능한 실패는 안정 code, 작업과 대상, 직접 원인, 사용자가 취할 조치를 제공한다. 대상 없음은 `skipped` 의미와 `swift-format.no-targets`를 출력하고 성공 종료한다. 새 안정 code는 `result-policy.sh`와 결과 계약, 관련 회귀를 한 논리 변경으로 갱신한다.

예외가 필요하면 이유, 영향과 검증하지 못한 범위를 변경의 자연어 문서에 기록한다. 설명 없는 예외는 허용하지 않는다.

## 독립 Git 훅 예외

`tools/githooks/commit-msg`는 커밋 컨벤션 검증 외의 책임을 갖지 않으며 `tools/githooks/`의 다른 명령이나 라이브러리를 호출 또는 source하지 않는다. 이 독립성 때문에 message file 읽기, 제목 정책 판정과 진단 렌더링을 한 파일에 함께 두되, 정책 함수는 명시적 문자열 인자만 받고 외부 상태를 변경하지 않는다. 이 예외의 영향 범위는 `commit-msg` 훅 하나이며 `scripts/` 기능 모듈의 계층 규칙을 완화하지 않는다.

`tools/githooks/pre-commit`은 독립 훅 예외가 아니다. 훅과 단계 스크립트는 모두 자신의 물리 경로를 기준으로 실행 저장소를 찾고, 각 기능의 공개 `bin/`을 셸 회귀, 포매팅, 일반 빌드, 테스트 컴파일 순서로 fail-fast 호출한다. 테스트 본문은 pre-commit에서 실행하지 않는다. 기능 내부 파일을 source하거나 세부 정책을 다시 정의하지 않는다. staged 포매팅이 작업 트리를 변경하면 Git index에는 쓰지 않고 `swift-format.restage-required`로 커밋을 중단한다.

## 주석 및 가독성

모든 스크립트 작성 시 과도하고 복잡한 구조를 지양하고, 코드의 주요 실행 단계마다 짧고 명확한 주석을 달아 의도를 설명한다.
