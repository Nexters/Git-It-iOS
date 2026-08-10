# 스크립트 아키텍처 리뷰 체크리스트

## 계층 책임과 의존 방향

- [x] 모든 공개 `bin/`은 입력 검증, 유스케이스와 port 조립, 결과 렌더링을 담당한다.
- [x] 유스케이스 함수는 함수명으로 주입된 port를 조합하고 구체 Git·파일·도구 명령을 소유하지 않는다.
- [x] `*-policy.sh`의 순수 정책은 명시적 argv만 판정하며 외부 I/O와 환경에 접근하지 않는다.
- [x] adapter 함수만 Git, 파일 시스템, Xcode와 외부 프로세스 통신을 담당한다.
- [x] 다른 기능 모듈의 `core/`를 직접 source하지 않는다.
- [x] 교차 기능 호출은 기능 테스트와 각 기능의 공개 `bin/`만 사용하며 `commit-msg`는 프로젝트 스크립트를 호출하지 않는다.
- [x] `pre-commit`은 공개 셸 회귀·포매팅·빌드·테스트 명령만 fail-fast 호출하고 기능 내부 계층을 source하지 않는다.
- [x] `commit-msg`의 정책·입출력 동거 예외는 커밋 컨벤션 하나로 제한되고 독립 실행 회귀로 검증된다.

## 정책 중복과 공용 경계

- [x] 경로 포함 관계는 `shared/core/path-policy.sh` 한 곳에서 정의한다.
- [x] Git 상태 token은 `shared/core/git-status-policy.sh` 한 곳에서 정의한다.
- [x] 결과 상태와 안정 진단 code는 `shared/core/result-policy.sh`와 결과 계약에 일치한다.
- [x] 저장소 경로 기본값은 `tools/repository-paths/repository-paths.json` 한 곳에서 정의하고 공용 판독 명령으로만 소비한다.
- [x] JSON 판독기 이외의 스크립트와 CI에는 중앙 경로값이나 workspace basename을 하드코딩하지 않는다.
- [x] scheme, Swift target과 hook 정책은 각 기능에 남고, verification 정책은 스킬에, commit message 정책은 독립 훅 한 곳에만 있다.

## POSIX/BSD 및 상태 안전성

- [x] Bash 배열, `[[ ]]`, `local`, process substitution과 `pipefail`을 사용하지 않는다.
- [x] Git 경로 collection은 `-z`와 NUL 파일로 보존하고 `xargs -0`에서 argv로 복원한다.
- [x] 중요 생산 명령의 상태를 pipeline 뒤에서 잃지 않는다.
- [x] 호출별 단일 임시 디렉터리와 HUP·INT·TERM 정리 경로가 있다.
- [x] staged formatter 실패·중단 rollback은 원본 바이트와 metadata를 복원한다.
- [x] 포매터는 Git index를 쓰지 않고 staged 결과가 달라지면 재스테이징을 요구하며 commit-msg는 message file을 읽기만 한다.
- [x] 공용 검증은 dependency를 자동 준비하거나 네트워크에 접근하지 않는다.

## 예외

- [x] `commit-msg`의 단일 파일 예외는 다른 스크립트에 대한 런타임 의존을 완전히 제거하기 위한 것이며, 영향은 커밋 제목 검증에 한정되고 독립 실행·정적 검사를 모두 수행한다.
